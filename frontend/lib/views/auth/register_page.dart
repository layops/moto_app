// frontend/lib/views/auth/register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/api_service.dart'; // ApiService'i import ediyoruz

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService(); // ApiService örneği
  bool _isLoading = false; // Yüklenme durumu için

  // Kayıt işlemini yöneten metod
  Future<void> _register() async {
    setState(() {
      _isLoading = true; // Yükleniyor durumunu başlat
    });

    try {
      final response = await _apiService.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (response.statusCode == 201) {
        // 201 Created genellikle başarılı kayıt durumudur
        // Başarılı kayıt sonrası kullanıcıya bilgi ver ve giriş sayfasına yönlendir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Kayıt başarılı! Şimdi giriş yapabilirsiniz.')),
          );
          Navigator.pop(context); // Giriş sayfasına geri dön
        }
      } else {
        // Hata durumunda kullanıcıya bilgi ver
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Kayıt başarısız: ${response.data['detail'] ?? 'Bilinmeyen hata'}')),
          );
        }
      }
    } catch (e) {
      // Ağ hatası veya diğer istisnalar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Yükleniyor durumunu bitir
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
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlutterLogo(size: 100.w), // Geçici logo
              SizedBox(height: 40.h),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: Icon(Icons.person, size: 20.w),
                ),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 20.h),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: Icon(Icons.email, size: 20.w),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20.h),

              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: Icon(Icons.lock, size: 20.w),
                ),
                obscureText: true,
              ),
              SizedBox(height: 30.h),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Kayıt Ol',
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ),
              SizedBox(height: 20.h),

              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Giriş sayfasına geri dön
                },
                child: Text(
                  'Zaten hesabın var mı? Giriş Yap',
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
