import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AnimatedRoutePolyline extends StatefulWidget {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  final Duration animationDuration;
  final bool isAnimating;

  const AnimatedRoutePolyline({
    super.key,
    required this.points,
    this.color = const Color(0xFFD10000),
    this.strokeWidth = 5.0,
    this.animationDuration = const Duration(milliseconds: 2000),
    this.isAnimating = true,
  });

  @override
  State<AnimatedRoutePolyline> createState() => _AnimatedRoutePolylineState();
}

class _AnimatedRoutePolylineState extends State<AnimatedRoutePolyline>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<LatLng> _animatedPoints = [];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAnimating) {
      _animationController.forward();
    }

    _animation.addListener(() {
      _updateAnimatedPoints();
    });
  }

  @override
  void didUpdateWidget(AnimatedRoutePolyline oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.points != oldWidget.points) {
      _animationController.reset();
      if (widget.isAnimating) {
        _animationController.forward();
      }
    }
  }

  void _updateAnimatedPoints() {
    if (widget.points.isEmpty) return;

    final progress = _animation.value;
    final totalPoints = widget.points.length;
    final animatedPointCount = (totalPoints * progress).ceil();
    
    setState(() {
      _animatedPoints = widget.points.take(animatedPointCount).toList();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_animatedPoints.length < 2) {
      return const SizedBox.shrink();
    }

    return PolylineLayer(
      polylines: [
        Polyline(
          points: _animatedPoints,
          color: widget.color,
          strokeWidth: widget.strokeWidth,
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ),
      ],
    );
  }
}

class PulsingRoutePolyline extends StatefulWidget {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;

  const PulsingRoutePolyline({
    super.key,
    required this.points,
    this.color = const Color(0xFFD10000),
    this.strokeWidth = 5.0,
  });

  @override
  State<PulsingRoutePolyline> createState() => _PulsingRoutePolylineState();
}

class _PulsingRoutePolylineState extends State<PulsingRoutePolyline>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return PolylineLayer(
          polylines: [
            Polyline(
              points: widget.points,
              color: widget.color.withOpacity(_pulseAnimation.value),
              strokeWidth: widget.strokeWidth * _pulseAnimation.value,
              borderColor: Colors.white.withOpacity(_pulseAnimation.value * 0.8),
              borderStrokeWidth: 2 * _pulseAnimation.value,
            ),
          ],
        );
      },
    );
  }
}
