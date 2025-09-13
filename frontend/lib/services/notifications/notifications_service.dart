// lib/services/notifications/notifications_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../service_locator.dart';

class NotificationsService {
  final String _restApiBaseUrl = '$kBaseUrl/api';
  // Render.com için WebSocket URL'i - HTTPS protokolü kullan (Render.com proxy)
  final String _wsApiUrl = kBaseUrl + '/ws/notifications/';
  
  // Debug için constructor'da URL'yi yazdır
  NotificationsService() {
    print('DEBUG: kBaseUrl = $kBaseUrl');
    print('DEBUG: _wsApiUrl = $_wsApiUrl');
  }

  WebSocketChannel? _channel;
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

  /// WebSocket bağlantısını başlatır
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
      
      // Render.com için WebSocket bağlantısı - HTTPS üzerinden upgrade
      print('DEBUG: WebSocketChannel.connect çağrılıyor...');
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['websocket'],
      );

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
    _notificationStreamController.close();
    _connectionStatusController.close();
  }
}
