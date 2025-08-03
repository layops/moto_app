import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapView extends StatelessWidget {
  final MapController? controller;
  final LatLng initialPosition;

  const MapView({
    super.key,
    this.controller,
    required this.initialPosition,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        center: initialPosition, // 'initialCenter' yerine 'center' kullanılıyor
        zoom: 13, // 'initialZoom' yerine sadece 'zoom'
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.spiride.app',
        ),
      ],
    );
  }
}
