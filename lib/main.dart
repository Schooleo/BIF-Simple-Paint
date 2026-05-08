import 'package:bif_simple_paint/core/routing/app_router.dart';
import 'package:bif_simple_paint/core/theme/app_theme.dart';
import 'package:bif_simple_paint/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: BifPaintApp()));
}

class BifPaintApp extends ConsumerWidget {
  const BifPaintApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'BIF Paint',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: AppRouter.canvasListPath,
      routes: AppRouter.routes,
    );
  }
}
