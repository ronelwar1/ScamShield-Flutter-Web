import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Central theme. Kept deliberately small (no component-theme classes whose names change between
/// Flutter releases); individual widgets set their own shapes where needed.
abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.sunshine,
      tertiary: AppColors.coral,
      surface: Colors.white,
    );
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary, 2),
        errorBorder: border(AppColors.coralDeep),
        focusedErrorBorder: border(AppColors.coralDeep, 2),
      ),
    );
  }
}

/// Breakpoints shared by every screen.
abstract final class Breakpoints {
  static const double tablet = 720;
  static const double desktop = 1100;

  static bool isMobile(double width) => width < tablet;
  static bool isDesktop(double width) => width >= desktop;
}
