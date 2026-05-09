import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme =>
      _buildTheme(colors: AppColors.light, brightness: Brightness.light);

  static ThemeData get darkTheme =>
      _buildTheme(colors: AppColors.dark, brightness: Brightness.dark);

  static ThemeData _buildTheme({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final Color onPrimary = brightness == Brightness.dark
        ? colors.textPrimary
        : colors.backgroundPrimary;
    final Color onSecondary = brightness == Brightness.dark
        ? colors.textPrimary
        : colors.backgroundPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: <ThemeExtension<dynamic>>[colors],
      scaffoldBackgroundColor: colors.backgroundPrimary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accentPrimary,
        onPrimary: onPrimary,
        secondary: colors.accentSecondary,
        onSecondary: onSecondary,
        error: colors.error,
        onError: colors.backgroundPrimary,
        surface: colors.surfacePrimary,
        onSurface: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.backgroundPrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        shadowColor: colors.shadowColor,
        iconTheme: IconThemeData(color: colors.iconPrimary),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ).copyWith(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceFloating,
        elevation: 12,
        shadowColor: colors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colors.iconPrimary),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.accentPrimary,
        inactiveTrackColor: colors.borderSubtle,
        thumbColor: colors.accentPrimary,
        overlayColor: colors.overlayHover,
        valueIndicatorColor: colors.surfaceFloating,
        valueIndicatorTextStyle: TextStyle(color: colors.textPrimary),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.surfaceFloating,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        textStyle: TextStyle(color: colors.textPrimary, fontSize: 12),
        waitDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}
