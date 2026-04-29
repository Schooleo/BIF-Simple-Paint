import 'package:bif_simple_paint/core/layout/responsive_split_view.dart';
import 'package:bif_simple_paint/features/canvas_list/views/screens/canvas_list_screen.dart';
import 'package:bif_simple_paint/features/drawing_board/views/screens/drawing_board_screen.dart';
import 'package:flutter/material.dart';

abstract final class AppRouter {
  static const String canvasListPath = '/';
  static const String drawingBoardPath = '/drawing-board';

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
    canvasListPath: (_) => const ResponsiveSplitView(
      mobile: CanvasListScreen(),
      desktop: DrawingBoardScreen(),
    ),
    drawingBoardPath: (_) => const ResponsiveSplitView(
      mobile: DrawingBoardScreen(),
      desktop: DrawingBoardScreen(),
    ),
  };
}
