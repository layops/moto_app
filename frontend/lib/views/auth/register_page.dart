import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/views/auth/auth_common.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_button.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_logo.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_text_field.dart';
import 'package:motoapp_frontend/views/auth/widgets/password_field.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';

class RegisterPage extends StatefulWidget {
  final AuthService authService;

  const RegisterPage({super.key, required this.authService});

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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      AuthCommon.showErrorSnackbar(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.authService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        password2: _confirmPasswordController.text, // ekledik
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(authService: widget.authService),
          ),
        );
        AuthCommon.showSuccessSnackbar(
            context, 'Registration successful! You can login now');
      }
    } catch (e) {
      String errorMessage = 'Registration failed';
      if (e.toString().contains('Kayıt hatası:')) {
        errorMessage =
            e.toString().replaceFirst('Exception: Kayıt hatası: ', '');
      }
      AuthCommon.showErrorSnackbar(context, errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColorSchemes.primaryColor.withOpacity(0.15),
              AppColorSchemes.primaryColor.withOpacity(0.08),
              AppColorSchemes.secondaryColor.withOpacity(0.05),
              colors.surface.withOpacity(0.9),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    
                    // Logo ve Başlık Bölümü
                    _buildHeader(theme, colors),
                    
                    SizedBox(height: 30.h),
                    
                    // Form Kartı
                    _buildFormCard(theme, colors),
                    
                    SizedBox(height: 30.h),
                    
                    // Giriş Linki
                    _buildLoginLink(theme, colors),
                    
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        // Logo Container
        Container(
          padding: EdgeInsets.all(15.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surface,
                colors.surface.withOpacity(0.95),
                AppColorSchemes.primaryColor.withOpacity(0.05),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
            border: Border.all(
              color: AppColorSchemes.primaryColor.withOpacity(0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColorSchemes.primaryColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: colors.shadow.withOpacity(0.06),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: -6,
              ),
            ],
          ),
          child: const AuthLogo(size: 100),
        ),
        
        SizedBox(height: 20.h),
        
        // Başlık
        Text(
          'Hesap Oluştur',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.8,
            fontSize: 32.sp,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 12.h),
        
        // Alt başlık
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'Motosiklet topluluğuna katıl ve maceralarını paylaş',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface.withOpacity(0.8),
              height: 1.5,
              fontSize: 16.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface.withOpacity(0.98),
            colors.surface.withOpacity(0.95),
            colors.surface.withOpacity(0.92),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: AppColorSchemes.primaryColor.withOpacity(0.05),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 15),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: AppColorSchemes.primaryColor.withOpacity(0.02),
            blurRadius: 60,
            offset: const Offset(0, 25),
            spreadRadius: -8,
          ),
        ],
        border: Border.all(
          color: AppColorSchemes.primaryColor.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Form Alanları
          AuthTextField(
            controller: _usernameController,
            labelText: 'Kullanıcı Adı',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen kullanıcı adınızı girin';
              }
              return null;
            },
          ),
          
          SizedBox(height: 20.h),
          
          AuthTextField(
            controller: _emailController,
            labelText: 'E-posta',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen e-postanızı girin';
              }
              if (!value.contains('@')) {
                return 'Lütfen geçerli bir e-posta girin';
              }
              return null;
            },
          ),
          
          SizedBox(height: 20.h),
          
          PasswordField(
            controller: _passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen şifrenizi girin';
              }
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalı';
              }
              return null;
            },
          ),
          
          SizedBox(height: 20.h),
          
          PasswordField(
            controller: _confirmPasswordController,
            labelText: 'Şifre Tekrar',
          ),
          
          SizedBox(height: 24.h),
          
          // Kayıt Butonu
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: AuthButton(
              text: 'Kayıt Ol',
              onPressed: _register,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 28.w),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColorSchemes.primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorSchemes.primaryColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Zaten hesabınız var mı? ',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface.withOpacity(0.8),
              fontSize: 16.sp,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LoginPage(authService: widget.authService),
              ),
            ),
            child: Text(
              'Giriş Yap',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColorSchemes.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
