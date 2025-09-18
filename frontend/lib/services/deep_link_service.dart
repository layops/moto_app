import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper_new.dart';
import 'package:motoapp_frontend/widgets/navigations/navigation_items.dart';
import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/map/map_page.dart';
import 'package:motoapp_frontend/views/groups/group_page.dart';
import 'package:motoapp_frontend/views/event/events_page.dart';
import 'package:motoapp_frontend/views/messages/messages_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';

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
    print('🔗 Deep link received: $uri');
    print('🔗 Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
    
    if (uri.scheme == 'motoapp') {
      if (uri.host == 'oauth') {
        if (uri.pathSegments.contains('success')) {
          // OAuth success deep link
          print('🔗 Processing OAuth success deep link');
          _handleGoogleOAuthSuccess(uri);
        } else {
          // OAuth callback deep link
          print('🔗 Processing OAuth callback deep link');
          final callbackUrl = uri.queryParameters['url'];
          if (callbackUrl != null) {
            _handleGoogleOAuthCallback(callbackUrl);
          }
        }
      } else {
        print('🔗 Unknown motoapp host: ${uri.host}');
      }
    } else if (uri.scheme == 'https' && uri.host == 'spiride.onrender.com' && uri.path.startsWith('/api/users/auth/callback/')) {
      // Direct HTTPS callback URL
      print('🔗 Processing direct HTTPS callback URL');
      _handleGoogleOAuthCallback(uri.toString());
    } else {
      print('🔗 Deep link not handled - Scheme: ${uri.scheme}, Host: ${uri.host}');
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
      final tokenDataEncoded = uri.queryParameters['token_data'];
      
      print('🔗 Google OAuth success deep link received');
      print('🔗 User data encoded length: ${userDataEncoded?.length ?? 0}');
      print('🔗 Token data encoded length: ${tokenDataEncoded?.length ?? 0}');
      
      if (userDataEncoded != null && tokenDataEncoded != null) {
        // Base64 decode user data
        final userDataJson = String.fromCharCodes(base64Decode(userDataEncoded));
        final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
        
        // Base64 decode token data
        final tokenDataJson = String.fromCharCodes(base64Decode(tokenDataEncoded));
        final tokenData = jsonDecode(tokenDataJson) as Map<String, dynamic>;
        
        print('🔗 Decoded user data: ${userData['username']} (${userData['email']})');
        print('🔗 Token data available: ${tokenData.containsKey('access_token')}');
        
        // AuthService ile giriş yap - gerçek token'ları kullan
        final authService = ServiceLocator.auth;
        
        await authService.loginWithGoogle(
          tokenData['access_token']?.toString() ?? '',
          tokenData['refresh_token']?.toString() ?? '',
          userData,
        );
        
        print('🔗 Google OAuth login completed, navigating to home...');
        
        // Ana sayfaya yönlendir
        _navigateToHome();
      } else {
        _showError('User data veya token data bulunamadı');
      }
    } catch (e) {
      print('🔗 Google OAuth success işleme hatası: $e');
      _showError('Success callback işlenirken hata: $e');
    }
  }

  static void _navigateToHome() {
    // Ana sayfaya yönlendirme
    print('Google OAuth başarılı, ana sayfaya yönlendiriliyor...');

    // Explicit navigation - StreamBuilder'a güvenmek yerine direkt navigasyon yap
    final navigatorKey = ServiceLocator.navigatorKey;
    if (navigatorKey.currentContext != null) {
      final context = navigatorKey.currentContext!;
      
      // Sayfaları oluştur
      final pages = [
        const HomePage(),
        const MapPage(allowSelection: true),
        const GroupsPage(),
        const EventsPage(),
        const MessagesPage(),
        const ProfilePage(username: 'emre.celik.290'), // Username'i token'dan alabiliriz
      ];

      // Ana sayfaya yönlendir
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainWrapperNew(
            pages: pages,
            navItems: NavigationItems.items,
          ),
        ),
        (route) => false,
      );
      
      print('Explicit navigation to home page completed');
    } else {
      print('Navigator context not available, relying on StreamBuilder');
    }
  }

  static void _showError(String message) {
    print('Google OAuth hatası: $message');
    // Hata mesajını göster
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }
}
