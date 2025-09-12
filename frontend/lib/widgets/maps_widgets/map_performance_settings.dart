import 'package:flutter/material.dart';
import 'package:motoapp_frontend/widgets/maps_widgets/map_performance_manager.dart';

class MapPerformanceSettings extends StatefulWidget {
  final MapPerformanceManager performanceManager;
  final ValueChanged<bool>? onAnimationsChanged;
  final ValueChanged<bool>? onTileCachingChanged;
  final ValueChanged<int>? onMaxMarkersChanged;
  final ValueChanged<int>? onMaxRoutePointsChanged;

  const MapPerformanceSettings({
    super.key,
    required this.performanceManager,
    this.onAnimationsChanged,
    this.onTileCachingChanged,
    this.onMaxMarkersChanged,
    this.onMaxRoutePointsChanged,
  });

  @override
  State<MapPerformanceSettings> createState() => _MapPerformanceSettingsState();
}

class _MapPerformanceSettingsState extends State<MapPerformanceSettings> {
  bool _enableAnimations = true;
  bool _enableTileCaching = true;
  int _maxMarkers = 50;
  int _maxRoutePoints = 1000;
  bool _showAdvancedSettings = false;

  @override
  Widget build(BuildContext context) {
    final performanceStatus = widget.performanceManager.getPerformanceStatus();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              const Icon(
                Icons.settings,
                color: Color(0xFFD10000),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Performans Ayarları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD10000),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showAdvancedSettings ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFFD10000),
                ),
                onPressed: () {
                  setState(() {
                    _showAdvancedSettings = !_showAdvancedSettings;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Performans durumu
          _buildPerformanceStatus(performanceStatus),
          const SizedBox(height: 16),

          // Temel ayarlar
          _buildBasicSettings(),
          
          // Gelişmiş ayarlar
          if (_showAdvancedSettings) ...[
            const SizedBox(height: 16),
            _buildAdvancedSettings(),
          ],

          // Cache temizleme butonu
          const SizedBox(height: 16),
          _buildCacheControls(),
        ],
      ),
    );
  }

  Widget _buildPerformanceStatus(MapPerformanceStatus status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.isOptimal ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status.isOptimal ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            status.isOptimal ? Icons.check_circle : Icons.warning,
            color: status.isOptimal ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                status.isOptimal ? 'Optimal Performans' : 'Performans Uyarısı',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: status.isOptimal ? Colors.green : Colors.orange,
                ),
              ),
              Text(
                'Marker: ${status.markerCount}, Rota: ${status.routePointCount}, Cache: ${status.cacheSize}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSettings() {
    return Column(
      children: [
        // Animasyonlar
        SwitchListTile(
          title: const Text('Animasyonlar'),
          subtitle: const Text('Marker ve rota animasyonları'),
          value: _enableAnimations,
          onChanged: (value) {
            setState(() {
              _enableAnimations = value;
            });
            widget.onAnimationsChanged?.call(value);
          },
          activeColor: const Color(0xFFD10000),
        ),

        // Tile Cache
        SwitchListTile(
          title: const Text('Tile Önbelleği'),
          subtitle: const Text('Harita tile\'larını önbellekte tut'),
          value: _enableTileCaching,
          onChanged: (value) {
            setState(() {
              _enableTileCaching = value;
            });
            widget.onTileCachingChanged?.call(value);
          },
          activeColor: const Color(0xFFD10000),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Gelişmiş Ayarlar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD10000),
          ),
        ),
        const SizedBox(height: 16),

        // Maksimum Marker Sayısı
        _buildSliderSetting(
          title: 'Maksimum Marker Sayısı',
          subtitle: '$_maxMarkers marker',
          value: _maxMarkers.toDouble(),
          min: 10,
          max: 200,
          divisions: 19,
          onChanged: (value) {
            setState(() {
              _maxMarkers = value.round();
            });
            widget.onMaxMarkersChanged?.call(_maxMarkers);
          },
        ),

        const SizedBox(height: 16),

        // Maksimum Rota Noktası Sayısı
        _buildSliderSetting(
          title: 'Maksimum Rota Noktası',
          subtitle: '$_maxRoutePoints nokta',
          value: _maxRoutePoints.toDouble(),
          min: 100,
          max: 5000,
          divisions: 49,
          onChanged: (value) {
            setState(() {
              _maxRoutePoints = value.round();
            });
            widget.onMaxRoutePointsChanged?.call(_maxRoutePoints);
          },
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: const Color(0xFFD10000),
        ),
      ],
    );
  }

  Widget _buildCacheControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              widget.performanceManager.clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache temizlendi'),
                  backgroundColor: Color(0xFFD10000),
                ),
              );
            },
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Cache Temizle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD10000),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              widget.performanceManager.cleanExpiredCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Eski cache temizlendi'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            icon: const Icon(Icons.cleaning_services, size: 18),
            label: const Text('Eski Cache'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
