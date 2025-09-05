import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

/// Map kontrol butonları widget'ı
class MapControlsWidget extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleMapType;
  final VoidCallback onToggleRouteMode;
  final VoidCallback onGoToCurrentLocation;
  final bool isSatelliteView;
  final bool isRouteMode;

  const MapControlsWidget({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleMapType,
    required this.onToggleRouteMode,
    required this.onGoToCurrentLocation,
    required this.isSatelliteView,
    required this.isRouteMode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Positioned(
      bottom: 200 + safeAreaBottom,
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
            _buildControlButton(
              context: context,
              icon: Icons.add,
              onPressed: onZoomIn,
              heroTag: 'map_zoom_in_fab',
            ),
            const SizedBox(height: 4),
            _buildControlButton(
              context: context,
              icon: Icons.remove,
              onPressed: onZoomOut,
              heroTag: 'map_zoom_out_fab',
            ),
            const SizedBox(height: 4),
            _buildControlButton(
              context: context,
              icon: isSatelliteView ? Icons.map_outlined : Icons.satellite_outlined,
              onPressed: onToggleMapType,
              heroTag: 'map_toggle_type_fab',
            ),
            const SizedBox(height: 4),
            _buildControlButton(
              context: context,
              icon: Icons.route,
              onPressed: onToggleRouteMode,
              heroTag: 'map_route_fab',
              backgroundColor: isRouteMode ? colorScheme.error : colorScheme.primary,
            ),
            const SizedBox(height: 4),
            _buildControlButton(
              context: context,
              icon: Icons.my_location,
              onPressed: onGoToCurrentLocation,
              heroTag: 'map_my_location_fab',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required String heroTag,
    Color? backgroundColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? colorScheme.primary,
      mini: true,
      child: Icon(icon, color: colorScheme.onPrimary),
    );
  }
}
