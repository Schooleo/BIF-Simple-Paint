import 'dart:io';
import 'dart:ui';

import 'package:bif_simple_paint/features/drawing_board/models/base_shape.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
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

    ToolSelectionState selection({
      ToolType toolType = ToolType.brush,
      Color fillColor = const Color(0x00000000),
      Color strokeColor = const Color(0xFF000000),
      double strokeWidth = 2,
    }) {
      return ToolSelectionState(
        toolType: toolType,
        currentFillColor: fillColor,
        currentStrokeColor: strokeColor,
        currentStrokeWidth: strokeWidth,
      );
    }

    test('initial state is empty with no active preview or history', () {
      final state = container.read(drawingBoardNotifierProvider);

      expect(state.finalizedShapes, isEmpty);
      expect(state.activeTempShape, isNull);
      expect(state.selectedShapeId, isNull);
      expect(state.undoStack, isEmpty);
      expect(state.redoStack, isEmpty);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
    });

    test(
      'startDrawing seeds a styled brush preview without history changes',
      () {
        notifier.startDrawing(
          const Offset(1, 2),
          selection(strokeColor: const Color(0xFF00FF00), strokeWidth: 5),
        );

        final state = container.read(drawingBoardNotifierProvider);
        final activeTempShape = state.activeTempShape as BrushShape;

        expect(activeTempShape.points, <Offset>[const Offset(1, 2)]);
        expect(activeTempShape.strokeColor, const Color(0xFF00FF00));
        expect(activeTempShape.strokeWidth, 5);
        expect(state.undoStack, isEmpty);
        expect(state.redoStack, isEmpty);
      },
    );

    test('startDrawing maps ToolType.shape to styled rectangle preview', () {
      notifier.startDrawing(
        const Offset(5, 6),
        selection(
          toolType: ToolType.shape,
          fillColor: const Color(0x2200FF00),
          strokeColor: const Color(0xFF123456),
          strokeWidth: 7,
        ),
      );

      final activeTempShape =
          container.read(drawingBoardNotifierProvider).activeTempShape
              as RectangleShape;

      expect(activeTempShape.start, const Offset(5, 6));
      expect(activeTempShape.end, const Offset(5, 6));
      expect(activeTempShape.fillColor, const Color(0x2200FF00));
      expect(activeTempShape.strokeColor, const Color(0xFF123456));
      expect(activeTempShape.strokeWidth, 7);
      expect(activeTempShape.id, isNotEmpty);
    });

    test('updateDrawing is a no-op before startDrawing', () {
      final before = container.read(drawingBoardNotifierProvider);

      notifier.updateDrawing(const Offset(7, 8));

      final after = container.read(drawingBoardNotifierProvider);

      expect(after.finalizedShapes, before.finalizedShapes);
      expect(after.activeTempShape, isNull);
    });

    test('commitDrawing pushes a finalized snapshot onto the undo stack', () {
      notifier.startDrawing(const Offset(1, 1), selection());
      notifier.updateDrawing(const Offset(2, 2));

      notifier.commitDrawing();

      final state = container.read(drawingBoardNotifierProvider);
      final committedShape = state.finalizedShapes.single as BrushShape;

      expect(state.activeTempShape, isNull);
      expect(state.finalizedShapes, hasLength(1));
      expect(committedShape.points, <Offset>[
        const Offset(1, 1),
        const Offset(2, 2),
      ]);
      expect(committedShape.isFinalized, isTrue);
      expect(state.undoStack, hasLength(1));
      expect(state.undoStack.single, isEmpty);
      expect(state.redoStack, isEmpty);
      expect(state.selectedShapeId, committedShape.id);
    });

    test('selectShape picks the committed shape by id', () {
      notifier.startDrawing(const Offset(1, 1), selection());
      notifier.commitDrawing();
      final shapeId = container
          .read(drawingBoardNotifierProvider)
          .finalizedShapes
          .single
          .id;

      notifier.selectShape(shapeId);

      final state = container.read(drawingBoardNotifierProvider);
      expect(state.selectedShapeId, shapeId);
      expect(state.selectedShape?.id, shapeId);
    });

    test(
      'updateSelectedShapeStyle commits a detached snapshot for undo history',
      () {
        notifier.startDrawing(const Offset(1, 1), selection());
        notifier.commitDrawing();
        final shapeId = container
            .read(drawingBoardNotifierProvider)
            .finalizedShapes
            .single
            .id;
        notifier.selectShape(shapeId);

        notifier.updateSelectedShapeStyle(
          strokeColor: const Color(0xFFFF0000),
          strokeWidth: 8,
        );

        final state = container.read(drawingBoardNotifierProvider);
        final currentShape = state.finalizedShapes.single as BrushShape;
        final historicalShape = state.undoStack.last.single as BrushShape;

        expect(currentShape.strokeColor, const Color(0xFFFF0000));
        expect(currentShape.strokeWidth, 8);
        expect(historicalShape.strokeColor, const Color(0xFF000000));
        expect(historicalShape.strokeWidth, 2);
        expect(identical(currentShape, historicalShape), isFalse);
        expect(state.redoStack, isEmpty);
      },
    );

    test(
      'undo and redo restore cloned snapshots without leaking style mutations',
      () {
        notifier.startDrawing(const Offset(1, 1), selection());
        notifier.commitDrawing();
        final shapeId = container
            .read(drawingBoardNotifierProvider)
            .finalizedShapes
            .single
            .id;
        notifier.selectShape(shapeId);
        notifier.updateSelectedShapeStyle(
          strokeColor: const Color(0xFFFF0000),
          strokeWidth: 8,
        );

        notifier.undo();
        var state = container.read(drawingBoardNotifierProvider);
        var shape = state.finalizedShapes.single as BrushShape;

        expect(shape.strokeColor, const Color(0xFF000000));
        expect(shape.strokeWidth, 2);
        expect(state.redoStack, hasLength(1));

        notifier.redo();
        state = container.read(drawingBoardNotifierProvider);
        shape = state.finalizedShapes.single as BrushShape;

        expect(shape.strokeColor, const Color(0xFFFF0000));
        expect(shape.strokeWidth, 8);
        expect(state.undoStack, hasLength(2));
        expect(state.redoStack, isEmpty);
      },
    );

    test('new actions after undo clear the redo stack', () {
      notifier.startDrawing(const Offset(1, 1), selection());
      notifier.commitDrawing();
      final shapeId = container
          .read(drawingBoardNotifierProvider)
          .finalizedShapes
          .single
          .id;
      notifier.selectShape(shapeId);
      notifier.updateSelectedShapeStyle(strokeWidth: 6);
      notifier.undo();

      notifier.updateSelectedShapeStyle(strokeColor: const Color(0xFF00FF00));

      final state = container.read(drawingBoardNotifierProvider);
      expect(state.redoStack, isEmpty);
      expect(
        (state.finalizedShapes.single as BrushShape).strokeColor,
        const Color(0xFF00FF00),
      );
    });

    test('updateSelectedShapeStyle is a no-op without a selection', () {
      notifier.startDrawing(const Offset(1, 1), selection());
      notifier.commitDrawing();
      notifier.selectShape('missing-shape');
      final before = container.read(drawingBoardNotifierProvider);

      notifier.updateSelectedShapeStyle(strokeWidth: 10);

      final after = container.read(drawingBoardNotifierProvider);
      expect(after.finalizedShapes.single, before.finalizedShapes.single);
      expect(after.undoStack, before.undoStack);
      expect(after.redoStack, before.redoStack);
      expect(after.selectedShapeId, isNull);
    });

    test('finalizedShapes exposure is unmodifiable', () {
      notifier.startDrawing(const Offset(1, 1), selection());
      notifier.commitDrawing();

      final finalizedShapes = container
          .read(drawingBoardNotifierProvider)
          .finalizedShapes;

      expect(
        () => finalizedShapes.add(BrushShape.seed(const Offset(3, 3))),
        throwsUnsupportedError,
      );
    });

    test('provider implementation stays isolated from repository concerns', () {
      final notifierSource = File(
        'lib/features/drawing_board/providers/drawing_board_notifier.dart',
      ).readAsStringSync();
      final shapeSource = File(
        'lib/features/drawing_board/models/base_shape.dart',
      ).readAsStringSync();

      expect(shapeSource, contains('BaseShape copyStyle'));
      expect(shapeSource, contains('BaseShape clone'));
      expect(notifierSource, contains('void undo()'));
      expect(notifierSource, contains('void redo()'));
      expect(notifierSource, contains('void selectShape(String id)'));
      expect(notifierSource, contains('void updateSelectedShapeStyle'));

      for (final source in <String>[notifierSource, shapeSource]) {
        expect(source, isNot(contains('loadSession')));
        expect(source, isNot(contains('addStroke')));
        expect(source, isNot(contains('stroke_data.dart')));
        expect(source, isNot(contains('drawingSessionRepositoryProvider')));
        expect(source, isNot(contains('drawing_session_repository.dart')));
      }
    });
  });
}
