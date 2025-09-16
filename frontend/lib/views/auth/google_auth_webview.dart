import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/views/auth/auth_common.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper_new.dart';
import 'package:motoapp_frontend/widgets/navigations/navigation_items.dart';
import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/map/map_page.dart';
import 'package:motoapp_frontend/views/groups/group_page.dart';
import 'package:motoapp_frontend/views/event/events_page.dart';
import 'package:motoapp_frontend/views/messages/messages_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';
import 'package:motoapp_frontend/config.dart';

class GoogleAuthWebView extends StatefulWidget {
  final AuthService authService;

  const GoogleAuthWebView({super.key, required this.authService});

  @override
  State<GoogleAuthWebView> createState() => _GoogleAuthWebViewState();
}

class _GoogleAuthWebViewState extends State<GoogleAuthWebView> {
  String? authUrl;
  String? state;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getAuthUrl();
  }

  Future<void> _getAuthUrl() async {
    try {
      final response = await widget.authService.getGoogleAuthUrl();
      if (response.statusCode == 200) {
        setState(() {
          authUrl = response.data['auth_url'];
          state = response.data['state']; // PKCE state'i sakla
          _isLoading = false;
        });
        // URL'i otomatik olarak aç
        _launchGoogleAuth();
      } else {
        setState(() {
          _errorMessage = 'Google OAuth URL alınamadı';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google OAuth URL alınırken hata: Lütfen normal email/şifre ile giriş yapın';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchGoogleAuth() async {
    if (authUrl != null) {
      try {
        final uri = Uri.parse(authUrl!);
        
        // External browser yerine WebView kullanarak callback'i yakala
        await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
        
        // URL başarıyla açıldı, success state'e geç
        setState(() {
          _isLoading = false;
          _errorMessage = '';
        });
        
        // Kullanıcıya callback URL'yi manuel olarak girmesini söyle
        _showCallbackInstructions();
        
      } catch (e) {
        setState(() {
          _errorMessage = 'Google OAuth URL açılırken hata: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showCallbackInstructions() {
    final TextEditingController urlController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Google Giriş Tamamlandı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Google ile giriş yaptıktan sonra, tarayıcıda görünen URL\'yi buraya yapıştırın:'),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Callback URL',
                hintText: 'https://spiride.onrender.com/api/users/auth/callback/?code=...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (url) => _handleCallbackUrl(url),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                _handleCallbackUrl(url);
              }
            },
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCallbackUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final stateFromUrl = uri.queryParameters['state'];
      
      if (code != null && state != null) {
        // Backend'e callback gönder - state parametresini ekle
        final response = await widget.authService.handleGoogleCallback(code, state!);
        
        if (response.statusCode == 200) {
          final data = response.data;
          
          // Token'ları kaydet
          await widget.authService.loginWithGoogle(
            data['access_token'],
            data['refresh_token'],
            data['user'],
          );
          
          // Ana sayfaya yönlendir
          if (mounted) {
            Navigator.pop(context); // Dialog'u kapat
            
            final pages = [
              const HomePage(),
              const MapPage(allowSelection: true),
              const GroupsPage(),
              const EventsPage(),
              const MessagesPage(),
              ProfilePage(username: data['user']['username']),
            ];

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
          }
        } else {
          if (mounted) {
            final errorData = response.data;
            AuthCommon.showErrorSnackbar(context, 'Google giriş başarısız: ${errorData?['error'] ?? 'Bilinmeyen hata'}');
          }
        }
      } else {
        if (mounted) {
          String errorMsg = 'Geçersiz callback URL';
          if (code == null) errorMsg += ' - Authorization code bulunamadı';
          if (state == null) errorMsg += ' - State bulunamadı';
          AuthCommon.showErrorSnackbar(context, errorMsg);
        }
      }
    } catch (e) {
      if (mounted) {
        AuthCommon.showErrorSnackbar(context, 'Callback işlenirken hata: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Google ile Giriş'),
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colors.primary,
              ),
              SizedBox(height: 16.h),
              Text(
                'Google OAuth URL alınıyor...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Google ile Giriş'),
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.w,
                color: colors.error,
              ),
              SizedBox(height: 16.h),
              Text(
                'Hata',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google ile Giriş'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64.w,
              color: colors.primary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Google OAuth Başlatıldı',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                'Google giriş sayfası tarayıcınızda açıldı. Giriş yaptıktan sonra uygulamaya geri dönün.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.8),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
  }
}
