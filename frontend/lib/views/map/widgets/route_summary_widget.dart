import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

/// Rota özeti widget'ı
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

    return Positioned(
      bottom: 16 + safeAreaBottom,
      left: 16,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Route Info
              Row(
                children: [
                  Icon(
                    Icons.route,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rota Bilgileri',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInfoChip(
                              context,
                              Icons.straighten,
                              '${(distance / 1000).toStringAsFixed(1)} km',
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              context,
                              Icons.access_time,
                              '${(duration / 60).round()} dk',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Clear Button
                  IconButton(
                    onPressed: onClearRoute,
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.error,
                    ),
                    tooltip: 'Rotayı Temizle',
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isNavigating ? null : onStartNavigation,
                      icon: Icon(
                        isNavigating ? Icons.navigation : Icons.play_arrow,
                        color: colorScheme.onPrimary,
                      ),
                      label: Text(
                        isNavigating ? 'Navigasyon Aktif' : 'Navigasyonu Başlat',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isNavigating 
                            ? colorScheme.surfaceVariant 
                            : colorScheme.primary,
                        foregroundColor: isNavigating 
                            ? colorScheme.onSurfaceVariant 
                            : colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: colorScheme.onPrimaryContainer,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}