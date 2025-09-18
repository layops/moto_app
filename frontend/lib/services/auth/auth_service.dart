import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../http/api_client.dart';
import '../storage/local_storage.dart';
import 'token_service.dart';
import 'package:motoapp_frontend/services/service_locator.dart';

class AuthService {
  final ApiClient _apiClient;
  final TokenService _tokenService;
  final LocalStorage _storage;
  final BehaviorSubject<bool> _authStateController = BehaviorSubject<bool>.seeded(false);

  AuthService(this._apiClient, this._tokenService, this._storage);

  Stream<bool> get authStateChanges => _authStateController.stream;
  ApiClient get apiClient => _apiClient;
  
  // Current user bilgisi için async getter
  Future<Map<String, dynamic>?> get currentUser async {
    // Token'dan kullanıcı bilgilerini al
    try {
      // print('🔑 AuthService - Getting current user from token...');
      final token = await _tokenService.getToken();
      // print('🔑 AuthService - Raw token: $token');
      
      final tokenData = await _tokenService.getTokenData();
      // print('🔑 AuthService - Token data: $tokenData');
      
      if (tokenData != null) {
        final userData = {
          'id': tokenData['user_id'] ?? tokenData['id'],
          'username': tokenData['username'],
          'email': tokenData['email'],
        };
        // print('🔑 AuthService - Current user data: $userData');
        return userData;
      } else {
        // print('🔑 AuthService - No token data found, trying alternative method...');
        
        // Alternatif: Token'dan username al ve API'den user bilgilerini çek
        final username = await _tokenService.getUsernameFromToken();
        // print('🔑 AuthService - Username from token: $username');
        
        if (username != null) {
          // API'den user bilgilerini çek
          try {
            final response = await _apiClient.get('users/$username/profile/');
            if (response.statusCode == 200) {
              final userData = response.data;
              // print('🔑 AuthService - User data from API: $userData');
              return {
                'id': userData['id'],
                'username': userData['username'],
                'email': userData['email'],
              };
            }
          } catch (e) {
            // print('❌ AuthService - Error fetching user from API: $e');
          }
        }
      }
    } catch (e) {
      // print('❌ AuthService - Error getting current user: $e');
    }
    return null;
  }

  Future<void> initializeAuthState() async {
    final loggedIn = await isLoggedIn();
    _authStateController.value = loggedIn;
  }

  Future<Response> login(String username, String password,
      {bool rememberMe = false}) async {
    try {
      // print('🔑 AuthService - JWT Login başlatılıyor: $username');
      final response = await _apiClient.post('users/login/', {
        'username': username,
        'password': password,
      });

      // print('🔑 AuthService - JWT Login response: ${response.statusCode}');
      // print('🔑 AuthService - JWT Login data: ${response.data}');

      final accessToken = _extractAccessToken(response);
      final refreshToken = _extractRefreshToken(response);
      // print('🔑 AuthService - Extracted access token: ${accessToken.isNotEmpty ? "Token mevcut (${accessToken.substring(0, 10)}...)" : "Token boş"}');
      // print('🔑 AuthService - Extracted refresh token: ${refreshToken.isNotEmpty ? "Refresh token mevcut" : "Refresh token boş"}');
      
      if (accessToken.isNotEmpty) {
        await _tokenService.saveAuthData(accessToken, username, refreshToken: refreshToken);
        await _storage.setCurrentUsername(username);

        await saveRememberMe(rememberMe);
        if (rememberMe) {
          await saveRememberedUsername(username);
        } else {
          await clearRememberedUsername();
        }

        // Auth state güncelle
        _authStateController.value = true;
        
        // FCM'i initialize et
        await _initializeFCM();
        
        // print('🔑 AuthService - JWT Login başarılı, auth state güncellendi');
      } else {
        // print('❌ AuthService - Access token boş, login başarısız');
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
      // JWT token'ı blacklist'e ekle
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post('token/blacklist/', {
          'refresh': refreshToken,
        });
      }
    } catch (e) {
      // print('❌ AuthService - Logout sırasında token blacklist hatası: $e');
    }
    
    await clearAllUserData();
    ServiceLocator.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) {
        // print('❌ AuthService - Refresh token bulunamadı');
        return false;
      }

      // print('🔑 AuthService - Token yenileniyor...');
      final response = await _apiClient.post('token/refresh/', {
        'refresh': refreshToken,
      });

      if (response.statusCode == 200) {
        final newAccessToken = _extractAccessToken(response);
        final newRefreshToken = _extractRefreshToken(response);
        
        if (newAccessToken.isNotEmpty) {
          final username = await getCurrentUsername();
          if (username != null) {
            await _tokenService.saveAuthData(
              newAccessToken, 
              username, 
              refreshToken: newRefreshToken.isNotEmpty ? newRefreshToken : refreshToken
            );
            
            // Auth state'i güncelle
            _authStateController.value = true;
            // print('🔑 AuthService - Token başarıyla yenilendi');
            return true;
          }
        }
      }
      
      // print('❌ AuthService - Token yenileme başarısız');
      return false;
    } catch (e) {
      // print('❌ AuthService - Token yenileme hatası: $e');
      return false;
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

  String _extractAccessToken(Response response) {
    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['access'] ??
            data['access_token'] ??
            data['accessToken'] ??
            data['token'] ??
            '';
      } else if (data is String) {
        final jsonData = jsonDecode(data);
        if (jsonData is Map<String, dynamic>) {
          return jsonData['access'] ??
              jsonData['access_token'] ??
              jsonData['accessToken'] ??
              jsonData['token'] ??
              '';
        }
      }
      return '';
    } catch (e) {
      // print('Access token alınırken hata: $e');
      return '';
    }
  }

  String _extractRefreshToken(Response response) {
    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['refresh'] ??
            data['refresh_token'] ??
            data['refreshToken'] ??
            '';
      } else if (data is String) {
        final jsonData = jsonDecode(data);
        if (jsonData is Map<String, dynamic>) {
          return jsonData['refresh'] ??
              jsonData['refresh_token'] ??
              jsonData['refreshToken'] ??
              '';
        }
      }
      return '';
    } catch (e) {
      // print('Refresh token alınırken hata: $e');
      return '';
    }
  }

  Future<void> clearAllUserData() async {
    await _tokenService.deleteAuthData();
    await _storage.removeCurrentUsername();
    await _storage.clearRememberedUsername();
    await _storage.setRememberMe(false);
    await _storage.clearProfileData();

    // Tüm servislerin cache'lerini temizle
    await ServiceLocator.reset();

    // Auth state sıfırla
    _authStateController.value = false;
  }

  // Google OAuth ile giriş yapma
  Future<void> loginWithGoogle(String accessToken, String refreshToken, Map<String, dynamic> userData) async {
    try {
      print('🔑 AuthService - Google OAuth login başlatılıyor: ${userData['username']}');
      
      // Token'ları kaydet
      await _tokenService.saveAuthData(accessToken, userData['username'], refreshToken: refreshToken);
      await _storage.setCurrentUsername(userData['username']);
      
      // Auth state güncelle
      _authStateController.value = true;
      
      // FCM'i initialize et
      await _initializeFCM();
      
      print('🔑 AuthService - Google OAuth login başarılı, auth state güncellendi');
    } catch (e) {
      print('❌ AuthService - Google OAuth login hatası: $e');
      rethrow;
    }
  }

  // Google OAuth callback'i işleme
  Future<Response> handleGoogleCallback(String code, String state) async {
    try {
      print('🔑 AuthService - Google OAuth callback işleniyor');
      
      final response = await _apiClient.get('users/auth/callback/', queryParameters: {
        'code': code,
        'state': state,
      });
      
      print('🔑 AuthService - Google OAuth callback response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ AuthService - Google OAuth callback hatası: $e');
      rethrow;
    }
  }

  // FCM'i initialize et
  Future<void> _initializeFCM() async {
    try {
      print('🔑 AuthService - FCM initialize ediliyor...');
      final fcmService = ServiceLocator.fcm;
      if (fcmService != null) {
        await fcmService.initialize();
        print('🔑 AuthService - FCM başarıyla initialize edildi');
      } else {
        print('❌ AuthService - FCM service bulunamadı');
      }
    } catch (e) {
      print('❌ AuthService - FCM initialize hatası: $e');
    }
  }

  void dispose() {
    _authStateController.close();
  }
  
  // Cache temizleme metodu
  void clearCache() {
    // AuthService için özel cache yok, sadece placeholder
    // Gelecekte auth cache'i eklenebilir
  }

  // Google OAuth metodları
  Future<Response> getGoogleAuthUrl() async {
    try {
      final response = await _apiClient.get('users/auth/google/');
      return response;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error'] ??
          e.response?.data?['message'] ??
          e.message ??
          'Google OAuth URL alınırken hata oluştu';
      throw Exception('Google OAuth hatası: $errorMessage');
    }
  }


  Future<Response> verifyToken(String accessToken) async {
    try {
      final response = await _apiClient.post('users/verify-token/', {
        'access_token': accessToken,
      });
      return response;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error'] ??
          e.response?.data?['message'] ??
          e.message ??
          'Token doğrulanırken hata oluştu';
      throw Exception('Token doğrulama hatası: $errorMessage');
    }
  }


  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post('users/change-password/', {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password2': newPassword,
      });
      return response;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error'] ??
          e.response?.data?['message'] ??
          e.response?.data?['detail'] ??
          e.message ??
          'Şifre değiştirme işlemi sırasında bir hata oluştu';
      throw Exception('Şifre değiştirme hatası: $errorMessage');
    }
  }
}
