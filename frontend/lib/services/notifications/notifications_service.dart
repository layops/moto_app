// lib/services/notifications/notifications_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../service_locator.dart';

class NotificationsService {
  final String _restApiBaseUrl = kBaseUrl;
  final String _wsApiUrl =
      kBaseUrl.replaceFirst('https', 'ws') + 'ws/notifications/';

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  Future<void> connectWebSocket() async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse('$_wsApiUrl?token=$token'));

      _channel!.stream.listen(
        (data) {
          final decodedData = jsonDecode(data);
          print('WebSocket yeni bildirim: $decodedData');
          _notificationStreamController.add(decodedData);
        },
        onDone: () => print('WebSocket kapandı'),
        onError: (error) => print('WebSocket hatası: $error'),
      );

      print('WebSocket bağlandı.');
    } catch (e) {
      print('WebSocket bağlantı hatası: $e');
    }
  }

  void disconnectWebSocket() {
    _channel?.sink.close();
    print('WebSocket bağlantısı kesildi.');
  }

  Future<List<dynamic>> getNotifications() async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) return [];

    final uri = Uri.parse('$_restApiBaseUrl/notifications/');
    final response =
        await http.get(uri, headers: {'Authorization': 'Token $token'});

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      print('Bildirimler alınamadı: ${response.statusCode}');
      return [];
    }
  }

  Future<void> markAllAsRead() async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) return;

    final uri = Uri.parse('$_restApiBaseUrl/notifications/mark-read/');
    final response =
        await http.patch(uri, headers: {'Authorization': 'Token $token'});

    if (response.statusCode == 200) {
      print('Tüm bildirimler okundu.');
    } else {
      print('Okundu işaretleme hatası: ${response.statusCode}');
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) return;

    final uri = Uri.parse('$_restApiBaseUrl/notifications/mark-read/');
    final response = await http.patch(
      uri,
      headers: {'Authorization': 'Token $token'},
      body: jsonEncode({
        'notification_ids': [notificationId]
      }),
    );

    if (response.statusCode == 200) {
      print('Bildirim $notificationId okundu.');
    } else {
      print('Bildirim okundu işaretleme hatası: ${response.statusCode}');
    }
  }
}
