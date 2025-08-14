import 'package:flutter/material.dart';
import 'package:motoapp_frontend/views/auth/widgets/auth_text_field.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final FormFieldValidator<String>? validator;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText = 'Şifre',
    this.validator,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AuthTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      prefixIcon: Icons.lock,
      obscureText: _obscureText,
      validator: widget.validator,
      keyboardType: TextInputType.visiblePassword,
      suffixIcon: IconButton(
        // Artık suffixIcon parametresi var
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: colors.primary,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
    );
  }
}
