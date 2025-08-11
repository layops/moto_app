import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/views/auth/register_page.dart';
import 'package:motoapp_frontend/views/auth/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  final AuthService authService;

  const LoginPage({super.key, required this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userOrEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // AuthService.login(username, password, {rememberMe}) şeklinde
      await widget.authService.login(
        _userOrEmailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );
      // Giriş başarılıysa gerekli yönlendirme buraya eklenmeli (varsa)
    } catch (e) {
      _showError('Giriş başarısız: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
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
  void dispose() {
    _userOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: ThemeConstants.paddingMedium,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 50.h),
                Image.asset(
                  'assets/images/spiride_logo_main_page.png',
                  height: 190.h,
                  width: 190.w,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 40.h),
                TextFormField(
                  controller: _userOrEmailController,
                  keyboardType: TextInputType.text,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen kullanıcı adı veya e-posta girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                TextFormField(
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifre girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _rememberMe = newValue ?? false;
                        });
                      },
                      activeColor: colors.primary,
                    ),
                    const Text('Beni Hatırla'),
                  ],
                ),
                SizedBox(height: 20.h),
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
                            'GİRİŞ YAP',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hesabın yok mu? ',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: colors.onSurface),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RegisterPage(authService: widget.authService),
                        ),
                      ),
                      child: Text(
                        'Kayıt Ol',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.secondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ForgotPasswordPage(authService: widget.authService),
                    ),
                  ),
                  child: Text(
                    'Şifremi Unuttum',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
