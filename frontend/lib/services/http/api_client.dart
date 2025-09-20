import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../config.dart';
import '../storage/local_storage.dart';
import 'api_exceptions.dart';
import '../auth/token_service.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import '../performance/performance_optimizer.dart';

class ApiClient {
  final Dio _dio;
  final LocalStorage _storage;
  final TokenService _tokenService;
  bool _isRefreshing = false;
  
  // Cache için
  final Map<String, CacheEntry> _cache = {};
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  
  // Connection pooling için
  static final Dio _sharedDio = Dio();

  ApiClient(this._storage)
      : _tokenService = TokenService(_storage),
        _dio = _sharedDio {
    _dio.options.baseUrl = '$kBaseUrl/api/';
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);
    
    // Connection pooling ayarları
    _dio.options.persistentConnection = true;
    _dio.options.maxRedirects = 3;

    // Token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // JWT token endpoint'lerinde token ekleme
        if (options.path.contains('token/') ||
            options.path.contains('users/register') ||
            options.path.contains('notifications/fcm-token/')) {
          return handler.next(options);
        }

        final token = await _tokenService.getToken();
        
        if (token != null) {
          // Token süresi kontrolü (5 dakika toleranslı)
          if (await _tokenService.isTokenExpired()) {
            if (!_isRefreshing) {
              _isRefreshing = true;
              try {
                // Token yenileme mekanizması
                await _refreshToken();
              } catch (e) {
                _isRefreshing = false;
                // Token yenilenemezse logout yap
                await ServiceLocator.auth.logout();
                return handler.reject(DioException(
                  requestOptions: options,
                  error: 'Oturum süresi doldu',
                ));
              }
              _isRefreshing = false;
            }
          }

          // Yeni token'ı al ve header'a ekle
          final newToken = await _tokenService.getToken();
          if (newToken != null) {
            options.headers['Authorization'] = 'Bearer $newToken';
          }
        } else {
        }
        return handler.next(options);
      },
    ));

    // Error interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException err, ErrorInterceptorHandler handler) async {
        if (err.response?.statusCode == 401 ||
            err.response?.statusCode == 403) {
          // Token geçersiz veya süresi dolmuşsa, sadece log yaz
          // Otomatik logout yapma, kullanıcı manuel olarak logout yapabilir
        }
        handler.next(err);
      },
    ));

    // Log interceptor (sadece debug modda)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
        logPrint: (object) => print(object.toString()),
      ));
    }
    
    // Cache interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // GET istekleri için cache kontrolü
        // Arama endpoint'leri için cache kullanma
        if (options.method == 'GET' && 
            _shouldCache(options.path) && 
            !options.path.contains('search/users/') && 
            !options.path.contains('search/groups/')) {
          final cachedResponse = _getCachedResponse(options.path);
          if (cachedResponse != null) {
            return handler.resolve(cachedResponse);
          }
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        // GET istekleri için cache'e kaydet
        // Arama endpoint'leri için cache'e kaydetme
        if (response.requestOptions.method == 'GET' && 
            _shouldCache(response.requestOptions.path) &&
            !response.requestOptions.path.contains('search/users/') && 
            !response.requestOptions.path.contains('search/groups/')) {
          _cacheResponse(response.requestOptions.path, response);
        }
        handler.next(response);
      },
    ));
  }

  Dio get dio => _dio;

  // JWT Token yenileme metodu
  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('Refresh token bulunamadı');
      }


      // JWT token yenileme endpoint'ini çağır
      final response = await _dio.post('token/refresh/', data: {
        'refresh': refreshToken,
      });

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        final newRefreshToken = response.data['refresh'];
        
        if (newAccessToken != null) {
          // Yeni token'ı kaydet
          await _tokenService.saveAuthData(
            newAccessToken, 
            await _tokenService.getCurrentUsername() ?? '', 
            refreshToken: newRefreshToken ?? refreshToken
          );
          
          // Auth state'i güncelle (public method kullan)
          await ServiceLocator.auth.initializeAuthState();
        } else {
          throw Exception('Yeni access token alınamadı');
        }
      } else {
        throw Exception('JWT Token yenileme başarısız: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cache helper methods
  bool _shouldCache(String path) {
    // Belirli endpoint'leri cache'le
    // Arama endpoint'lerini cache'leme (her arama farklı olabilir)
    return path.contains('users/') || 
           path.contains('posts/') || 
           path.contains('groups/') ||
           path.contains('events/') ||
           (path.contains('search/') && !path.contains('search/users/') && !path.contains('search/groups/'));
  }
  
  Response? _getCachedResponse(String path) {
    final entry = _cache[path];
    if (entry != null && !entry.isExpired) {
      return entry.response;
    }
    if (entry != null) {
      _cache.remove(path);
    }
    return null;
  }
  
  void _cacheResponse(String path, Response response) {
    _cache[path] = CacheEntry(
      response: response,
      timestamp: DateTime.now(),
      duration: _defaultCacheDuration,
    );
  }
  
  // Cache temizleme
  void clearCache() {
    _cache.clear();
  }
  
  void clearCacheForPath(String path) {
    _cache.remove(path);
  }
  
  /// Belirli bir pattern'e uyan tüm cache'leri temizle
  void clearCacheForPattern(String pattern) {
    final keysToRemove = <String>[];
    for (final key in _cache.keys) {
      if (key.contains(pattern)) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }
  
  /// Kullanıcı ile ilgili tüm cache'leri temizle
  void clearUserCache(String username) {
    clearCacheForPattern('users/$username');
  }
  
  // Arama cache'ini temizle
  void clearSearchCache() {
    final keysToRemove = <String>[];
    for (final key in _cache.keys) {
      if (key.contains('search/')) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  // ----------------------
  // GET
  // ----------------------
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options, bool useCache = true}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      if (kDebugMode) {
      }
      
      // Cache kontrolü
      if (useCache && _shouldCache(path)) {
        final cachedResponse = _getCachedResponse(path);
        if (cachedResponse != null) {
          if (kDebugMode) {
          }
          return cachedResponse;
        }
      }
      
      final response = await _dio.get(path,
          queryParameters: queryParameters, options: options);
      
      stopwatch.stop();
      
      if (kDebugMode) {
      }
      return response;
    } on DioException catch (e) {
      stopwatch.stop();
      
      if (kDebugMode) {
      }
      throw ApiExceptions.fromDioError(e);
    }
  }

  // ----------------------
  // POST
  // ----------------------
  Future<Response> post(String path, dynamic data, {Options? options}) async {
    try {
      if (kDebugMode) {
        // print('POST Request: $path');
        // print('POST Data: $data');
      }
      
      final response = await _dio.post(path, data: data, options: options);
      
      // POST işleminden sonra ilgili cache'leri temizle
      _invalidateRelatedCache(path);
      
      if (kDebugMode) {
        // print('POST Response: ${response.statusCode}');
        // print('POST Response Data: ${response.data}');
      }
      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        // print('POST Error: ${e.message}');
      }
      throw ApiExceptions.fromDioError(e);
    }
  }

  // ----------------------
  // PUT
  // ----------------------
  Future<Response> put(String path, dynamic data, {Options? options}) async {
    try {
      if (kDebugMode) {
        // print('PUT Request: $path');
      }
      
      final response = await _dio.put(path, data: data, options: options);
      
      // PUT işleminden sonra ilgili cache'leri temizle
      _invalidateRelatedCache(path);
      
      if (kDebugMode) {
        // print('PUT Response: ${response.statusCode}');
      }
      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        // print('PUT Error: ${e.message}');
      }
      throw ApiExceptions.fromDioError(e);
    }
  }

  // ----------------------
  // DELETE
  // ----------------------
  Future<Response> delete(String path, {Options? options}) async {
    try {
      if (kDebugMode) {
        // print('DELETE Request: $path');
      }
      
      final response = await _dio.delete(path, options: options);
      
      // DELETE işleminden sonra ilgili cache'leri temizle
      _invalidateRelatedCache(path);
      
      if (kDebugMode) {
        // print('DELETE Response: ${response.statusCode}');
      }
      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        // print('DELETE Error: ${e.message}');
      }
      throw ApiExceptions.fromDioError(e);
    }
  }
  
  // Cache invalidation helper
  void _invalidateRelatedCache(String path) {
    final keysToRemove = <String>[];
    
    for (final key in _cache.keys) {
      // İlgili endpoint'leri temizle
      if (path.contains('posts') && key.contains('posts')) {
        keysToRemove.add(key);
      } else if (path.contains('users') && key.contains('users')) {
        keysToRemove.add(key);
      } else if (path.contains('groups') && key.contains('groups')) {
        keysToRemove.add(key);
      } else if (path.contains('events') && key.contains('events')) {
        keysToRemove.add(key);
      } else if (path.contains('search') && key.contains('search')) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }
}

// Cache entry class
class CacheEntry {
  final Response response;
  final DateTime timestamp;
  final Duration duration;
  
  CacheEntry({
    required this.response,
    required this.timestamp,
    required this.duration,
  });
  
  bool get isExpired {
    return DateTime.now().difference(timestamp) > duration;
  }
}

// ApiClient sınıfına baseUrl getter'ı ekle
extension ApiClientExtension on ApiClient {
  String get baseUrl => _dio.options.baseUrl;
}