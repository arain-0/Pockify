import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PockifyLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showGlow; // Kept for compatibility but effect removed for seamless look

  const PockifyLogo({
    super.key,
    this.size = 120,
    this.showText = false,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    // Seamless coded logo only
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Container(
          width: size * 0.45,
          height: size * 0.45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: size * 0.12,
            ),
          ),
        ),
      ),
    );
  }
}

class PockifyAppIcon extends StatelessWidget {
  final double size;

  const PockifyAppIcon({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Container(
          width: size * 0.45,
          height: size * 0.45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: size * 0.12,
            ),
          ),
        ),
      ),
    );
  }
}


