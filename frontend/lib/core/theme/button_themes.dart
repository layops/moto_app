import 'package:flutter/material.dart';
import 'theme_constants.dart';
import 'color_schemes.dart';

class AppButtonThemes {
  static ButtonThemeData get light => ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        ),
        padding: ThemeConstants.paddingMedium,
        buttonColor: AppColorSchemes.light.primary,
        textTheme: ButtonTextTheme.primary,
      );

  static ButtonThemeData get dark => ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        ),
        padding: ThemeConstants.paddingMedium,
        buttonColor: AppColorSchemes.dark.primary,
        textTheme: ButtonTextTheme.primary,
      );

  // ElevatedButton teması
  static ElevatedButtonThemeData get elevatedLight => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorSchemes.light.primary,
          foregroundColor: AppColorSchemes.light.onPrimary,
          padding: ThemeConstants.paddingMedium,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          ),
        ),
      );

  static ElevatedButtonThemeData get elevatedDark => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorSchemes.dark.primary,
          foregroundColor: AppColorSchemes.dark.onPrimary,
          padding: ThemeConstants.paddingMedium,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          ),
        ),
      );

  // OutlinedButton teması (Sosyal medya butonları için)
  static OutlinedButtonThemeData get outlinedLight => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColorSchemes.light.onSurface,
          padding: ThemeConstants.paddingMedium,
          side: BorderSide(color: AppColorSchemes.light.outline),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          ),
        ),
      );

  static OutlinedButtonThemeData get outlinedDark => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColorSchemes.dark.onSurface,
          padding: ThemeConstants.paddingMedium,
          side: BorderSide(color: AppColorSchemes.dark.outline),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          ),
        ),
      );
}
