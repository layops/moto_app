import 'package:dio/dio.dart';
import 'api_interceptors.dart';
import 'api_exceptions.dart';
import '../storage/local_storage.dart';
import 'package:motoapp_frontend/config.dart';

class ApiClient {
  final Dio _dio;
  final LocalStorage _storage;

  ApiClient(this._storage) : _dio = Dio() {
    _dio.options.baseUrl = kBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.interceptors
        .add(ApiInterceptors(_storage)); // LocalStorage parametresi eklendi
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ApiExceptions.fromDioError(e);
    }
  }

  Future<Response> post(String path, dynamic data) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw ApiExceptions.fromDioError(e);
    }
  }

  Future<Response> put(String path, dynamic data) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw ApiExceptions.fromDioError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw ApiExceptions.fromDioError(e);
    }
  }
}
