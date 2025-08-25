import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/views/auth/auth_common.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_button.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_logo.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_text_field.dart';

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
          'Password reset link sent to ${_emailController.text}',
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
        AuthCommon.showErrorSnackbar(context, 'Error: ${e.toString()}');
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
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                Center(child: AuthLogo(size: 100)),
                SizedBox(height: 40.h),
                Text(
                  'Forgot Password',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Enter your email and we will send you a reset link',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onBackground.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 40.h),
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30.h),
                AuthButton(
                  text: 'Send Reset Link',
                  onPressed: _sendResetLink,
                  isLoading: _isLoading,
                ),
                SizedBox(height: 20.h),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LoginPage(authService: widget.authService),
                      ),
                    ),
                    child: Text(
                      'Back to Login',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
