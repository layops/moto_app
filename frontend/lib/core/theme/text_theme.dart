import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';

class AppTextTheme {
  static TextTheme get light => TextTheme(
        displayLarge: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: AppColorSchemes.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w600,
          color: AppColorSchemes.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: AppColorSchemes.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w500,
          color: AppColorSchemes.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.sp,
          color: AppColorSchemes.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.sp,
          color: AppColorSchemes.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16.sp,
          color: AppColorSchemes.linkColor,
          fontWeight: FontWeight.w500,
        ),
      );

  static TextTheme get dark => TextTheme(
        displayLarge: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.sp,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.sp,
          color: Colors.white70,
        ),
        labelLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16.sp,
          color: AppColorSchemes.linkColor,
          fontWeight: FontWeight.w500,
        ),
      );
}
