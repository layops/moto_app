import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/services/post/post_service.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/core/providers/theme_provider.dart';
import 'package:motoapp_frontend/core/theme/light_theme.dart';
import 'package:motoapp_frontend/core/theme/dark_theme.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper_new.dart';
import 'package:motoapp_frontend/widgets/navigations/navigation_items.dart';
import 'package:motoapp_frontend/config/supabase_config.dart';

import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/map/map_page.dart';
import 'package:motoapp_frontend/views/groups/group_page.dart';
import 'package:motoapp_frontend/views/event/events_page.dart';
import 'package:motoapp_frontend/views/messages/messages_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';
import 'package:motoapp_frontend/views/notifications/notifications_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Supabase'i initialize et
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    
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

class MotoApp extends StatefulWidget {
  const MotoApp({super.key});

  @override
  State<MotoApp> createState() => _MotoAppState();
}

class _MotoAppState extends State<MotoApp> {
  String? _currentUsername;
  final GlobalKey<MainWrapperNewState> _mainWrapperKey = GlobalKey<MainWrapperNewState>();

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
  }

  Future<void> _loadCurrentUsername() async {
    try {
      final usernameFromToken =
          await ServiceLocator.token.getUsernameFromToken();

      final username =
          usernameFromToken ?? await ServiceLocator.token.getCurrentUsername();

      if (mounted) {
        setState(() {
          _currentUsername = username;
        });
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = ServiceLocator.auth;

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return StreamBuilder<bool>(
              stream: authService.authStateChanges,
              builder: (context, snapshot) {
                final isAuthenticated = snapshot.data == true;

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
                      return ProfilePage(username: username);
                    },
                  },
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

  void _onUnreadCountChanged() {
    // Bu fonksiyon MessagesPage'den çağrılacak
    // MainWrapperNew'deki unread count'u direkt güncelle
    _mainWrapperKey.currentState?.refreshUnreadCount();
  }

  Widget _buildMainWrapper() {
    // ProfilePage için güvenli username kontrolü
    final profileUsername = _currentUsername ?? '';
    
    // Sayfaları navigation items ile aynı sırada tanımla
    final List<Widget> pages = [
      const HomePage(),           // Index 0 - Home
      const MapPage(allowSelection: true), // Index 1 - Map
      const GroupsPage(),         // Index 2 - Groups  
      const EventsPage(),         // Index 3 - Events
      MessagesPage(onUnreadCountChanged: _onUnreadCountChanged), // Index 4 - Messages
      ProfilePage(username: profileUsername), // Index 5 - Profile
    ];

    // Pages initialized

    return MainWrapperNew(
      key: _mainWrapperKey,
      pages: pages,
      navItems: NavigationItems.items,
      onUnreadCountChanged: _onUnreadCountChanged,
    );
  }
}
