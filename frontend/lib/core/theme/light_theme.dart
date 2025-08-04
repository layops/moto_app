import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'text_theme.dart';
import 'button_themes.dart';
import 'input_themes.dart';

class LightTheme {
  static ThemeData get theme => ThemeData(
        colorScheme: AppColorSchemes.light,
        textTheme: AppTextTheme.light,
        buttonTheme: AppButtonThemes.light,
        inputDecorationTheme: AppInputThemes.light,
        useMaterial3: true,
      );
}
