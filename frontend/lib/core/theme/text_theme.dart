import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextTheme {
  static TextTheme get light => TextTheme(
        headlineLarge: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 16.sp),
      );

  static TextTheme get dark => TextTheme(
        headlineLarge: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 16.sp),
      );
}
