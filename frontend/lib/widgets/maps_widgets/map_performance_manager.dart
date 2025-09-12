import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class MapPerformanceManager {
  static final MapPerformanceManager _instance = MapPerformanceManager._internal();
  factory MapPerformanceManager() => _instance;
  MapPerformanceManager._internal();

  // Performans ayarları
  static const int maxMarkers = 50;
  static const int maxRoutePoints = 1000;
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Cache yönetimi
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration cacheExpiry = Duration(minutes: 5);

  // Debounce timer'ları
  final Map<String, Timer> _debounceTimers = {};

  // Performans metrikleri
  int _markerCount = 0;
  int _routePointCount = 0;
  DateTime _lastUpdate = DateTime.now();

  // Marker sayısını kontrol et
  bool canAddMarker() {
    return _markerCount < maxMarkers;
  }

  // Rota noktası sayısını kontrol et
  bool canAddRoutePoint() {
    return _routePointCount < maxRoutePoints;
  }

  // Marker ekle
  void addMarker() {
    _markerCount++;
    _updatePerformanceMetrics();
  }

  // Marker kaldır
  void removeMarker() {
    if (_markerCount > 0) {
      _markerCount--;
      _updatePerformanceMetrics();
    }
  }

  // Rota noktası ekle
  void addRoutePoints(int count) {
    _routePointCount += count;
    _updatePerformanceMetrics();
  }

  // Rota noktalarını temizle
  void clearRoutePoints() {
    _routePointCount = 0;
    _updatePerformanceMetrics();
  }

  // Performans metriklerini güncelle
  void _updatePerformanceMetrics() {
    _lastUpdate = DateTime.now();
  }

  // Debounce işlemi
  void debounce(String key, VoidCallback callback) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(debounceDelay, callback);
  }

  // Cache işlemleri
  void setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  dynamic getCache(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < cacheExpiry) {
      return _cache[key];
    }
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }

  // Cache temizle
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Eski cache'leri temizle
  void cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > cacheExpiry) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Performans durumunu al
  MapPerformanceStatus getPerformanceStatus() {
    return MapPerformanceStatus(
      markerCount: _markerCount,
      routePointCount: _routePointCount,
      cacheSize: _cache.length,
      lastUpdate: _lastUpdate,
      isOptimal: _markerCount < maxMarkers && _routePointCount < maxRoutePoints,
    );
  }

  // Optimize edilmiş marker listesi oluştur
  List<Marker> optimizeMarkers(List<Marker> markers) {
    if (markers.length <= maxMarkers) {
      return markers;
    }

    // Çok fazla marker varsa clustering uygula
    return _clusterMarkers(markers);
  }

  List<Marker> _clusterMarkers(List<Marker> markers) {
    // Basit clustering algoritması
    final clusters = <String, List<Marker>>{};
    const clusterSize = 0.01; // Yaklaşık 1km

    for (final marker in markers) {
      final clusterKey = '${(marker.point.latitude / clusterSize).floor()}_${(marker.point.longitude / clusterSize).floor()}';
      clusters.putIfAbsent(clusterKey, () => []).add(marker);
    }

    final optimizedMarkers = <Marker>[];
    clusters.forEach((key, clusterMarkers) {
      if (clusterMarkers.length == 1) {
        optimizedMarkers.add(clusterMarkers.first);
      } else {
        // Cluster için tek marker oluştur
        final centerLat = clusterMarkers.map((m) => m.point.latitude).reduce((a, b) => a + b) / clusterMarkers.length;
        final centerLng = clusterMarkers.map((m) => m.point.longitude).reduce((a, b) => a + b) / clusterMarkers.length;
        
        optimizedMarkers.add(
          Marker(
            point: LatLng(centerLat, centerLng),
            width: 60,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD10000),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${clusterMarkers.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    });

    return optimizedMarkers;
  }

  // Optimize edilmiş rota noktaları
  List<LatLng> optimizeRoutePoints(List<LatLng> points) {
    if (points.length <= maxRoutePoints) {
      return points;
    }

    // Rota noktalarını azalt (Douglas-Peucker algoritması)
    return _simplifyRoute(points);
  }

  List<LatLng> _simplifyRoute(List<LatLng> points) {
    if (points.length <= 2) return points;

    final simplified = <LatLng>[points.first];
    const tolerance = 0.0001; // Yaklaşık 10m

    for (int i = 1; i < points.length - 1; i++) {
      final prev = simplified.last;
      final current = points[i];
      final next = points[i + 1];

      // Mesafe hesapla
      final distance = _calculateDistance(prev, current);
      if (distance > tolerance) {
        simplified.add(current);
      }
    }

    simplified.add(points.last);
    return simplified;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metre
    final lat1Rad = point1.latitude * (3.14159265359 / 180);
    final lat2Rad = point2.latitude * (3.14159265359 / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    final deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    final a = (deltaLatRad / 2).sin() * (deltaLatRad / 2).sin() +
        lat1Rad.cos() * lat2Rad.cos() *
        (deltaLngRad / 2).sin() * (deltaLngRad / 2).sin();
    final c = 2 * (a.sqrt()).asin();

    return earthRadius * c;
  }

  // Temizlik işlemleri
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    clearCache();
  }
}

class MapPerformanceStatus {
  final int markerCount;
  final int routePointCount;
  final int cacheSize;
  final DateTime lastUpdate;
  final bool isOptimal;

  const MapPerformanceStatus({
    required this.markerCount,
    required this.routePointCount,
    required this.cacheSize,
    required this.lastUpdate,
    required this.isOptimal,
  });

  @override
  String toString() {
    return 'MapPerformanceStatus(markers: $markerCount, routes: $routePointCount, cache: $cacheSize, optimal: $isOptimal)';
  }
}
