import 'package:flutter/material.dart';
import 'theme_constants.dart';
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
        scaffoldBackgroundColor: AppColorSchemes.dark.surface,
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
        iconTheme: IconThemeData(color: AppColorSchemes.dark.onSurface),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColorSchemes.primaryColor,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColorSchemes.dark.surface,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      );
}
