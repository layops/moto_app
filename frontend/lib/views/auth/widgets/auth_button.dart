import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 48.h),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          ),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 22.h,
                width: 22.h,
                child: CircularProgressIndicator(
                  color: colors.onPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
