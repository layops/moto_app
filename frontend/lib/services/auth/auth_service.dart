import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../storage/local_storage.dart';
import 'token_service.dart';

class AuthService {
  final ApiClient _apiClient;
  final TokenService _tokenService;
  final LocalStorage _storage;

  AuthService(this._apiClient, this._tokenService, this._storage);

  Future<Response> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        'login/',
        {'username': username, 'password': password},
      );

      final token = _extractToken(response);
      if (token.isNotEmpty) {
        await _tokenService.saveAuthData(token, username);
        await _storage.setString(
            'current_username', username); // Güncel kullanıcı adını kaydet
      }
      return response;
    } on DioException catch (e) {
      throw Exception(
          'Giriş hatası: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<void> logout() async {
    await _tokenService.deleteAuthData();
    await _storage
        .remove('current_username'); // Çıkış yapınca kullanıcı adını sil
  }

  Future<bool> isLoggedIn() async {
    return await _tokenService.hasToken();
  }

  // Kullanıcı adı yönetimi
  Future<String?> getCurrentUsername() async {
    // Önce token'dan kontrol et
    final tokenData = await _tokenService.getTokenData();
    if (tokenData?['username'] != null) {
      return tokenData!['username'] as String;
    }

    // Sonra storage'dan kontrol et
    return _storage.getString('current_username') ??
        _storage.getString('rememberedUsername');
  }

  // Remember me fonksiyonları
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

  // Token çıkarma işlemi
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

  // Kullanıcı verilerini temizleme (tam logout için)
  Future<void> clearAllUserData() async {
    await _tokenService.deleteAuthData();
    await _storage.remove('current_username');
    await _storage.remove('rememberedUsername');
    await _storage.remove('rememberMe');
  }
}
