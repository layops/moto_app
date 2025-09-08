import 'package:flutter/material.dart';
import '../core/theme/color_schemes.dart';

class GradientContainer extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GradientContainer({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  const GradientContainer.primary({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : colors = AppColorSchemes.primaryGradient,
       begin = Alignment.topLeft,
       end = Alignment.bottomRight;

  const GradientContainer.secondary({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : colors = AppColorSchemes.secondaryGradient,
       begin = Alignment.topLeft,
       end = Alignment.bottomRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? AppColorSchemes.primaryGradient,
          begin: begin,
          end: end,
        ),
        borderRadius: borderRadius,
      ),
      child: padding != null
          ? Padding(
              padding: padding!,
              child: child,
            )
          : child,
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GradientCard({
    super.key,
    required this.child,
    this.colors,
    this.elevation = 2.0,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? AppColorSchemes.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: padding != null
            ? Padding(
                padding: padding!,
                child: child,
              )
            : child,
      ),
    );
  }
}
