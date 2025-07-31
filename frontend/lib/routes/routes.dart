import 'package:flutter/material.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/views/settings/settings_page.dart';
import 'package:motoapp_frontend/views/home/dashboard_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
        '/': (context) => const LoginPage(),
        '/settings': (context) => const SettingsPage(),
        '/dashboard': (context) => const DashboardPage(),
      };
}
