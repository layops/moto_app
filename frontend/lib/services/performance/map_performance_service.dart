import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Harita performans optimizasyon servisi
class MapPerformanceService {
  static final MapPerformanceService _instance = MapPerformanceService._internal();
  factory MapPerformanceService() => _instance;
  MapPerformanceService._internal();

  // Cache for route calculations
  final Map<String, RouteCacheEntry> _routeCache = {};
  final Map<String, SearchCacheEntry> _searchCache = {};
  
  // Performance settings
  static const Duration _routeCacheDuration = Duration(minutes: 30);
  static const Duration _searchCacheDuration = Duration(minutes: 5);
  static const int _maxCacheSize = 100;
  
  // Throttling
  Timer? _throttleTimer;
  static const Duration _throttleDuration = Duration(milliseconds: 100);

  /// Rota hesaplama cache'i
  Future<List<LatLng>?> getCachedRoute(LatLng start, LatLng end) async {
    final key = _generateRouteKey(start, end);
    final entry = _routeCache[key];
    
    if (entry != null && !entry.isExpired) {
      return entry.routePoints;
    }
    
    if (entry != null) {
      _routeCache.remove(key);
    }
    
    return null;
  }

  /// Rota cache'e kaydet
  void cacheRoute(LatLng start, LatLng end, List<LatLng> routePoints) {
    final key = _generateRouteKey(start, end);
    
    // Cache boyutunu kontrol et
    if (_routeCache.length >= _maxCacheSize) {
      _evictOldestRouteCache();
    }
    
    _routeCache[key] = RouteCacheEntry(
      routePoints: routePoints,
      timestamp: DateTime.now(),
      duration: _routeCacheDuration,
    );
  }

  /// Arama cache'i
  Future<List<SearchResult>?> getCachedSearch(String query) async {
    final key = query.toLowerCase().trim();
    final entry = _searchCache[key];
    
    if (entry != null && !entry.isExpired) {
      return entry.results;
    }
    
    if (entry != null) {
      _searchCache.remove(key);
    }
    
    return null;
  }

  /// Arama cache'e kaydet
  void cacheSearch(String query, List<SearchResult> results) {
    final key = query.toLowerCase().trim();
    
    // Cache boyutunu kontrol et
    if (_searchCache.length >= _maxCacheSize) {
      _evictOldestSearchCache();
    }
    
    _searchCache[key] = SearchCacheEntry(
      results: results,
      timestamp: DateTime.now(),
      duration: _searchCacheDuration,
    );
  }

  /// Throttled callback execution
  void throttle(VoidCallback callback) {
    _throttleTimer?.cancel();
    _throttleTimer = Timer(_throttleDuration, callback);
  }

  /// Rota noktalarını optimize et (çok fazla nokta varsa azalt)
  List<LatLng> optimizeRoutePoints(List<LatLng> points, {double tolerance = 0.0001}) {
    if (points.length <= 2) return points;
    
    // Douglas-Peucker algoritması ile nokta azaltma
    return _douglasPeucker(points, tolerance);
  }

  /// Douglas-Peucker algoritması
  List<LatLng> _douglasPeucker(List<LatLng> points, double tolerance) {
    if (points.length <= 2) return points;
    
    // En uzak noktayı bul
    double maxDistance = 0;
    int maxIndex = 0;
    
    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(
        points[i],
        points[0],
        points[points.length - 1],
      );
      
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }
    
    // Eğer maksimum mesafe toleranstan büyükse, recursive olarak böl
    if (maxDistance > tolerance) {
      final leftPoints = _douglasPeucker(
        points.sublist(0, maxIndex + 1),
        tolerance,
      );
      final rightPoints = _douglasPeucker(
        points.sublist(maxIndex),
        tolerance,
      );
      
      // Son noktayı tekrarlamayı önle
      return [...leftPoints, ...rightPoints.sublist(1)];
    } else {
      // Sadece başlangıç ve bitiş noktalarını al
      return [points[0], points[points.length - 1]];
    }
  }

  /// Dik mesafe hesaplama
  double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final A = point.latitude - lineStart.latitude;
    final B = point.longitude - lineStart.longitude;
    final C = lineEnd.latitude - lineStart.latitude;
    final D = lineEnd.longitude - lineStart.longitude;
    
    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) {
      return sqrt(A * A + B * B);
    }
    
    final param = dot / lenSq;
    
    double xx, yy;
    if (param < 0) {
      xx = lineStart.latitude;
      yy = lineStart.longitude;
    } else if (param > 1) {
      xx = lineEnd.latitude;
      yy = lineEnd.longitude;
    } else {
      xx = lineStart.latitude + param * C;
      yy = lineStart.longitude + param * D;
    }
    
    final dx = point.latitude - xx;
    final dy = point.longitude - yy;
    
    return sqrt(dx * dx + dy * dy);
  }

  /// Rota key oluştur
  String _generateRouteKey(LatLng start, LatLng end) {
    return '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}-${end.latitude.toStringAsFixed(4)},${end.longitude.toStringAsFixed(4)}';
  }

  /// En eski rota cache'ini temizle
  void _evictOldestRouteCache() {
    if (_routeCache.isEmpty) return;
    
    String oldestKey = _routeCache.keys.first;
    DateTime oldestTime = _routeCache[oldestKey]!.timestamp;
    
    for (final entry in _routeCache.entries) {
      if (entry.value.timestamp.isBefore(oldestTime)) {
        oldestTime = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }
    
    _routeCache.remove(oldestKey);
  }

  /// En eski arama cache'ini temizle
  void _evictOldestSearchCache() {
    if (_searchCache.isEmpty) return;
    
    String oldestKey = _searchCache.keys.first;
    DateTime oldestTime = _searchCache[oldestKey]!.timestamp;
    
    for (final entry in _searchCache.entries) {
      if (entry.value.timestamp.isBefore(oldestTime)) {
        oldestTime = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }
    
    _searchCache.remove(oldestKey);
  }

  /// Cache'leri temizle
  void clearCache() {
    _routeCache.clear();
    _searchCache.clear();
  }

  /// Dispose
  void dispose() {
    _throttleTimer?.cancel();
    clearCache();
  }
}

/// Rota cache entry
class RouteCacheEntry {
  final List<LatLng> routePoints;
  final DateTime timestamp;
  final Duration duration;
  
  RouteCacheEntry({
    required this.routePoints,
    required this.timestamp,
    required this.duration,
  });
  
  bool get isExpired => DateTime.now().difference(timestamp) > duration;
}

/// Arama cache entry
class SearchCacheEntry {
  final List<SearchResult> results;
  final DateTime timestamp;
  final Duration duration;
  
  SearchCacheEntry({
    required this.results,
    required this.timestamp,
    required this.duration,
  });
  
  bool get isExpired => DateTime.now().difference(timestamp) > duration;
}

/// Search result model (placeholder)
class SearchResult {
  final String displayName;
  final LatLng coordinates;
  final String city;
  final String country;
  
  SearchResult({
    required this.displayName,
    required this.coordinates,
    required this.city,
    required this.country,
  });
  
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      coordinates: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
      city: json['address']?['city'] ?? '',
      country: json['address']?['country'] ?? '',
    );
  }
}
