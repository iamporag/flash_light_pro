import 'package:flutter/material.dart';

/// Shared visual tokens for the dark premium theme.
///
/// Component-specific decoration (gradients, glows) stays with its widget; the
/// values here are the ones shared by more than one screen or by the theme.
abstract final class AppColors {
  static const Color accent = Color(0xFFFFC94D);
  static const Color accentAlt = Color(0xFF6FD3FF);
  static const Color background = Color(0xFF0A0F1E);
  static const Color backgroundGlow = Color(0xFF1B2542);
  static const Color surface = Color(0xFF161D31);
  static const Color surfaceHigh = Color(0xFF232D49);
  static const Color textPrimary = Color(0xFFF4F6FF);
  static const Color textMuted = Color(0xFF9BA5C2);
  static const Color danger = Color(0xFFFF6B6B);

  static const Color warm = Color(0xFFFFD9A0);
  static const Color neutral = Color(0xFFFFFFFF);
  static const Color cool = Color(0xFFCCE4FF);

  static const Color onAccent = Color(0xFF201A05);
  static const Color track = Color(0x33FFFFFF);
  static const Color accentOverlay = Color(0x33FFC94D);
  static const Color divider = Color(0x1FFFFFFF);
  static const Color surfaceBorder = Color(0x14FFFFFF);
}

/// Shared spacing steps used across screens and cards.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 32;
}

/// Shared corner radii.
abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
}

/// Shared motion durations. Screens that honour reduced motion pass
/// [Duration.zero] instead.
abstract final class AppDurations {
  static const Duration chip = Duration(milliseconds: 220);
  static const Duration quick = Duration(milliseconds: 180);
}

ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accentAlt,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.accent,
      thumbColor: AppColors.accent,
      inactiveTrackColor: AppColors.track,
      overlayColor: AppColors.accentOverlay,
      valueIndicatorColor: AppColors.accent,
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: AppColors.track),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      showDragHandle: true,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
  );
}
