import 'package:flutter/material.dart';

import '../models/scan_result.dart';

/// Color palette. Risk colors are always paired with an icon and text label.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4F46E5);
  static const Color heroStart = Color(0xFF1E1B4B);
  static const Color heroEnd = Color(0xFF4338CA);
  static const Color background = Color(0xFFF5F6FB);
  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);

  static const Color riskLow = Color(0xFF15803D);
  static const Color riskMedium = Color(0xFFB45309);
  static const Color riskHigh = Color(0xFFB91C1C);

  static Color risk(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return riskLow;
      case RiskLevel.medium:
        return riskMedium;
      case RiskLevel.high:
        return riskHigh;
    }
  }

  static Color riskTint(RiskLevel level) =>
      risk(level).withValues(alpha: 0.08);
}
