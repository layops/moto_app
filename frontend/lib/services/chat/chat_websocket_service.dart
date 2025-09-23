import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:dio/dio.dart';
import '../../config.dart';
import '../service_locator.dart';
import '../connection/connection_manager.dart';
import '../connection/smart_retry.dart';

/// Real-time chat için WebSocket servisi - Akıllı strateji ile
class ChatWebSocketService {
  final String _baseUrl = kBaseUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  // Akıllı bağlantı yönetimi
  final ConnectionManager _connectionManager = ConnectionManager();
  SmartRetry? _smartRetry;
  
  // Stream controllers
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<String> _typingController =
      StreamController<String>.broadcast();

  // Connection state
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentUserId;
  int? _lastMessageId; // Son mesaj ID'sini takip et
  Timer? _pollingTimer; // HTTP polling timer'ını takip et
  
  // Constructor
  ChatWebSocketService() {
    _smartRetry = SmartRetry(_connectionManager);
  }

  // Getters
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<String> get typingStream => _typingController.stream;
  bool get isConnected => _isConnected;

  /// WebSocket bağlantısını başlat - akıllı strateji ile
  Future<void> connectToRoom(String roomId) async {
    try {
      print('💬 Chat servisi HTTP modunda çalışıyor');
      // WebSocket yerine HTTP kullanıyoruz - daha güvenilir
      _isConnected = false;
      _connectionStatusController.add(false);
      _currentRoomId = roomId;
      
      print('🔗 HTTP modu için room ID set edildi: $_currentRoomId');
      
      // HTTP modunda polling ile mesajları kontrol et
      _startPollingForMessages();
      
    } catch (e) {
      print('❌ ChatWebSocketService: Bağlantı hatası: $e');
      _handleError(e);
    }
  }

  /// WebSocket ile bağlantı kurma
  Future<void> _connectWithWebSocket(String roomId) async {
    final token = await ServiceLocator.token.getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    // Önceki bağlantıyı kapat
    await disconnect();

    // WebSocket URL'ini oluştur
    final wsUrl = _baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$wsUrl/ws/chat/$roomId/?token=$token');

    // Timeout ile WebSocket bağlantısını başlat
    final timeout = _connectionManager.getConnectionTimeout();
    _channel = await Future.any([
      Future.value(WebSocketChannel.connect(uri)),
      Future.delayed(timeout).then((_) {
        throw TimeoutException('WebSocket connection timeout', timeout);
      }),
    ]);
    
    _currentRoomId = roomId;

    // Mesaj dinleyicisini başlat
    _subscription = _channel!.stream.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDisconnection,
    );

    _isConnected = true;
    _connectionStatusController.add(true);
    _connectionManager.updateConnectionStatus(true);

    print('🔌 ChatWebSocketService: WebSocket bağlantısı kuruldu - Room: $roomId');
  }

  /// Özel mesajlaşma için WebSocket bağlantısı
  Future<void> connectToPrivateChat(int userId1, int userId2) async {
    try {
      final token = await ServiceLocator.token.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      await disconnect();

      final wsUrl = _baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
      final uri = Uri.parse('$wsUrl/ws/private_chat/$userId1/$userId2/?token=$token');

      _channel = WebSocketChannel.connect(uri);
      _currentRoomId = 'private_${userId1}_$userId2';

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      _isConnected = true;
      _connectionStatusController.add(true);

      print('🔌 ChatWebSocketService: Özel sohbet bağlantısı kuruldu - $userId1 <-> $userId2');
    } catch (e) {
      print('❌ ChatWebSocketService: Özel sohbet bağlantı hatası: $e');
      _handleError(e);
    }
  }

  /// Mesaj gönder
  Future<void> sendMessage(String message) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket bağlantısı yok');
    }

    try {
      final messageData = {
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(messageData));
      print('📤 ChatWebSocketService: Mesaj gönderildi');
    } catch (e) {
      print('❌ ChatWebSocketService: Mesaj gönderme hatası: $e');
      throw Exception('Mesaj gönderilemedi: $e');
    }
  }

  /// Özel mesaj gönder
  Future<void> sendPrivateMessage(String message, int receiverId) async {
    if (!_isConnected || _channel == null) {
      print('❌ WebSocket bağlantısı yok, HTTP API kullanılmalı');
      throw Exception('WebSocket bağlantısı yok');
    }

    try {
      final messageData = {
        'message': message,
        'receiver_id': receiverId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(messageData));
      print('📤 ChatWebSocketService: Özel mesaj gönderildi - Alıcı: $receiverId');
    } catch (e) {
      print('❌ ChatWebSocketService: Özel mesaj gönderme hatası: $e');
      // Bağlantı durumunu güncelle
      _isConnected = false;
      _connectionStatusController.add(false);
      throw Exception('Özel mesaj gönderilemedi: $e');
    }
  }

  /// Typing indicator gönder
  void sendTypingIndicator() {
    if (!_isConnected || _channel == null) return;

    try {
      final typingData = {
        'type': 'typing',
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(typingData));
    } catch (e) {
      print('❌ ChatWebSocketService: Typing indicator hatası: $e');
    }
  }

  /// Bağlantıyı kapat
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _channel?.sink.close(status.goingAway);
      _pollingTimer?.cancel(); // HTTP polling timer'ını da iptal et
      
      _isConnected = false;
      _currentRoomId = null;
      _currentUserId = null;
      _lastMessageId = null; // Son mesaj ID'sini sıfırla
      
      _connectionStatusController.add(false);
      
      print('🔌 ChatWebSocketService: Bağlantı kapatıldı');
    } catch (e) {
      print('❌ ChatWebSocketService: Bağlantı kapatma hatası: $e');
    }
  }

  /// Gelen mesajları işle
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      print('📥 ChatWebSocketService: Mesaj alındı: $data');

      switch (data['type']) {
        case 'connection_established':
          print('✅ ChatWebSocketService: Bağlantı onaylandı');
          break;
          
        case 'chat_message':
          _messageController.add(data);
          break;
          
        case 'private_message':
          _messageController.add(data);
          break;
          
        case 'private_chat_message':
          _messageController.add(data);
          break;
          
        case 'typing':
          _typingController.add(data['username'] ?? 'Birisi');
          break;
          
        case 'error':
          print('❌ ChatWebSocketService: Sunucu hatası: ${data['message']}');
          break;
          
        default:
          print('❓ ChatWebSocketService: Bilinmeyen mesaj türü: ${data['type']}');
      }
    } catch (e) {
      print('❌ ChatWebSocketService: Mesaj işleme hatası: $e');
    }
  }

  /// Hata işleme - akıllı retry stratejisi ile
  void _handleError(dynamic error) {
    print('❌ ChatWebSocketService: WebSocket hatası: $error');
    _isConnected = false;
    _connectionStatusController.add(false);
    _connectionManager.updateConnectionStatus(false);
    
    // Akıllı retry stratejisi başlat
    if (_currentRoomId != null) {
      _smartRetry?.startRetry(() => connectToRoom(_currentRoomId!));
    }
  }

  /// Bağlantı kesilme işleme
  void _handleDisconnection() {
    print('🔌 ChatWebSocketService: Bağlantı kesildi');
    _isConnected = false;
    _connectionStatusController.add(false);
    _connectionManager.updateConnectionStatus(false);
    
    // HTTP moduna geç ve polling başlat
    if (_currentRoomId != null) {
      print('🔄 HTTP moduna geçiş yapılıyor - Room: $_currentRoomId');
      _startPollingForMessages();
    }
    
    // Bağlantı kesilirse akıllı retry başlat
    if (_currentRoomId != null) {
      _smartRetry?.startRetry(() => connectToRoom(_currentRoomId!));
    }
  }

  /// HTTP polling ile mesajları kontrol et
  void _startPollingForMessages() {
    print('📡 HTTP polling başlatıldı');
    
    // Önceki timer'ı iptal et
    _pollingTimer?.cancel();
    
    // İlk polling'i hemen yap
    if (_currentRoomId != null && !_isConnected) {
      print('🚀 İlk HTTP polling hemen yapılıyor...');
      _fetchLatestMessages();
    }
    
    // Her 5 saniyede bir mesajları kontrol et (daha az sıklıkta)
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_currentRoomId != null && !_isConnected) {
        try {
          await _fetchLatestMessages();
        } catch (e) {
          print('❌ HTTP polling hatası: $e');
        }
      } else if (_isConnected) {
        // WebSocket bağlantısı varsa polling'i durdur
        timer.cancel();
        print('🔌 WebSocket bağlantısı aktif, HTTP polling durduruldu');
      } else {
        timer.cancel();
      }
    });
  }
  
  /// HTTP ile son mesajları getir
  Future<void> _fetchLatestMessages() async {
    if (_currentRoomId == null) return;
    
    final token = await ServiceLocator.token.getToken();
    if (token == null) return;
    
    try {
      // HTTP ile mesajları getir
      final dio = Dio();
      final response = await dio.get(
        '$_baseUrl/api/chat/rooms/$_currentRoomId/messages/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          // Son mesajı işle - sadece yeni mesajları kontrol et
          final lastMessage = data.last;
          final messageId = lastMessage['id'];
          
          // Eğer bu mesaj daha önce işlenmişse, tekrar işleme
          if (_lastMessageId == null || messageId > _lastMessageId!) {
            _lastMessageId = messageId;
            
            // Mesajı WebSocket formatında gönder
            final messageData = {
              'type': 'private_chat_message',
              'message': lastMessage['message'],
              'sender_id': lastMessage['sender']['id'],
              'sender_username': lastMessage['sender']['username'],
              'receiver_id': lastMessage['receiver']['id'],
              'receiver_username': lastMessage['receiver']['username'],
              'message_id': lastMessage['id'],
              'timestamp': lastMessage['timestamp'],
              'is_read': lastMessage['is_read'],
            };
            
            _messageController.add(messageData);
            print('📥 HTTP polling: Yeni mesaj alındı - ${lastMessage['message']} (ID: $messageId)');
          }
          // Gereksiz log mesajını kaldırdık - sadece yeni mesajlar için log
        }
      }
    } catch (e) {
      print('❌ HTTP polling mesaj alma hatası: $e');
    }
  }

  /// HTTP polling'i manuel olarak tetikle
  void triggerPolling() {
    if (_currentRoomId != null) {
      print('🔄 HTTP polling manuel olarak tetiklendi - Room: $_currentRoomId');
      _fetchLatestMessages();
    } else {
      print('❌ HTTP polling tetiklenemedi - _currentRoomId null');
    }
  }

  /// Dispose
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStatusController.close();
    _typingController.close();
  }
}
