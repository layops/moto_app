import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/views/auth/auth_common.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_button.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_logo.dart';
import 'package:motoapp_frontend/views/auth/widgets/password_field.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ServiceLocator.auth.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        AuthCommon.showSuccessSnackbar(
          context,
          'Şifreniz başarıyla değiştirildi',
        );

        // Başarılı değişiklik sonrası geri dön
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        
        String errorMessage = 'Şifre değiştirilemedi';
        if (response.data != null && response.data['error'] != null) {
          errorMessage = response.data['error'];
        }
        
        AuthCommon.showErrorSnackbar(context, errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Şifre değiştirme hatası: $e';
      if (e.toString().contains('Oturum süresi doldu')) {
        errorMessage = 'Oturumunuz sona ermiş. Lütfen tekrar giriş yapın.';
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          }
        });
      }
      
      AuthCommon.showErrorSnackbar(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bu alan gerekli';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    
    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalı';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Şifre en az bir büyük harf içermeli';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Şifre en az bir küçük harf içermeli';
    }
    
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Şifre en az bir rakam içermeli';
    }
    
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gerekli';
    }
    
    if (value != _newPasswordController.text) {
      return 'Şifreler eşleşmiyor';
    }
    
    return null;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Şifre Değiştir',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                
                // Logo
                const AuthLogo(),
                
                SizedBox(height: 40.h),
                
                // Başlık
                Text(
                  'Şifrenizi Değiştirin',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 8.h),
                
                Text(
                  'Güvenliğiniz için mevcut şifrenizi girin ve yeni şifrenizi belirleyin',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 40.h),
                
                // Mevcut Şifre
                PasswordField(
                  controller: _currentPasswordController,
                  labelText: 'Mevcut Şifre',
                  validator: _validateRequired,
                ),
                
                SizedBox(height: 16.h),
                
                // Yeni Şifre
                PasswordField(
                  controller: _newPasswordController,
                  labelText: 'Yeni Şifre',
                  validator: _validatePassword,
                ),
                
                SizedBox(height: 16.h),
                
                // Şifre Tekrarı
                PasswordField(
                  controller: _confirmPasswordController,
                  labelText: 'Yeni Şifre Tekrar',
                  validator: _validateConfirmPassword,
                ),
                
                SizedBox(height: 32.h),
                
                // Şifre Değiştir Butonu
                AuthButton(
                  text: 'Şifreyi Değiştir',
                  onPressed: _isLoading ? null : () => _changePassword(),
                  isLoading: _isLoading,
                ),
                
                SizedBox(height: 24.h),
                
                // Güvenlik Uyarısı
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: colors.primary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Şifreniz değiştirildikten sonra tüm cihazlardan çıkış yapmanız gerekebilir.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
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
