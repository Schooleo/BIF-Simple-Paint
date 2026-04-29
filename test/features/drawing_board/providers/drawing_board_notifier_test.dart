import 'dart:collection';
import 'dart:io';

import 'package:bif_simple_paint/features/drawing_board/models/base_shape.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrawingBoardNotifier', () {
    late ProviderContainer container;
    late DrawingBoardNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(drawingBoardNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty with no active preview', () {
      final state = container.read(drawingBoardNotifierProvider);

      expect(state.finalizedShapes, isEmpty);
      expect(state.activeTempShape, isNull);
    });

    test(
      'startDrawing seeds a brush preview without changing committed shapes',
      () {
        final before = container.read(drawingBoardNotifierProvider);

        notifier.startDrawing(const Offset(1, 2), ToolType.brush);

        final after = container.read(drawingBoardNotifierProvider);
        final activeTempShape = after.activeTempShape;

        expect(
          identical(before.finalizedShapes, after.finalizedShapes),
          isTrue,
        );
        expect(activeTempShape, isA<BrushShape>());
        expect((activeTempShape! as BrushShape).points, <Offset>[
          const Offset(1, 2),
        ]);
      },
    );

    test(
      'startDrawing seeds an eraser preview without changing committed shapes',
      () {
        final before = container.read(drawingBoardNotifierProvider);

        notifier.startDrawing(const Offset(3, 4), ToolType.eraser);

        final after = container.read(drawingBoardNotifierProvider);
        final activeTempShape = after.activeTempShape;

        expect(
          identical(before.finalizedShapes, after.finalizedShapes),
          isTrue,
        );
        expect(activeTempShape, isA<EraserShape>());
        expect((activeTempShape! as EraserShape).points, <Offset>[
          const Offset(3, 4),
        ]);
      },
    );

    test('startDrawing maps ToolType.shape to rectangle preview', () {
      final before = container.read(drawingBoardNotifierProvider);

      notifier.startDrawing(const Offset(5, 6), ToolType.shape);

      final after = container.read(drawingBoardNotifierProvider);
      final activeTempShape = after.activeTempShape;

      expect(identical(before.finalizedShapes, after.finalizedShapes), isTrue);
      expect(activeTempShape, isA<RectangleShape>());
      expect(
        activeTempShape,
        const RectangleShape(start: Offset(5, 6), end: Offset(5, 6)),
      );
    });

    test('updateDrawing is a no-op before startDrawing', () {
      final before = container.read(drawingBoardNotifierProvider);

      notifier.updateDrawing(const Offset(7, 8));

      final after = container.read(drawingBoardNotifierProvider);

      expect(identical(before.finalizedShapes, after.finalizedShapes), isTrue);
      expect(after.activeTempShape, isNull);
    });

    test('commitDrawing is a no-op before startDrawing', () {
      final before = container.read(drawingBoardNotifierProvider);

      notifier.commitDrawing();

      final after = container.read(drawingBoardNotifierProvider);

      expect(identical(before.finalizedShapes, after.finalizedShapes), isTrue);
      expect(after.activeTempShape, isNull);
    });

    test(
      'updateDrawing appends to brush preview and keeps committed list identity',
      () {
        notifier.startDrawing(const Offset(0, 0), ToolType.brush);
        final afterStart = container.read(drawingBoardNotifierProvider);

        notifier.updateDrawing(const Offset(9, 9));

        final afterUpdate = container.read(drawingBoardNotifierProvider);
        final activeTempShape = afterUpdate.activeTempShape;

        expect(
          identical(afterStart.finalizedShapes, afterUpdate.finalizedShapes),
          isTrue,
        );
        expect(activeTempShape, isA<BrushShape>());
        expect((activeTempShape! as BrushShape).points, <Offset>[
          const Offset(0, 0),
          const Offset(9, 9),
        ]);
      },
    );

    test('repeated updates keep committed list identity stable', () {
      notifier.startDrawing(const Offset(0, 0), ToolType.eraser);
      final afterStart = container.read(drawingBoardNotifierProvider);

      notifier.updateDrawing(const Offset(1, 1));
      final afterFirstUpdate = container.read(drawingBoardNotifierProvider);

      notifier.updateDrawing(const Offset(2, 2));
      final afterSecondUpdate = container.read(drawingBoardNotifierProvider);

      expect(
        identical(afterStart.finalizedShapes, afterFirstUpdate.finalizedShapes),
        isTrue,
      );
      expect(
        identical(
          afterFirstUpdate.finalizedShapes,
          afterSecondUpdate.finalizedShapes,
        ),
        isTrue,
      );
      expect(
        (afterSecondUpdate.activeTempShape! as EraserShape).points,
        <Offset>[const Offset(0, 0), const Offset(1, 1), const Offset(2, 2)],
      );
    });

    test('updateDrawing updates rectangle end point only', () {
      notifier.startDrawing(const Offset(2, 3), ToolType.shape);

      notifier.updateDrawing(const Offset(8, 13));

      final activeTempShape = container
          .read(drawingBoardNotifierProvider)
          .activeTempShape;

      expect(
        activeTempShape,
        const RectangleShape(start: Offset(2, 3), end: Offset(8, 13)),
      );
    });

    test(
      'commitDrawing appends preview exactly once and clears active preview',
      () {
        notifier.startDrawing(const Offset(1, 1), ToolType.brush);
        notifier.updateDrawing(const Offset(2, 2));
        final beforeCommit = container.read(drawingBoardNotifierProvider);

        notifier.commitDrawing();

        final afterCommit = container.read(drawingBoardNotifierProvider);

        expect(
          identical(beforeCommit.finalizedShapes, afterCommit.finalizedShapes),
          isFalse,
        );
        expect(afterCommit.activeTempShape, isNull);
        expect(afterCommit.finalizedShapes, hasLength(1));
        expect(afterCommit.finalizedShapes.single, isA<BrushShape>());
        expect(
          (afterCommit.finalizedShapes.single as BrushShape).points,
          <Offset>[const Offset(1, 1), const Offset(2, 2)],
        );
      },
    );

    test(
      'startDrawing during active preview replaces abandoned preview without commit',
      () {
        notifier.startDrawing(const Offset(1, 1), ToolType.brush);
        notifier.updateDrawing(const Offset(2, 2));
        final beforeRestart = container.read(drawingBoardNotifierProvider);

        notifier.startDrawing(const Offset(10, 10), ToolType.shape);

        final afterRestart = container.read(drawingBoardNotifierProvider);

        expect(
          identical(
            beforeRestart.finalizedShapes,
            afterRestart.finalizedShapes,
          ),
          isTrue,
        );
        expect(afterRestart.finalizedShapes, isEmpty);
        expect(
          afterRestart.activeTempShape,
          const RectangleShape(start: Offset(10, 10), end: Offset(10, 10)),
        );
      },
    );

    test('finalizedShapes exposure is unmodifiable', () {
      notifier.startDrawing(const Offset(1, 1), ToolType.eraser);
      notifier.commitDrawing();

      final finalizedShapes = container
          .read(drawingBoardNotifierProvider)
          .finalizedShapes;

      expect(finalizedShapes, isA<UnmodifiableListView<BaseShape>>());
      expect(
        () => finalizedShapes.add(BrushShape.seed(const Offset(3, 3))),
        throwsUnsupportedError,
      );
    });

    test('boundary imports stay out of notifier and shape models', () {
      final notifierSource = File(
        'lib/features/drawing_board/providers/drawing_board_notifier.dart',
      ).readAsStringSync();
      final shapeSource = File(
        'lib/features/drawing_board/models/base_shape.dart',
      ).readAsStringSync();

      expect(shapeSource, contains('sealed class BaseShape'));
      expect(notifierSource, isNot(contains('loadSession')));
      expect(notifierSource, isNot(contains('addStroke')));
      expect(notifierSource, isNot(contains('undo()')));
      expect(notifierSource, isNot(contains('redo()')));

      for (final source in <String>[notifierSource, shapeSource]) {
        expect(source, isNot(contains('toolSelectionNotifierProvider')));
        expect(source, isNot(contains('stroke_data.dart')));
        expect(source, isNot(contains('drawingSessionRepositoryProvider')));
        expect(source, isNot(contains('drawing_session_repository.dart')));
        expect(source, isNot(contains('color')));
        expect(source, isNot(contains('thickness')));
      }
    });
  });
}
