import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/interactive_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dragCanvas_onPanGesture_commitsBrushStroke', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SizedBox(width: 200, height: 200, child: InteractiveCanvas()),
        ),
      ),
    );

    final canvasFinder = find.byType(InteractiveCanvas);
    final topLeft = tester.getTopLeft(canvasFinder);
    final startGlobal = topLeft + const Offset(10, 10);
    final endGlobal = topLeft + const Offset(100, 50);

    final gesture = await tester.startGesture(startGlobal);
    await tester.pump();
    const dragDelta = Offset(60, 20);
    await gesture.moveBy(dragDelta);
    await tester.pump();
    await gesture.moveTo(endGlobal);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final state = container.read(drawingBoardNotifierProvider);

    expect(state.activeTempShape, isNull);
    expect(state.finalizedShapes, hasLength(1));

    final shape = state.finalizedShapes.single as BrushShape;
    expect(shape.points.length, greaterThanOrEqualTo(2));
    expect(shape.points.first, const Offset(10, 10) + dragDelta);
    expect(shape.points.last, const Offset(100, 50));
  });

  testWidgets('tapCanvas_selectsTopMostShape_whenCursorTool', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(drawingBoardNotifierProvider.notifier);
    notifier.startDrawing(
      const Offset(20, 20),
      const ToolSelectionState(toolType: ToolType.shape),
    );
    notifier.updateDrawing(const Offset(120, 120));
    notifier.commitDrawing();

    notifier.startDrawing(
      const Offset(60, 60),
      const ToolSelectionState(toolType: ToolType.shape),
    );
    notifier.updateDrawing(const Offset(160, 160));
    notifier.commitDrawing();

    final shapes =
        container.read(drawingBoardNotifierProvider).finalizedShapes;
    final backId = shapes.first.id;
    final topId = shapes.last.id;
    notifier.selectShape(backId);

    container
        .read(toolSelectionNotifierProvider.notifier)
        .selectTool(ToolType.cursor);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SizedBox(width: 200, height: 200, child: InteractiveCanvas()),
        ),
      ),
    );

    final canvasFinder = find.byType(InteractiveCanvas);
    final topLeft = tester.getTopLeft(canvasFinder);
    await tester.tapAt(topLeft + const Offset(80, 80));
    await tester.pump();

    final selectedId =
        container.read(drawingBoardNotifierProvider).selectedShapeId;
    expect(selectedId, topId);
    await tester.pumpAndSettle();
  });
}
