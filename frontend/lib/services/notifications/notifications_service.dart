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
    print('DEBUG: kBaseUrl = $kBaseUrl');
    print('DEBUG: _wsApiUrl = $_wsApiUrl');
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
      print('SSE başarısız, polling fallback başlatılıyor: $e');
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
      print('DEBUG: SSE bağlantısı başlatılıyor...');
      
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
        print('SSE bağlantısı başarılı');
        
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
                    print('SSE yeni bildirim: $decodedData');
                    _notificationStreamController.add(decodedData);
                  }
                } catch (e) {
                  print('SSE veri parse hatası: $e');
                }
              }
            }
          },
          onDone: () {
            print('SSE bağlantısı kapandı');
            _isConnected = false;
            _connectionStatusController.add(false);
          },
          onError: (error) {
            print('SSE hatası: $error');
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
      print('SSE bağlantı hatası: $e');
      
      // SSE başarısız olursa polling fallback başlat
      print('DEBUG: SSE başarısız, polling fallback başlatılıyor...');
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
    print('SSE bağlantısı kesildi.');
    
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
      print('DEBUG: _wsApiUrl değeri: $_wsApiUrl');
      print('DEBUG: Token: $token');
      
      final wsUrl = '$_wsApiUrl?token=$token';
      print('DEBUG: WebSocket bağlantısı kuruluyor: $wsUrl');
      print('DEBUG: WebSocket URL protokolü: ${Uri.parse(wsUrl).scheme}');
      print('DEBUG: WebSocket URL host: ${Uri.parse(wsUrl).host}');
      print('DEBUG: WebSocket URL port: ${Uri.parse(wsUrl).port}');
      print('DEBUG: WebSocket URL path: ${Uri.parse(wsUrl).path}');
      print('DEBUG: Parsed URI: ${Uri.parse(wsUrl)}');
      
      final uri = Uri.parse(wsUrl);
      print('DEBUG: URI scheme: ${uri.scheme}');
      print('DEBUG: URI host: ${uri.host}');
      print('DEBUG: URI port: ${uri.port}');
      print('DEBUG: URI path: ${uri.path}');
      print('DEBUG: URI query: ${uri.query}');
      
      // Render.com için WebSocket bağlantısı - WSS protokolü
      print('DEBUG: WebSocketChannel.connect çağrılıyor...');
      
      // Render.com'da WebSocket bağlantısı için timeout ekle
      _channel = await Future.any([
        Future.value(WebSocketChannel.connect(
          Uri.parse(wsUrl),
        )).then((channel) {
          print('DEBUG: WebSocket bağlantısı başarılı');
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
            print('WebSocket yeni bildirim: $decodedData');
            _notificationStreamController.add(decodedData);
          } catch (e) {
            print('WebSocket veri parse hatası: $e');
          }
        },
        onDone: () {
          print('WebSocket kapandı');
          _isConnected = false;
          _connectionStatusController.add(false);
        },
        onError: (error) {
          print('WebSocket hatası: $error');
          _isConnected = false;
          _connectionStatusController.add(false);
          _notificationStreamController.addError(error);
        },
      );

      _isConnected = true;
      _connectionStatusController.add(true);
      print('WebSocket başarıyla bağlandı.');
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
      print('WebSocket bağlantı hatası: $e');
      
      // WebSocket başarısız olursa polling fallback başlat
      print('DEBUG: WebSocket başarısız, polling fallback başlatılıyor...');
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
    print('WebSocket bağlantısı kesildi.');
    
    // Polling'i de durdur
    _stopPollingFallback();
  }

  /// Polling fallback başlatır
  void _startPollingFallback() {
    if (_isPolling) return;
    
    _isPolling = true;
    print('DEBUG: Polling fallback başlatıldı');
    
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
        print('DEBUG: WebSocket bağlı, polling atlanıyor');
        return;
      }
      
      final notifications = await getNotifications();
      if (notifications.isNotEmpty) {
        // Yeni bildirimler varsa notification stream'e ekle
        for (final notification in notifications) {
          _notificationStreamController.add(notification);
        }
        print('DEBUG: Polling ile ${notifications.length} bildirim alındı');
      }
    } catch (e) {
      print('Polling hatası: $e');
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
    print('DEBUG: Polling fallback durduruldu');
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
        print('Tüm bildirimler okundu olarak işaretlendi.');
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
        print('Bildirim $notificationId okundu olarak işaretlendi.');
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
