import 'package:bif_simple_paint/core/routing/app_router.dart';
import 'package:bif_simple_paint/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: BifPaintApp()));
}

class BifPaintApp extends StatelessWidget {
  const BifPaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIF Paint',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: AppRouter.canvasListPath,
      routes: AppRouter.routes,
    );
  }
}
