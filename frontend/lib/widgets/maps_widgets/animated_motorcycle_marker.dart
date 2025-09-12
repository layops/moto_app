import 'package:flutter/material.dart';

class AnimatedMotorcycleMarker extends StatefulWidget {
  final bool isSelected;
  final bool isPulsing;
  final Color? color;
  final IconData? icon;
  final double size;

  const AnimatedMotorcycleMarker({
    super.key,
    this.isSelected = false,
    this.isPulsing = false,
    this.color,
    this.icon,
    this.size = 50,
  });

  @override
  State<AnimatedMotorcycleMarker> createState() => _AnimatedMotorcycleMarkerState();
}

class _AnimatedMotorcycleMarkerState extends State<AnimatedMotorcycleMarker>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    if (widget.isPulsing) {
      _pulseController.repeat(reverse: true);
    }

    if (widget.isSelected) {
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedMotorcycleMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFFD10000);
    final icon = widget.icon ?? Icons.motorcycle;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPulsing ? _pulseAnimation.value : 1.0,
          child: Transform.scale(
            scale: widget.isSelected ? _scaleAnimation.value : 1.0,
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
                    color: color.withOpacity(0.4),
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
          ),
        );
      },
    );
  }
}
