import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'text_theme.dart';
import 'button_themes.dart';
import 'input_themes.dart';

class DarkTheme {
  static ThemeData get theme => ThemeData(
        colorScheme: AppColorSchemes.dark,
        textTheme: AppTextTheme.dark,
        buttonTheme: AppButtonThemes.dark,
        elevatedButtonTheme: AppButtonThemes.elevatedDark,
        outlinedButtonTheme: AppButtonThemes.outlinedDark,
        inputDecorationTheme: AppInputThemes.dark,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorSchemes.dark.surface,
          foregroundColor: AppColorSchemes.dark.onSurface,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColorSchemes.dark.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
