import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The friendly shield mark used in headers and empty states.
class ShieldLogo extends StatelessWidget {
  const ShieldLogo({super.key, this.size = 48, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: onDark
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.teal, AppColors.primary],
              ),
        color: onDark ? Colors.white : null,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shield_rounded, color: onDark ? AppColors.primary : Colors.white, size: size * 0.58),
          Positioned(
            right: size * 0.12,
            top: size * 0.1,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: const BoxDecoration(color: AppColors.sunshine, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
