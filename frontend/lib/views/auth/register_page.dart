// frontend/lib/views/auth/register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _register() async {
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
                content: Text('Kayıt başarılı! Şimdi giriş yapabilirsiniz.')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Kayıt başarısız: ${response.data['detail'] ?? 'Bilinmeyen hata'}')),
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
      setState(() {
        _isLoading = false;
      });
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
    return Scaffold(
      // Scaffold'ın arka plan rengi temadan gelecek
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        // AppBar renkleri temadan gelecek
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/spiride_logo.png',
                width: 150.w,
                height: 150.h,
              ),
              SizedBox(height: 40.h),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  // Tema Input Decoration kullanacak
                  labelText: 'Kullanıcı Adı',
                  prefixIcon: Icon(Icons.person), // İkon rengi temadan gelecek
                ),
                keyboardType: TextInputType.text,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge, // Metin rengini temadan al
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  // Tema Input Decoration kullanacak
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email), // İkon rengi temadan gelecek
                ),
                keyboardType: TextInputType.emailAddress,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge, // Metin rengini temadan al
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  // Tema Input Decoration kullanacak
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock), // İkon rengi temadan gelecek
                ),
                obscureText: true,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge, // Metin rengini temadan al
              ),
              SizedBox(height: 30.h),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      // Stil temadan gelecek
                      child: const Text(
                        'Kayıt Ol',
                      ),
                    ),
              SizedBox(height: 20.h),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                // Stil temadan gelecek
                child: const Text(
                  'Zaten hesabın var mı? Giriş Yap',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
