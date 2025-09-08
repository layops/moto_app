import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';

class SocialButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Google ve Apple için özel renkler
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    Color borderColor;
    
    if (text.toLowerCase() == 'google') {
      backgroundColor = Colors.white;
      textColor = Colors.black87;
      iconColor = const Color(0xFF4285F4); // Google mavi
      borderColor = Colors.grey.shade300;
    } else if (text.toLowerCase() == 'apple') {
      backgroundColor = Colors.black;
      textColor = Colors.white;
      iconColor = Colors.white;
      borderColor = Colors.grey.shade800;
    } else {
      backgroundColor = colors.surface;
      textColor = colors.onSurface;
      iconColor = colors.onSurface;
      borderColor = colors.outline;
    }

    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon, 
                  color: iconColor, 
                  size: 22.h,
                ),
                SizedBox(width: 12.w),
                Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
