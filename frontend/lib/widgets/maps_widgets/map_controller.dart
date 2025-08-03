import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CustomMapController {
  final MapController _mapController = MapController();

  MapController get mapController => _mapController;

  // Konuma animasyonla gitme
  Future<void> animatedMove(LatLng targetLocation, double zoomLevel) async {
    _mapController.move(targetLocation, zoomLevel);
    // Alternatif: Eğer animasyon eklemek isterseniz:
    // _mapController.animate(targetLocation, zoomLevel, duration: Duration(milliseconds: 500));
  }

  // Mevcut konumu getir
  LatLng? getCurrentCenter() {
    return _mapController.center;
  }

  // Yakınlaştırma seviyesini değiştir
  void setZoom(double zoom) {
    _mapController.move(_mapController.center, zoom);
  }

  // Haritayı temizle (gerekiyorsa)
  void dispose() {
    _mapController.dispose();
  }
}
