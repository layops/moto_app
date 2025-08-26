import 'package:flutter/material.dart';

class AppColorSchemes {
  // Ana renk: Enerjik turuncu motosiklet teması için
  static const primaryColor = Color(0xFFFF8C00);
  // İkincil renk: Koyu mavi güven ve profesyonellik için
  static const secondaryColor = Color(0xFF1A4B8C);
  // Nötr renkler
  static const lightBackground = Color(0xFFF8F9FA);
  static const surfaceColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF333333);
  static const textSecondary = Color(0xFF666666);
  static const borderColor = Color(0xFFE0E0E0);
  static const linkColor = Color(0xFF007BFF);

  static ColorScheme get light => ColorScheme.light(
        primary: primaryColor,
        primaryContainer: Color(0xFFFF6A00),
        secondary: secondaryColor,
        surface: surfaceColor,
        error: Color(0xFFB00020),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        brightness: Brightness.light,
      );

  static ColorScheme get dark => ColorScheme.dark(
        primary: primaryColor,
        primaryContainer: Color(0xFFFF6A00),
        secondary: secondaryColor,
        surface: Color(0xFF121212),
        error: Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.black,
        brightness: Brightness.dark,
      );
}
