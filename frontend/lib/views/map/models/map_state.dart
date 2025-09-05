import 'package:latlong2/latlong.dart';

/// Map sayfasının durumunu yöneten model sınıfı
class MapState {
  final LatLng? currentPosition;
  final LatLng? selectedPosition;
  final bool isLoading;
  final double zoomLevel;
  final bool isSatelliteView;
  final bool isSearchFocused;
  final String? selectedLocationLabel;
  final List<String> searchHistory;

  const MapState({
    this.currentPosition,
    this.selectedPosition,
    this.isLoading = true,
    this.zoomLevel = 13.0,
    this.isSatelliteView = false,
    this.isSearchFocused = false,
    this.selectedLocationLabel,
    this.searchHistory = const [],
  });

  MapState copyWith({
    LatLng? currentPosition,
    LatLng? selectedPosition,
    bool? isLoading,
    double? zoomLevel,
    bool? isSatelliteView,
    bool? isSearchFocused,
    String? selectedLocationLabel,
    List<String>? searchHistory,
  }) {
    return MapState(
      currentPosition: currentPosition ?? this.currentPosition,
      selectedPosition: selectedPosition ?? this.selectedPosition,
      isLoading: isLoading ?? this.isLoading,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      isSatelliteView: isSatelliteView ?? this.isSatelliteView,
      isSearchFocused: isSearchFocused ?? this.isSearchFocused,
      selectedLocationLabel: selectedLocationLabel ?? this.selectedLocationLabel,
      searchHistory: searchHistory ?? this.searchHistory,
    );
  }
}

/// Rota durumunu yöneten model sınıfı
class RouteState {
  final List<LatLng> routePoints;
  final bool isRouteMode;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final double? routeDistance;
  final int? routeDuration;
  final bool isNavigating;
  final int currentRouteIndex;

  const RouteState({
    this.routePoints = const [],
    this.isRouteMode = false,
    this.startPoint,
    this.endPoint,
    this.routeDistance,
    this.routeDuration,
    this.isNavigating = false,
    this.currentRouteIndex = 0,
  });

  RouteState copyWith({
    List<LatLng>? routePoints,
    bool? isRouteMode,
    LatLng? startPoint,
    LatLng? endPoint,
    double? routeDistance,
    int? routeDuration,
    bool? isNavigating,
    int? currentRouteIndex,
  }) {
    return RouteState(
      routePoints: routePoints ?? this.routePoints,
      isRouteMode: isRouteMode ?? this.isRouteMode,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      routeDistance: routeDistance ?? this.routeDistance,
      routeDuration: routeDuration ?? this.routeDuration,
      isNavigating: isNavigating ?? this.isNavigating,
      currentRouteIndex: currentRouteIndex ?? this.currentRouteIndex,
    );
  }
}

/// Arama sonucu modeli
class SearchResult {
  final String displayName;
  final String city;
  final String country;
  final LatLng coordinates;

  const SearchResult({
    required this.displayName,
    required this.city,
    required this.country,
    required this.coordinates,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat'].toString()) ?? 0.0;
    final lon = double.tryParse(json['lon'].toString()) ?? 0.0;
    final address = json['address'] as Map<String, dynamic>?;
    
    return SearchResult(
      displayName: json['display_name'] as String? ?? 'Bilinmeyen konum',
      city: address?['city'] ?? address?['town'] ?? address?['village'] ?? '',
      country: address?['country'] ?? '',
      coordinates: LatLng(lat, lon),
    );
  }
}
