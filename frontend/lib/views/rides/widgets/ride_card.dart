import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import '../../../services/rides/rides_service.dart';

/// Ride kartı widget'ı
class RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;

  const RideCard({
    super.key,
    required this.ride,
    required this.onTap,
    required this.onJoin,
    required this.onLeave,
    required this.onToggleFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.title,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${ride.owner}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Favorite Button
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? colorScheme.error : colorScheme.onSurfaceVariant,
                    ),
                    tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Route Info
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.startLocation,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ride.endLocation,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stats
              Row(
                children: [
                  if (ride.distanceKm != null) ...[
                    _buildStatChip(
                      context,
                      Icons.straighten,
                      '${ride.distanceKm!.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (ride.estimatedDurationMinutes != null) ...[
                    _buildStatChip(
                      context,
                      Icons.access_time,
                      '${ride.estimatedDurationMinutes} dk',
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildStatChip(
                    context,
                    Icons.people,
                    '${ride.participants.length}${ride.maxParticipants != null ? '/${ride.maxParticipants}' : ''}',
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Footer
              Row(
                children: [
                  // Ride Type & Privacy
                  Expanded(
                    child: Row(
                      children: [
                        _buildTypeChip(context, ride.rideType),
                        const SizedBox(width: 8),
                        _buildPrivacyChip(context, ride.privacyLevel),
                      ],
                    ),
                  ),
                  
                  // Action Button
                  ElevatedButton(
                    onPressed: ride.participants.contains(ride.owner) ? onLeave : onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ride.participants.contains(ride.owner) 
                          ? colorScheme.error 
                          : colorScheme.primary,
                      foregroundColor: ride.participants.contains(ride.owner) 
                          ? colorScheme.onError 
                          : colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      ride.participants.contains(ride.owner) ? 'Ayrıl' : 'Katıl',
                      style: textTheme.labelMedium?.copyWith(
                        color: ride.participants.contains(ride.owner) 
                            ? colorScheme.onError 
                            : colorScheme.onPrimary,
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

  Widget _buildStatChip(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: colorScheme.onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, String type) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final typeLabels = {
      'casual': 'Günlük',
      'touring': 'Tur',
      'group': 'Grup',
      'track': 'Pist',
      'adventure': 'Macera',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        typeLabels[type] ?? type,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPrivacyChip(BuildContext context, String privacy) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final privacyLabels = {
      'public': 'Açık',
      'friends': 'Arkadaşlar',
      'private': 'Özel',
    };

    final privacyColors = {
      'public': colorScheme.primaryContainer,
      'friends': colorScheme.secondaryContainer,
      'private': colorScheme.errorContainer,
    };

    final privacyTextColors = {
      'public': colorScheme.onPrimaryContainer,
      'friends': colorScheme.onSecondaryContainer,
      'private': colorScheme.onErrorContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: privacyColors[privacy],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        privacyLabels[privacy] ?? privacy,
        style: textTheme.bodySmall?.copyWith(
          color: privacyTextColors[privacy],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
