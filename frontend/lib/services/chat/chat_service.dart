import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../service_locator.dart';

class ChatService {
  final String _baseUrl = '$kBaseUrl/api';
  
  // Cache için
  final Map<String, List<PrivateMessage>> _messagesCache = {};
  final Map<String, List<Conversation>> _conversationsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(seconds: 30); // Cache süresini kısalt

  Future<String?> _getToken() async {
    return await ServiceLocator.token.getToken();
  }

  Future<int?> _getCurrentUserId() async {
    try {
      final currentUser = await ServiceLocator.user.getCurrentUsername();
      if (currentUser != null) {
        final profileData = await ServiceLocator.profile.getProfile(currentUser);
        return profileData?['id'];
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
    return null;
  }

  /// Özel mesajları getir
  Future<List<PrivateMessage>> getPrivateMessages() async {
    const cacheKey = 'private_messages';
    
    // Cache kontrolü
    if (_isCacheValid(cacheKey) && _messagesCache.containsKey(cacheKey)) {
      return _messagesCache[cacheKey]!;
    }
    
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/private-messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data as List)
            .map((json) => PrivateMessage.fromJson(json))
            .toList();
            
        // Cache'e kaydet
        _messagesCache[cacheKey] = messages;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return messages;
      } else {
        throw Exception('Mesajlar alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mesajlar alınırken hata: $e');
    }
  }

  /// Konuşma listesini getir (son mesajlar ile birlikte)
  Future<List<Conversation>> getConversations() async {
    const cacheKey = 'conversations';
    
    // Cache kontrolü - mesaj gönderme sonrası güncel veri için cache'i bypass et
    // if (_isCacheValid(cacheKey) && _conversationsCache.containsKey(cacheKey)) {
    //   return _conversationsCache[cacheKey]!;
    // }
    
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final url = '$_baseUrl/chat/conversations/';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversations = (data as List)
            .map((json) => Conversation.fromJson(json))
            .toList();
            
            
        // Cache'e kaydet
        _conversationsCache[cacheKey] = conversations;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return conversations;
      } else {
        throw Exception('Konuşmalar alınamadı: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Konuşmalar alınırken hata: $e');
    }
  }

  /// Belirli bir kullanıcı ile konuşmayı getir
  Future<List<PrivateMessage>> getConversationWithUser(int userId) async {
    final cacheKey = 'conversation_$userId';
    
    // Cache kontrolü
    if (_isCacheValid(cacheKey) && _messagesCache.containsKey(cacheKey)) {
      return _messagesCache[cacheKey]!;
    }
    
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/private-messages/with-user/$userId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data as List)
            .map((json) => PrivateMessage.fromJson(json))
            .toList();
            
        // Mesajları timestamp'e göre sırala
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            
        // Cache'e kaydet
        _messagesCache[cacheKey] = messages;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return messages;
      } else {
        throw Exception('Konuşma alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Konuşma alınırken hata: $e');
    }
  }

  /// Room messages endpoint'i (frontend'in beklediği format)
  Future<List<PrivateMessage>> getRoomMessages(int user1Id, int user2Id) async {
    final cacheKey = 'room_${user1Id}_${user2Id}';
    
    // Cache kontrolü
    if (_isCacheValid(cacheKey) && _messagesCache.containsKey(cacheKey)) {
      return _messagesCache[cacheKey]!;
    }
    
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/rooms/private_${user1Id}_${user2Id}/messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data as List)
            .map((json) => PrivateMessage.fromJson(json))
            .toList();
            
        // Mesajları timestamp'e göre sırala
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            
        // Cache'e kaydet
        _messagesCache[cacheKey] = messages;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return messages;
      } else {
        throw Exception('Room messages alınamadı: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Room messages alınırken hata: $e');
    }
  }

  /// Room'a mesaj gönder (frontend'in beklediği format)
  Future<PrivateMessage> sendRoomMessage({
    required int user1Id,
    required int user2Id,
    required String message,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      // Alıcı kullanıcıyı belirle (gönderen kullanıcı user1Id ise alıcı user2Id, değilse user1Id)
      final currentUserId = await _getCurrentUserId();
      final receiverId = currentUserId == user1Id ? user2Id : user1Id;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/rooms/private_${user1Id}_${user2Id}/messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'receiver_id': receiverId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newMessage = PrivateMessage.fromJson(data);
        
        // Cache'i temizle
        _clearMessageCache();
        
        return newMessage;
      } else {
        throw Exception('Room message gönderilemedi: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Room message gönderilirken hata: $e');
    }
  }

  /// Özel mesaj gönder
  Future<PrivateMessage> sendPrivateMessage({
    required int receiverId,
    required String message,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/private-messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'receiver_id': receiverId,
          'message': message,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newMessage = PrivateMessage.fromJson(data);
        
        // Cache'i temizle - mesaj gönderme sonrası tüm cache'leri temizle
        _clearMessageCache();
        
        // Conversations cache'ini de temizle ki yeni konuşma listeye eklensin
        _conversationsCache.clear();
        _cacheTimestamps.clear();
        
        
        return newMessage;
      } else {
        throw Exception('Mesaj gönderilemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mesaj gönderilirken hata: $e');
    }
  }

  /// Mesajı okundu olarak işaretle
  Future<void> markMessageAsRead(int messageId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/chat/private-messages/$messageId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_read': true}),
      );

      if (response.statusCode != 200) {
        throw Exception('Mesaj okundu olarak işaretlenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mesaj işaretlenirken hata: $e');
    }
  }

  /// Özel mesajı düzenle
  Future<PrivateMessage> editPrivateMessage({
    required int messageId,
    required String message,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/chat/private-messages/$messageId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedMessage = PrivateMessage.fromJson(data);
        
        // Cache'i temizle
        _clearMessageCache();
        
        return updatedMessage;
      } else {
        throw Exception('Mesaj düzenlenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mesaj düzenlenirken hata: $e');
    }
  }

  /// Özel mesajı sil
  Future<void> deletePrivateMessage(int messageId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/private-messages/$messageId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        // Cache'i temizle
        _clearMessageCache();
      } else {
        throw Exception('Mesaj silinemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mesaj silinirken hata: $e');
    }
  }

  /// Konuşmayı gizle (mesajları silme, sadece gizle)
  Future<void> hideConversation(int userId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/private-messages/conversation/$userId/hide/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Cache'i temizle
        _clearMessageCache();
      } else {
        throw Exception('Konuşma gizlenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Konuşma gizlenirken hata: $e');
    }
  }

  /// Kullanıcıları ara
  Future<List<User>> searchUsers(String query) async {
    final cacheKey = 'search_users_$query';
    
    // Cache kontrolü (kısa süreli cache)
    if (_isCacheValid(cacheKey) && _messagesCache.containsKey(cacheKey)) {
      // Bu durumda User listesi için ayrı cache kullanmak daha iyi olur
      // Şimdilik cache'lemiyoruz çünkü arama sonuçları sık değişebilir
    }
    
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final url = '$_baseUrl/search/users/?q=$query';
      // print('🔍 ChatService - Searching users at: $url');
      // print('🔍 ChatService - Query: "$query"');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // print('🔍 ChatService - Response status: ${response.statusCode}');
      // print('🔍 ChatService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = (data as List)
            .map((json) => User.fromJson(json))
            .toList();
        return users;
      } else {
        throw Exception('Kullanıcılar aranamadı: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Kullanıcılar aranırken hata: $e');
    }
  }

  /// Mesajlarda arama yap
  Future<List<PrivateMessage>> searchMessages(String query) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final url = '$_baseUrl/chat/private-messages/search/?q=${Uri.encodeComponent(query)}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data as List)
            .map((json) => PrivateMessage.fromJson(json))
            .toList();
        return messages;
      } else {
        throw Exception('Mesajlar aranamadı: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Mesajlar aranırken hata: $e');
    }
  }
  
  // Cache helper methods
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
  
  void _clearMessageCache() {
    _messagesCache.clear();
    _conversationsCache.clear();
    _cacheTimestamps.clear();
  }
  
  void clearCache() {
    _clearMessageCache();
  }
}

/// Özel mesaj modeli
class PrivateMessage {
  final int id;
  final User sender;
  final User receiver;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  PrivateMessage({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory PrivateMessage.fromJson(Map<String, dynamic> json) {
    return PrivateMessage(
      id: json['id'],
      sender: User.fromJson(json['sender']),
      receiver: User.fromJson(json['receiver']),
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'],
    );
  }
}

/// Konuşma modeli
class Conversation {
  final User otherUser;
  final PrivateMessage? lastMessage;
  final int unreadCount;
  final bool isOnline;

  Conversation({
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    required this.isOnline,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      otherUser: User.fromJson(json['other_user']),
      lastMessage: json['last_message'] != null 
          ? PrivateMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      isOnline: json['is_online'] ?? false,
    );
  }
}

/// Kullanıcı modeli
class User {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;

  User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePicture,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePicture: json['profile_picture'],
    );
  }
}
