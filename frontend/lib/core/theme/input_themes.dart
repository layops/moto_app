import 'package:flutter/material.dart';
import 'theme_constants.dart';

class AppInputThemes {
  static InputDecorationTheme get light => InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        ),
        contentPadding: ThemeConstants.paddingMedium,
      );

  static InputDecorationTheme get dark => InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        ),
        contentPadding: ThemeConstants.paddingMedium,
      );
}
