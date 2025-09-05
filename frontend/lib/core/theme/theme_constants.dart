import 'package:flutter/material.dart';

class ThemeConstants {
  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;

  // Padding
  static const EdgeInsets paddingSmall = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMedium = EdgeInsets.all(16.0);
  static const EdgeInsets paddingLarge = EdgeInsets.all(24.0);

  // Horizontal Padding
  static const EdgeInsets horizontalPaddingSmall = EdgeInsets.symmetric(horizontal: 8.0);
  static const EdgeInsets horizontalPaddingMedium = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets horizontalPaddingLarge = EdgeInsets.symmetric(horizontal: 24.0);

  // Vertical Padding
  static const EdgeInsets verticalPaddingSmall = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets verticalPaddingMedium = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets verticalPaddingLarge = EdgeInsets.symmetric(vertical: 24.0);

  // Animasyon Süreleri
  static const Duration durationShort = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 400);
  static const Duration durationLong = Duration(milliseconds: 600);
}
