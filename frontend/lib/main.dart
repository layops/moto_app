import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/core/providers/theme_provider.dart';
import 'package:motoapp_frontend/core/theme/light_theme.dart';
import 'package:motoapp_frontend/core/theme/dark_theme.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper.dart';
import 'package:motoapp_frontend/widgets/navigations/navigation_items.dart';

import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/search/search_page.dart';
import 'package:motoapp_frontend/views/map/map_page.dart';
import 'package:motoapp_frontend/views/messages/messages_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ServiceLocator.init();
    await ServiceLocator.auth.initializeAuthState();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<AuthService>.value(
              value: ServiceLocator
                  .auth), // <-- Burada AuthService provider eklendi
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

    final List<Widget> pages = [
      const HomePage(),
      const SearchPage(),
      const MapPage(),
      const MessagesPage(),
      const ProfilePage(),
    ];

    debugPrint("Uygulama başlatılıyor. Tanımlanan sayfalar:");
    for (int i = 0; i < pages.length; i++) {
      debugPrint("Index $i: ${pages[i].runtimeType}");
    }

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

                final homeScreen = isAuthenticated
                    ? MainWrapper(
                        pages: pages,
                        navItems: NavigationItems.items,
                      )
                    : LoginPage(authService: authService);

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
                  home: homeScreen,
                  navigatorKey: ServiceLocator.navigatorKey,
                  scaffoldMessengerKey: ServiceLocator.scaffoldMessengerKey,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(1.0)), // düzeltildi
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
}
