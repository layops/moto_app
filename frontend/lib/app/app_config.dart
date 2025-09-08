import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/app/navigator_service.dart';
import 'package:motoapp_frontend/core/theme/app_theme.dart';
import 'package:motoapp_frontend/core/providers/theme_provider.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/views/groups/group_page.dart';
import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/map/map_page.dart';
import 'package:motoapp_frontend/views/event/events_page.dart';
import 'package:motoapp_frontend/views/messages/messages_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';
import 'package:motoapp_frontend/views/settings/settings_page.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper.dart';
import 'package:motoapp_frontend/widgets/navigations/navigation_items.dart';
// ozan
class AppConfig extends StatelessWidget {
  const AppConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeProvider()),
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
                  '/login': (context) =>
                      LoginPage(authService: ServiceLocator.auth),
                  '/home': (context) => MainWrapper(
                        pages: [
                          const HomePage(),           // Index 0 - Home
                          const MapPage(allowSelection: true), // Index 1 - Map
                          const GroupsPage(),         // Index 2 - Groups  
                          const EventsPage(),         // Index 3 - Events
                          const MessagesPage(),       // Index 4 - Messages
                          FutureBuilder<String?>(
                            future: ServiceLocator.token.getUsernameFromToken(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final username = snapshot.data ?? 'Kullanıcı';
                              return ProfilePage(username: username); // Index 5 - Profile
                            },
                          ),
                        ],
                        navItems: NavigationItems.items,
                      ),
                },
                navigatorKey: NavigatorService.navigatorKey,
                scaffoldMessengerKey: ServiceLocator.scaffoldMessengerKey,
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
