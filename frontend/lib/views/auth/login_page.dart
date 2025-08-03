import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/api_service.dart';
import 'package:motoapp_frontend/views/auth/register_page.dart';
import 'package:motoapp_frontend/views/home/home_page.dart'; // 👈 HomePage eklendi

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late ApiService _apiService;
  bool _isApiServiceReady = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;

  String _selectedLanguage = 'TR';

  @override
  void initState() {
    super.initState();
    _initApiService();
  }

  Future<void> _initApiService() async {
    _apiService = await ApiService.create();
    _isApiServiceReady = true;
    await _loadRememberedUser();
    if (mounted) setState(() {});
  }

  Future<void> _loadRememberedUser() async {
    if (!_isApiServiceReady) return;
    _rememberMe = await _apiService.getRememberMe();
    if (_rememberMe) {
      final rememberedUsername = await _apiService.getRememberedUsername();
      if (rememberedUsername != null) {
        _usernameController.text = rememberedUsername;
      }
    }
  }

  Future<void> _login() async {
    if (!_isApiServiceReady) return;
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        await _apiService.saveAuthToken(token);

        await _apiService.saveRememberMe(_rememberMe);
        if (_rememberMe) {
          await _apiService.saveRememberedUsername(_usernameController.text);
        } else {
          await _apiService.clearRememberedUsername();
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                  username: _usernameController.text), // ✅ Burası değiştirildi
            ),
          );
        }
      } else {
        _showError(
          'Giriş başarısız: ${response.data['detail'] ?? 'Bilinmeyen hata'}',
        );
      }
    } catch (e) {
      _showError('Bir hata oluştu: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isApiServiceReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final inputDecorationTheme = Theme.of(context).inputDecorationTheme;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 24.w, top: 8.h, bottom: 8.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  underline: const SizedBox(),
                  icon: Icon(Icons.language, color: colorScheme.primary),
                  items: ['TR', 'EN', 'DE'].map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedLanguage = val;
                      });
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/spiride_logo_main_page.png',
                      width: 220.w,
                      height: 220.h,
                    ),
                    SizedBox(height: 32.h),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Kullanıcı Adı',
                        prefixIcon: Icon(
                          Icons.person,
                          color: inputDecorationTheme.prefixIconColor ??
                              // ignore: deprecated_member_use
                              colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: colorScheme.onSurface),
                    ),
                    SizedBox(height: 20.h),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: Icon(
                          Icons.lock,
                          color: inputDecorationTheme.prefixIconColor ??
                              // ignore: deprecated_member_use
                              colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      obscureText: true,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: colorScheme.onSurface),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) =>
                                  setState(() => _rememberMe = val ?? false),
                              activeColor: colorScheme.primary,
                              checkColor: colorScheme.onPrimary,
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _rememberMe = !_rememberMe),
                              child: Text(
                                'Beni Hatırla',
                                style: textTheme.bodyMedium?.copyWith(
                                  // ignore: deprecated_member_use
                                  color: colorScheme.onSurface.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            _showError(
                                "Şifre sıfırlama özelliği yakında eklenecek.");
                          },
                          child: Text(
                            'Şifremi Unuttum',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 48.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            child: Text(
                              'Giriş Yap',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    SizedBox(height: 20.h),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage()),
                        );
                      },
                      child: Text(
                        'Hesabın yok mu? Kayıt Ol',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
