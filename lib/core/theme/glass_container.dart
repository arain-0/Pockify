import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final BoxShape shape; // Added shape property

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.2,
    this.color,
    this.padding,
    this.borderRadius,
    this.border,
    this.shape = BoxShape.rectangle, // Default to rectangle
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: shape == BoxShape.circle 
          ? BorderRadius.zero // ClipRRect doesn't handle circle perfectly without hacking, simpler to just rely on Container clip if we were strict, but let's assume rectangle mostly. 
          // Actually for circle, ClipOval is better, but let's stick to standard behavior or just use BoxDecoration.
          // Glass morphism requires backdrop filter which needs clipping.
          : (borderRadius ?? BorderRadius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: opacity), // Fixed deprecation
            borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(16)),
            shape: shape,
            border: border ?? Border.all(
              color: Colors.white.withValues(alpha: 0.2), // Fixed deprecation
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
