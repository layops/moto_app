import 'package:flutter/material.dart';

class OptimizedMotorcycleMarker extends StatefulWidget {
  final bool isSelected;
  final bool isPulsing;
  final Color? color;
  final IconData? icon;
  final double size;
  final bool enableAnimations;

  const OptimizedMotorcycleMarker({
    super.key,
    this.isSelected = false,
    this.isPulsing = false,
    this.color,
    this.icon,
    this.size = 50,
    this.enableAnimations = true,
  });

  @override
  State<OptimizedMotorcycleMarker> createState() => _OptimizedMotorcycleMarkerState();
}

class _OptimizedMotorcycleMarkerState extends State<OptimizedMotorcycleMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Tek AnimationController kullanarak performans artırımı
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isPulsing && widget.enableAnimations) {
      _animationController.repeat(reverse: true);
    } else if (widget.isSelected && widget.enableAnimations) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(OptimizedMotorcycleMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Sadece gerekli durumlarda animasyonu güncelle
    if (widget.enableAnimations) {
      if (widget.isPulsing != oldWidget.isPulsing) {
        if (widget.isPulsing) {
          _animationController.repeat(reverse: true);
        } else {
          _animationController.stop();
          _animationController.reset();
        }
      }

      if (widget.isSelected != oldWidget.isSelected) {
        if (widget.isSelected) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFFD10000);
    final icon = widget.icon ?? Icons.motorcycle;

    // Animasyonlar devre dışıysa basit widget döndür
    if (!widget.enableAnimations) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: widget.size * 0.5,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final scale = widget.isPulsing ? _pulseAnimation.value : 
                     (widget.isSelected ? _scaleAnimation.value : 1.0);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(widget.isPulsing ? 0.6 : 0.4),
                  blurRadius: widget.isPulsing ? 25 : 15,
                  spreadRadius: widget.isPulsing ? 5 : 3,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: widget.size * 0.5,
            ),
          ),
        );
      },
    );
  }
}

// Performans için optimize edilmiş marker listesi
class OptimizedMarkerLayer extends StatelessWidget {
  final List<OptimizedMarkerData> markers;
  final bool enableAnimations;

  const OptimizedMarkerLayer({
    super.key,
    required this.markers,
    this.enableAnimations = true,
  });

  @override
  Widget build(BuildContext context) {
    // Marker sayısına göre performans optimizasyonu
    if (markers.length > 100) {
      return _buildClusteredMarkers();
    }
    
    return _buildNormalMarkers();
  }

  Widget _buildNormalMarkers() {
    return Stack(
      children: markers.map((markerData) {
        return Positioned(
          left: markerData.position.dx - markerData.size / 2,
          top: markerData.position.dy - markerData.size / 2,
          child: OptimizedMotorcycleMarker(
            isSelected: markerData.isSelected,
            isPulsing: markerData.isPulsing,
            color: markerData.color,
            icon: markerData.icon,
            size: markerData.size,
            enableAnimations: enableAnimations,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClusteredMarkers() {
    // Çok fazla marker varsa clustering uygula
    return const SizedBox.shrink(); // Placeholder for clustering logic
  }
}

class OptimizedMarkerData {
  final Offset position;
  final bool isSelected;
  final bool isPulsing;
  final Color color;
  final IconData icon;
  final double size;

  const OptimizedMarkerData({
    required this.position,
    this.isSelected = false,
    this.isPulsing = false,
    this.color = const Color(0xFFD10000),
    this.icon = Icons.motorcycle,
    this.size = 50,
  });
}
