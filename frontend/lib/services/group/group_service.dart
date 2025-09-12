import 'package:dio/dio.dart';
import 'dart:io';
import '../auth/auth_service.dart';
import '../../config.dart';

class GroupService {
  final Dio _dio;
  final AuthService _authService;
  
  // Cache için
  final Map<String, dynamic> _groupCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  GroupService({Dio? dio, required AuthService authService})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: '$kBaseUrl/api/',
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            )),
        _authService = authService;

  Options _authOptions(String? token) {
    if (token == null) throw Exception('Token bulunamadı. Lütfen giriş yapın.');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<dynamic>> fetchUserGroups() async {
    final token = await _authService.getToken();
    final response = await _dio.get('groups/', options: _authOptions(token));
    return response.data as List<dynamic>;
  }

  /// Grup detaylarını getir
  Future<Map<String, dynamic>> getGroupDetails(int groupId) async {
    final token = await _authService.getToken();
    final response = await _dio.get('groups/$groupId/', options: _authOptions(token));
    return response.data as Map<String, dynamic>;
  }

  /// Grup üyelerini getir
  Future<List<GroupMember>> getGroupMembers(int groupId) async {
    final cacheKey = 'group_members_$groupId';
    
    // Cache kontrolü
    if (_isCacheValid(cacheKey) && _groupCache.containsKey(cacheKey)) {
      return _groupCache[cacheKey] as List<GroupMember>;
    }

    final token = await _authService.getToken();
    final response = await _dio.get('groups/$groupId/members/', options: _authOptions(token));
    
    final members = (response.data as List)
        .map((json) => GroupMember.fromJson(json))
        .toList();
    
    // Cache'e kaydet
    _groupCache[cacheKey] = members;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    return members;
  }

  Future<void> createGroup(String name, String description, {File? profilePicture}) async {
    final token = await _authService.getToken();
    
    // FormData oluştur
    FormData formData = FormData.fromMap({
      'name': name,
      'description': description,
    });
    
    // Profil fotoğrafı varsa ekle
    if (profilePicture != null) {
      formData.files.add(MapEntry(
        'profile_picture',
        await MultipartFile.fromFile(
          profilePicture.path,
          filename: profilePicture.path.split('/').last,
        ),
      ));
    }
    
    // Grup oluştur
    final response = await _dio.post(
      'groups/',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    if (response.statusCode != 201) {
      throw Exception('Grup oluşturulamadı: ${response.statusCode}');
    }
    
    // Grup oluşturma sonrası cache'i temizle
    clearCache();
  }

  /// Grup profil fotoğrafını güncelle
  Future<void> updateGroupProfilePicture(int groupId, File newProfilePicture) async {
    final token = await _authService.getToken();
    
    // FormData oluştur
    FormData formData = FormData.fromMap({
      'profile_picture': await MultipartFile.fromFile(
        newProfilePicture.path,
        filename: newProfilePicture.path.split('/').last,
      ),
    });
    
    // Grup profil fotoğrafını güncelle
    final response = await _dio.patch(
      'groups/$groupId/',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Profil fotoğrafı güncellenemedi: ${response.statusCode}');
    }
  }

  // --- GRUP KATILIM TALEPLERİ ---

  /// Gruba katıl (public gruplar için)
  Future<Map<String, dynamic>> joinGroup(int groupId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.patch(
      'groups/$groupId/join-leave/',
      data: {'action': 'join'},
      options: _authOptions(token),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Gruba katılınamadı: ${response.statusCode}');
    }
    
    return response.data as Map<String, dynamic>;
  }

  /// Grup katılım talebi gönder
  Future<void> sendJoinRequest(int groupId, {String? message}) async {
    final token = await _authService.getToken();
    
    final response = await _dio.post(
      'groups/$groupId/join-requests/',
      data: {'message': message ?? ''},
      options: _authOptions(token),
    );
    
    if (response.statusCode != 201) {
      throw Exception('Katılım talebi gönderilemedi: ${response.statusCode}');
    }
  }

  /// Grup katılım taleplerini getir
  Future<List<dynamic>> getJoinRequests(int groupId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.get(
      'groups/$groupId/join-requests/',
      options: _authOptions(token),
    );
    
    return response.data as List<dynamic>;
  }

  /// Katılım talebini onayla
  Future<void> approveJoinRequest(int groupId, int requestId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.post(
      'groups/$groupId/join-requests/$requestId/approve/',
      options: _authOptions(token),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Katılım talebi onaylanamadı: ${response.statusCode}');
    }
  }

  /// Katılım talebini reddet
  Future<void> rejectJoinRequest(int groupId, int requestId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.post(
      'groups/$groupId/join-requests/$requestId/reject/',
      options: _authOptions(token),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Katılım talebi reddedilemedi: ${response.statusCode}');
    }
  }

  // --- GRUP MESAJLARI ---

  /// Grup mesajlarını getir
  Future<List<dynamic>> getGroupMessages(int groupId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.get(
      'groups/$groupId/messages/',
      options: _authOptions(token),
    );
    
    return response.data as List<dynamic>;
  }

  /// Grup mesajı gönder
  Future<dynamic> sendGroupMessage(int groupId, String content, {String? messageType, String? fileUrl, int? replyTo, File? mediaFile}) async {
    final token = await _authService.getToken();
    
    if (mediaFile != null) {
      // Medya dosyası ile mesaj gönder
      print('Medya dosyası gönderiliyor: ${mediaFile.path}');
      print('Dosya boyutu: ${await mediaFile.length()} bytes');
      
      FormData formData = FormData.fromMap({
        'content': content,
        'message_type': messageType ?? 'image',
        if (replyTo != null) 'reply_to': replyTo,
      });
      
      // Dosya boyutunu kontrol et
      final fileSize = await mediaFile.length();
      print('Gönderilecek dosya boyutu: $fileSize bytes');
      
      if (fileSize == 0) {
        throw Exception('Dosya boş');
      }
      
      formData.files.add(MapEntry(
        'media',
        await MultipartFile.fromFile(
          mediaFile.path,
          filename: mediaFile.path.split('/').last,
        ),
      ));
      
      final response = await _dio.post(
        'groups/$groupId/messages/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      if (response.statusCode != 201) {
        throw Exception('Mesaj gönderilemedi: ${response.statusCode}');
      }
      
      return response.data;
    } else {
      // Sadece metin mesajı gönder
      final data = {
        'content': content,
        'message_type': messageType ?? 'text',
        if (fileUrl != null) 'file_url': fileUrl,
        if (replyTo != null) 'reply_to': replyTo,
      };
      
      final response = await _dio.post(
        'groups/$groupId/messages/',
        data: data,
        options: _authOptions(token),
      );
      
      if (response.statusCode != 201) {
        throw Exception('Mesaj gönderilemedi: ${response.statusCode}');
      }
      
      return response.data;
    }
  }

  /// Grup mesajını düzenle
  Future<void> editGroupMessage(int groupId, int messageId, String content) async {
    final token = await _authService.getToken();
    
    final response = await _dio.patch(
      'groups/$groupId/messages/$messageId/',
      data: {'content': content},
      options: _authOptions(token),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Mesaj düzenlenemedi: ${response.statusCode}');
    }
  }

  /// Grup mesajını sil
  Future<void> deleteGroupMessage(int groupId, int messageId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.delete(
      'groups/$groupId/messages/$messageId/',
      options: _authOptions(token),
    );
    
    if (response.statusCode != 204) {
      throw Exception('Mesaj silinemedi: ${response.statusCode}');
    }
  }

  // --- GRUP POSTLARI ---

  /// Grup postlarını getir
  Future<List<dynamic>> getGroupPosts(int groupId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.get(
      'posts/groups/$groupId/posts/',
      options: _authOptions(token),
    );
    
    return response.data as List<dynamic>;
  }

  /// Grup postu oluştur
  Future<Map<String, dynamic>> createGroupPost(int groupId, String content, {File? image}) async {
    final token = await _authService.getToken();
    
    FormData formData = FormData.fromMap({
      'content': content,
    });
    
    if (image != null) {
      // Dosya boyutunu kontrol et
      final fileSize = await image.length();
      print('Gönderilecek post resmi boyutu: $fileSize bytes');
      
      if (fileSize == 0) {
        throw Exception('Dosya boş');
      }
      
      formData.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
      ));
    }
    
    final response = await _dio.post(
      'posts/groups/$groupId/posts/',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    
    if (response.statusCode != 201) {
      throw Exception('Post oluşturulamadı: ${response.statusCode}');
    }
    
    // Grup postu oluşturma sonrası cache'i temizle
    clearCache();
    
    return response.data as Map<String, dynamic>;
  }

  /// Grup postunu güncelle
  Future<Map<String, dynamic>> updateGroupPost(
    int groupId, 
    int postId, 
    String content, {
    File? image,
  }) async {
    final token = await _authService.getToken();
    
    FormData formData = FormData.fromMap({
      'content': content,
    });
    
    if (image != null) {
      formData.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
      ));
    }
    
    final response = await _dio.patch(
      'posts/groups/$groupId/posts/$postId/',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Post güncellenemedi: ${response.statusCode}');
    }
    
    // Grup postu güncelleme sonrası cache'i temizle
    clearCache();
    
    return response.data as Map<String, dynamic>;
  }

  /// Grup postunu sil
  Future<void> deleteGroupPost(int groupId, int postId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.delete(
      'posts/$postId/',
      options: _authOptions(token),
    );
    
    if (response.statusCode != 204) {
      throw Exception('Post silinemedi: ${response.statusCode}');
    }
    
    // Grup postu silme sonrası cache'i temizle
    clearCache();
  }

  // --- GRUP ÜYELERİ ---

  /// Grup üyelerini getir
  Future<List<dynamic>> getGroupMembers(int groupId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.get(
      'groups/$groupId/members/',
      options: _authOptions(token),
    );
    
    return response.data as List<dynamic>;
  }

  /// Grup üyesini kaldır
  Future<void> removeGroupMember(int groupId, int userId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.delete(
      'groups/$groupId/members/$userId/',
      options: _authOptions(token),
    );
    
    if (response.statusCode != 204) {
      throw Exception('Üye kaldırılamadı: ${response.statusCode}');
    }
  }

  /// Üyeyi moderator yap
  Future<void> makeModerator(int groupId, int userId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.post(
      'groups/$groupId/members/$userId/make-moderator/',
      options: _authOptions(token),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Moderator yapılamadı: ${response.statusCode}');
    }
  }

  /// Grup bilgilerini güncelle
  Future<void> updateGroup(int groupId, String name, String description) async {
    final token = await _authService.getToken();
    
    // FormData oluştur
    FormData formData = FormData.fromMap({
      'name': name,
      'description': description,
    });
    
    final response = await _dio.patch(
      'groups/$groupId/',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Grup güncellenemedi: ${response.statusCode}');
    }
  }

  /// Grubu sil
  Future<void> deleteGroup(int groupId) async {
    final token = await _authService.getToken();
    
    final response = await _dio.delete(
      'groups/$groupId/',
      options: _authOptions(token),
    );
    
    if (response.statusCode != 204) {
      throw Exception('Grup silinemedi: ${response.statusCode}');
    }
  }

  // Cache helper methods
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
  
  void clearCache() {
    _groupCache.clear();
    _cacheTimestamps.clear();
  }
}

/// Grup üyesi modeli
class GroupMember {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;
  final String role;
  final DateTime joinedAt;
  final bool isOnline;

  GroupMember({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePicture,
    required this.role,
    required this.joinedAt,
    required this.isOnline,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePicture: json['profile_picture'],
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
      isOnline: json['is_online'] ?? false,
    );
  }
}
