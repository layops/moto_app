import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'motorcycle_map_theme.dart';

class MotorcycleMapControls extends StatelessWidget {
  final MapController mapController;
  final LatLng? currentPosition;
  final VoidCallback? onLocationPressed;
  final VoidCallback? onZoomInPressed;
  final VoidCallback? onZoomOutPressed;
  final VoidCallback? onSatelliteTogglePressed;
  final bool isSatelliteView;
  final bool showSatelliteToggle;

  const MotorcycleMapControls({
    super.key,
    required this.mapController,
    this.currentPosition,
    this.onLocationPressed,
    this.onZoomInPressed,
    this.onZoomOutPressed,
    this.onSatelliteTogglePressed,
    this.isSatelliteView = false,
    this.showSatelliteToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Konum butonu
          if (currentPosition != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: MotorcycleMapTheme.buildMapControlButton(
                icon: Icons.my_location,
                onPressed: onLocationPressed ?? () {
                  mapController.move(currentPosition!, 15);
                },
                backgroundColor: MotorcycleMapTheme.primaryRed,
              ),
            ),
          
          // Zoom in butonu
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: MotorcycleMapTheme.buildMapControlButton(
              icon: Icons.add,
              onPressed: onZoomInPressed ?? () {
                final currentZoom = mapController.camera.zoom;
                if (currentZoom < 20) {
                  mapController.move(mapController.camera.center, currentZoom + 1);
                }
              },
              backgroundColor: MotorcycleMapTheme.primaryBlue,
            ),
          ),
          
          // Zoom out butonu
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: MotorcycleMapTheme.buildMapControlButton(
              icon: Icons.remove,
              onPressed: onZoomOutPressed ?? () {
                final currentZoom = mapController.camera.zoom;
                if (currentZoom > 1) {
                  mapController.move(mapController.camera.center, currentZoom - 1);
                }
              },
              backgroundColor: MotorcycleMapTheme.primaryBlue,
            ),
          ),
          
          // Uydu görünümü toggle butonu
          if (showSatelliteToggle)
            MotorcycleMapTheme.buildMapControlButton(
              icon: isSatelliteView ? Icons.map : Icons.satellite,
              onPressed: onSatelliteTogglePressed ?? () {
                // Bu fonksiyon parent widget'ta implement edilmeli
              },
              backgroundColor: isSatelliteView 
                  ? MotorcycleMapTheme.primaryGreen 
                  : Colors.grey[600]!,
            ),
        ],
      ),
    );
  }
}

class MotorcycleMapZoomLevels extends StatelessWidget {
  final MapController mapController;
  final List<double> zoomLevels;
  final List<String> zoomLabels;

  const MotorcycleMapZoomLevels({
    super.key,
    required this.mapController,
    this.zoomLevels = const [5.0, 10.0, 13.0, 15.0, 18.0],
    this.zoomLabels = const ['Ülke', 'Bölge', 'Şehir', 'Mahalle', 'Sokak'],
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: zoomLevels.asMap().entries.map((entry) {
            final index = entry.key;
            final zoom = entry.value;
            final label = index < zoomLabels.length ? zoomLabels[index] : '';
            
            return GestureDetector(
              onTap: () {
                mapController.move(mapController.camera.center, zoom);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: MotorcycleMapTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: MotorcycleMapTheme.primaryRed,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class MotorcycleMapSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onClearPressed;
  final bool isSearching;
  final List<String>? searchHistory;

  const MotorcycleMapSearchBar({
    super.key,
    required this.controller,
    this.onSearchPressed,
    this.onClearPressed,
    this.isSearching = false,
    this.searchHistory,
  });

  @override
  State<MotorcycleMapSearchBar> createState() => _MotorcycleMapSearchBarState();
}

class _MotorcycleMapSearchBarState extends State<MotorcycleMapSearchBar> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          onTap: () {
            setState(() {
              _isFocused = true;
            });
          },
          decoration: MotorcycleMapTheme.getSearchInputDecoration(
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onClearPressed?.call();
                      setState(() {});
                    },
                  )
                : IconButton(
                    icon: Icon(
                      widget.isSearching ? Icons.search_off : Icons.search,
                      color: MotorcycleMapTheme.primaryRed,
                    ),
                    onPressed: widget.onSearchPressed,
                  ),
          ),
          onChanged: (value) {
            setState(() {});
          },
          onSubmitted: (value) {
            setState(() {
              _isFocused = false;
            });
            widget.onSearchPressed?.call();
          },
        ),
      ),
    );
  }
}
