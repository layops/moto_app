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
    final safeAreaTop = mediaQuery.padding.top;

    return Positioned(
      top: 16 + safeAreaTop,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
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
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(ThemeConstants.borderRadiusLarge),
                  topRight: Radius.circular(ThemeConstants.borderRadiusLarge),
                ),
              ),
              child: Text(
                'Zoom',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Zoom Levels
            ...zoomLevels.asMap().entries.map((entry) {
              final index = entry.key;
              final zoomLevel = entry.value;
              final isSelected = (currentZoomLevel - zoomLevel).abs() < 0.5;
              
              return _buildZoomLevelItem(
                context,
                zoomLevel,
                zoomLabels[index],
                isSelected,
                index == zoomLevels.length - 1,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomLevelItem(
    BuildContext context,
    double zoomLevel,
    String label,
    bool isSelected,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: () => onZoomLevelSelected(zoomLevel),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.only(
            bottomLeft: isLast ? const Radius.circular(ThemeConstants.borderRadiusLarge) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(ThemeConstants.borderRadiusLarge) : Radius.zero,
          ),
        ),
        child: Column(
          children: [
            Text(
              zoomLevel.toStringAsFixed(0),
              style: textTheme.bodySmall?.copyWith(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}