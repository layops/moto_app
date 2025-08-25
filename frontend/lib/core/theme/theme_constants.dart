import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThemeConstants {
  // Border Radius
  static final borderRadiusSmall = 4.r;
  static final borderRadiusMedium = 8.r;
  static final borderRadiusLarge = 12.r;
  static final borderRadiusXLarge = 16.r;

  // Padding
  static final paddingSmall = EdgeInsets.all(8.r);
  static final paddingMedium = EdgeInsets.all(16.r);
  static final paddingLarge = EdgeInsets.all(24.r);

  // Horizontal Padding
  static final horizontalPaddingSmall = EdgeInsets.symmetric(horizontal: 8.r);
  static final horizontalPaddingMedium = EdgeInsets.symmetric(horizontal: 16.r);
  static final horizontalPaddingLarge = EdgeInsets.symmetric(horizontal: 24.r);

  // Vertical Padding
  static final verticalPaddingSmall = EdgeInsets.symmetric(vertical: 8.r);
  static final verticalPaddingMedium = EdgeInsets.symmetric(vertical: 16.r);
  static final verticalPaddingLarge = EdgeInsets.symmetric(vertical: 24.r);

  // Animasyon Süreleri
  static const durationShort = Duration(milliseconds: 200);
  static const durationMedium = Duration(milliseconds: 400);
  static const durationLong = Duration(milliseconds: 600);
}
