import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

/// Zoom seviyeleri widget'ı
class ZoomLevelsWidget extends StatelessWidget {
  final List<double> zoomLevels;
  final List<String> zoomLabels;
  final double currentZoomLevel;
  final Function(double) onZoomLevelSelected;

  const ZoomLevelsWidget({
    super.key,
    required this.zoomLevels,
    required this.zoomLabels,
    required this.currentZoomLevel,
    required this.onZoomLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Positioned(
      bottom: 160 + safeAreaBottom,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: zoomLevels.asMap().entries.map((entry) {
            final index = entry.key;
            final level = entry.value;
            final isSelected = (currentZoomLevel - level).abs() < 0.5;

            return InkWell(
              onTap: () => onZoomLevelSelected(level),
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      zoomLabels[index],
                      style: textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.7),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
