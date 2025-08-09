import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Şifreler eşleşmiyor');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ServiceLocator.user.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          _showSuccess('Kayıt başarılı! Giriş yapabilirsiniz');
        }
      } else {
        _showError(response.data['detail'] ?? 'Kayıt başarısız');
      }
    } catch (e) {
      _showError('Hata: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                // Logo - login_page ile aynı
                Image.asset(
                  'assets/images/spiride_logo_main_page.png',
                  height: 190.h,
                  width: 190.w,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 40.h),

                // Kullanıcı Adı
                TextFormField(
                  controller: _usernameController,
                  style: theme.textTheme.bodyLarge,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen kullanıcı adı girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: theme.textTheme.bodyLarge,
                  cursorColor: colors.primary,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: theme.textTheme.bodyLarge
                        // ignore: deprecated_member_use
                        ?.copyWith(color: colors.onSurface.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.email, color: colors.primary),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen email girin';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir email adresi girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),

                // Şifre
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: theme.textTheme.bodyLarge,
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifre girin';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),

                // Şifre Tekrar
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: theme.textTheme.bodyLarge,
                  cursorColor: colors.primary,
                  decoration: InputDecoration(
                    labelText: 'Şifre Tekrar',
                    labelStyle: theme.textTheme.bodyLarge
                        // ignore: deprecated_member_use
                        ?.copyWith(color: colors.onSurface.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.lock, color: colors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colors.primary,
                      ),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
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
                SizedBox(height: 32.h),

                // Kayıt Ol Butonu
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50.h),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          ThemeConstants.borderRadiusMedium),
                    ),
                    padding: ThemeConstants.paddingMedium,
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
                          'KAYIT OL',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                SizedBox(height: 16.h),

                // Giriş Yap Butonu
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: Text(
                    'Zaten hesabın var mı? Giriş Yap',
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
