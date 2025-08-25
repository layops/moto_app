import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AuthLogo({
    super.key,
    this.size = 200,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/spiride_logo_main_page.png',
      height: size.h,
      width: size.w,
      fit: BoxFit.contain,
    );
  }
}
