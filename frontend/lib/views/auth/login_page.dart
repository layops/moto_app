import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/views/auth/register_page.dart';
import 'package:motoapp_frontend/views/auth/forgot_password_page.dart';
import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/map/map_page.dart';
import 'package:motoapp_frontend/views/messages/messages_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';
import 'package:motoapp_frontend/views/search/search_page.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper.dart';
import 'package:motoapp_frontend/widgets/navigations/navigation_items.dart';

class LoginPage extends StatefulWidget {
  final AuthService authService;

  const LoginPage({super.key, required this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedData();
  }

  Future<void> _loadRememberedData() async {
    final rememberMe = await widget.authService.getRememberMe();
    if (rememberMe) {
      final username = await widget.authService.getRememberedUsername();
      if (username != null) {
        setState(() {
          _rememberMe = true;
          _usernameController.text = username;
        });
      }
    }
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackbar('Lütfen kullanıcı adı ve şifre giriniz');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Remember me ayarını kaydet
      await widget.authService.saveRememberMe(_rememberMe);
      if (_rememberMe) {
        await widget.authService
            .saveRememberedUsername(_usernameController.text);
      } else {
        await widget.authService.clearRememberedUsername();
      }

      // AuthService ile giriş yap
      await widget.authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainWrapper(
              pages: [
                const HomePage(),
                const SearchPage(),
                const MapPage(),
                const MessagesPage(),
                const ProfilePage(),
              ],
              navItems: NavigationItems.items,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorSchemes.light.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: ThemeConstants.paddingMedium,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50.h),
              // Logo
              Image.asset(
                'assets/images/spiride_logo_main_page.png',
                height: 190.h,
                width: 190.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 40.h),

              // Kullanıcı Adı Alanı
              TextField(
                controller: _usernameController,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colors.onSurface),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı veya E-posta',
                  labelStyle: theme.textTheme.bodyLarge
                      ?.copyWith(color: colors.onSurfaceVariant),
                  prefixIcon: Icon(Icons.person, color: colors.primary),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        ThemeConstants.borderRadiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.primary, width: 2),
                    borderRadius: BorderRadius.circular(
                        ThemeConstants.borderRadiusMedium),
                  ),
                  contentPadding: ThemeConstants.paddingMedium,
                ),
              ),
              SizedBox(height: 20.h),

              // Şifre Alanı
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colors.onSurface),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  labelStyle: theme.textTheme.bodyLarge
                      ?.copyWith(color: colors.onSurfaceVariant),
                  prefixIcon: Icon(Icons.lock, color: colors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: colors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        ThemeConstants.borderRadiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.primary, width: 2),
                    borderRadius: BorderRadius.circular(
                        ThemeConstants.borderRadiusMedium),
                  ),
                  contentPadding: ThemeConstants.paddingMedium,
                ),
              ),
              SizedBox(height: 10.h),

              // Beni Hatırla ve Şifremi Unuttum Satırı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Beni Hatırla Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: colors.primary,
                      ),
                      Text(
                        'Beni Hatırla',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),

                  // Şifremi Unuttum Butonu
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ForgotPasswordPage(authService: widget.authService),
                      ),
                    ),
                    child: Text(
                      'Şifremi Unuttum',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.secondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Giriş Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50.h),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          ThemeConstants.borderRadiusMedium),
                    ),
                    padding: ThemeConstants.paddingMedium,
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24.h,
                          width: 24.h,
                          child: CircularProgressIndicator(
                            color: colors.onPrimary,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'Giriş Yap',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 15.h),

              // Kayıt Ol Butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hesabınız yok mu? ',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RegisterPage(authService: widget.authService),
                      ),
                    ),
                    child: Text(
                      'Kayıt Olun',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.secondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
