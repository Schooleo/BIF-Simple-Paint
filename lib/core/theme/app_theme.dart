import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    extensions: const <ThemeExtension<dynamic>>[AppColors.light],
  );

  static ThemeData get darkTheme => ThemeData.dark(
    useMaterial3: true,
  ).copyWith(extensions: const <ThemeExtension<dynamic>>[AppColors.dark]);
}
