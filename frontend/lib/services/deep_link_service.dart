import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/services/service_locator.dart';

class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;

  static void initialize() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );
  }

  static void _handleDeepLink(Uri uri) {
    print('Deep link received: $uri');
    
    if (uri.scheme == 'motoapp' && uri.host == 'oauth') {
      if (uri.pathSegments.contains('success')) {
        // OAuth success deep link
        _handleGoogleOAuthSuccess(uri);
      } else {
        // OAuth callback deep link
        final callbackUrl = uri.queryParameters['url'];
        if (callbackUrl != null) {
          _handleGoogleOAuthCallback(callbackUrl);
        }
      }
    }
  }

  static Future<void> _handleGoogleOAuthCallback(String callbackUrl) async {
    try {
      // URL'i decode et
      final decodedUrl = Uri.decodeFull(callbackUrl);
      final uri = Uri.parse(decodedUrl);
      
      // Query parametrelerini decode et
      final code = uri.queryParameters['code'] != null 
          ? Uri.decodeComponent(uri.queryParameters['code']!)
          : null;
      final state = uri.queryParameters['state'] != null
          ? Uri.decodeComponent(uri.queryParameters['state']!)
          : null;
      
      print('Deep link - Decoded URL: $decodedUrl');
      print('Deep link - Decoded code: $code');
      print('Deep link - Decoded state: $state');
      
      if (code != null && state != null) {
        // AuthService ile callback'i işle
        final authService = ServiceLocator.auth;
        final response = await authService.handleGoogleCallback(code, state);
        
        if (response.statusCode == 200) {
          final data = response.data;
          
          // Eğer cached response ise, tekrar işleme
          if (data['cached'] == true) {
            print('Google OAuth callback already processed via deep link');
            return;
          }
          
          // Backend'den gelen JSON response'u işle
          if (data['success'] == true && data['user'] != null) {
            final userData = data['user'] as Map<String, dynamic>;
            
            // Token'ları kaydet ve kullanıcıyı giriş yap
            await authService.loginWithGoogle(
              data['access_token']?.toString() ?? '',
              data['refresh_token']?.toString() ?? '',
              userData,
            );
            
            // Ana sayfaya yönlendir
            _navigateToHome();
          } else {
            // Hata durumu
            final errorMessage = data['error']?.toString() ?? 'Google giriş başarısız';
            _showError(errorMessage);
          }
        } else {
          _showError('Google giriş başarısız: ${response.data?['error'] ?? 'Bilinmeyen hata'}');
        }
      } else {
        _showError('Geçersiz callback URL - code: $code, state: $state');
      }
    } catch (e) {
      print('Deep link callback işleme hatası: $e');
      _showError('Callback işlenirken hata: $e');
    }
  }

  static Future<void> _handleGoogleOAuthSuccess(Uri uri) async {
    try {
      final userDataEncoded = uri.queryParameters['user_data'];
      final callbackUrl = uri.queryParameters['url'];
      
      print('Google OAuth success deep link received');
      print('User data encoded: $userDataEncoded');
      print('Callback URL: $callbackUrl');
      
      if (userDataEncoded != null) {
        // Base64 decode user data
        final userDataJson = String.fromCharCodes(base64Decode(userDataEncoded));
        final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
        
        print('Decoded user data: $userData');
        
        // AuthService ile giriş yap
        final authService = ServiceLocator.auth;
        
        // Mock tokens (gerçek uygulamada backend'den alınmalı)
        await authService.loginWithGoogle(
          'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
          'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          userData,
        );
        
        // Ana sayfaya yönlendir
        _navigateToHome();
      } else {
        _showError('User data bulunamadı');
      }
    } catch (e) {
      print('Google OAuth success işleme hatası: $e');
      _showError('Success callback işlenirken hata: $e');
    }
  }

  static void _navigateToHome() {
    // Ana sayfaya yönlendirme
    // Bu kısım mevcut navigation yapınıza göre düzenlenebilir
    print('Google OAuth başarılı, ana sayfaya yönlendiriliyor...');
  }

  static void _showError(String message) {
    print('Google OAuth hatası: $message');
    // Hata mesajını göster
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }
}
