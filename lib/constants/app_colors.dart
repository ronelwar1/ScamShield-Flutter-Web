import 'package:flutter/material.dart';

/// ScamShield's cheerful teal / mint palette with sunshine and coral accents.
/// Text-bearing colours are chosen to keep at least ~4.5:1 contrast with white or dark text.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0B7A74); // buttons, headers (white text OK)
  static const Color primaryDark = Color(0xFF0A4F4B); // sidebar, deep text
  static const Color teal = Color(0xFF19B5A8); // decorative gradients / accents
  static const Color mint = Color(0xFFDFF7F0);
  static const Color background = Color(0xFFF2FBF8);
  static const Color softAccent = Color(0xFFE3F5EF);
  static const Color border = Color(0xFFD3EBE4);
  static const Color text = Color(0xFF173532);
  static const Color mutedText = Color(0xFF56706B);
  static const Color white = Colors.white;

  // Cheerful accents
  static const Color sunshine = Color(0xFFFFD166);
  static const Color sunshineSoft = Color(0xFFFFF3CC);
  static const Color sunshineDeep = Color(0xFF8A5A00); // text on sunshine tints
  static const Color coral = Color(0xFFFF8A75);
  static const Color coralSoft = Color(0xFFFFE6E0);
  static const Color coralDeep = Color(0xFFD64532); // danger (white text OK)
  static const Color sky = Color(0xFFBFE8F5);
  static const Color grape = Color(0xFF7B6CF6);
  static const Color grapeSoft = Color(0xFFE9E6FF);

  // Status
  static const Color safe = Color(0xFF1E8E5A);
  static const Color safeSoft = Color(0xFFD7F5E6);
}
