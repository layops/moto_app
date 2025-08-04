import 'package:flutter/material.dart';

class AppColorSchemes {
  static const primaryColor = Color(0xFFd32f2f);
  static const secondaryColor = Color(0xFF757575);

  static ColorScheme get light => ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        background: Color(0xFFf5f5f5),
        error: Color(0xFFb00020),
      );

  static ColorScheme get dark => ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFF121212),
        background: Color(0xFF1E1E1E),
        error: Color(0xFFcf6679),
      );
}
