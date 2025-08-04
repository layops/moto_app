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
        inputDecorationTheme: AppInputThemes.dark,
        useMaterial3: true,
      );
}
