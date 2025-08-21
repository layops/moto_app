import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exceptions.dart';
import '../storage/local_storage.dart';
import '../../config.dart';

class ApiClient {
  final Dio _dio;
  final LocalStorage _storage;

  ApiClient(this._storage) : _dio = Dio() {
    _dio.options.baseUrl = kBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);

    // Interceptor: Token ekleme
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _storage.getAuthToken(); // Düzeltilmiş metod
        if (token != null) {
          options.headers['Authorization'] = 'Token $token';
        }
        return handler.next(options);
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
