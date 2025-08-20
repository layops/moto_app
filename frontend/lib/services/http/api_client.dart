import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_interceptors.dart';
import 'api_exceptions.dart';
import '../storage/local_storage.dart';
import 'package:motoapp_frontend/config.dart';

class ApiClient {
  final Dio _dio;
  final LocalStorage _storage;

  ApiClient(this._storage) : _dio = Dio() {
    // DEBUG: Base URL'yi kontrol et
    debugPrint('API BASE URL: $kBaseUrl');

    _dio.options.baseUrl = kBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Detaylı loglama ekle
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) => debugPrint(object.toString()),
    ));

    _dio.interceptors.add(ApiInterceptors(_storage));
  }

  // Dio instance'ını dışarıya açan getter
  Dio get dio => _dio;

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      debugPrint('GET Request: $path');
      final response = await _dio.get(path, queryParameters: queryParameters);
      debugPrint('GET Response: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      debugPrint('GET Error: ${e.message}');
      throw ApiExceptions.fromDioError(e);
    }
  }

  Future<Response> post(String path, dynamic data) async {
    try {
      debugPrint('POST Request: $path');
      debugPrint('POST Data: $data');
      final response = await _dio.post(path, data: data);
      debugPrint('POST Response: ${response.statusCode}');
      debugPrint('POST Response Data: ${response.data}');
      return response;
    } on DioException catch (e) {
      debugPrint('POST Error: ${e.message}');
      debugPrint('POST Error Response: ${e.response?.data}');
      throw ApiExceptions.fromDioError(e);
    }
  }

  Future<Response> put(String path, dynamic data) async {
    try {
      debugPrint('PUT Request: $path');
      final response = await _dio.put(path, data: data);
      debugPrint('PUT Response: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      debugPrint('PUT Error: ${e.message}');
      throw ApiExceptions.fromDioError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      debugPrint('DELETE Request: $path');
      final response = await _dio.delete(path);
      debugPrint('DELETE Response: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      debugPrint('DELETE Error: ${e.message}');
      throw ApiExceptions.fromDioError(e);
    }
  }
}
