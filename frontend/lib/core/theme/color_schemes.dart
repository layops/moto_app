// color_schemes.dart
import 'package:flutter/material.dart';

class AppColorSchemes {
  // Mevcut renkler
  static const primaryColor = Color(0xFFFF8C00);
  static const secondaryColor = Color(0xFF1A4B8C);
  static const lightBackground = Color(0xFFF8F9FA);
  static const surfaceColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF333333);
  static const textSecondary = Color(0xFF666666);
  static const borderColor = Color(0xFFE0E0E0);
  static const linkColor = Color(0xFF007BFF);

  // Light mod difficulty renkleri
  static const difficultyEasyLight = Color(0xFF4CAF50);
  static const difficultyModerateLight = Color(0xFFFFA500);
  static const difficultyExpertLight = Color(0xFFF44336);

  // Dark mod difficulty renkleri
  static const difficultyEasyDark = Color(0xFF81C784);
  static const difficultyModerateDark = Color(0xFFFFB74D);
  static const difficultyExpertDark = Color(0xFFE57373);

  // Light ColorScheme
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

  // Dark ColorScheme
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

  // Mod durumuna göre difficulty renkleri
  static Color difficultyEasy(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? difficultyEasyDark
          : difficultyEasyLight;

  static Color difficultyModerate(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? difficultyModerateDark
          : difficultyModerateLight;

  static Color difficultyExpert(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? difficultyExpertDark
          : difficultyExpertLight;
}
