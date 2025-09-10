import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../service_locator.dart';

class GroupChatService {
  final String _baseUrl = '$kBaseUrl/api';
  
  // Cache için
  final Map<String, List<GroupMessage>> _messagesCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 2);

  Future<String?> _getToken() async {
    return await ServiceLocator.token.getToken();
  }

  /// Grup mesajlarını getir
  Future<List<GroupMessage>> getGroupMessages(int groupId) async {
    final cacheKey = 'group_messages_$groupId';
    
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
        Uri.parse('$_baseUrl/groups/$groupId/messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data as List)
            .map((json) => GroupMessage.fromJson(json))
            .toList();
            
        // Mesajları timestamp'e göre sırala
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            
        // Cache'e kaydet
        _messagesCache[cacheKey] = messages;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return messages;
      } else {
        throw Exception('Grup mesajları alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Grup mesajları alınırken hata: $e');
    }
  }

  /// Grup mesajı gönder
  Future<GroupMessage> sendGroupMessage({
    required int groupId,
    required String content,
    String? replyToId,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final body = {
        'content': content,
        'message_type': 'text',
      };
      
      if (replyToId != null) {
        body['reply_to'] = replyToId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newMessage = GroupMessage.fromJson(data);
        
        // Cache'i temizle
        _clearGroupMessageCache(groupId);
        
        return newMessage;
      } else {
        throw Exception('Grup mesajı gönderilemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Grup mesajı gönderilirken hata: $e');
    }
  }

  /// Grup mesajı düzenle
  Future<GroupMessage> editGroupMessage({
    required int groupId,
    required int messageId,
    required String content,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/groups/$groupId/messages/$messageId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedMessage = GroupMessage.fromJson(data);
        
        // Cache'i temizle
        _clearGroupMessageCache(groupId);
        
        return updatedMessage;
      } else {
        throw Exception('Grup mesajı düzenlenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Grup mesajı düzenlenirken hata: $e');
    }
  }

  /// Grup mesajı sil
  Future<void> deleteGroupMessage({
    required int groupId,
    required int messageId,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/groups/$groupId/messages/$messageId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        // Cache'i temizle
        _clearGroupMessageCache(groupId);
      } else {
        throw Exception('Grup mesajı silinemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Grup mesajı silinirken hata: $e');
    }
  }

  // Cache helper methods
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
  
  void _clearGroupMessageCache(int groupId) {
    final cacheKey = 'group_messages_$groupId';
    _messagesCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
  }
  
  void clearCache() {
    _messagesCache.clear();
    _cacheTimestamps.clear();
  }
}

/// Grup mesajı modeli
class GroupMessage {
  final int id;
  final int groupId;
  final String groupName;
  final User sender;
  final String content;
  final String messageType;
  final String? fileUrl;
  final GroupMessage? replyTo;
  final String? replyToContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.sender,
    required this.content,
    required this.messageType,
    this.fileUrl,
    this.replyTo,
    this.replyToContent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'],
      groupId: json['group'],
      groupName: json['group_name'] ?? '',
      sender: User.fromJson(json['sender']),
      content: json['content'],
      messageType: json['message_type'] ?? 'text',
      fileUrl: json['file_url'],
      replyTo: json['reply_to'] != null ? GroupMessage.fromJson(json['reply_to']) : null,
      replyToContent: json['reply_to_content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Kullanıcı modeli (ChatService'den kopyalandı)
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
