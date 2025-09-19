import 'package:flutter/material.dart';

class AppColorSchemes {
  // Modern motosiklet teması - Parlak kırmızı renk paleti
  static const Color primaryColor = Color(0xFFFF0000); // Parlak kırmızı
  static const Color primaryLight = Color(0xFFFF4444); // Açık kırmızı
  static const Color primaryDark = Color(0xFFCC0000); // Koyu kırmızı
  
  // İkincil renkler - Gradient için
  static const Color secondaryColor = Color(0xFF1565C0); // Koyu mavi
  static const Color secondaryLight = Color(0xFF42A5F5); // Açık mavi
  static const Color accentColor = Color(0xFF00BCD4); // Cyan accent
  
  // Nötr renkler - Daha modern
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Metin renkleri
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  
  // Border ve divider
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFEEEEEE);
  
  // Link ve etkileşim
  static const Color linkColor = Color(0xFF1976D2);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  
  // Gradient renkleri
  static const List<Color> primaryGradient = [
    Color(0xFFFF0000),
    Color(0xFFFF4444),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
  ];

  static final ColorScheme light = ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: secondaryColor,
        secondaryContainer: secondaryLight,
        tertiary: warningColor,
        surface: surfaceColor,
        surfaceVariant: surfaceVariant,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        onError: Colors.white,
        brightness: Brightness.light,
        outline: borderColor,
        outlineVariant: dividerColor,
      );

  static final ColorScheme dark = ColorScheme.dark(
        primary: primaryLight,
        primaryContainer: primaryColor,
        secondary: secondaryLight,
        secondaryContainer: secondaryColor,
        tertiary: warningColor,
        surface: const Color(0xFF121212),
        surfaceVariant: const Color(0xFF1E1E1E),
        error: const Color(0xFFCF6679),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onTertiary: Colors.black,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        onError: Colors.black,
        brightness: Brightness.dark,
        outline: const Color(0xFF424242),
        outlineVariant: const Color(0xFF2C2C2C),
      );
}
