import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';
import '../service_locator.dart';
import '../http/api_client.dart';

class PostService {
  // ServiceLocator'dan ApiClient kullan
  ApiClient get _apiClient => ServiceLocator.api;
  
  // Cache için
  final Map<String, List<dynamic>> _postsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 3);

  PostService();

  Future<String?> _getToken() async {
    return await ServiceLocator.token.getToken();
  }

  Future<void> createPost({
    required String content,
    File? file,
    int? groupPk,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Lütfen giriş yapın.');
    }

    FormData formData = FormData.fromMap({'content': content});
    if (file != null) {
      formData.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      ));
    }

    final endpoint = groupPk != null ? 'groups/$groupPk/posts/' : 'posts/';

    try {
      final response = await _apiClient.post(endpoint, formData);
      
      if (response.statusCode != 201) {
        throw Exception('Post oluşturulamadı: ${response.statusCode}');
      }
      
      // Cache'i temizle
      _clearPostsCache();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('API endpointi bulunamadı: $kBaseUrl/$endpoint');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Sunucuya bağlanılamıyor. Lütfen sunucunun çalıştığından emin olun.');
      } else {
        throw Exception('Post oluşturulurken hata oluştu: ${e.message}');
      }
    }
  }

  Future<List<dynamic>> fetchPosts(String token, {int? groupPk}) async {
    final endpoint = groupPk != null ? 'groups/$groupPk/posts/' : 'posts/';
    final cacheKey = 'posts_${groupPk ?? 'all'}';

    // Cache kontrolü
    if (_isCacheValid(cacheKey)) {
      return _postsCache[cacheKey]!;
    }

    try {
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final posts = response.data as List<dynamic>;
        
        // Cache'e kaydet
        _postsCache[cacheKey] = posts;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return posts;
      } else {
        throw Exception('Postlar alınamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('API endpointi bulunamadı: $kBaseUrl/$endpoint');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Sunucuya bağlanılamıyor. Lütfen sunucunun çalıştığından emin olun.');
      } else {
        throw Exception('Postlar alınırken hata oluştu: ${e.message}');
      }
    }
  }

  /// Profil postlarını çekmek için
  Future<List<dynamic>> fetchUserPosts(String username) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Lütfen giriş yapın.');
    }

    final endpoint = 'posts/?username=$username';
    final cacheKey = 'user_posts_$username';

    // Cache kontrolü
    if (_isCacheValid(cacheKey)) {
      return _postsCache[cacheKey]!;
    }

    try {
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final posts = response.data as List<dynamic>;
        
        // Cache'e kaydet
        _postsCache[cacheKey] = posts;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return posts;
      } else {
        throw Exception('Postlar alınamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('API endpointi bulunamadı: $kBaseUrl/$endpoint');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Sunucuya bağlanılamıyor. Lütfen sunucunun çalıştığından emin olun.');
      } else {
        throw Exception('Postlar alınırken hata oluştu: ${e.message}');
      }
    }
  }
  
  // Cache helper methods
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
  
  void _clearPostsCache() {
    _postsCache.clear();
    _cacheTimestamps.clear();
  }
  
  void clearCache() {
    _clearPostsCache();
  }
}
