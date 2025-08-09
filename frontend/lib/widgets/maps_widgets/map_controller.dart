import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CustomMapController {
  final MapController _mapController = MapController();

  // Merkez koordinatı almak
  LatLng get center => _mapController.camera.center;

  // Zoom seviyesini almak
  double get zoom => _mapController.camera.zoom;

  // Basit hareket (animasyonsuz)
  void move(LatLng newLocation, double zoomLevel) {
    _mapController.move(newLocation, zoomLevel);
  }

  // Animasyonlu hareket (Güncel API)
  Future<void> animatedMove({
    required LatLng dest,
    required double zoom,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    // FlutterMap v8.x'te doğrudan move kullanımı
    _mapController.move(dest, zoom);

    // Alternatif olarak eğer animasyon süresi önemliyse:
    await Future.delayed(duration); // Animasyon efekti için
  }

  // Harita sınırlarını ayarlama
  Future<void> fitBounds(LatLngBounds bounds) async {
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  // Controller'a erişim
  MapController get controller => _mapController;

  void dispose() {
    _mapController.dispose();
  }
}
