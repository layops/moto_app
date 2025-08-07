import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
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
              home: const LoginPage(),
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
  }
}

// LoginPage'den başarılı giriş sonrası örnek kullanım:
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainWrapper(
                  pages: [
                    const HomePage(),
                    const SearchPage(),
                    const MapPage(),
                    const MessagesPage(),
                    const ProfilePage(),
                  ],
                  navItems: NavigationItems.items,
                ),
              ),
            );
          },
          child: const Text('Giriş Yap'),
        ),
      ),
    );
  }
}
