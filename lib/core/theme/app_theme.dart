import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => ThemeData(useMaterial3: true);

  static ThemeData get darkTheme => ThemeData.dark(useMaterial3: true);
}
