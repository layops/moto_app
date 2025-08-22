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
  ApiClient get apiClient => _apiClient;

  Future<void> initializeAuthState() async {
    final loggedIn = await isLoggedIn();
    _authStateController.add(loggedIn);
  }

  /// Login işlemi - endpoint düzeltildi
  Future<Response> login(String username, String password,
      {bool rememberMe = false}) async {
    try {
      final response = await _apiClient.post(
        'users/login/', // ✅ Doğru endpoint
        {
          'username': username,
          'password': password,
        },
      );

      final token = _extractToken(response);
      if (token.isNotEmpty) {
        await _tokenService.saveAuthData(token, username);
        await _storage.setCurrentUsername(username);

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
      final errorMessage = e.response?.data?['message'] ??
          e.response?.data?['detail'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Giriş işlemi sırasında bir hata oluştu';

      throw Exception('Giriş hatası: $errorMessage');
    }
  }

  /// Register işlemi - endpoint düzeltildi
  Future<Response> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        'users/register/', // ✅ Doğru endpoint
        {
          'username': username,
          'email': email,
          'password': password,
        },
      );
      return response;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ??
          e.response?.data?['detail'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Kayıt işlemi sırasında bir hata oluştu';

      throw Exception('Kayıt hatası: $errorMessage');
    }
  }

  /// Logout işlemi
  Future<void> logout() async {
    try {
      await _apiClient.post('users/logout/', {});
    } catch (e) {
      // Logout hatası kritik değil, devam et
    } finally {
      await clearAllUserData();
    }
  }

  /// Kullanıcı giriş yapmış mı?
  Future<bool> isLoggedIn() async {
    return await _tokenService.hasToken();
  }

  /// Token al
  Future<String?> getToken() async {
    return await _tokenService.getToken();
  }

  /// Şu anki kullanıcı adını al
  Future<String?> getCurrentUsername() async {
    final tokenData = await _tokenService.getTokenData();
    if (tokenData?['username'] != null) {
      return tokenData!['username'] as String;
    }
    return _storage.getCurrentUsername() ?? _storage.getRememberedUsername();
  }

  /// Remember me durumu
  Future<void> saveRememberMe(bool rememberMe) async {
    await _storage.setRememberMe(rememberMe);
  }

  Future<bool> getRememberMe() async {
    return (_storage.getRememberMe()) ?? false;
  }

  /// Remembered username
  Future<void> saveRememberedUsername(String username) async {
    await _storage.setRememberedUsername(username);
  }

  Future<String?> getRememberedUsername() async {
    return _storage.getRememberedUsername();
  }

  Future<void> clearRememberedUsername() async {
    await _storage.clearRememberedUsername();
  }

  /// Token'ı response'dan çıkar - Backend yapısına uygun
  String _extractToken(Response response) {
    try {
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data['token'] ?? ''; // ✅ Backend 'token' döndürüyor
      }

      return '';
    } catch (e) {
      throw Exception('Token alınırken hata: $e');
    }
  }

  /// Tüm kullanıcı verilerini temizle
  Future<void> clearAllUserData() async {
    await _tokenService.deleteAuthData();
    await _storage.removeCurrentUsername();
    await _storage.clearRememberedUsername();
    await _storage.setRememberMe(false);
    _authStateController.add(false);
  }

  void dispose() {
    _authStateController.close();
  }
}
