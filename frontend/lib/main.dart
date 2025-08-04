import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/core/providers/theme_provider.dart';
import 'package:motoapp_frontend/core/theme/app_theme.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';

void main() async {
  // Flutter engine hazır olana kadar bekler
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Servis locator'ı başlat
    await ServiceLocator.init();

    // Uygulamayı başlat
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MotoApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Hata durumunda fallback UI göster
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Uygulama başlatılamadı',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hata: $e',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Hata detaylarını logla
    debugPrint('Uygulama başlatma hatası: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

class MotoApp extends StatelessWidget {
  const MotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Tasarım ölçüleri
      minTextAdapt: true, // Metinlerin responsive olması
      splitScreenMode: true, // Tablet/desktop uyumluluğu
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'MotoApp',
              debugShowCheckedModeBanner: false,

              // Tema Ayarları
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeProvider.themeMode,

              // Localization Ayarları
              locale: const Locale('tr', 'TR'),
              supportedLocales: const [
                Locale('tr', 'TR'), // Türkçe
                Locale('en', 'US'), // İngilizce (fallback)
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],

              // Navigasyon Ayarları
              home: const LoginPage(),
              navigatorKey: ServiceLocator.navigatorKey,
              scaffoldMessengerKey: ServiceLocator.scaffoldMessengerKey,

              // Performans Ayarları
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  child: child!,
                );
              },

              // Diğer Global Ayarlar
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                physics: const BouncingScrollPhysics(),
              ),
            );
          },
        );
      },
    );
  }
}
