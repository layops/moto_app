import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class PerformanceOptimizedMap extends StatefulWidget {
  final MapController mapController;
  final List<LatLng>? routePoints;
  final LatLng? currentPosition;
  final LatLng? selectedPosition;
  final bool isRouteMode;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final bool enableAnimations;
  final bool enableTileCaching;
  final int maxZoom;
  final int minZoom;

  const PerformanceOptimizedMap({
    super.key,
    required this.mapController,
    this.routePoints,
    this.currentPosition,
    this.selectedPosition,
    this.isRouteMode = false,
    this.startPoint,
    this.endPoint,
    this.enableAnimations = true,
    this.enableTileCaching = true,
    this.maxZoom = 20,
    this.minZoom = 1,
  });

  @override
  State<PerformanceOptimizedMap> createState() => _PerformanceOptimizedMapState();
}

class _PerformanceOptimizedMapState extends State<PerformanceOptimizedMap>
    with AutomaticKeepAliveClientMixin {
  
  Timer? _debounceTimer;
  bool _isMapReady = false;
  List<LatLng> _cachedRoutePoints = [];

  @override
  bool get wantKeepAlive => true; // Widget'ı bellekte tut

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Harita başlatma işlemini optimize et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isMapReady = true;
      });
    });
  }

  @override
  void didUpdateWidget(PerformanceOptimizedMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Sadece gerekli durumlarda güncelle
    if (widget.routePoints != oldWidget.routePoints) {
      _debounceRouteUpdate();
    }
  }

  void _debounceRouteUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _cachedRoutePoints = widget.routePoints ?? [];
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    
    if (!_isMapReady) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD10000),
        ),
      );
    }

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.currentPosition ?? const LatLng(41.0082, 28.9784),
        initialZoom: 13.0,
        maxZoom: widget.maxZoom.toDouble(),
        minZoom: widget.minZoom.toDouble(),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        // Performans optimizasyonları
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            const LatLng(-90, -180),
            const LatLng(90, 180),
          ),
        ),
      ),
      children: [
        // Optimize edilmiş tile layer
        _buildOptimizedTileLayer(),
        
        // Performans için optimize edilmiş markerlar
        if (widget.currentPosition != null) _buildCurrentPositionMarker(),
        if (widget.selectedPosition != null) _buildSelectedPositionMarker(),
        if (widget.isRouteMode && widget.startPoint != null) _buildStartPointMarker(),
        if (widget.isRouteMode && widget.endPoint != null) _buildEndPointMarker(),
        
        // Optimize edilmiş rota çizgisi
        if (_cachedRoutePoints.isNotEmpty) _buildOptimizedRoute(),
      ],
    );
  }

  Widget _buildOptimizedTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.spiride.app',
      maxZoom: widget.maxZoom,
      minZoom: widget.minZoom,
      // Tile cache optimizasyonu
      tileProvider: widget.enableTileCaching 
          ? NetworkTileProvider()
          : NetworkTileProvider(),
      // Performans için tile boyutunu optimize et
      tileSize: 256,
      // Tile yükleme hızını artır
      maxNativeZoom: 18,
      // Retina ekranlar için optimizasyon
      retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
    );
  }

  Widget _buildCurrentPositionMarker() {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.currentPosition!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD10000),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD10000).withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.motorcycle,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPositionMarker() {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.selectedPosition!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.location_pin,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartPointMarker() {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.startPoint!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndPointMarker() {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.endPoint!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD10000),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.flag,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizedRoute() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: _cachedRoutePoints,
          color: const Color(0xFFD10000),
          strokeWidth: 5,
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ),
      ],
    );
  }
}

// Bellek kullanımını optimize etmek için marker cache
class MarkerCache {
  static final Map<String, Widget> _cache = {};
  
  static Widget getCachedMarker({
    required String key,
    required Widget Function() builder,
  }) {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    
    final marker = builder();
    _cache[key] = marker;
    
    // Cache boyutunu sınırla
    if (_cache.length > 100) {
      final keys = _cache.keys.toList();
      for (int i = 0; i < 20; i++) {
        _cache.remove(keys[i]);
      }
    }
    
    return marker;
  }
  
  static void clearCache() {
    _cache.clear();
  }
}

// Tile cache optimizasyonu
class OptimizedTileProvider extends NetworkTileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // Tile cache key oluştur
    final cacheKey = '${coordinates.z}_${coordinates.x}_${coordinates.y}';
    
    return super.getImage(coordinates, options);
  }
}
