part of map_page;

extension MapControls on _MapPageState {
  Widget _buildMapControls(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Positioned(
      bottom: 200 + safeAreaBottom, // Location actions ve confirm button için yer bırak
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
            FloatingActionButton(
              heroTag: 'map_zoom_in_fab',
              onPressed: _zoomIn,
              backgroundColor: colorScheme.primary,
              mini: true,
              child: Icon(Icons.add, color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 4),
            FloatingActionButton(
              heroTag: 'map_zoom_out_fab',
              onPressed: _zoomOut,
              backgroundColor: colorScheme.primary,
              mini: true,
              child: Icon(Icons.remove, color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 4),
            FloatingActionButton(
              heroTag: 'map_toggle_type_fab',
              onPressed: _toggleMapType,
              backgroundColor: colorScheme.primary,
              mini: true,
              child: Icon(
                _isSatelliteView ? Icons.map_outlined : Icons.satellite_outlined,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 4),
            FloatingActionButton(
              heroTag: 'map_route_fab',
              onPressed: _toggleRouteMode,
              backgroundColor:
                  _isRouteMode ? colorScheme.error : colorScheme.primary,
              mini: true,
              child: Icon(
                Icons.route,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 4),
            FloatingActionButton(
              heroTag: 'map_my_location_fab',
              onPressed: _goToCurrentLocation,
              backgroundColor: colorScheme.primary,
              mini: true,
              child: Icon(Icons.my_location, color: colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _isSatelliteView = !_isSatelliteView;
    });
  }
}
