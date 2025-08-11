import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/app/navigator_service.dart';
import 'package:motoapp_frontend/core/theme/app_theme.dart';
import 'package:motoapp_frontend/core/providers/theme_provider.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/services/auth/token_service.dart';
import 'package:motoapp_frontend/services/http/api_client.dart';
import 'package:motoapp_frontend/services/storage/local_storage.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/groups/group_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';
import 'package:motoapp_frontend/views/settings/settings_page.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper.dart';
import 'package:motoapp_frontend/widgets/navigations/navigation_items.dart';

class AppConfig extends StatelessWidget {
  final ApiClient apiClient;
  final LocalStorage localStorage;

  const AppConfig({
    super.key,
    required this.apiClient,
    required this.localStorage,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // Servisleri oluştur
        final tokenService = TokenService(localStorage);
        final authService = AuthService(apiClient, tokenService, localStorage);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeProvider()),
            Provider<AuthService>.value(value: authService),
            Provider<TokenService>.value(value: tokenService),
          ],
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
                  '/login': (context) => LoginPage(
                        authService:
                            Provider.of<AuthService>(context, listen: false),
                      ),
                  '/home': (context) => MainWrapper(
                        pages: [
                          const HomePage(),
                          const GroupsPage(),
                          const ProfilePage(),
                          const SettingsPage(),
                        ],
                        navItems: NavigationItems.items,
                      ),
                },
                navigatorKey: NavigatorService.navigatorKey,
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  return MediaQuery(
                    data: mediaQuery.copyWith(
                        textScaler: const TextScaler.linear(1.0)),
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
