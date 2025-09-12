import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'animated_motorcycle_marker.dart';
import 'performance_optimized_map.dart';
import 'map_performance_manager.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin {
  late final MapController _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  final MapPerformanceManager _performanceManager = MapPerformanceManager();
  bool _enableAnimations = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
    _performanceManager.cleanExpiredCache();
  }

  @override
  void dispose() {
    _performanceManager.dispose();
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
      if (permission != LocationPermission.whileInUse) {
        setState(() => _isLoading = false);
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });
    _mapController.move(_currentPosition!, 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Spiride Harita', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PerformanceOptimizedMap(
              mapController: _mapController,
              currentPosition: _currentPosition,
              enableAnimations: _enableAnimations,
              enableTileCaching: true,
              maxZoom: 20,
              minZoom: 1,
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map_screen_fab',
        onPressed: _getCurrentLocation,
        backgroundColor: const Color(0xFFD10000),
        child: const Icon(Icons.gps_fixed, color: Colors.white),
      ),
    );
  }
}
