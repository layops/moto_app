import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThemeConstants {
  // Temel Ölçüler (Border Radius)
  static final borderRadiusSmall = 4.r;
  static final borderRadiusMedium = 8.r;
  static final borderRadiusLarge = 12.r;

  // Paddingler
  static final paddingSmall = EdgeInsets.all(8.r);
  static final paddingMedium = EdgeInsets.all(16.r);
  static final paddingLarge = EdgeInsets.all(24.r); // yeni eklendi

  // Animasyonlar
  static const durationShort = Duration(milliseconds: 200);
  static const durationMedium = Duration(milliseconds: 400);
  static const durationLong = Duration(milliseconds: 600);
}
