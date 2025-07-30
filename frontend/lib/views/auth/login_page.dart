// frontend/lib/views/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/api_service.dart'; // ApiService'i import ediyoruz
import 'package:motoapp_frontend/views/auth/register_page.dart'; // RegisterPage'i import ediyoruz (ileride oluşturacağız)
import 'package:motoapp_frontend/views/home/dashboard_page.dart'; // DashboardPage'i import ediyoruz (başarılı giriş sonrası yönlendirme)

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService(); // ApiService örneği
  bool _isLoading = false; // Yüklenme durumu için

  // Giriş işlemini yöneten metod
  Future<void> _login() async {
    setState(() {
      _isLoading = true; // Yükleniyor durumunu başlat
    });

    try {
      final response = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (response.statusCode == 200) {
        // Başarılı giriş
        final token = response.data['token'];
        await _apiService.saveAuthToken(token); // Token'ı kaydet

        // Başarılı giriş sonrası DashboardPage'e yönlendir
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      } else {
        // Hata durumunda kullanıcıya bilgi ver
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Giriş başarısız: ${response.data['detail'] ?? 'Bilinmeyen hata'}')),
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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlandırması için ScreenUtil'i kullanın
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş Yap'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w), // Responsive padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo veya uygulama adı
              FlutterLogo(size: 100.w), // Geçici logo
              SizedBox(height: 40.h),

              // Kullanıcı adı girişi
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12.r), // Responsive border radius
                  ),
                  prefixIcon: Icon(Icons.person, size: 20.w),
                ),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 20.h),

              // Şifre girişi
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: Icon(Icons.lock, size: 20.w),
                ),
                obscureText: true, // Şifreyi gizle
              ),
              SizedBox(height: 30.h),

              // Giriş butonu
              _isLoading
                  ? const CircularProgressIndicator() // Yüklenirken spinner göster
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity,
                            50.h), // Buton genişliği ve yüksekliği
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Giriş Yap',
                        style:
                            TextStyle(fontSize: 18.sp), // Responsive font size
                      ),
                    ),
              SizedBox(height: 20.h),

              // Kayıt ol butonu
              TextButton(
                onPressed: () {
                  // Kayıt sayfasına yönlendir
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterPage()),
                  );
                },
                child: Text(
                  'Hesabın yok mu? Kayıt Ol',
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
