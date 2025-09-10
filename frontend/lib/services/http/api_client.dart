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
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    
    // Connection pooling ayarları
    _dio.options.persistentConnection = true;
    _dio.options.maxRedirects = 3;

    // Token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Login ve register endpoint'lerinde token ekleme
        if (options.path.contains('users/login') ||
            options.path.contains('users/register')) {
          return handler.next(options);
        }

        final token = await _tokenService.getToken();
        debugPrint('API Request - Path: ${options.path}');
        debugPrint('API Request - Token: ${token != null ? "Token mevcut (${token.substring(0, 10)}...)" : "Token yok"}');
        
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
            debugPrint('API Request - Authorization header eklendi: Bearer ${newToken.substring(0, 10)}...');
          }
        } else {
          debugPrint('API Request - Token bulunamadı, istek token olmadan gönderiliyor');
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
          debugPrint('API Error - 401/403: Token geçersiz veya süresi dolmuş');
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
        logPrint: (object) => debugPrint(object.toString()),
      ));
    }
    
    // Cache interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // GET istekleri için cache kontrolü
        if (options.method == 'GET' && _shouldCache(options.path)) {
          final cachedResponse = _getCachedResponse(options.path);
          if (cachedResponse != null) {
            return handler.resolve(cachedResponse);
          }
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        // GET istekleri için cache'e kaydet
        if (response.requestOptions.method == 'GET' && 
            _shouldCache(response.requestOptions.path)) {
          _cacheResponse(response.requestOptions.path, response);
        }
        handler.next(response);
      },
    ));
  }

  Dio get dio => _dio;

  // Token yenileme metodu
  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('Refresh token bulunamadı');
      }

      debugPrint('Token yenileme işlemi başlatıldı');

      // Token yenileme endpoint'ini çağır
      final response = await _dio.post('users/refresh-token/', data: {
        'refresh': refreshToken,
      });

      if (response.statusCode == 200) {
        final newToken = response.data['token'];
        final newRefreshToken = response.data['refresh'];
        
        if (newToken != null) {
          // Yeni token'ı kaydet
          await _tokenService.saveAuthData(
            newToken, 
            await _tokenService.getCurrentUsername() ?? '', 
            refreshToken: newRefreshToken
          );
          debugPrint('Token başarıyla yenilendi');
        } else {
          throw Exception('Yeni token alınamadı');
        }
      } else {
        throw Exception('Token yenileme başarısız: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Token yenileme hatası: $e');
      rethrow;
    }
  }

  // Cache helper methods
  bool _shouldCache(String path) {
    // Belirli endpoint'leri cache'le
    return path.contains('users/') || 
           path.contains('posts/') || 
           path.contains('groups/') ||
           path.contains('events/');
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

  // ----------------------
  // GET
  // ----------------------
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options, bool useCache = true}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      if (kDebugMode) {
        debugPrint('GET Request: $path');
      }
      
      // Cache kontrolü
      if (useCache && _shouldCache(path)) {
        final cachedResponse = _getCachedResponse(path);
        if (cachedResponse != null) {
          if (kDebugMode) {
            debugPrint('GET Response (cached): ${cachedResponse.statusCode}');
          }
          return cachedResponse;
        }
      }
      
      final response = await _dio.get(path,
          queryParameters: queryParameters, options: options);
      
      stopwatch.stop();
      
      if (kDebugMode) {
        debugPrint('GET Response: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
      }
      return response;
    } on DioException catch (e) {
      stopwatch.stop();
      
      if (kDebugMode) {
        debugPrint('GET Error: ${e.message} (${stopwatch.elapsedMilliseconds}ms)');
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
        debugPrint('POST Request: $path');
        debugPrint('POST Data: $data');
      }
      
      final response = await _dio.post(path, data: data, options: options);
      
      // POST işleminden sonra ilgili cache'leri temizle
      _invalidateRelatedCache(path);
      
      if (kDebugMode) {
        debugPrint('POST Response: ${response.statusCode}');
        debugPrint('POST Response Data: ${response.data}');
      }
      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('POST Error: ${e.message}');
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
        debugPrint('PUT Request: $path');
      }
      
      final response = await _dio.put(path, data: data, options: options);
      
      // PUT işleminden sonra ilgili cache'leri temizle
      _invalidateRelatedCache(path);
      
      if (kDebugMode) {
        debugPrint('PUT Response: ${response.statusCode}');
      }
      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('PUT Error: ${e.message}');
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
        debugPrint('DELETE Request: $path');
      }
      
      final response = await _dio.delete(path, options: options);
      
      // DELETE işleminden sonra ilgili cache'leri temizle
      _invalidateRelatedCache(path);
      
      if (kDebugMode) {
        debugPrint('DELETE Response: ${response.statusCode}');
      }
      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('DELETE Error: ${e.message}');
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
