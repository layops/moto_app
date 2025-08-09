import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart'; // Renk şemaları için import
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/views/auth/register_page.dart';
import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/groups/group_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';
import 'package:motoapp_frontend/views/settings/settings_page.dart';
import 'package:motoapp_frontend/widgets/navigations/bottom_nav_item.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen kullanıcı adı ve şifre giriniz'),
          backgroundColor: AppColorSchemes.light.error, // Hata rengi
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainWrapper(
              pages: [
                const HomePage(),
                const GroupsPage(),
                ProfilePage(
                    email:
                        _usernameController.text), // Email parametresi verildi
                const SettingsPage(),
              ],
              navItems: const [
                BottomNavItem(icon: Icons.home, label: 'Ana Sayfa', index: 0),
                BottomNavItem(icon: Icons.group, label: 'Gruplar', index: 1),
                BottomNavItem(icon: Icons.person, label: 'Profil', index: 2),
                BottomNavItem(icon: Icons.settings, label: 'Ayarlar', index: 3),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme; // Renk şemasını al

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: ThemeConstants.paddingMedium,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50.h),
              // Logo - Primary renk kullanıyoruz
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
                  labelText: 'Kullanıcı Adı',
                  labelStyle: theme.textTheme.bodyLarge
                      // ignore: deprecated_member_use
                      ?.copyWith(color: colors.onSurface.withOpacity(0.6)),
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
                      // ignore: deprecated_member_use
                      ?.copyWith(color: colors.onSurface.withOpacity(0.6)),
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
                ),
              ),
              SizedBox(height: 30.h),

              // Giriş Butonu - Primary renk kullanıyoruz
              ElevatedButton(
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
              SizedBox(height: 15.h),

              // Kayıt Ol Butonu - Secondary renk kullanıyoruz
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
                child: Text(
                  'Hesabınız yok mu? Kayıt Olun',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.secondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
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
