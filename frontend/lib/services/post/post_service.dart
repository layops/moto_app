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
      if (e.response?.statusCode == 400) {
        // Bad Request - validation error
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('detail')) {
          throw Exception('Hata: ${errorData['detail']}');
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception('Hata: ${errorData['message']}');
        } else {
          throw Exception('Geçersiz veri gönderildi.');
        }
      } else if (e.response?.statusCode == 401) {
        throw Exception('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Bu işlem için yetkiniz yok.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('API endpointi bulunamadı: $kBaseUrl/$endpoint');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Sunucu hatası. Lütfen daha sonra tekrar deneyin.');
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

  Future<List<dynamic>> fetchPosts(String token, {int? groupPk, bool followingOnly = false}) async {
    String endpoint;
    String cacheKey;
    
    if (groupPk != null) {
      endpoint = 'groups/$groupPk/posts/';
      cacheKey = 'posts_group_$groupPk';
    } else if (followingOnly) {
      endpoint = 'posts/following/';
      cacheKey = 'posts_following';
    } else {
      endpoint = 'posts/';
      cacheKey = 'posts_all';
    }

    print('PostService - fetchPosts başlatıldı, endpoint: $endpoint');
    print('PostService - Cache key: $cacheKey');
    print('PostService - Following only: $followingOnly');

    // Cache kontrolü
    if (_isCacheValid(cacheKey)) {
      print('PostService - Cache geçerli, cache\'den döndürülüyor');
      return _postsCache[cacheKey]!;
    }

    print('PostService - Cache geçersiz veya yok, API\'den çekiliyor');

    try {
      // Cache bypass için timestamp ekle
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final urlWithTimestamp = '$endpoint?t=$timestamp';
      
      final response = await _apiClient.get(urlWithTimestamp);
      print('PostService - API response alındı, status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final posts = response.data as List<dynamic>;
        
        // Debug için gelen postları yazdır
        print('PostService - Fetched ${posts.length} posts');
        for (int i = 0; i < posts.length && i < 5; i++) {
          final post = posts[i] as Map<String, dynamic>;
          final content = post['content']?.toString() ?? '';
          final contentPreview = content.length > 20 ? '${content.substring(0, 20)}...' : content;
          print('PostService - Post ${post['id']}: content="$contentPreview", author=${post['author']?['username']}');
        }
        
        // Cache'e kaydet
        _postsCache[cacheKey] = posts;
        _cacheTimestamps[cacheKey] = DateTime.now();
        print('PostService - Posts cache\'e kaydedildi');
        
        return posts;
      } else {
        print('PostService - API error: ${response.statusCode}');
        throw Exception('Postlar alınamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('PostService - DioException: ${e.message}');
      print('PostService - Status code: ${e.response?.statusCode}');
      if (e.response?.statusCode == 404) {
        // Eğer following endpoint yoksa, fallback olarak tüm postları getir ve filtrele
        if (followingOnly) {
          print('PostService - Following endpoint bulunamadı, fallback yapılıyor...');
          return await _fetchFollowingPostsFallback();
        }
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
    } catch (e) {
      print('PostService - Genel hata: $e');
      // Eğer following endpoint yoksa, fallback olarak tüm postları getir ve filtrele
      if (followingOnly) {
        print('PostService - Genel hata durumunda fallback yapılıyor...');
        return await _fetchFollowingPostsFallback();
      }
      rethrow;
    }
  }

  /// Fallback: Tüm postları getir ve takip edilen kullanıcıların postlarını filtrele
  Future<List<dynamic>> _fetchFollowingPostsFallback() async {
    try {
      print('🔄 PostService - Fallback: Tüm postları getirip filtreleme yapılıyor...');
      
      // Tüm postları getir
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await _apiClient.get('posts/?t=$timestamp');
      
      print('🔄 PostService - Fallback: Tüm postlar alındı, status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final allPosts = response.data as List<dynamic>;
        print('🔄 PostService - Fallback: Toplam ${allPosts.length} post alındı');
        
        // Takip edilen kullanıcıları al
        final currentUser = await ServiceLocator.auth.currentUser;
        if (currentUser == null) {
          print('❌ PostService - Fallback: Kullanıcı bilgisi alınamadı');
          return [];
        }
        
        final username = currentUser['username'];
        if (username == null) {
          print('❌ PostService - Fallback: Username alınamadı');
          return [];
        }
        
        print('🔄 PostService - Fallback: Mevcut kullanıcı: $username');
        
        // Takip edilen kullanıcıları getir
        final following = await ServiceLocator.follow.getFollowing(username);
        final followingUsernames = following.map((user) => user['username'] as String).toSet();
        followingUsernames.add(username); // Kendi postlarını da ekle
        
        print('🔄 PostService - Fallback: Takip edilen kullanıcılar: $followingUsernames');
        
        // Sadece takip edilen kullanıcıların postlarını filtrele
        final filteredPosts = allPosts.where((post) {
          final author = post['author'];
          if (author is Map<String, dynamic>) {
            final authorUsername = author['username'] as String?;
            return authorUsername != null && followingUsernames.contains(authorUsername);
          }
          return false;
        }).toList();
        
        print('✅ PostService - Fallback: ${filteredPosts.length} takip edilen post bulundu');
        
        // Cache'e kaydet
        _postsCache['posts_following'] = filteredPosts;
        _cacheTimestamps['posts_following'] = DateTime.now();
        
        return filteredPosts;
      } else {
        print('❌ PostService - Fallback: Tüm postlar alınamadı: ${response.statusCode}');
        throw Exception('Fallback postlar alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PostService - Fallback hatası: $e');
      return [];
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
    print('PostService - Cache temizleniyor...');
    _postsCache.clear();
    _cacheTimestamps.clear();
    print('PostService - Cache temizlendi');
  }
  
  void clearCache() {
    _clearPostsCache();
  }

  Future<void> deletePost(int postId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Lütfen giriş yapın.');
    }

    try {
      final response = await _apiClient.delete('posts/$postId/');
      
      if (response.statusCode != 204) {
        throw Exception('Post silinemedi: ${response.statusCode}');
      }
      
      // Cache'i temizle
      _clearPostsCache();
      print('PostService - Post $postId silindi, cache temizlendi');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Bu postu silme yetkiniz yok.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Post bulunamadı.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Sunucu hatası. Lütfen daha sonra tekrar deneyin.');
      } else {
        throw Exception('Post silinirken hata oluştu: ${e.message}');
      }
    }
  }

  // Like/Unlike post
  Future<Map<String, dynamic>> toggleLike(int postId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Lütfen giriş yapın.');
    }

    try {
      final response = await _apiClient.post('posts/$postId/like/', {});
      
      if (response.statusCode == 200) {
        // Cache'i temizle
        _clearPostsCache();
        return response.data;
      } else {
        throw Exception('Beğeni işlemi başarısız: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Post bulunamadı');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.');
      } else {
        throw Exception('Beğeni işlemi sırasında hata oluştu: ${e.message}');
      }
    }
  }

  // Get post comments
  Future<List<dynamic>> getPostComments(int postId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Lütfen giriş yapın.');
    }

    try {
      final response = await _apiClient.get('posts/$postId/comments/');
      
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Yorumlar alınamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Post bulunamadı');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.');
      } else {
        throw Exception('Yorumlar alınırken hata oluştu: ${e.message}');
      }
    }
  }

  // Create comment
  Future<Map<String, dynamic>> createComment(int postId, String content) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Lütfen giriş yapın.');
    }

    try {
      final response = await _apiClient.post(
        'posts/$postId/comments/',
        {'content': content},
      );
      
      if (response.statusCode == 201) {
        // Cache'i temizle
        _clearPostsCache();
        return response.data;
      } else {
        throw Exception('Yorum oluşturulamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Post bulunamadı');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.');
      } else {
        throw Exception('Yorum oluşturulurken hata oluştu: ${e.message}');
      }
    }
  }

  // Delete comment
  Future<void> deleteComment(int postId, int commentId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Lütfen giriş yapın.');
    }

    try {
      final response = await _apiClient.delete('posts/$postId/comments/$commentId/');
      
      if (response.statusCode == 204) {
        // Cache'i temizle
        _clearPostsCache();
      } else {
        throw Exception('Yorum silinemedi: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Yorum bulunamadı');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.');
      } else {
        throw Exception('Yorum silinirken hata oluştu: ${e.message}');
      }
    }
  }
}
