import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../models/map_state.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../services/search_service.dart';

/// Ana map controller sınıfı
class MapController extends ChangeNotifier {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final SearchService _searchService = SearchService();

  // State
  MapState _mapState = const MapState();
  RouteState _routeState = const RouteState();
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  
  // Streams
  StreamSubscription<Position>? _positionStream;
  Timer? _searchDebounce;
  late VoidCallback _searchControllerListener;
  
  // Performance optimizations
  Timer? _updateThrottle;
  LatLng? _lastUpdatePosition;
  static const double _minUpdateDistance = 10.0; // 10 metre minimum güncelleme mesafesi
  static const Duration _throttleDuration = Duration(milliseconds: 500);

  // Getters
  MapState get mapState => _mapState;
  RouteState get routeState => _routeState;
  TextEditingController get searchController => _searchController;
  TextEditingController get labelController => _labelController;
  MapController get mapController => _mapController;

  // Constants
  static const List<double> zoomLevels = [5.0, 10.0, 13.0, 15.0, 18.0];
  static const List<String> zoomLabels = [
    'Ülke',
    'Bölge',
    'Şehir',
    'Mahalle',
    'Sokak'
  ];

  MapController() {
    _initializeController();
  }

  void _initializeController() {
    _searchControllerListener = () {
      notifyListeners();
    };
    _searchController.addListener(_searchControllerListener);
    _loadSearchHistory();
  }

  // Map State Methods
  void updateMapState(MapState newState) {
    _mapState = newState;
    notifyListeners();
  }

  void updateRouteState(RouteState newState) {
    _routeState = newState;
    notifyListeners();
  }

  // Location Methods
  Future<void> getCurrentLocation() async {
    try {
      updateMapState(_mapState.copyWith(isLoading: true));
      
      final position = await _locationService.getCurrentLocation();
      
      updateMapState(_mapState.copyWith(
        currentPosition: position,
        isLoading: false,
      ));
      
      if (position != null) {
        _mapController.move(position, 15.0);
      }
    } catch (e) {
      updateMapState(_mapState.copyWith(isLoading: false));
      _showError('Konum alınamadı: ${e.toString()}');
    }
  }

  // Search Methods
  Future<void> _loadSearchHistory() async {
    try {
      final history = await _searchService.loadSearchHistory();
      updateMapState(_mapState.copyWith(searchHistory: history));
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  void onSearchTextChanged(String text) {
    _searchService.searchWithDebounce(text, (results) {
      // Search results handling
      notifyListeners();
    });
  }

  void onSearchSubmitted() {
    // Search submission handling
  }

  void onSearchResultSelected(SearchResult result) {
    updateMapState(_mapState.copyWith(
      selectedPosition: result.coordinates,
      isSearchFocused: false,
    ));
    _searchController.clear();
    _mapController.move(result.coordinates, 15.0);
  }

  void onSearchHistorySelected(String query) {
    _searchController.text = query;
    onSearchTextChanged(query);
  }

  void clearSearch() {
    _searchController.clear();
    updateMapState(_mapState.copyWith(isSearchFocused: false));
  }

  // Zoom Methods
  void zoomIn() {
    if (_mapState.zoomLevel < 20) {
      final newZoom = _mapState.zoomLevel + 1;
      updateMapState(_mapState.copyWith(zoomLevel: newZoom));
      final center = _mapState.selectedPosition ?? _mapController.camera.center;
      _mapController.move(center, newZoom);
    }
  }

  void zoomOut() {
    if (_mapState.zoomLevel > 1) {
      final newZoom = _mapState.zoomLevel - 1;
      updateMapState(_mapState.copyWith(zoomLevel: newZoom));
      final center = _mapState.selectedPosition ?? _mapController.camera.center;
      _mapController.move(center, newZoom);
    }
  }

  void setZoomLevel(double level) {
    updateMapState(_mapState.copyWith(zoomLevel: level));
    final center = _mapState.selectedPosition ?? 
                   _mapState.currentPosition ?? 
                   const LatLng(41.0082, 28.9784);
    _mapController.move(center, level);
  }

  // Map Type Methods
  void toggleMapType() {
    updateMapState(_mapState.copyWith(
      isSatelliteView: !_mapState.isSatelliteView,
    ));
  }

  // Route Methods
  void toggleRouteMode() {
    final newRouteMode = !_routeState.isRouteMode;
    
    if (!newRouteMode) {
      updateRouteState(RouteState(
        routePoints: [],
        isRouteMode: false,
        startPoint: null,
        endPoint: null,
        routeDistance: null,
        routeDuration: null,
        isNavigating: false,
        currentRouteIndex: 0,
      ));
      _showInfo('Rota modu kapatıldı');
    } else {
      updateRouteState(_routeState.copyWith(isRouteMode: true));
      _showInfo('Rota modu aktif! Map\'e tıklayarak başlangıç noktasını seçin.');
    }
  }

  void setRoutePoint(LatLng point) {
    if (!_routeState.isRouteMode) return;

    if (_routeState.startPoint == null) {
      updateRouteState(_routeState.copyWith(startPoint: point));
      _showInfo('Başlangıç noktası seçildi. Şimdi bitiş noktasını seçin.');
    } else if (_routeState.endPoint == null) {
      updateRouteState(_routeState.copyWith(endPoint: point));
      _calculateRoute();
    } else {
      updateRouteState(_routeState.copyWith(
        startPoint: point,
        endPoint: null,
        routePoints: [],
      ));
      _showInfo('Yeni başlangıç noktası seçildi. Bitiş noktasını seçin.');
    }
  }

  Future<void> _calculateRoute() async {
    if (_routeState.startPoint == null || _routeState.endPoint == null) return;

    updateMapState(_mapState.copyWith(isLoading: true));

    try {
      final result = await _routeService.calculateRoute(
        _routeState.startPoint!,
        _routeState.endPoint!,
      );

      updateRouteState(_routeState.copyWith(
        routePoints: result.routePoints,
        routeDistance: result.distance,
        routeDuration: result.duration,
        isRouteMode: false,
      ));

      _showInfo('Rota oluşturuldu: ${result.formattedDistance}, ${result.formattedDuration}');
    } catch (e) {
      // Fallback to simple route
      final result = _routeService.createSimpleRoute(
        _routeState.startPoint!,
        _routeState.endPoint!,
      );

      updateRouteState(_routeState.copyWith(
        routePoints: result.routePoints,
        routeDistance: result.distance,
        routeDuration: result.duration,
        isRouteMode: false,
      ));

      _showError('Rota hesaplanamadı, basit çizgi gösteriliyor');
    } finally {
      updateMapState(_mapState.copyWith(isLoading: false));
    }
  }

  void startNavigation() {
    if (_routeState.routePoints.isEmpty) return;

    updateRouteState(_routeState.copyWith(
      isNavigating: true,
      currentRouteIndex: 0,
    ));

    _startLocationTracking();
    _showInfo('Navigasyon başladı! Rotayı takip edin.');
  }

  void stopNavigation() {
    updateRouteState(_routeState.copyWith(
      isNavigating: false,
      currentRouteIndex: 0,
    ));

    _positionStream?.cancel();
    _showInfo('Navigasyon durduruldu');
  }

  void _startLocationTracking() {
    _positionStream = _locationService.getLocationStream().listen((position) {
      if (!_routeState.isNavigating || _routeState.routePoints.isEmpty) return;

      final currentLocation = LatLng(position.latitude, position.longitude);
      _updateLocationIfSignificant(currentLocation);
      _updateNavigationProgress(currentLocation);
    });
  }

  void _updateNavigationProgress(LatLng currentLocation) {
    if (_routeState.routePoints.isEmpty) return;

    // En yakın rota noktasını bul (optimized)
    double minDistance = double.infinity;
    int nearestIndex = 0;
    
    // Sadece mevcut indeksin etrafındaki noktaları kontrol et
    final startIndex = max(0, _routeState.currentRouteIndex - 5);
    final endIndex = min(_routeState.routePoints.length, _routeState.currentRouteIndex + 10);

    for (int i = startIndex; i < endIndex; i++) {
      final distance = _calculateDistance(currentLocation, _routeState.routePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // Eğer kullanıcı rota üzerinde ilerliyorsa
    if (minDistance < 50) { // 50 metre tolerans
      updateRouteState(_routeState.copyWith(currentRouteIndex: nearestIndex));

      // Map'i kullanıcının konumuna odakla (throttled)
      _throttledUpdate();

      // Hedefe yaklaştıysa navigasyonu bitir
      if (nearestIndex >= _routeState.routePoints.length - 5) {
        stopNavigation();
        _showInfo('Hedefe ulaştınız!');
      }
    }
  }

  void clearRoute() {
    updateRouteState(const RouteState());
    _positionStream?.cancel();
    _showInfo('Rota temizlendi');
  }

  // Utility Methods
  void _showInfo(String message) {
    // Bu method UI tarafından implement edilecek
  }

  void _showError(String message) {
    // Bu method UI tarafından implement edilecek
  }

  // Map Tap Handler
  void onMapTap(LatLng point) {
    updateMapState(_mapState.copyWith(isSearchFocused: false));
    
    if (_routeState.isRouteMode) {
      setRoutePoint(point);
    } else {
      updateMapState(_mapState.copyWith(selectedPosition: point));
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchControllerListener);
    _searchController.dispose();
    _labelController.dispose();
    _searchDebounce?.cancel();
    _updateThrottle?.cancel();
    _positionStream?.cancel();
    _searchService.dispose();
    super.dispose();
  }
  
  /// Performans optimizasyonu için throttled update
  void _throttledUpdate() {
    _updateThrottle?.cancel();
    _updateThrottle = Timer(_throttleDuration, () {
      notifyListeners();
    });
  }
  
  /// Mesafe kontrolü ile konum güncelleme
  void _updateLocationIfSignificant(LatLng newPosition) {
    if (_lastUpdatePosition == null) {
      _lastUpdatePosition = newPosition;
      _updateMapState(_mapState.copyWith(currentPosition: newPosition));
      return;
    }
    
    final distance = _calculateDistance(_lastUpdatePosition!, newPosition);
    if (distance >= _minUpdateDistance) {
      _lastUpdatePosition = newPosition;
      _updateMapState(_mapState.copyWith(currentPosition: newPosition));
    }
  }
  
  /// İki nokta arasındaki mesafeyi hesapla (metre)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metre
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
}
