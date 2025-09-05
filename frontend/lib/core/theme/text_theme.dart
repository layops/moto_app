import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';

class AppTextTheme {
  static final TextTheme light = TextTheme(
        displayLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColorSchemes.textPrimary,
        ),
        displayMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColorSchemes.textPrimary,
        ),
        headlineLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColorSchemes.textPrimary,
        ),
        headlineMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColorSchemes.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: AppColorSchemes.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: AppColorSchemes.textSecondary,
        ),
        labelLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          color: AppColorSchemes.linkColor,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );

  static final TextTheme dark = TextTheme(
        displayLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
        labelLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          color: AppColorSchemes.linkColor,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
}
