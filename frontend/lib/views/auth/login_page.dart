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
import 'package:motoapp_frontend/core/theme/color_schemes.dart';

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
      // debugPrint('Giriş yapılırken hata: $e');
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
                    
                    SizedBox(height: 35.h),
                    
                    // Sosyal Medya Girişi
                    _buildSocialLogin(theme, colors),
                    
                    SizedBox(height: 35.h),
                    
                    // Kayıt Ol Linki
                    _buildSignUpLink(theme, colors),
                    
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
          'Hoş Geldiniz',
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
            'Motosiklet tutkunları ile bağlantı kurun ve maceralarınızı takip edin',
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
            controller: _userOrEmailController,
            labelText: 'Kullanıcı Adı veya E-posta',
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen kullanıcı adınızı veya e-postanızı girin';
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
              return null;
            },
          ),
          
          SizedBox(height: 20.h),
          
          // Remember Me ve Forgot Password
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  Text(
                    'Beni Hatırla',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(0.8),
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
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                ),
                child: Text(
                  'Şifremi Unuttum?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24.h),
          
          // Giriş Butonu
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: AuthButton(
              text: 'Giriş Yap',
              onPressed: _login,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLogin(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(
              child: Divider(
                color: colors.outline.withOpacity(0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'VEYA',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: colors.outline.withOpacity(0.3),
                thickness: 1,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 20.h),
        
        // Sosyal Medya Butonları
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
      ],
    );
  }

  Widget _buildSignUpLink(ThemeData theme, ColorScheme colors) {
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
            'Hesabınız yok mu? ',
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
                    RegisterPage(authService: widget.authService),
              ),
            ),
            child: Text(
              'Kayıt Ol',
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
