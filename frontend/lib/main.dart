import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'views/auth/login_page.dart';
import 'views/home/home_page.dart';
import 'views/profile/profile_page.dart';
import 'views/settings/settings_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Moto App',
          theme: AppTheme.lightTheme(context),
          darkTheme: AppTheme.darkTheme(context),
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) =>
                HomePage(username: 'emre'), // Burada username geç
            '/profile': (context) => ProfilePage(username: 'emre'),
            '/settings': (context) => const SettingsPage(),
          },
        );
      },
    );
  }
}
