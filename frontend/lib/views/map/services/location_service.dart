import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Konum servislerini yöneten sınıf
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Mevcut konumu al
  Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceException('Konum servisleri kapalı');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationServiceException('Konum izni reddedildi');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationServiceException('Konum izni kalıcı olarak reddedildi');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw LocationServiceException('Konum alınamadı: ${e.toString()}');
    }
  }

  /// Konum stream'i başlat
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10 metre değişiklikte güncelle
      ),
    );
  }

  /// İki nokta arasındaki mesafeyi hesapla
  double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Konum izinlerini kontrol et
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Konum servislerinin açık olup olmadığını kontrol et
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}

/// Konum servisi hata sınıfı
class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);
  
  @override
  String toString() => 'LocationServiceException: $message';
}
