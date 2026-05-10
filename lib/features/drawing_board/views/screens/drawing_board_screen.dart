import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_mobile_layout.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/interactive_canvas.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/tool_palette.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class CanvasArea extends ConsumerWidget {
  const CanvasArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.backgroundCanvas;
    final Color textColor = colors.textMuted;

    return Container(
      color: background,
      child: DropTarget(
        onDragDone: (details) async {
          if (details.files.isEmpty) {
            return;
          }

          final file = details.files.first;
          final name = file.name.toLowerCase();
          if (!name.endsWith('.mypt')) {
            return;
          }

          final bytes = await file.readAsBytes();
          if (!context.mounted) {
            return;
          }

          ref.read(drawingBoardNotifierProvider.notifier).loadFromBytes(bytes);
        },
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
      ),
    );
  }
}
