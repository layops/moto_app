import 'package:flutter/material.dart';

class AppColorSchemes {
  // Ana renk: Enerjik turuncu motosiklet teması için
  static const Color primaryColor = Color(0xFFFF8C00);
  // İkincil renk: Koyu mavi güven ve profesyonellik için
  static const Color secondaryColor = Color(0xFF1A4B8C);
  // Nötr renkler
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color linkColor = Color(0xFF007BFF);

  static final ColorScheme light = ColorScheme.light(
        primary: primaryColor,
        primaryContainer: const Color(0xFFFF6A00),
        secondary: secondaryColor,
        surface: surfaceColor,
        error: const Color(0xFFB00020),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        brightness: Brightness.light,
      );

  static final ColorScheme dark = ColorScheme.dark(
        primary: primaryColor,
        primaryContainer: const Color(0xFFFF6A00),
        secondary: secondaryColor,
        surface: const Color(0xFF121212),
        error: const Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.black,
        brightness: Brightness.dark,
      );
}
