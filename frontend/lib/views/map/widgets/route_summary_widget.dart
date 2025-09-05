import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

/// Rota özet widget'ı
class RouteSummaryWidget extends StatelessWidget {
  final double distance;
  final int duration;
  final bool isNavigating;
  final VoidCallback onStartNavigation;
  final VoidCallback onClearRoute;

  const RouteSummaryWidget({
    super.key,
    required this.distance,
    required this.duration,
    required this.isNavigating,
    required this.onStartNavigation,
    required this.onClearRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    final distanceKm = (distance / 1000).toStringAsFixed(1);
    final durationMin = (duration / 60).round();

    return Positioned(
      bottom: 16 + safeAreaBottom,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.route,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rota Bilgileri',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm} km',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${durationMin} dk',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isNavigating) ...[
              ElevatedButton.icon(
                onPressed: onStartNavigation,
                icon: Icon(Icons.play_arrow, size: 18),
                label: Text('Başla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: onClearRoute,
              icon: Icon(Icons.close, color: colorScheme.onSurface.withOpacity(0.7)),
              tooltip: 'Rota temizle',
            ),
          ],
        ),
      ),
    );
  }
}
