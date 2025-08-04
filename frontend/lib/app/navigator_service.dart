import 'package:flutter/material.dart';

class NavigatorService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<T?> push<T>(Widget page) {
    return navigatorKey.currentState?.push<T>(
          MaterialPageRoute(builder: (_) => page),
        ) ??
        Future<T?>.value(null);
  }

  static void pop<T>([T? result]) {
    navigatorKey.currentState?.pop<T>(result);
  }

  static Future<void> pushReplacement(Widget page) {
    return navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => page),
        ) ??
        Future.value();
  }
}
