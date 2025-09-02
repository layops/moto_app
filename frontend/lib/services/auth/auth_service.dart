import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../http/api_client.dart';
import '../storage/local_storage.dart';
import 'token_service.dart';
import 'package:motoapp_frontend/services/service_locator.dart';

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

  Future<Response> login(String username, String password,
      {bool rememberMe = false}) async {
    try {
      final response = await _apiClient.post('users/login/', {
        'username': username,
        'password': password,
      });

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

        // Auth state güncelle
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

  Future<Response> register({
    required String username,
    required String email,
    required String password,
    required String password2,
  }) async {
    try {
      final response = await _apiClient.post('users/register/', {
        'username': username,
        'email': email,
        'password': password,
        'password2': password2,
      });
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

  Future<void> logout() async {
    try {
      await _apiClient.post('users/logout/', {});
    } finally {
      await clearAllUserData();
      ServiceLocator.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  Future<bool> isLoggedIn() async => await _tokenService.hasToken();

  Future<String?> getToken() async => await _tokenService.getToken();

  Future<String?> getCurrentUsername() async {
    final tokenData = await _tokenService.getTokenData();
    if (tokenData?['username'] != null) return tokenData!['username'] as String;
    return _storage.getCurrentUsername() ?? _storage.getRememberedUsername();
  }

  Future<void> saveRememberMe(bool rememberMe) async =>
      await _storage.setRememberMe(rememberMe);

  Future<bool> getRememberMe() async => _storage.getRememberMe() ?? false;

  Future<void> saveRememberedUsername(String username) async =>
      await _storage.setRememberedUsername(username);

  Future<String?> getRememberedUsername() async =>
      _storage.getRememberedUsername();

  Future<void> clearRememberedUsername() async =>
      await _storage.clearRememberedUsername();

  String _extractToken(Response response) {
    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['token'] ??
            data['access_token'] ??
            data['accessToken'] ??
            '';
      } else if (data is String) {
        final jsonData = jsonDecode(data);
        if (jsonData is Map<String, dynamic>) {
          return jsonData['token'] ??
              jsonData['access_token'] ??
              jsonData['accessToken'] ??
              '';
        }
      }
      return '';
    } catch (e) {
      debugPrint('Token alınırken hata: $e');
      return '';
    }
  }

  Future<void> clearAllUserData() async {
    await _tokenService.deleteAuthData();
    await _storage.removeCurrentUsername();
    await _storage.clearRememberedUsername();
    await _storage.setRememberMe(false);
    await _storage.clearProfileData();

    // Auth state sıfırla
    _authStateController.add(false);
  }

  void dispose() {
    _authStateController.close();
  }
}
