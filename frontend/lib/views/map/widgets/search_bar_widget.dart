import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

/// Arama çubuğu widget'ı
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;
  final bool isSearchFocused;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.isSearchFocused,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    return Positioned(
      top: 16 + safeAreaTop,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusXLarge),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: "Konum ara... (örn: İstanbul, Kadıköy)",
            border: InputBorder.none,
            hintStyle: textTheme.bodyMedium,
            prefixIcon: Icon(Icons.search, color: textTheme.bodyMedium?.color),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: textTheme.bodyMedium?.color),
                    onPressed: onClear,
                  )
                : null,
          ),
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted(),
        ),
      ),
    );
  }
}
