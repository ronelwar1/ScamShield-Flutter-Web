import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/scan_result.dart';

/// Risk level shown as icon + text + color (never color alone).
class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.level});

  final RiskLevel level;

  static String label(RiskLevel l) {
    switch (l) {
      case RiskLevel.low:
        return 'LOW RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.high:
        return 'HIGH RISK';
    }
  }

  static IconData icon(RiskLevel l) {
    switch (l) {
      case RiskLevel.low:
        return Icons.check_circle_rounded;
      case RiskLevel.medium:
        return Icons.warning_amber_rounded;
      case RiskLevel.high:
        return Icons.dangerous_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.risk(level);
    return Semantics(
      label: label(level).toLowerCase(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.riskTint(level),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon(level), size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label(level),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
