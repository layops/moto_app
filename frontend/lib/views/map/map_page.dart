import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _currentPosition;
  bool _isLoading = true;
  double _zoomLevel = 13.0;
  bool _isSatelliteView = false;

  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });
  }

  void _zoomIn() {
    _zoomLevel += 1;
    _mapController.move(_mapController.camera.center, _zoomLevel);
    setState(() {});
  }

  void _zoomOut() {
    _zoomLevel -= 1;
    _mapController.move(_mapController.camera.center, _zoomLevel);
    setState(() {});
  }

  void _goToCurrentLocation() {
    if (_currentPosition != null) {
      _zoomLevel = 15.0;
      _mapController.move(_currentPosition!, _zoomLevel);
      setState(() {});
    }
  }

  Future<void> _searchLocation() async {
    final String searchText = _searchController.text.trim();
    if (searchText.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final String url =
          'https://nominatim.openstreetmap.org/search?q=$searchText&format=json&limit=5';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => _searchResults = data);
      } else {
        debugPrint("Search failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectSearchResult(dynamic result) {
    if (result != null) {
      final double lat = double.parse(result['lat']);
      final double lon = double.parse(result['lon']);

      _mapController.move(LatLng(lat, lon), 15.0);

      setState(() {
        _searchResults = [];
        _searchController.clear();
      });
    }
  }

  void _toggleMapType() {
    setState(() => _isSatelliteView = !_isSatelliteView);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // ✅ Tema bağımsız OSM harita URL'si
    const String mapUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    // Uydu görünümü
    const String satelliteUrl =
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(41.0082, 28.9784),
              initialZoom: _zoomLevel,
              onTap: (tapPosition, point) {
                debugPrint(
                    "Tıklanan konum: ${point.latitude}, ${point.longitude}");
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatelliteView ? satelliteUrl : mapUrl,
                userAgentPackageName: 'com.example.frontend',
                maxZoom: 20,
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_pin,
                        color: colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Mevcut konuma git
          Positioned(
            bottom: ThemeConstants.paddingMedium.bottom,
            right: ThemeConstants.paddingMedium.right,
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              backgroundColor: colorScheme.primary,
              mini: true,
              child: Icon(Icons.my_location, color: colorScheme.onPrimary),
            ),
          ),

          // Uydu görünümü butonu
          Positioned(
            bottom: ThemeConstants.paddingMedium.bottom + 60,
            right: ThemeConstants.paddingMedium.right,
            child: FloatingActionButton(
              onPressed: _toggleMapType,
              backgroundColor: colorScheme.primary,
              mini: true,
              child: Icon(
                _isSatelliteView
                    ? Icons.map_outlined
                    : Icons.satellite_outlined,
                color: colorScheme.onPrimary,
              ),
            ),
          ),

          // Zoom in/out
          Positioned(
            bottom: ThemeConstants.paddingMedium.bottom + 120,
            right: ThemeConstants.paddingMedium.right,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _zoomIn,
                  backgroundColor: colorScheme.primary,
                  mini: true,
                  child: Icon(Icons.add, color: colorScheme.onPrimary),
                ),
                SizedBox(height: ThemeConstants.paddingSmall.bottom),
                FloatingActionButton(
                  onPressed: _zoomOut,
                  backgroundColor: colorScheme.primary,
                  mini: true,
                  child: Icon(Icons.remove, color: colorScheme.onPrimary),
                ),
              ],
            ),
          ),

          // Arama kutusu
          Positioned(
            top: 40,
            left: ThemeConstants.paddingMedium.left,
            right: ThemeConstants.paddingMedium.right,
            child: Container(
              padding: ThemeConstants.paddingSmall,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    BorderRadius.circular(ThemeConstants.borderRadiusXLarge),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: "Konum ara...",
                  border: InputBorder.none,
                  hintStyle: textTheme.bodyMedium,
                  suffixIcon: IconButton(
                    icon:
                        Icon(Icons.search, color: textTheme.bodyMedium?.color),
                    onPressed: _searchLocation,
                  ),
                ),
                onSubmitted: (_) => _searchLocation(),
              ),
            ),
          ),

          // Arama sonuçları
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 100,
              left: ThemeConstants.paddingMedium.left,
              right: ThemeConstants.paddingMedium.right,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius:
                      BorderRadius.circular(ThemeConstants.borderRadiusMedium),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      title: Text(
                        result['display_name'],
                        style: textTheme.bodyLarge,
                      ),
                      onTap: () => _selectSearchResult(result),
                    );
                  },
                ),
              ),
            ),

          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
        ],
      ),
    );
  }
}
