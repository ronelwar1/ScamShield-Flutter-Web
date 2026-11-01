import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Visual treatment for a verdict. Never relies on colour alone: every style has an icon and a word.
class StatusStyle {
  const StatusStyle({
    required this.accent,
    required this.soft,
    required this.onSoft,
    required this.icon,
    required this.emoji,
    required this.short,
  });

  final Color accent; // strong colour for gauges / borders
  final Color soft; // tinted background
  final Color onSoft; // readable text on [soft]
  final IconData icon;
  final String emoji;
  final String short;
}

const StatusStyle _likely = StatusStyle(
  accent: AppColors.coralDeep,
  soft: AppColors.coralSoft,
  onSoft: Color(0xFF8E1F10),
  icon: Icons.gpp_bad_rounded,
  emoji: '🚨',
  short: 'Likely scam',
);

const StatusStyle _suspicious = StatusStyle(
  accent: Color(0xFFE8A200),
  soft: AppColors.sunshineSoft,
  onSoft: AppColors.sunshineDeep,
  icon: Icons.gpp_maybe_rounded,
  emoji: '🧐',
  short: 'Be careful',
);

const StatusStyle _clear = StatusStyle(
  accent: AppColors.safe,
  soft: AppColors.safeSoft,
  onSoft: Color(0xFF0F5C3A),
  icon: Icons.gpp_good_rounded,
  emoji: '🙂',
  short: 'No obvious signs',
);

StatusStyle statusForLabel(String label) {
  switch (label) {
    case 'likely_scam':
    case 'high_risk':
      return _likely;
    case 'suspicious':
      return _suspicious;
    default:
      return _clear;
  }
}

/// Severity of an individual signal / finding.
StatusStyle statusForSeverity(String severity) {
  switch (severity) {
    case 'high':
      return _likely;
    case 'medium':
      return _suspicious;
    case 'low':
      return const StatusStyle(
        accent: AppColors.grape,
        soft: AppColors.grapeSoft,
        onSoft: Color(0xFF3B2FA8),
        icon: Icons.info_outline_rounded,
        emoji: 'ℹ️',
        short: 'Minor',
      );
    default:
      return _clear;
  }
}
