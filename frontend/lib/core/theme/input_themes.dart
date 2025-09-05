import 'package:flutter/material.dart';
import 'theme_constants.dart';
import 'color_schemes.dart';

class AppInputThemes {
  static final InputDecorationTheme light = InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColorSchemes.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColorSchemes.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColorSchemes.primaryColor),
        ),
        contentPadding: ThemeConstants.paddingMedium,
        fillColor: AppColorSchemes.surfaceColor,
        filled: true,
        labelStyle: const TextStyle(
          color: AppColorSchemes.textSecondary,
          fontSize: 16,
        ),
        hintStyle: const TextStyle(
          color: AppColorSchemes.textSecondary,
          fontSize: 16,
        ),
      );

  static final InputDecorationTheme dark = InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColorSchemes.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColorSchemes.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColorSchemes.primaryColor),
        ),
        contentPadding: ThemeConstants.paddingMedium,
        fillColor: const Color(0xFF1E1E1E),
        filled: true,
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
        hintStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      );
}
