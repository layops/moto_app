import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../controllers/map_controller.dart' as custom;
import '../widgets/map_controls_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_results_widget.dart';
import '../widgets/search_history_widget.dart';
import '../widgets/zoom_levels_widget.dart';
import '../widgets/route_summary_widget.dart';
import '../widgets/navigation_ui_widget.dart';
import '../models/map_state.dart';

class MapPageNew extends StatefulWidget {
  final LatLng? initialCenter;
  final bool allowSelection;
  final bool showMarker;

  const MapPageNew({
    super.key,
    this.initialCenter,
    this.allowSelection = false,
    this.showMarker = false,
  });

  @override
  State<MapPageNew> createState() => _MapPageNewState();
}

class _MapPageNewState extends State<MapPageNew> {
  late custom.MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = custom.MapController();
    
    if (widget.initialCenter != null) {
      if (widget.allowSelection || widget.showMarker) {
        _mapController.updateMapState(
          _mapController.mapState.copyWith(selectedPosition: widget.initialCenter),
        );
      }
      _mapController.updateMapState(
        _mapController.mapState.copyWith(isLoading: false),
      );
    } else {
      _mapController.getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _mapController,
      child: Consumer<custom.MapController>(
        builder: (context, controller, child) {
          final mapState = controller.mapState;
          final routeState = controller.routeState;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          const String defaultMapUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
          const String satelliteUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: SizedBox.expand(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: controller.mapController,
                    options: MapOptions(
                      initialCenter: widget.initialCenter ??
                          (mapState.currentPosition ?? const LatLng(41.0082, 28.9784)),
                      initialZoom: mapState.zoomLevel,
                      onTap: (tapPosition, point) {
                        if (routeState.isRouteMode || widget.allowSelection) {
                          controller.onMapTap(point);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: mapState.isSatelliteView ? satelliteUrl : defaultMapUrl,
                        userAgentPackageName: 'com.example.frontend',
                        maxZoom: 20,
                      ),
                      if (mapState.currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: mapState.currentPosition!,
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.my_location,
                                color: colorScheme.primary,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      if (mapState.selectedPosition != null && widget.showMarker)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: mapState.selectedPosition!,
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.location_pin,
                                color: colorScheme.error,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      if (routeState.routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routeState.routePoints,
                              color: colorScheme.primary,
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                      if (routeState.isRouteMode && routeState.startPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: routeState.startPoint!,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.onPrimary,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: colorScheme.onPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (routeState.isRouteMode && routeState.endPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: routeState.endPoint!,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.onError,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.flag,
                                  color: colorScheme.onError,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  // UI Widgets
                  SearchBarWidget(
                    controller: controller.searchController,
                    onChanged: controller.onSearchTextChanged,
                    onSubmitted: controller.onSearchSubmitted,
                    onClear: controller.clearSearch,
                    isSearchFocused: mapState.isSearchFocused,
                  ),
                  
                  MapControlsWidget(
                    onZoomIn: controller.zoomIn,
                    onZoomOut: controller.zoomOut,
                    onToggleMapType: controller.toggleMapType,
                    onToggleRouteMode: controller.toggleRouteMode,
                    onGoToCurrentLocation: controller.getCurrentLocation,
                    isSatelliteView: mapState.isSatelliteView,
                    isRouteMode: routeState.isRouteMode,
                  ),
                  
                  if (mapState.selectedPosition != null)
                    _buildLocationActions(context, controller),
                  
                  if (mapState.selectedPosition != null)
                    _buildConfirmButton(context, controller),
                  
                  SearchHistoryWidget(
                    searchHistory: mapState.searchHistory,
                    onHistoryItemSelected: controller.onSearchHistorySelected,
                  ),
                  
                  // SearchResultsWidget will be implemented when search results are available
                  
                  ZoomLevelsWidget(
                    zoomLevels: custom.MapController.zoomLevels,
                    zoomLabels: custom.MapController.zoomLabels,
                    currentZoomLevel: mapState.zoomLevel,
                    onZoomLevelSelected: controller.setZoomLevel,
                  ),
                  
                  if (routeState.routePoints.isNotEmpty && 
                      routeState.routeDistance != null && 
                      routeState.routeDuration != null)
                    RouteSummaryWidget(
                      distance: routeState.routeDistance!,
                      duration: routeState.routeDuration!,
                      isNavigating: routeState.isNavigating,
                      onStartNavigation: controller.startNavigation,
                      onClearRoute: controller.clearRoute,
                    ),
                  
                  if (routeState.isNavigating && routeState.routePoints.isNotEmpty)
                    NavigationUIWidget(
                      progress: routeState.currentRouteIndex / routeState.routePoints.length,
                      remainingDistance: _calculateRemainingDistance(routeState),
                      remainingTime: _calculateRemainingTime(routeState),
                      onStopNavigation: controller.stopNavigation,
                    ),
                  
                  if (mapState.isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationActions(BuildContext context, custom.MapController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Positioned(
      bottom: 80 + safeAreaBottom,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'share_location_fab',
              onPressed: () => _shareLocation(controller),
              backgroundColor: colorScheme.secondary,
              mini: true,
              child: Icon(Icons.share, color: colorScheme.onSecondary),
            ),
            const SizedBox(width: 4),
            FloatingActionButton(
              heroTag: 'label_location_fab',
              onPressed: () => _showLabelDialog(context, controller),
              backgroundColor: colorScheme.secondary,
              mini: true,
              child: Icon(Icons.label, color: colorScheme.onSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, custom.MapController controller) {
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.check),
          label: Text(
            controller.mapState.selectedLocationLabel != null
                ? "Seç: ${controller.mapState.selectedLocationLabel}"
                : "Bu Konumu Seç",
            style: textTheme.labelLarge,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(controller.mapState.selectedPosition);
            }
          },
        ),
      ),
    );
  }

  void _shareLocation(custom.MapController controller) {
    if (controller.mapState.selectedPosition == null) return;

    final locationText = 'Konum: ${controller.mapState.selectedPosition!.latitude}, ${controller.mapState.selectedPosition!.longitude}';
    // Clipboard.setData(ClipboardData(text: locationText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Konum panoya kopyalandı'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showLabelDialog(BuildContext context, custom.MapController controller) {
    if (controller.mapState.selectedPosition == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: AlertDialog(
          title: Text('Konum Etiketi', style: textTheme.headlineMedium),
          content: TextField(
            controller: controller.labelController,
            decoration: InputDecoration(
              hintText: 'Bu konum için bir etiket girin',
              hintStyle: textTheme.bodyMedium,
            ),
            style: textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: textTheme.titleMedium),
            ),
            TextButton(
              onPressed: () {
                controller.updateMapState(
                  controller.mapState.copyWith(
                    selectedLocationLabel: controller.labelController.text.trim(),
                  ),
                );
                controller.labelController.clear();
                Navigator.pop(context);
              },
              child: Text('Kaydet', style: textTheme.titleMedium),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateRemainingDistance(RouteState routeState) {
    if (routeState.routePoints.isEmpty || routeState.currentRouteIndex >= routeState.routePoints.length - 1) {
      return 0;
    }

    double totalDistance = 0;
    for (int i = routeState.currentRouteIndex; i < routeState.routePoints.length - 1; i++) {
      // Distance calculation would be implemented here
      totalDistance += 100; // Placeholder
    }
    return totalDistance;
  }

  double _calculateRemainingTime(RouteState routeState) {
    final remainingDistance = _calculateRemainingDistance(routeState);
    if (remainingDistance == 0 || routeState.routeDistance == null || routeState.routeDuration == null) {
      return 0;
    }

    // Average speed calculation
    final avgSpeed = (routeState.routeDistance! / 1000) / (routeState.routeDuration! / 3600);
    return (remainingDistance / 1000) / avgSpeed * 3600;
  }
}
