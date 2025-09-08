import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../service_locator.dart';

class ChatService {
  final String _baseUrl = kBaseUrl;

  Future<String?> _getToken() async {
    return await ServiceLocator.token.getToken();
  }

  /// Özel mesajları getir
  Future<List<PrivateMessage>> getPrivateMessages() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chat/private-messages/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data as List)
            .map((json) => PrivateMessage.fromJson(json))
            .toList();
      } else {
        throw Exception('Mesajlar alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mesajlar alınırken hata: $e');
    }
  }

  /// Konuşma listesini getir (son mesajlar ile birlikte)
  Future<List<Conversation>> getConversations() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chat/conversations/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data as List)
            .map((json) => Conversation.fromJson(json))
            .toList();
      } else {
        throw Exception('Konuşmalar alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Konuşmalar alınırken hata: $e');
    }
  }

  /// Belirli bir kullanıcı ile konuşmayı getir
  Future<List<PrivateMessage>> getConversationWithUser(int userId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chat/private-messages/$userId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data as List)
            .map((json) => PrivateMessage.fromJson(json))
            .toList();
      } else {
        throw Exception('Konuşma alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Konuşma alınırken hata: $e');
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
        Uri.parse('$_baseUrl/api/chat/private-messages/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'receiver': receiverId,
          'message': message,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PrivateMessage.fromJson(data);
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
        Uri.parse('$_baseUrl/api/chat/private-messages/$messageId/mark-read/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Mesaj okundu olarak işaretlenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mesaj işaretlenirken hata: $e');
    }
  }

  /// Kullanıcıları ara
  Future<List<User>> searchUsers(String query) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/search/?q=$query'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data as List)
            .map((json) => User.fromJson(json))
            .toList();
      } else {
        throw Exception('Kullanıcılar aranamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kullanıcılar aranırken hata: $e');
    }
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
