import 'package:flutter/material.dart';
import 'theme_constants.dart';

class AppButtonThemes {
  static ButtonThemeData get light => ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        ),
        padding: ThemeConstants.paddingMedium,
      );

  static ButtonThemeData get dark => ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        ),
        padding: ThemeConstants.paddingMedium,
      );
}
