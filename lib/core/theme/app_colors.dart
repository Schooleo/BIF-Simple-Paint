import 'package:flutter/material.dart';

import 'raw_colors.dart';

abstract final class AppColors {
  static const Color background = RawColors.blueTint50;
  static const Color surface = RawColors.neutral0;
  static const Color sidebar = RawColors.blueTint75;
  static const Color border = RawColors.blueTint100;

  static const Color primary = RawColors.brandBlue500;
  static const Color primaryStrong = RawColors.brandBlue700;

  static const Color textPrimary = RawColors.neutral950;
  static const Color textSecondary = RawColors.neutral800;
  static const Color textMuted = RawColors.neutral500;

  static const Color icon = RawColors.neutral800;
  static const Color iconInactive = RawColors.neutral500;

  static const Color success = RawColors.success500;
  static const Color error = RawColors.error500;
  static const Color warning = RawColors.warning500;

  static const Color selection = RawColors.brandBlue500_20;
  static const Color selectionLight = RawColors.brandBlue500_05;
}
