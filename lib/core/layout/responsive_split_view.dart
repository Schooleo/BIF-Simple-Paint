import 'package:bif_simple_paint/features/canvas_list/views/screens/canvas_list_screen.dart';
import 'package:bif_simple_paint/features/drawing_board/views/screens/drawing_board_screen.dart';
import 'package:flutter/material.dart';

const double _desktopBreakpoint = 800;

class ResponsiveSplitView extends StatelessWidget {
  const ResponsiveSplitView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (screenWidth < _desktopBreakpoint) {
      return child;
    }

    return const Row(
      children: <Widget>[
        Expanded(flex: 1, child: CanvasListScreen()),
        Expanded(flex: 3, child: DrawingBoardScreen()),
      ],
    );
  }
}
