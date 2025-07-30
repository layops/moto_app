// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Ekran boyutlandırma için
import 'package:google_fonts/google_fonts.dart'; // Google Fonts için
import 'package:motoapp_frontend/views/auth/login_page.dart'; // LoginPage'i import ediyoruz

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtil'i başlatıyoruz. Bu, responsive UI için temeldir.
    // Tasarım genişliği ve yüksekliğini kendi Figma/tasarım dosyanıza göre ayarlayın.
    // Örneğin, 360x690 yaygın bir mobil tasarım boyutudur.
    return ScreenUtilInit(
      designSize:
          const Size(360, 690), // Tasarımınızın baz aldığı ekran boyutları
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'MotoApp',
          debugShowCheckedModeBanner: false, // Debug bandını kaldırır
          theme: ThemeData(
            primarySwatch: Colors.blue, // Uygulamanın ana rengi
            visualDensity: VisualDensity.adaptivePlatformDensity,
            // Google Fonts entegrasyonu (örnek olarak Poppins)
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          home: const LoginPage(), // Uygulama başladığında LoginPage'i göster
        );
      },
    );
  }
}
