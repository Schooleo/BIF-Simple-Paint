import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_mobile_layout.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/interactive_canvas.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/tool_palette.dart';
import 'package:flutter/material.dart';

class DrawingBoardScreen extends StatelessWidget {
  const DrawingBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;

    if (screenWidth < _desktopBreakpoint) {
      return const Scaffold(body: MobileLayout());
    }

    return const Scaffold(body: DesktopLayout());
  }
}

const double _desktopBreakpoint = 800;

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const CanvasArea();
  }
}

class CanvasArea extends StatelessWidget {
  const CanvasArea({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.backgroundCanvas;
    final Color textColor = colors.textMuted;

    return Container(
      color: background,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: InteractiveCanvas()),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Drawing Board',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: textColor),
              ),
            ),
          ),
          const Positioned(top: 24, right: 24, child: ToolPalette()),
        ],
      ),
    );
  }
}
