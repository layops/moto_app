import 'package:flutter/material.dart';

class MotorcycleMapTheme {
  static const Color primaryRed = Color(0xFFD10000);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color lightBackground = Color(0xFFF5F5F5);

  // Motosiklet ikonları
  static const IconData motorcycleIcon = Icons.motorcycle;
  static const IconData startIcon = Icons.play_arrow;
  static const IconData endIcon = Icons.flag;
  static const IconData gasStationIcon = Icons.local_gas_station;
  static const IconData repairIcon = Icons.build;
  static const IconData parkingIcon = Icons.local_parking;

  // Harita stilleri
  static BoxDecoration getMotorcycleMarkerDecoration({
    required Color color,
    bool isSelected = false,
    bool isPulsing = false,
  }) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white,
        width: 3,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(isPulsing ? 0.6 : 0.4),
          blurRadius: isPulsing ? 25 : 15,
          spreadRadius: isPulsing ? 5 : 3,
        ),
      ],
    );
  }

  // Rota çizgisi stilleri
  static PolylineStyle getRouteStyle({
    Color color = primaryRed,
    double strokeWidth = 5.0,
  }) {
    return PolylineStyle(
      color: color,
      strokeWidth: strokeWidth,
      borderColor: Colors.white,
      borderStrokeWidth: 2,
      isDotted: false,
    );
  }

  // Animasyon süreleri
  static const Duration markerAnimationDuration = Duration(milliseconds: 300);
  static const Duration routeAnimationDuration = Duration(milliseconds: 2000);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 1000);

  // Harita kontrolleri için stiller
  static Widget buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    Color iconColor = Colors.white,
    double size = 48.0,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Icon(
            icon,
            color: iconColor,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  // Harita arama çubuğu stili
  static InputDecoration getSearchInputDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText ?? 'Konum ara...',
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 16,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // Harita bilgi kartı stili
  static Widget buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PolylineStyle {
  final Color color;
  final double strokeWidth;
  final Color borderColor;
  final double borderStrokeWidth;
  final bool isDotted;

  const PolylineStyle({
    required this.color,
    required this.strokeWidth,
    required this.borderColor,
    required this.borderStrokeWidth,
    required this.isDotted,
  });
}
