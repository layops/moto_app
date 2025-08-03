import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'views/auth/login_page.dart';
import 'views/home/home_page.dart';
import 'widgets/maps_widgets/map_page.dart';
import 'views/profile/profile_page.dart';
import 'views/settings/settings_page.dart';
import 'widgets/custom_bottom_navbar.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
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
                '/home': (context) => const MainWrapper(),
                '/map': (context) => const MapPage(),
                '/profile': (context) => const ProfilePage(username: 'emre'),
                '/settings': (context) => const SettingsPage(),
              },
            );
          },
        );
      },
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(username: 'emre'),
    const Placeholder(), // Gruplar sayfası
    const MapPage(),
    const ProfilePage(username: 'emre'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) {
            // Titreşim efekti için
            HapticFeedback.lightImpact();
          }
        },
      ),
    );
  }
}
