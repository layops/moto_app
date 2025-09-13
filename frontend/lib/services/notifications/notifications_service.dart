// lib/services/notifications/notifications_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../service_locator.dart';

class NotificationsService {
  final String _restApiBaseUrl = '$kBaseUrl/api';
  // Render.com için WebSocket URL'i - WSS protokolü kullan, port belirtme
  final String _wsApiUrl = kBaseUrl.replaceFirst('https://', 'wss://') + '/ws/notifications/';
  
  // Polling fallback için
  Timer? _pollingTimer;
  bool _isPolling = false;
  
  // Debug için constructor'da URL'yi yazdır
  NotificationsService() {
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
  
  /// Ana bağlantı metodu - önce SSE'yi dener, başarısız olursa polling'e geçer
  Future<void> connect() async {
    try {
      // Önce SSE'yi dene
      await connectSSE();
    } catch (e) {
      // SSE başarısız olursa polling fallback başlat
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
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');
      
      final response = await request.close();
      
      if (response.statusCode == 200) {
        _isConnected = true;
        _connectionStatusController.add(true);
        
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
                    _notificationStreamController.add(decodedData);
                  }
                } catch (e) {
                }
              }
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
      } else {
        throw Exception('SSE bağlantı hatası: ${response.statusCode}');
      }
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
      // SSE başarısız olursa polling fallback başlat
      _startPollingFallback();
      
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

  /// Polling fallback başlatır
  void _startPollingFallback() {
    if (_isPolling) return;
    
    _isPolling = true;
    
    // İlk polling'i hemen yap
    _performPolling();
    
    // Sonra periyodik olarak devam et
    _pollingTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      await _performPolling();
    });
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

  /// Cache'i temizler
  void clearCache() {
    // NotificationsService için özel cache yok, sadece placeholder
    // Gelecekte bildirim cache'i eklenebilir
  }

  /// Servisi temizler
  void dispose() {
    disconnectWebSocket();
    disconnectSSE();
    _stopPollingFallback();
    _notificationStreamController.close();
    _connectionStatusController.close();
  }
}
