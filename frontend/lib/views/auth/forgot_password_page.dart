import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/views/auth/auth_common.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_button.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_logo.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_text_field.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';

class ForgotPasswordPage extends StatefulWidget {
  final AuthService authService;

  const ForgotPasswordPage({super.key, required this.authService});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        AuthCommon.showSuccessSnackbar(
          context,
          'Şifre sıfırlama bağlantısı ${_emailController.text} adresine gönderildi',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(authService: widget.authService),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AuthCommon.showErrorSnackbar(context, 'Hata: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                    
                    // Geri butonu
                    _buildBackButton(theme, colors),
                    
                    SizedBox(height: 30.h),
                    
                    // Logo ve Başlık Bölümü
                    _buildHeader(theme, colors),
                    
                    SizedBox(height: 30.h),
                    
                    // Form Kartı
                    _buildFormCard(theme, colors),
                    
                    SizedBox(height: 35.h),
                    
                    // Giriş Sayfasına Dön Linki
                    _buildBackToLoginLink(theme, colors),
                    
                    SizedBox(height: 50.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme, ColorScheme colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColorSchemes.primaryColor.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColorSchemes.primaryColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colors.onSurface,
            size: 20.h,
          ),
          padding: EdgeInsets.all(12.w),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        // Logo Container - Küçük logo ve yuvarlak
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
        
        // Başlık - Daha büyük ve etkileyici
        Text(
          'Şifremi Unuttum',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.8,
            fontSize: 32.sp,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 12.h),
        
        // Alt başlık - Daha okunabilir
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim',
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
          // E-posta Alanı
          AuthTextField(
            controller: _emailController,
            labelText: 'E-posta Adresi',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen e-posta adresinizi girin';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Lütfen geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          
          SizedBox(height: 24.h),
          
          // Gönder Butonu
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: AuthButton(
              text: 'Sıfırlama Bağlantısı Gönder',
              onPressed: _sendResetLink,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginLink(ThemeData theme, ColorScheme colors) {
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
          Icon(
            Icons.arrow_back_ios,
            color: colors.onSurface.withOpacity(0.6),
            size: 16.h,
          ),
          SizedBox(width: 8.w),
          Text(
            'Giriş sayfasına dön ',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface.withOpacity(0.8),
              fontSize: 16.sp,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LoginPage(authService: widget.authService),
              ),
            ),
            child: Text(
              'buradan',
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
