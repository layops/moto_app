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

  Stream<bool> get authStateChanges => _authStateController.stream;

  // Uygulama başlangıcında kimlik durumunu kontrol et
  Future<void> initializeAuthState() async {
    final isLoggedIn = await this.isLoggedIn();
    _authStateController.add(isLoggedIn);
  }

  Future<Response> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        'login/',
        {'username': username, 'password': password},
      );

      final token = _extractToken(response);
      if (token.isNotEmpty) {
        await _tokenService.saveAuthData(token, username);
        await _storage.setString('current_username', username);
        _authStateController.add(true); // Giriş başarılı
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
    await _tokenService.deleteAuthData();
    await _storage.remove('current_username');
    _authStateController.add(false); // Çıkış yapıldı
  }

  Future<bool> isLoggedIn() async {
    return await _tokenService.hasToken();
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
