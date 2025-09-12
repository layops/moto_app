library map_page;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'map_controls.dart';
part 'map_search.dart';
part 'map_route.dart';

class MapPage extends StatefulWidget {
  final LatLng? initialCenter;
  final bool allowSelection;
  final bool showMarker;

  const MapPage({
    super.key,
    this.initialCenter,
    this.allowSelection = false,
    this.showMarker = false,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  bool _isLoading = true;
  double _zoomLevel = 13.0;

  List<dynamic> _searchResults = [];
  Timer? _searchDebounce;
  bool _isSatelliteView = false;
  late VoidCallback _searchControllerListener;

  List<LatLng> _routePoints = [];
  bool _isRouteMode = false;
  LatLng? _startPoint;
  LatLng? _endPoint;
  double? _routeDistance; // metre cinsinden
  int? _routeDuration; // saniye cinsinden
  bool _isNavigating = false; // navigasyon modu aktif mi
  int _currentRouteIndex = 0; // mevcut rota noktası indeksi
  StreamSubscription<Position>? _positionStream; // konum takibi

  String? _selectedLocationLabel;
  List<String> _searchHistory = [];
  bool _isSearchFocused = false;

  static const List<double> _zoomLevels = [5.0, 10.0, 13.0, 15.0, 18.0];
  static const List<String> _zoomLabels = [
    'Ülke',
    'Bölge',
    'Şehir',
    'Mahalle',
    'Sokak'
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchControllerListener = () {
      setState(() {}); // Suffix icon'ın görünürlüğü için
    };
    _searchController.addListener(_searchControllerListener);
    if (widget.initialCenter != null) {
      if (widget.allowSelection || widget.showMarker) {
        _selectedPosition = widget.initialCenter;
      }
      _isLoading = false;
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchControllerListener);
    _searchController.dispose();
    _labelController.dispose();
    _searchDebounce?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showLocationError('Konum servisleri kapalı. Lütfen ayarlardan açın.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showLocationError('Konum izni reddedildi. Uygulama varsayılan konumu kullanacak.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showLocationError('Konum izni kalıcı olarak reddedildi. Ayarlardan değiştirebilirsiniz.');
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showLocationError('Konum alınamadı: ${e.toString()}');
      }
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _zoomIn() {
    if (_zoomLevel < 20) {
      _zoomLevel += 1;
      final center = _selectedPosition ?? _mapController.camera.center;
      _mapController.move(center, _zoomLevel);
    }
  }

  void _zoomOut() {
    if (_zoomLevel > 1) {
      _zoomLevel -= 1;
      final center = _selectedPosition ?? _mapController.camera.center;
      _mapController.move(center, _zoomLevel);
    }
  }

  void _goToCurrentLocation() {
    if (_currentPosition != null) {
      _zoomLevel = 15.0;
      final center = _selectedPosition ?? _currentPosition!;
      _mapController.move(center, _zoomLevel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    const String defaultMapUrl =
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    const String satelliteUrl =
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SizedBox.expand(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialCenter ??
                    (_currentPosition ?? const LatLng(41.0082, 28.9784)),
                initialZoom: _zoomLevel,
                onTap: (tapPosition, point) {
                  setState(() => _isSearchFocused = false);
                  if (_isRouteMode) {
                    // Rota modu aktifken allowSelection kontrolünü bypass et
                    _setRoutePoint(point);
                  } else if (widget.allowSelection) {
                    setState(() => _selectedPosition = point);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _isSatelliteView ? satelliteUrl : defaultMapUrl,
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
                        child: Icon(Icons.my_location,
                            color: colorScheme.primary, size: 32),
                      ),
                    ],
                  ),
                if (_selectedPosition != null && widget.showMarker)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPosition!,
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_pin,
                            color: colorScheme.error, size: 32),
                      ),
                    ],
                  ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: colorScheme.primary,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                if (_isRouteMode && _startPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _startPoint!,
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
                if (_isRouteMode && _endPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _endPoint!,
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
            _buildSearchBar(context),
            _buildMapControls(context),
            if (_selectedPosition != null) _buildLocationActions(context),
            if (_selectedPosition != null) _buildConfirmButton(context),
            _buildSearchHistory(context),
            _buildSearchResults(context),
            _buildZoomLevels(context),
            _buildRouteInfo(context),
            _buildRouteSummary(context),
            _buildNavigationUI(context),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
