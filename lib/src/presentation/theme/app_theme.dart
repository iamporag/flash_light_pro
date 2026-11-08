import 'package:flutter/material.dart';

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
}

ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      onPrimary: const Color(0xFF201A05),
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
      inactiveTrackColor: Color(0x33FFFFFF),
      overlayColor: Color(0x33FFC94D),
      valueIndicatorColor: AppColors.accent,
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: Color(0x33FFFFFF)),
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
    dividerTheme: const DividerThemeData(color: Color(0x1FFFFFFF)),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
  );
}
