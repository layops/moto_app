// lib/services/notifications/notifications_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../service_locator.dart';
import '../connection/connection_manager.dart';
import '../connection/smart_retry.dart';

class NotificationsService {
  final String _restApiBaseUrl = '$kBaseUrl/api';
  // Render.com için WebSocket URL'i - WSS protokolü kullan, port belirtme
  final String _wsApiUrl = kBaseUrl.replaceFirst('https://', 'wss://') + '/ws/notifications/';
  
  // Akıllı bağlantı yönetimi
  final ConnectionManager _connectionManager = ConnectionManager();
  SmartRetry? _smartRetry;
  
  // Polling fallback için
  Timer? _pollingTimer;
  bool _isPolling = false;
  
  // Debug için constructor'da URL'yi yazdır
  NotificationsService() {
    _smartRetry = SmartRetry(_connectionManager);
    // Service initialized
  }

  WebSocketChannel? _channel;
  HttpClient? _sseClient;
  StreamSubscription? _sseSubscription;
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;
  Stream<bool> get connectionStatusStream =>
      _connectionStatusController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  /// Ana bağlantı metodu - akıllı strateji ile en iyi bağlantı türünü seçer
  Future<void> connect() async {
    if (_isConnected) {
      print('⚠️ Zaten bağlı, yeniden bağlanma iptal edildi');
      return;
    }
    
    try {
      // Connection Manager'ı başlat
      await _connectionManager.initialize();
      
      // SSE production'da sorunlu, direkt polling kullan
      print('📡 Bildirimler polling ile bağlanıyor (SSE production sorunlu)');
      await _connectWithPolling();
      _connectionManager.updateConnectionType(ConnectionType.polling);
      
      print('✅ Polling bağlantı başarılı');
      
    } catch (e) {
      print('❌ Akıllı bağlantı başarısız: $e');
      // Akıllı retry başlat - sadece henüz bağlı değilse
      if (!_isConnected) {
        _smartRetry?.startRetry(() => connect());
      }
    }
  }

  /// WebSocket ile bağlanma
  Future<void> _connectWithWebSocket() async {
    try {
      await connectWebSocket();
      _connectionManager.updateConnectionStatus(true);
    } catch (e) {
      _connectionManager.updateConnectionStatus(false);
      throw e;
    }
  }

  /// SSE ile bağlanma
  Future<void> _connectWithSSE() async {
    try {
      await connectSSE();
      _connectionManager.updateConnectionStatus(true);
    } catch (e) {
      _connectionManager.updateConnectionStatus(false);
      // SSE başarısız olursa polling fallback başlat
      print('🔄 SSE başarısız, polling fallback başlatılıyor...');
      _startPollingFallback();
      throw e;
    }
  }

  /// Polling ile bağlanma
  Future<void> _connectWithPolling() async {
    try {
      _startPollingFallback();
      _isConnected = true;
      _connectionManager.updateConnectionStatus(true);
    } catch (e) {
      _isConnected = false;
      _connectionManager.updateConnectionStatus(false);
      throw e;
    }
  }

  /// Akıllı yeniden bağlanma - bağlantı türüne göre en iyi stratejiyi seçer
  Future<void> _smartReconnect() async {
    if (_isConnected) return;
    
    try {
      // En iyi bağlantı türünü yeniden değerlendir
      final bestType = _connectionManager.determineBestConnectionType();
      _connectionManager.updateConnectionType(bestType);
      
      // Bağlantı türüne göre yeniden bağlan
      switch (bestType) {
        case ConnectionType.websocket:
          await _connectWithWebSocket();
          print('✅ WebSocket ile yeniden bağlanıldı');
          break;
        case ConnectionType.sse:
          await _connectWithSSE();
          print('✅ SSE ile yeniden bağlanıldı');
          break;
        case ConnectionType.polling:
          await _connectWithPolling();
          print('✅ Polling ile yeniden bağlanıldı');
          break;
      }
    } catch (e) {
      print('❌ Akıllı yeniden bağlanma başarısız: $e');
      // Son çare olarak polling'e geç
      _startPollingFallback();
    }
  }
  
  /// Bağlantıyı kapatır
  void disconnect() {
    disconnectSSE();
    disconnectWebSocket();
    _stopPollingFallback();
  }

  /// Server-Sent Events ile bağlantıyı başlatır (WebSocket alternatifi)
  Future<void> connectSSE() async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    // Eğer zaten bağlıysa, önceki bağlantıyı kapat
    if (_isConnected) {
      disconnectSSE();
    }

    try {
      
      final uri = Uri.parse('$_restApiBaseUrl/notifications/stream/');
      final request = await HttpClient().getUrl(uri);
      
      // Authorization header ekle
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'text/event-stream, */*');
      request.headers.set('Cache-Control', 'no-cache');
      request.headers.set('Connection', 'keep-alive');
      request.headers.set('User-Agent', 'MotoApp/1.0');
      
      print('SSE isteği gönderiliyor: $uri');
      final response = await request.close();
      
      print('SSE response status: ${response.statusCode}');
      print('SSE response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        _isConnected = true;
        if (!_connectionStatusController.isClosed) {
          _connectionStatusController.add(true);
        }
        
        // SSE stream'i dinle
        response.listen(
          (data) {
            final text = utf8.decode(data);
            final lines = text.split('\n');
            
            for (final line in lines) {
              if (line.startsWith('data: ')) {
                try {
                  final jsonData = line.substring(6); // 'data: ' kısmını çıkar
                  if (jsonData.trim().isNotEmpty) {
                    final decodedData = jsonDecode(jsonData);
                    
                    // Heartbeat mesajlarını handle et
                    if (decodedData['type'] == 'heartbeat') {
                      print('💓 SSE heartbeat alındı');
                      continue; // Heartbeat'i notification stream'e ekleme
                    }
                    
                    // Error mesajlarını handle et
                    if (decodedData['type'] == 'error') {
                      print('❌ SSE error: ${decodedData['error']}');
                      continue;
                    }
                    
                    if (!_notificationStreamController.isClosed) {
                      _notificationStreamController.add(decodedData);
                    }
                  }
                } catch (e) {
                  print('SSE data parse hatası: $e');
                }
              }
            }
          },
          onDone: () {
            _isConnected = false;
            if (!_connectionStatusController.isClosed) {
              _connectionStatusController.add(false);
            }
            print('SSE stream kapandı');
          },
          onError: (error) {
            _isConnected = false;
            if (!_connectionStatusController.isClosed) {
              _connectionStatusController.add(false);
            }
            if (!_notificationStreamController.isClosed) {
              _notificationStreamController.addError(error);
            }
            print('SSE stream hatası: $error');
          },
        );
      } else {
        throw Exception('SSE bağlantı hatası: ${response.statusCode}');
      }
    } catch (e) {
      _isConnected = false;
      if (!_connectionStatusController.isClosed) {
        _connectionStatusController.add(false);
      }
      
      throw Exception('SSE bağlantı hatası: $e');
    }
  }

  /// SSE bağlantısını kapatır
  void disconnectSSE() {
    if (_sseClient != null) {
      _sseClient!.close();
      _sseClient = null;
    }
    if (_sseSubscription != null) {
      _sseSubscription!.cancel();
      _sseSubscription = null;
    }
    _isConnected = false;
    _connectionStatusController.add(false);
    
    // Polling'i de durdur
    _stopPollingFallback();
  }

  /// WebSocket bağlantısını başlatır (eski metod - SSE başarısız olursa kullanılabilir)
  Future<void> connectWebSocket() async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    // Eğer zaten bağlıysa, önceki bağlantıyı kapat
    if (_isConnected) {
      disconnectWebSocket();
    }

    try {
      final wsUrl = '$_wsApiUrl?token=$token';
      final uri = Uri.parse(wsUrl);
      
      // Render.com'da WebSocket bağlantısı için timeout ekle
      _channel = await Future.any([
        Future.value(WebSocketChannel.connect(
          Uri.parse(wsUrl),
        )).then((channel) {
          return channel;
        }),
        Future.delayed(Duration(seconds: 5)).then((_) {
          throw TimeoutException('WebSocket connection timeout', Duration(seconds: 5));
        }),
      ]);

      _channel!.stream.listen(
        (data) {
          try {
            final decodedData = jsonDecode(data);
            _notificationStreamController.add(decodedData);
          } catch (e) {
          }
        },
        onDone: () {
          _isConnected = false;
          _connectionStatusController.add(false);
        },
        onError: (error) {
          _isConnected = false;
          _connectionStatusController.add(false);
          _notificationStreamController.addError(error);
        },
      );

      _isConnected = true;
      _connectionStatusController.add(true);
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
      // WebSocket başarısız olursa polling fallback başlat
      _startPollingFallback();
      
      throw Exception('WebSocket bağlantı hatası: $e');
    }
  }

  /// WebSocket bağlantısını kapatır
  void disconnectWebSocket() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _connectionStatusController.add(false);
    
    // Polling'i de durdur
    _stopPollingFallback();
  }

  /// Polling fallback başlatır - akıllı interval ile
  void _startPollingFallback() {
    if (_isPolling) return;
    
    _isPolling = true;
    
    // İlk polling'i hemen yap
    _performPolling();
    
    // Akıllı interval ile periyodik polling
    final optimalInterval = _connectionManager.getOptimalPollingInterval();
    _pollingTimer = Timer.periodic(optimalInterval, (timer) async {
      await _performPolling();
    });
    
    print('📡 Polling başlatıldı - interval: ${optimalInterval.inSeconds}s');
  }
  
  /// Polling işlemini gerçekleştirir
  Future<void> _performPolling() async {
    try {
      // WebSocket bağlıysa polling yapma (çift bildirim önleme)
      if (_isConnected) {
        return;
      }
      
      final notifications = await getNotifications();
      if (notifications.isNotEmpty) {
        // Yeni bildirimler varsa notification stream'e ekle
        for (final notification in notifications) {
          _notificationStreamController.add(notification);
        }
      }
    } catch (e) {
      // Polling hatası durumunda interval'i artır
      if (_pollingTimer != null) {
        _pollingTimer!.cancel();
        _pollingTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
          await _performPolling();
        });
      }
    }
  }
  
  /// Polling fallback'i durdurur
  void _stopPollingFallback() {
    if (_pollingTimer != null) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
    }
    _isPolling = false;
  }

  /// Backend'den bildirimleri çeker
  Future<List<dynamic>> getNotifications() async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final uri = Uri.parse('$_restApiBaseUrl/notifications/');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 401) {
        throw Exception('Yetkilendirme hatası. Lütfen tekrar giriş yapın.');
      } else {
        throw Exception('Bildirimler alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ağ hatası: $e');
    }
  }

  /// Tüm bildirimleri okundu olarak işaretler
  Future<void> markAllAsRead() async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final uri = Uri.parse('$_restApiBaseUrl/notifications/mark-read/');
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
      } else if (response.statusCode == 401) {
        throw Exception('Yetkilendirme hatası. Lütfen tekrar giriş yapın.');
      } else {
        throw Exception('Bildirimler okundu olarak işaretlenemedi: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ağ hatası: $e');
    }
  }

  /// Belirli bir bildirimi okundu olarak işaretler
  Future<void> markAsRead(int notificationId) async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final uri = Uri.parse('$_restApiBaseUrl/notifications/mark-read/');
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'notification_ids': [notificationId]
        }),
      );

      if (response.statusCode == 200) {
      } else if (response.statusCode == 401) {
        throw Exception('Yetkilendirme hatası. Lütfen tekrar giriş yapın.');
      } else {
        throw Exception('Bildirim okundu olarak işaretlenemedi: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ağ hatası: $e');
    }
  }

  /// Kullanıcının bildirim tercihlerini getirir
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final uri = Uri.parse('$_restApiBaseUrl/notifications/preferences/');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 401) {
        throw Exception('Yetkilendirme hatası. Lütfen tekrar giriş yapın.');
      } else {
        throw Exception('Bildirim tercihleri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ağ hatası: $e');
    }
  }

  /// Kullanıcının bildirim tercihlerini günceller
  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final uri = Uri.parse('$_restApiBaseUrl/notifications/preferences/');
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(preferences),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return responseData['preferences'] ?? responseData;
      } else if (response.statusCode == 401) {
        throw Exception('Yetkilendirme hatası. Lütfen tekrar giriş yapın.');
      } else {
        throw Exception('Bildirim tercihleri güncellenemedi: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ağ hatası: $e');
    }
  }

  /// FCM token kaydetme kaldırıldı - Supabase push notifications kullanılıyor
  // Future<void> saveFCMToken(String fcmToken) async {
  //   // FCM token kaydetme kaldırıldı - Supabase push notifications kullanılıyor
  //   print('⚠️ FCM token kaydetme kaldırıldı - Supabase push notifications kullanılıyor');
  // }

  /// Cache'i temizler
  void clearCache() {
    // NotificationsService için özel cache yok, sadece placeholder
    // Gelecekte bildirim cache'i eklenebilir
  }

  /// Servisi temizler
  void dispose() {
    _smartRetry?.dispose();
    _connectionManager.dispose();
    
    disconnectWebSocket();
    disconnectSSE();
    _stopPollingFallback();
    
    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.close();
    }
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.close();
    }
    
    print('🧹 NotificationsService temizlendi');
  }
}
