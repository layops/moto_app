import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/views/auth/register_page.dart';
import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/groups/group_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';
import 'package:motoapp_frontend/views/settings/settings_page.dart';
import 'package:motoapp_frontend/widgets/navigations/bottom_nav_item.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kullanıcı adı ve şifre giriniz')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainWrapper(
              email: _usernameController.text,
              pages: const [
                HomePage(),
                GroupsPage(),
                ProfilePage(),
                SettingsPage(),
              ],
              navItems: const [
                BottomNavItem(icon: Icons.home, label: 'Ana Sayfa', index: 0),
                BottomNavItem(icon: Icons.group, label: 'Gruplar', index: 1),
                BottomNavItem(icon: Icons.person, label: 'Profil', index: 2),
                BottomNavItem(icon: Icons.settings, label: 'Ayarlar', index: 3),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Büyütülmüş Logo (150x150 yerine 190x190 - %25 büyük)
            Image.asset(
              'assets/images/spiride_logo_main_page.png',
              height: 190
                  .h, // Önceki 120.h idi, %25 artışla ~150.h olmalı ama daha belirgin olsun diye 190.h yaptım
              width: 190.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 30.h),

            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Giriş Yap'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              ),
              child: const Text('Hesabınız yok mu? Kayıt Olun'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
