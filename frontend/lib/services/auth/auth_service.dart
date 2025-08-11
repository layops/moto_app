import 'dart:async';
import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../storage/local_storage.dart';
import 'token_service.dart';

class AuthService {
  final ApiClient _apiClient;
  final TokenService _tokenService;
  final LocalStorage _storage;
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  AuthService(this._apiClient, this._tokenService, this._storage);

  // Burada apiClient getter’ı
  ApiClient get apiClient => _apiClient;

  Stream<bool> get authStateChanges => _authStateController.stream;

  Future<void> initializeAuthState() async {
    final loggedIn = await isLoggedIn();
    _authStateController.add(loggedIn);
  }

  Future<Response> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      final response = await _apiClient.post(
        'login/',
        {'username': username, 'password': password},
      );

      final token = _extractToken(response);
      if (token.isNotEmpty) {
        await _tokenService.saveAuthData(token, username);
        await _storage.setString('current_username', username);

        await saveRememberMe(rememberMe);
        if (rememberMe) {
          await saveRememberedUsername(username);
        } else {
          await clearRememberedUsername();
        }

        _authStateController.add(true);
      }
      return response;
    } on DioException catch (e) {
      throw Exception(
          'Giriş hatası: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Response> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        'register/',
        {
          'username': username,
          'email': email,
          'password': password,
        },
      );
      return response;
    } on DioException catch (e) {
      throw Exception(
          'Kayıt hatası: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<void> logout() async {
    await clearAllUserData();
  }

  Future<bool> isLoggedIn() async {
    return await _tokenService.hasToken();
  }

  Future<String?> getToken() async {
    return await _tokenService.getToken();
  }

  Future<String?> getCurrentUsername() async {
    final tokenData = await _tokenService.getTokenData();
    if (tokenData?['username'] != null) {
      return tokenData!['username'] as String;
    }
    return _storage.getString('current_username') ??
        _storage.getString('rememberedUsername');
  }

  Future<void> saveRememberMe(bool rememberMe) async {
    await _storage.setBool('rememberMe', rememberMe);
  }

  Future<bool> getRememberMe() async {
    return (_storage.getBool('rememberMe')) ?? false;
  }

  Future<void> saveRememberedUsername(String username) async {
    await _storage.setString('rememberedUsername', username);
  }

  Future<String?> getRememberedUsername() async {
    return _storage.getString('rememberedUsername');
  }

  Future<void> clearRememberedUsername() async {
    await _storage.remove('rememberedUsername');
  }

  String _extractToken(Response response) {
    try {
      return response.data['token'] ??
          response.data['access_token'] ??
          response.data['access'] ??
          '';
    } catch (e) {
      throw Exception('Token alınırken hata: $e');
    }
  }

  Future<void> clearAllUserData() async {
    await _tokenService.deleteAuthData();
    await _storage.remove('current_username');
    await _storage.remove('rememberedUsername');
    await _storage.remove('rememberMe');
    _authStateController.add(false);
  }

  void dispose() {
    _authStateController.close();
  }
}
