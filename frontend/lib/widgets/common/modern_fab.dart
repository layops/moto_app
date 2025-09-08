import 'package:flutter/material.dart';
import '../../core/theme/color_schemes.dart';
import 'gradient_container.dart';

class ModernFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final String? label;
  final bool isExtended;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const ModernFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.label,
    this.isExtended = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  const ModernFAB.extended({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  }) : isExtended = true;

  @override
  Widget build(BuildContext context) {
    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: backgroundColor ?? AppColorSchemes.primaryColor,
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: elevation ?? 6.0,
        icon: Icon(icon),
        label: Text(
          label!,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColorSchemes.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorSchemes.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        child: Icon(
          icon,
          size: 28,
        ),
      ),
    );
  }
}

class AnimatedFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool isVisible;

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.isVisible = true,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.1,
            child: ModernFAB(
              onPressed: widget.onPressed,
              icon: widget.icon,
              tooltip: widget.tooltip,
            ),
          ),
        );
      },
    );
  }
}
