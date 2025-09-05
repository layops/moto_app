import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

/// Navigasyon UI widget'ı
class NavigationUIWidget extends StatelessWidget {
  final double progress;
  final double remainingDistance;
  final double remainingTime;
  final VoidCallback onStopNavigation;

  const NavigationUIWidget({
    super.key,
    required this.progress,
    required this.remainingDistance,
    required this.remainingTime,
    required this.onStopNavigation,
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
        padding: const EdgeInsets.all(16),
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
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navigasyon Aktif',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Kalan: ${(remainingDistance / 1000).toStringAsFixed(1)} km, ${(remainingTime / 60).round()} dk',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onStopNavigation,
                  icon: Icon(Icons.stop, color: colorScheme.error),
                  tooltip: 'Navigasyonu durdur',
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.onSurface.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'İlerleme: ${(progress * 100).toStringAsFixed(0)}%',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
