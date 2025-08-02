import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motoapp_frontend/config.dart';

class ApiService {
  late final Dio _dio;
  late final SharedPreferences _prefs;
  String? _cachedToken;

  final String _baseUrl = kBaseUrl;

  Future<Response> uploadProfileImage(File imageFile) async {
    final formData = FormData.fromMap({
      'profile_image': await MultipartFile.fromFile(imageFile.path),
    });
    return await _dio.post('profile/upload-photo/', data: formData);
  }

  ApiService._internal();

  static Future<ApiService> create() async {
    final service = ApiService._internal();
    await service._init();
    return service;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _cachedToken = _prefs.getString('authToken');

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_cachedToken != null && _cachedToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Token $_cachedToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  Future<Response> get(String path) async {
    return await _dio.get(path);
  }

  Future<Response> post(String path, dynamic data) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, dynamic data) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> patch(String path, dynamic data) async {
    return await _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  Future<Response> login(String username, String password) async {
    final response = await post('login/', {
      'username': username,
      'password': password,
    });
    if (response.statusCode == 200 && response.data != null) {
      String? token = response.data['token'] ?? response.data['access'];

      if (token != null) {
        await saveAuthToken(token);
      } else {
        throw Exception('Token bulunamadı');
      }

      if (response.data.containsKey('username')) {
        await saveUsername(response.data['username']);
      }
    }

    return response;
  }

  Future<Response> register(
      String username, String email, String password) async {
    return await post('register/', {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  Future<void> saveAuthToken(String token) async {
    await _prefs.setString('authToken', token);
    _cachedToken = token;
  }

  Future<void> saveUsername(String username) async {
    await _prefs.setString('username', username);
  }

  Future<void> deleteAuthToken() async {
    await _prefs.remove('authToken');
    await _prefs.remove('username');
    _cachedToken = null;
  }

  Future<String?> getAuthToken() async {
    return _prefs.getString('authToken');
  }

  Future<String?> getUsername() async {
    return _prefs.getString('username');
  }

  Future<void> saveRememberMe(bool rememberMe) async {
    await _prefs.setBool('rememberMe', rememberMe);
  }

  Future<bool> getRememberMe() async {
    return _prefs.getBool('rememberMe') ?? false;
  }

  Future<void> saveRememberedUsername(String username) async {
    await _prefs.setString('rememberedUsername', username);
  }

  Future<String?> getRememberedUsername() async {
    return _prefs.getString('rememberedUsername');
  }

  Future<void> clearRememberedUsername() async {
    await _prefs.remove('rememberedUsername');
  }
}
