import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/services/post/post_service.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/core/providers/theme_provider.dart';
import 'package:motoapp_frontend/core/theme/light_theme.dart';
import 'package:motoapp_frontend/core/theme/dark_theme.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper.dart';
import 'package:motoapp_frontend/widgets/navigations/navigation_items.dart';

import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/map/map_page.dart';
import 'package:motoapp_frontend/views/groups/group_page.dart';
import 'package:motoapp_frontend/views/event/events_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';
import 'package:motoapp_frontend/views/notifications/notifications_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ServiceLocator.init();
    await ServiceLocator.auth.initializeAuthState();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<AuthService>.value(value: ServiceLocator.auth),
          Provider<PostService>(create: (_) => PostService()),
        ],
        child: const MotoApp(),
      ),
    );
  } catch (e, stackTrace) {
    _runFallbackApp(e, stackTrace);
  }
}

void _runFallbackApp(Object error, StackTrace stackTrace) {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.w, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'Uygulama başlatılamadı',
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Hata: ${error.toString()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () => main(),
                  child: Text('Tekrar Dene', style: TextStyle(fontSize: 16.sp)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class MotoApp extends StatelessWidget {
  const MotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = ServiceLocator.auth;

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return StreamBuilder<dynamic>(
              stream: authService.authStateChanges,
              builder: (context, snapshot) {
                final isAuthenticated = snapshot.hasData;

                // Ana sayfayı oluşturmadan önce biraz bekleyelim
                Future.delayed(Duration.zero, () {
                  // Navigator'ın hazır olmasını sağla
                });

                return MaterialApp(
                  title: 'Moto App',
                  debugShowCheckedModeBanner: false,
                  theme: LightTheme.theme,
                  darkTheme: DarkTheme.theme,
                  themeMode: themeProvider.themeMode,
                  locale: const Locale('tr', 'TR'),
                  supportedLocales: const [Locale('tr', 'TR')],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                  ],
                  // Ana sayfa olarak doğrudan LoginPage veya MainWrapper veriyoruz
                  home: isAuthenticated
                      ? _buildMainWrapper()
                      : LoginPage(authService: authService),
                  routes: {
                    '/login': (context) =>
                        LoginPage(authService: ServiceLocator.auth),
                    '/notifications': (context) => const NotificationsPage(),
                    '/profile': (context) {
                      final username =
                          ModalRoute.of(context)!.settings.arguments as String?;
                      return ProfilePage(username: username ?? 'Kullanıcı');
                    },
                  },
                  // Navigator hatası için fallback
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => isAuthenticated
                          ? _buildMainWrapper()
                          : LoginPage(authService: authService),
                    );
                  },
                  onUnknownRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) =>
                          LoginPage(authService: ServiceLocator.auth),
                    );
                  },
                  navigatorKey: ServiceLocator.navigatorKey,
                  scaffoldMessengerKey: ServiceLocator.scaffoldMessengerKey,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(1.0)),
                      child: child!,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // MainWrapper'ı ayrı bir metod olarak oluşturuyoruz
  Widget _buildMainWrapper() {
    final List<Widget> pages = [
      const HomePage(),
      const MapPage(),
      const GroupsPage(),
      const EventsPage(),
      FutureBuilder<String?>(
        future: ServiceLocator.token.getUsernameFromToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final username = snapshot.data ?? 'Kullanıcı';
          return ProfilePage(username: username);
        },
      ),
    ];

    return MainWrapper(
      pages: pages,
      navItems: NavigationItems.items,
    );
  }
}
