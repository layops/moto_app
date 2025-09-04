import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

class MapPage extends StatefulWidget {
  final LatLng? initialCenter;
  final bool allowSelection;
  final bool showMarker; // Read-only modda da pin gösterilsin mi?
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
  LatLng? _currentPosition;
  LatLng? _selectedPosition; // Kullanıcının seçtiği konum
  bool _isLoading = true;
  double _zoomLevel = 13.0;

  List<dynamic> _searchResults = [];

  bool _isSatelliteView = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      if (widget.allowSelection || widget.showMarker) {
        _selectedPosition = widget.initialCenter;
      }
      _isLoading = false;
      setState(() {});
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel += 1;
      final center = _selectedPosition ?? _mapController.camera.center;
      _mapController.move(center, _zoomLevel);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel -= 1;
      final center = _selectedPosition ?? _mapController.camera.center;
      _mapController.move(center, _zoomLevel);
    });
  }

  void _goToCurrentLocation() {
    if (_currentPosition != null) {
      setState(() {
        _zoomLevel = 15.0;
        final center = _selectedPosition ?? _currentPosition!;
        _mapController.move(center, _zoomLevel);
      });
    }
  }

  void _searchLocation() async {
    final String searchText = _searchController.text;
    if (searchText.isEmpty || searchText.trim().length < 3) {
      if (mounted) setState(() => _searchResults = []);
      if (searchText.isNotEmpty && searchText.trim().length < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lütfen en az 3 karakter yazın.')),
          );
        }
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _searchResults = [];
      });
    }

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': searchText.trim(),
          'format': 'json',
          'limit': '5',
          'addressdetails': '0',
        },
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'motoapp-front/1.0 (search)'},
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => _searchResults = data);
        if (data.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hiç sonuç bulunamadı.')),
          );
        }
      } else if (response.statusCode == 429) {
        // Rate limit aşıldı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Çok hızlı arama yapıldı. Lütfen tekrar deneyin.')),
        );
        if (mounted) setState(() => _searchResults = []);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama sırasında hata oluştu.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İnternet bağlantınızı kontrol edin.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectSearchResult(dynamic result) {
    if (result != null) {
      final double? lat = double.tryParse(result['lat'].toString());
      final double? lon = double.tryParse(result['lon'].toString());
      if (lat == null || lon == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçersiz konum sonucu.')),
        );
        return;
      }

      setState(() {
        _selectedPosition = LatLng(lat, lon);
        _searchResults = [];
        _searchController.clear();
      });

      _mapController.move(_selectedPosition!, 15.0);
    }
  }

  void _toggleMapType() {
    setState(() => _isSatelliteView = !_isSatelliteView);
  }

  Widget _buildMapControls(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      bottom: ThemeConstants.paddingMedium.bottom + 60,
      right: ThemeConstants.paddingMedium.right,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: 'map_zoom_in_fab',
            onPressed: _zoomIn,
            backgroundColor: colorScheme.primary,
            mini: true,
            child: Icon(Icons.add, color: colorScheme.onPrimary),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'map_zoom_out_fab',
            onPressed: _zoomOut,
            backgroundColor: colorScheme.primary,
            mini: true,
            child: Icon(Icons.remove, color: colorScheme.onPrimary),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'map_my_location_fab',
            onPressed: _goToCurrentLocation,
            backgroundColor: colorScheme.primary,
            mini: true,
            child: Icon(Icons.my_location, color: colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Positioned(
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
              icon: Icon(Icons.search, color: textTheme.bodyMedium?.color),
              onPressed: _searchLocation,
            ),
          ),
          onSubmitted: (_) => _searchLocation(),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_searchResults.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: ThemeConstants.paddingMedium.left,
      right: ThemeConstants.paddingMedium.right,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          boxShadow: const [BoxShadow(blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return ListTile(
              title: Text(result['display_name'], style: textTheme.bodyLarge),
              onTap: () => _selectSearchResult(result),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    if (_selectedPosition == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: ThemeConstants.paddingMedium.bottom,
      left: ThemeConstants.paddingMedium.left,
      right: ThemeConstants.paddingMedium.right,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ThemeConstants.borderRadiusXLarge),
          ),
        ),
        icon: const Icon(Icons.check),
        label: const Text("Bu Konumu Seç"),
        onPressed: () {
          if (!mounted) return;
          final result = _selectedPosition;
          setState(() {
            _isLoading = false;
          });
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(result);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const String defaultMapUrl =
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    const String satelliteUrl =
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter ?? LatLng(41.0082, 28.9784),
              initialZoom: _zoomLevel,
              onTap: (tapPosition, point) {
                if (!widget.allowSelection) return;
                setState(() => _selectedPosition = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatelliteView ? satelliteUrl : defaultMapUrl,
                userAgentPackageName: 'com.example.frontend',
                maxZoom: 20,
              ),
              if (_currentPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.my_location,
                        color: colorScheme.primary, size: 32),
                  ),
                ]),
              if (_selectedPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _selectedPosition!,
                    width: 50,
                    height: 50,
                    child:
                        Icon(Icons.location_pin, color: Colors.red, size: 50),
                  ),
                ]),
            ],
          ),
          if (widget.allowSelection) _buildMapControls(context),
          if (widget.allowSelection) _buildSearchBar(context),
          if (widget.allowSelection) _buildSearchResults(context),
          if (widget.allowSelection) _buildConfirmButton(context),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
        ],
      ),
    );
  }
}
