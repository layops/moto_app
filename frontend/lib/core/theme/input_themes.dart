import 'package:flutter/material.dart';
import 'theme_constants.dart';
import 'color_schemes.dart';

class AppInputThemes {
  static InputDecorationTheme get light => InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: BorderSide(color: AppColorSchemes.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: BorderSide(color: AppColorSchemes.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: BorderSide(color: AppColorSchemes.primaryColor),
        ),
        contentPadding: ThemeConstants.paddingMedium,
        fillColor: AppColorSchemes.surfaceColor,
        filled: true,
        labelStyle: TextStyle(
          color: AppColorSchemes.textSecondary,
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          color: AppColorSchemes.textSecondary,
          fontSize: 16,
        ),
      );

  static InputDecorationTheme get dark => InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: BorderSide(color: AppColorSchemes.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: BorderSide(color: AppColorSchemes.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: BorderSide(color: AppColorSchemes.primaryColor),
        ),
        contentPadding: ThemeConstants.paddingMedium,
        fillColor: Color(0xFF1E1E1E),
        filled: true,
        labelStyle: TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      );
}
