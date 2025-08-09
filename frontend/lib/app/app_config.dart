import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/app/navigator_service.dart';
import 'package:motoapp_frontend/core/theme/app_theme.dart';
import 'package:motoapp_frontend/core/providers/theme_provider.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/groups/group_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';
import 'package:motoapp_frontend/views/settings/settings_page.dart';
import 'package:motoapp_frontend/widgets/navigations/bottom_nav_item.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper.dart';

class AppConfig extends StatelessWidget {
  const AppConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Moto App',
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeProvider.themeMode,
                initialRoute: '/login',
                routes: {
                  '/login': (context) => const LoginPage(),
                  '/home': (context) => MainWrapper(
                        pages: const [
                          HomePage(),
                          GroupsPage(),
                          ProfilePage(
                              email: ''), // Burada zorunlu email verildi
                          SettingsPage(),
                        ],
                        navItems: const [
                          BottomNavItem(
                              icon: Icons.home, label: 'Ana Sayfa', index: 0),
                          BottomNavItem(
                              icon: Icons.group, label: 'Gruplar', index: 1),
                          BottomNavItem(
                              icon: Icons.person, label: 'Profil', index: 2),
                          BottomNavItem(
                              icon: Icons.settings, label: 'Ayarlar', index: 3),
                        ],
                      ),
                },
                navigatorKey: NavigatorService.navigatorKey,
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  return MediaQuery(
                    data:
                        mediaQuery.copyWith(textScaler: TextScaler.linear(1.0)),
                    child: child!,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
