import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

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

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 48.h),
        // ignore: deprecated_member_use
        foregroundColor: colors.onSurface.withOpacity(0.7),
        // ignore: deprecated_member_use
        side: BorderSide(color: colors.onSurface.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        ),
        padding: EdgeInsets.symmetric(vertical: 14.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ignore: deprecated_member_use
          Icon(icon, color: colors.onSurface.withOpacity(0.7), size: 20.h),
          SizedBox(width: 8.w),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              // ignore: deprecated_member_use
              color: colors.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
