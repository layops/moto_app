import 'dart:async';
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
      final callbackUrl = uri.queryParameters['url'];
      if (callbackUrl != null) {
        _handleGoogleOAuthCallback(callbackUrl);
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
          
          // User data'yı güvenli şekilde al
          Map<String, dynamic> userData;
          if (data['user'] is Map<String, dynamic>) {
            userData = data['user'] as Map<String, dynamic>;
          } else {
            // Fallback user data
            userData = {
              'username': 'google_user_${DateTime.now().millisecondsSinceEpoch}',
              'email': 'user@google.com',
              'first_name': 'Google',
              'last_name': 'User'
            };
          }
          
          // Token'ları kaydet ve kullanıcıyı giriş yap
          await authService.loginWithGoogle(
            data['access_token']?.toString() ?? '',
            data['refresh_token']?.toString() ?? '',
            userData,
          );
          
          // Ana sayfaya yönlendir
          _navigateToHome();
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
