import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'text_theme.dart';
import 'button_themes.dart';
import 'input_themes.dart';

class LightTheme {
  static final ThemeData theme = ThemeData(
        colorScheme: AppColorSchemes.light,
        textTheme: AppTextTheme.light,
        buttonTheme: AppButtonThemes.light,
        elevatedButtonTheme: AppButtonThemes.elevatedLight,
        outlinedButtonTheme: AppButtonThemes.outlinedLight,
        inputDecorationTheme: AppInputThemes.light,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColorSchemes.lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColorSchemes.surfaceColor,
          foregroundColor: AppColorSchemes.textPrimary,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColorSchemes.surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
