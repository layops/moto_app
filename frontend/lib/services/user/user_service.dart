import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../storage/local_storage.dart';
import '../service_locator.dart';

class UserService {
  final ApiClient _apiClient;
  final LocalStorage _storage;
  
  // Cache için
  final Map<String, dynamic> _userCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  UserService(this._apiClient, this._storage);

  /// Kullanıcı detaylarını getir (ID ile)
  Future<Map<String, dynamic>> fetchUser(int userId) async {
    final cacheKey = 'user_$userId';
    
    // Cache kontrolü
    if (_isCacheValid(cacheKey) && _userCache.containsKey(cacheKey)) {
      return _userCache[cacheKey] as Map<String, dynamic>;
    }
    
    try {
      final response = await _apiClient.get('users/$userId');
      if (response.statusCode == 200) {
        final userData = response.data as Map<String, dynamic>;
        
        // Cache'e kaydet
        _userCache[cacheKey] = userData;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return userData;
      }
      throw Exception('Failed to fetch user: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Yeni kullanıcı kaydı
  Future<Response> register({
    required String username,
    required String email,
    required String password,
  }) {
    return _apiClient.post(
      'users/register/',
      {
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  /// Local storage’dan aktif kullanıcı adını getir
  Future<String?> getCurrentUsername() async {
    return _storage.getCurrentUsername();
  }

  /// Profil bilgilerini getir
  Future<Map<String, dynamic>?> getProfile(String username) async {
    final cacheKey = 'profile_$username';
    
    // Cache kontrolü
    if (_isCacheValid(cacheKey) && _userCache.containsKey(cacheKey)) {
      return _userCache[cacheKey] as Map<String, dynamic>?;
    }
    
    try {
      final response = await _apiClient.get('users/$username/profile/');
      final profileData = response.data as Map<String, dynamic>?;
      
      if (profileData != null) {
        // Cache'e kaydet
        _userCache[cacheKey] = profileData;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }
      
      return profileData;
    } catch (e) {
      // print('Profil getirme hatası: $e');
      return null;
    }
  }

  /// Kullanıcının gönderilerini getir
  Future<List<dynamic>> getPosts(String username) async {
    try {
      final response = await _apiClient.get('users/$username/posts/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        // print('User posts endpoint 500 hatası, fallback yapılıyor');
        return await _getPostsFallback(username);
      }
      // print('Gönderiler getirme hatası (DioException): ${e.message}');
      return [];
    } catch (e) {
      // print('Gönderiler getirme hatası (genel): $e');
      return await _getPostsFallback(username);
    }
  }

  /// Fallback: tüm gönderilerden filtrele
  Future<List<dynamic>> _getPostsFallback(String username) async {
    try {
      final response = await _apiClient.get('posts/');
      final allPosts = response.data as List<dynamic>;
      return allPosts
          .where((post) =>
              post['author'] != null && post['author']['username'] == username)
          .toList();
    } catch (e) {
      // print('Fallback gönderi getirme hatası: $e');
      return [];
    }
  }

  /// Kullanıcının medya içeriklerini getir
  Future<List<dynamic>> getMedia(String username) async {
    return _safeGetList('users/$username/media/', 'Medya');
  }

  /// Kullanıcının etkinliklerini getir
  Future<List<dynamic>> getEvents(String username) async {
    return _safeGetList('users/$username/events/', 'Etkinlikler');
  }

  /// Takipçileri getir
  Future<List<dynamic>> getFollowers(String username) async {
    return _safeGetList('users/$username/followers/', 'Takipçiler');
  }

  /// Takip edilenleri getir
  Future<List<dynamic>> getFollowing(String username) async {
    return _safeGetList('users/$username/following/', 'Takip edilenler');
  }

  /// Takip et
  Future<bool> followUser(String username) async {
    try {
      final response = await _apiClient.post('users/$username/follow/', {});
      return response.statusCode == 200;
    } catch (e) {
      // print('Takip etme hatası: $e');
      return false;
    }
  }

  /// Takibi bırak
  Future<bool> unfollowUser(String username) async {
    try {
      final response = await _apiClient.post('users/$username/unfollow/', {});
      return response.statusCode == 200;
    } catch (e) {
      // print('Takipten çıkma hatası: $e');
      return false;
    }
  }

  /// Tekrarlayan endpoint çağrıları için güvenli liste döndüren helper
  Future<List<dynamic>> _safeGetList(String path, String label) async {
    final cacheKey = 'list_${path.replaceAll('/', '_')}';
    
    // Cache kontrolü
    if (_isCacheValid(cacheKey) && _userCache.containsKey(cacheKey)) {
      return _userCache[cacheKey] as List<dynamic>;
    }
    
    try {
      final response = await _apiClient.get(path);
      final data = response.data as List<dynamic>;
      
      // Cache'e kaydet
      _userCache[cacheKey] = data;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        // print('$label endpointi sunucu hatası (500), boş liste döndürülüyor');
        return [];
      }
      // print('$label getirme hatası (DioException): ${e.message}');
      return [];
    } catch (e) {
      // print('$label getirme hatası (genel): $e');
      return [];
    }
  }
  
  // Cache helper methods
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
  
  void clearCache() {
    _userCache.clear();
    _cacheTimestamps.clear();
  }
  
  /// Belirli bir kullanıcının cache'ini temizle
  void clearUserCache(String username) {
    final cacheKey = 'profile_$username';
    _userCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
    // print('✅ UserService - User cache temizlendi: $username');
  }
}
