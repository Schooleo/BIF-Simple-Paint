import 'package:bif_simple_paint/features/drawing_board/models/base_shape.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
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
          home: SizedBox(
            width: 200,
            height: 200,
            child: InteractiveCanvas(),
          ),
        ),
      ),
    );

    final canvasFinder = find.byType(InteractiveCanvas);
    final topLeft = tester.getTopLeft(canvasFinder);
    final startGlobal = topLeft + const Offset(10, 10);
    final endGlobal = topLeft + const Offset(100, 50);

    final gesture = await tester.startGesture(startGlobal);
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
    expect(shape.points.first, const Offset(10, 10));
    expect(shape.points.last, const Offset(100, 50));
  });
}
