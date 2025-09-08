import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config.dart';
import '../storage/local_storage.dart';
import 'api_exceptions.dart';
import '../auth/token_service.dart';
import 'package:motoapp_frontend/services/service_locator.dart';

class ApiClient {
  final Dio _dio;
  final LocalStorage _storage;
  final TokenService _tokenService;
  bool _isRefreshing = false;

  ApiClient(this._storage)
      : _tokenService = TokenService(_storage),
        _dio = Dio() {
    _dio.options.baseUrl = '$kBaseUrl/api/';
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);

    // Token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Login ve register endpoint'lerinde token ekleme
        if (options.path.contains('users/login') ||
            options.path.contains('users/register')) {
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
            options.headers['Authorization'] = 'Token $newToken';
          }
        }
        return handler.next(options);
      },
    ));

    // Error interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException err, ErrorInterceptorHandler handler) async {
        if (err.response?.statusCode == 401 ||
            err.response?.statusCode == 403) {
          // Token geçersiz veya süresi dolmuşsa, logout yap
          await ServiceLocator.auth.logout();
        }
        handler.next(err);
      },
    ));

    // Log interceptor
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) => debugPrint(object.toString()),
    ));
  }

  Dio get dio => _dio;

  // Token yenileme metodu
  Future<void> _refreshToken() async {
    try {
      final username = await _tokenService.getCurrentUsername();
      if (username == null) {
        throw Exception('Kullanıcı adı bulunamadı');
      }

      // Burada token yenileme endpoint'inizi kullanmanız gerekir
      // Örnek: /users/refresh-token/
      debugPrint('Token yenileme işlemi başlatıldı');

      // Şimdilik mevcut token'ı tekrar kullanıyoruz
      // Gerçek uygulamada token refresh endpoint'ini çağırmanız gerekir
      final currentToken = await _tokenService.getToken();
      if (currentToken == null) {
        throw Exception('Mevcut token bulunamadı');
      }
    } catch (e) {
      debugPrint('Token yenileme hatası: $e');
      rethrow;
    }
  }

  // ----------------------
  // GET
  // ----------------------
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      debugPrint('GET Request: $path');
      final response = await _dio.get(path,
          queryParameters: queryParameters, options: options);
      debugPrint('GET Response: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      debugPrint('GET Error: ${e.message}');
      throw ApiExceptions.fromDioError(e);
    }
  }

  // ----------------------
  // POST
  // ----------------------
  Future<Response> post(String path, dynamic data, {Options? options}) async {
    try {
      debugPrint('POST Request: $path');
      debugPrint('POST Data: $data');
      final response = await _dio.post(path, data: data, options: options);
      debugPrint('POST Response: ${response.statusCode}');
      debugPrint('POST Response Data: ${response.data}');
      return response;
    } on DioException catch (e) {
      debugPrint('POST Error: ${e.message}');
      throw ApiExceptions.fromDioError(e);
    }
  }

  // ----------------------
  // PUT
  // ----------------------
  Future<Response> put(String path, dynamic data, {Options? options}) async {
    try {
      debugPrint('PUT Request: $path');
      final response = await _dio.put(path, data: data, options: options);
      debugPrint('PUT Response: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      debugPrint('PUT Error: ${e.message}');
      throw ApiExceptions.fromDioError(e);
    }
  }

  // ----------------------
  // DELETE
  // ----------------------
  Future<Response> delete(String path, {Options? options}) async {
    try {
      debugPrint('DELETE Request: $path');
      final response = await _dio.delete(path, options: options);
      debugPrint('DELETE Response: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      debugPrint('DELETE Error: ${e.message}');
      throw ApiExceptions.fromDioError(e);
    }
  }
}
