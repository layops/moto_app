import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
      cursorColor: colors.primary,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: theme.textTheme.bodyMedium
            ?.copyWith(color: colors.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(prefixIcon, color: colors.onSurface.withOpacity(0.6)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          borderSide: BorderSide(color: colors.onSurface.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
