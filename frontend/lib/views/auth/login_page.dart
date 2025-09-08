import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/views/auth/auth_common.dart';
import 'package:motoapp_frontend/views/auth/forgot_password_page.dart';
import 'package:motoapp_frontend/views/auth/register_page.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_button.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_logo.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_text_field.dart';
import 'package:motoapp_frontend/views/auth/widgets/password_field.dart';
import 'package:motoapp_frontend/views/auth/widgets/social_button.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper_new.dart';
import 'package:motoapp_frontend/widgets/navigations/navigation_items.dart';
import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/map/map_page.dart';
import 'package:motoapp_frontend/views/groups/group_page.dart';
import 'package:motoapp_frontend/views/event/events_page.dart';
import 'package:motoapp_frontend/views/messages/messages_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';

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
  bool _rememberMe = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _userOrEmailController.text.trim();
      final password = _passwordController.text;

      final response = await widget.authService.login(
        username,
        password,
        rememberMe: _rememberMe,
      );

      if (response.statusCode == 200) {
        final pages = [
          const HomePage(),           // Index 0 - Home
          const MapPage(allowSelection: true), // Index 1 - Map
          const GroupsPage(),         // Index 2 - Groups  
          const EventsPage(),         // Index 3 - Events
          const MessagesPage(),       // Index 4 - Messages
          ProfilePage(username: username), // Index 5 - Profile
        ];

        // Başarılı girişten sonra ana sayfaya yönlendirme ve tüm geçmiş rotaları temizleme
        if (mounted) {
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
        // Başarısız giriş durumunda snackbar ile hata mesajı gösterme
        String errorMessage = 'Invalid credentials. Please try again.';
        if (response.data != null && response.data['detail'] is String) {
          errorMessage = response.data['detail'];
        }
        if (mounted) {
          AuthCommon.showErrorSnackbar(context, errorMessage);
        }
      }
    } catch (e) {
      debugPrint('Giriş yapılırken hata: $e');
      if (mounted) {
        String errorMessage =
            'An unexpected error occurred. Please try again later.';
        if (e.toString().contains('Giriş hatası:')) {
          errorMessage =
              e.toString().replaceFirst('Exception: Giriş hatası: ', '');
        }
        AuthCommon.showErrorSnackbar(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Kullanıcı adı mı yoksa e-posta mı olduğunu kontrol eden fonksiyon
  // ignore: unused_element
  bool _isEmail(String input) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(input);
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
      backgroundColor: colors.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 80.h),
                const AuthLogo(size: 100),
                SizedBox(height: 40.h),
                Text(
                  'Welcome to Spiride',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  'Connect with fellow motorcycle riders and track your adventures',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    // ignore: deprecated_member_use
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 40.h),
                AuthTextField(
                  controller: _userOrEmailController,
                  labelText: 'Username or Email',
                  prefixIcon: Icons.person,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username or email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                PasswordField(
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                        Text(
                          'Remember me',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            // ignore: deprecated_member_use
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordPage(
                              authService: widget.authService),
                        ),
                      ),
                      child: Text(
                        'Forgot password?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                AuthButton(
                  text: 'Sign In',
                  onPressed: _login,
                  isLoading: _isLoading,
                ),
                SizedBox(height: 30.h),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        // ignore: deprecated_member_use
                        color: colors.onSurface.withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: theme.textTheme.bodySmall?.copyWith(
                          // ignore: deprecated_member_use
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        // ignore: deprecated_member_use
                        color: colors.onSurface.withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: SocialButton(
                        icon: Icons.g_mobiledata,
                        text: 'Google',
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: SocialButton(
                        icon: Icons.apple,
                        text: 'Apple',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        // ignore: deprecated_member_use
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RegisterPage(authService: widget.authService),
                        ),
                      ),
                      child: Text(
                        'Sign up',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
