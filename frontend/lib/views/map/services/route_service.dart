import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Rota hesaplama servisini yöneten sınıf
class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  /// OSRM API kullanarak rota hesapla
  Future<RouteResult> calculateRoute(LatLng start, LatLng end) async {
    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
        {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'MotoApp/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          final distance = route['distance'] as double; // metre
          final duration = route['duration'] as double; // saniye
          
          final routePoints = coordinates.map((coord) => 
            LatLng(coord[1].toDouble(), coord[0].toDouble())
          ).toList();

          return RouteResult(
            routePoints: routePoints,
            distance: distance,
            duration: duration.round(),
            success: true,
          );
        } else {
          throw RouteServiceException('Rota bulunamadı');
        }
      } else {
        throw RouteServiceException('API hatası: ${response.statusCode}');
      }
    } on http.ClientException {
      throw RouteServiceException('İnternet bağlantısı hatası');
    } catch (e) {
      throw RouteServiceException('Rota hesaplanamadı: ${e.toString()}');
    }
  }

  /// Basit çizgi rota oluştur (fallback)
  RouteResult createSimpleRoute(LatLng start, LatLng end) {
    const Distance distance = Distance();
    final routeDistance = distance.as(LengthUnit.Meter, start, end);
    
    return RouteResult(
      routePoints: [start, end],
      distance: routeDistance,
      duration: (routeDistance / 1000 * 2).round() * 60, // Ortalama 30 km/h hız varsayımı
      success: true,
      isSimpleRoute: true,
    );
  }
}

/// Rota hesaplama sonucu
class RouteResult {
  final List<LatLng> routePoints;
  final double distance; // metre
  final int duration; // saniye
  final bool success;
  final bool isSimpleRoute;

  const RouteResult({
    required this.routePoints,
    required this.distance,
    required this.duration,
    required this.success,
    this.isSimpleRoute = false,
  });

  /// Mesafeyi km cinsinden al
  double get distanceInKm => distance / 1000;

  /// Süreyi dakika cinsinden al
  int get durationInMinutes => (duration / 60).round();

  /// Mesafeyi formatlanmış string olarak al
  String get formattedDistance => '${distanceInKm.toStringAsFixed(1)} km';

  /// Süreyi formatlanmış string olarak al
  String get formattedDuration => '$durationInMinutes dk';
}

/// Rota servisi hata sınıfı
class RouteServiceException implements Exception {
  final String message;
  RouteServiceException(this.message);
  
  @override
  String toString() => 'RouteServiceException: $message';
}
