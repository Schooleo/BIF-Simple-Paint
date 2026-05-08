import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.backgroundCanvas,
    required this.backgroundSidebar,
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.surfaceFloating,
    required this.borderSubtle,
    required this.borderStrong,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.iconPrimary,
    required this.iconMuted,
    required this.iconActive,
    required this.shadowColor,
    required this.overlayHover,
    required this.overlayPressed,
    required this.overlayDisabled,
    required this.overlaySelection,
    required this.success,
    required this.warning,
    required this.error,
  });

  static const Color drawingFillTransparent = Color(0x00000000);
  static const Color drawingStrokeDefault = Color(0xFF000000);

  static const AppColors light = AppColors(
    backgroundPrimary: Color(0xFFFFFFFF),
    backgroundSecondary: Color(0xFFF5F7FF),
    backgroundCanvas: Color(0xFFF0F3FF),
    backgroundSidebar: Color(0xFFEFF3FF),
    surfacePrimary: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF8FAFC),
    surfaceFloating: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    accentPrimary: Color(0xFF2563EB),
    accentSecondary: Color(0xFF3B82F6),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    iconPrimary: Color(0xFF334155),
    iconMuted: Color(0xFF64748B),
    iconActive: Color(0xFF0F172A),
    shadowColor: Color(0x1A000000),
    overlayHover: Color(0x0D2563EB),
    overlayPressed: Color(0x1F2563EB),
    overlayDisabled: Color(0x1F94A3B8),
    overlaySelection: Color(0x332563EB),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
  );

  static const AppColors dark = AppColors(
    backgroundPrimary: Color(0xFF0B1020),
    backgroundSecondary: Color(0xFF111827),
    backgroundCanvas: Color(0xFF0F172A),
    backgroundSidebar: Color(0xFF111827),
    surfacePrimary: Color(0xFF111827),
    surfaceSecondary: Color(0xFF1F2937),
    surfaceFloating: Color(0xFF1E293B),
    borderSubtle: Color(0xFF243041),
    borderStrong: Color(0xFF334155),
    accentPrimary: Color(0xFF3B82F6),
    accentSecondary: Color(0xFF60A5FA),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    iconPrimary: Color(0xFFCBD5E1),
    iconMuted: Color(0xFF94A3B8),
    iconActive: Color(0xFFFFFFFF),
    shadowColor: Color(0x66000000),
    overlayHover: Color(0x143B82F6),
    overlayPressed: Color(0x263B82F6),
    overlayDisabled: Color(0x1F94A3B8),
    overlaySelection: Color(0x333B82F6),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
  );

  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color backgroundCanvas;
  final Color backgroundSidebar;
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color surfaceFloating;
  final Color borderSubtle;
  final Color borderStrong;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color iconPrimary;
  final Color iconMuted;
  final Color iconActive;
  final Color shadowColor;
  final Color overlayHover;
  final Color overlayPressed;
  final Color overlayDisabled;
  final Color overlaySelection;
  final Color success;
  final Color warning;
  final Color error;

  @override
  AppColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? backgroundCanvas,
    Color? backgroundSidebar,
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? surfaceFloating,
    Color? borderSubtle,
    Color? borderStrong,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? iconPrimary,
    Color? iconMuted,
    Color? iconActive,
    Color? shadowColor,
    Color? overlayHover,
    Color? overlayPressed,
    Color? overlayDisabled,
    Color? overlaySelection,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundCanvas: backgroundCanvas ?? this.backgroundCanvas,
      backgroundSidebar: backgroundSidebar ?? this.backgroundSidebar,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceFloating: surfaceFloating ?? this.surfaceFloating,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconMuted: iconMuted ?? this.iconMuted,
      iconActive: iconActive ?? this.iconActive,
      shadowColor: shadowColor ?? this.shadowColor,
      overlayHover: overlayHover ?? this.overlayHover,
      overlayPressed: overlayPressed ?? this.overlayPressed,
      overlayDisabled: overlayDisabled ?? this.overlayDisabled,
      overlaySelection: overlaySelection ?? this.overlaySelection,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }

    return AppColors(
      backgroundPrimary: Color.lerp(
        backgroundPrimary,
        other.backgroundPrimary,
        t,
      )!,
      backgroundSecondary: Color.lerp(
        backgroundSecondary,
        other.backgroundSecondary,
        t,
      )!,
      backgroundCanvas: Color.lerp(
        backgroundCanvas,
        other.backgroundCanvas,
        t,
      )!,
      backgroundSidebar: Color.lerp(
        backgroundSidebar,
        other.backgroundSidebar,
        t,
      )!,
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      surfaceFloating: Color.lerp(surfaceFloating, other.surfaceFloating, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      iconActive: Color.lerp(iconActive, other.iconActive, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      overlayHover: Color.lerp(overlayHover, other.overlayHover, t)!,
      overlayPressed: Color.lerp(overlayPressed, other.overlayPressed, t)!,
      overlayDisabled: Color.lerp(overlayDisabled, other.overlayDisabled, t)!,
      overlaySelection: Color.lerp(
        overlaySelection,
        other.overlaySelection,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
