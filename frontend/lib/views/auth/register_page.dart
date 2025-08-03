import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late ApiService _apiService;
  bool _isApiServiceReady = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _selectedLanguage = 'TR';

  @override
  void initState() {
    super.initState();
    _initApiService();
  }

  Future<void> _initApiService() async {
    _apiService = await ApiService.create();
    setState(() {
      _isApiServiceReady = true;
    });
  }

  Future<void> _register() async {
    if (!_isApiServiceReady) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt başarılı! Şimdi giriş yapabilirsiniz.'),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kayıt başarısız: ${response.data['detail'] ?? 'Bilinmeyen hata'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
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
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(
                          Icons.email,
                          color: inputDecorationTheme.prefixIconColor ??
                              // ignore: deprecated_member_use
                              colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
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
                    SizedBox(height: 30.h),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 48.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            child: Text(
                              'Kayıt Ol',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    SizedBox(height: 20.h),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Zaten hesabın var mı? Giriş Yap',
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
