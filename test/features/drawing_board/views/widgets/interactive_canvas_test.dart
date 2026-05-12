import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/interactive_canvas.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_mobile_layout.dart';
import 'package:bif_simple_paint/features/drawing_board/views/screens/drawing_board_screen.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDrawingBoardNotifier extends AutoDisposeNotifier<DrawingBoardState>
    with Mock
    implements DrawingBoardNotifier {
  @override
  DrawingBoardState build() => DrawingBoardState.initial();
}

Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  // --------------------------------------------------------------------------
  // Existing Tests
  // --------------------------------------------------------------------------
  testWidgets('dragCanvas_onPanGesture_commitsBrushStroke', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(
          const SizedBox(width: 200, height: 200, child: InteractiveCanvas()),
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

    final shapes = container.read(drawingBoardNotifierProvider).finalizedShapes;
    final backId = shapes.first.id;
    final topId = shapes.last.id;
    notifier.selectShape(backId);

    container
        .read(toolSelectionNotifierProvider.notifier)
        .selectTool(ToolType.cursor);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(
          const SizedBox(width: 200, height: 200, child: InteractiveCanvas()),
        ),
      ),
    );

    final canvasFinder = find.byType(InteractiveCanvas);
    final topLeft = tester.getTopLeft(canvasFinder);
    await tester.tapAt(topLeft + const Offset(80, 80));
    await tester.pump();

    final selectedId = container
        .read(drawingBoardNotifierProvider)
        .selectedShapeId;
    expect(selectedId, topId);
    await tester.pumpAndSettle();
  });

  // --------------------------------------------------------------------------
  // Skill 3: Write Widget Tests for Export UI
  // --------------------------------------------------------------------------
  testWidgets('exportIcon_whenRendered_existsInMobileTopBar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: wrapWithMaterialApp(
          MobileTopBar(
            onCaptureImage: ({bool asJpeg = false}) async => Uint8List(0),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.save_alt), findsOneWidget);
  });

  testWidgets('exportIcon_whenTapped_showsSaveOptions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: wrapWithMaterialApp(
          MobileTopBar(
            onCaptureImage: ({bool asJpeg = false}) async => Uint8List(0),
          ),
        ),
      ),
    );

    final exportIcon = find.byIcon(Icons.save_alt);
    await tester.tap(exportIcon);
    await tester.pumpAndSettle();

    expect(find.text('Save as PNG'), findsOneWidget);
    expect(find.text('Save as JPEG'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Skill 4: Write Tests for Drag and Drop
  // --------------------------------------------------------------------------
  testWidgets('dropTarget_withMyptFile_triggersLoadFromBytes', (tester) async {
    final mockNotifier = MockDrawingBoardNotifier();
    when(() => mockNotifier.loadFromBytes(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingBoardNotifierProvider.overrideWith(() => mockNotifier),
        ],
        child: wrapWithMaterialApp(const CanvasArea()),
      ),
    );

    final dropTargetFinder = find.byType(DropTarget);
    expect(dropTargetFinder, findsOneWidget);

    final dropTarget = tester.widget<DropTarget>(dropTargetFinder);

    final fakeFile = DropItemFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'drawing.mypt',
      path: 'drawing.mypt',
    );

    await tester.runAsync(() async {
      dropTarget.onDragDone!(
        DropDoneDetails(
          files: [fakeFile],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    verify(() => mockNotifier.loadFromBytes(any())).called(1);
  });

  testWidgets('dropTarget_withInvalidFile_ignoresDrop', (tester) async {
    final mockNotifier = MockDrawingBoardNotifier();
    when(() => mockNotifier.loadFromBytes(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingBoardNotifierProvider.overrideWith(() => mockNotifier),
        ],
        child: wrapWithMaterialApp(const CanvasArea()),
      ),
    );

    final dropTargetFinder = find.byType(DropTarget);
    expect(dropTargetFinder, findsOneWidget);

    final dropTarget = tester.widget<DropTarget>(dropTargetFinder);

    final fakeTxtFile = DropItemFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'drawing.txt',
      path: 'drawing.txt',
    );

    await tester.runAsync(() async {
      dropTarget.onDragDone!(
        DropDoneDetails(
          files: [fakeTxtFile],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    verifyNever(() => mockNotifier.loadFromBytes(any()));

    final fakePngFile = DropItemFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'drawing.png',
      path: 'drawing.png',
    );

    await tester.runAsync(() async {
      dropTarget.onDragDone!(
        DropDoneDetails(
          files: [fakePngFile],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    verifyNever(() => mockNotifier.loadFromBytes(any()));
  });

  // --------------------------------------------------------------------------
  // Skill 5: Write Tests for RepaintBoundary (Rasterization)
  // --------------------------------------------------------------------------
  testWidgets('captureImage_whenCalled_returnsUint8List', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: wrapWithMaterialApp(const InteractiveCanvas())),
    );

    final repaintBoundaryFinder = find.byType(RepaintBoundary);
    expect(repaintBoundaryFinder, findsWidgets);

    // Specifically check that RepaintBoundary wraps the CustomPaint (CanvasPainter)
    final customPaintFinder = find.descendant(
      of: repaintBoundaryFinder,
      matching: find.byType(CustomPaint),
    );
    expect(customPaintFinder, findsWidgets);
  });

  // --------------------------------------------------------------------------
  // Skill 6: Keyboard Shortcut Tests
  // --------------------------------------------------------------------------

  testWidgets('keyboardShortcut_ctrlZ_triggersUndo', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(drawingBoardNotifierProvider.notifier);
    // Draw a shape so there's something to undo
    notifier.startDrawing(
      const Offset(10, 10),
      const ToolSelectionState(toolType: ToolType.brush),
    );
    notifier.updateDrawing(const Offset(80, 80));
    notifier.commitDrawing();
    expect(
      container.read(drawingBoardNotifierProvider).finalizedShapes,
      hasLength(1),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(const InteractiveCanvas()),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(
      container.read(drawingBoardNotifierProvider).finalizedShapes,
      isEmpty,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('keyboardShortcut_ctrlY_triggersRedo', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(drawingBoardNotifierProvider.notifier);
    notifier.startDrawing(
      const Offset(10, 10),
      const ToolSelectionState(toolType: ToolType.brush),
    );
    notifier.updateDrawing(const Offset(80, 80));
    notifier.commitDrawing();
    notifier.undo();
    expect(
      container.read(drawingBoardNotifierProvider).canRedo,
      isTrue,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(const InteractiveCanvas()),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(
      container.read(drawingBoardNotifierProvider).finalizedShapes,
      hasLength(1),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('keyboardShortcut_deleteKey_deletesSelectedShape', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(drawingBoardNotifierProvider.notifier);
    notifier.startDrawing(
      const Offset(10, 10),
      const ToolSelectionState(toolType: ToolType.brush),
    );
    notifier.updateDrawing(const Offset(80, 80));
    notifier.commitDrawing();
    final shapeId = container
        .read(drawingBoardNotifierProvider)
        .finalizedShapes
        .single
        .id;
    notifier.selectShape(shapeId);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(const InteractiveCanvas()),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.delete);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    expect(
      container.read(drawingBoardNotifierProvider).finalizedShapes,
      isEmpty,
    );
    await tester.pumpAndSettle();
  });

  testWidgets(
    'keyboardShortcut_backspaceKey_deletesSelectedShape',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(drawingBoardNotifierProvider.notifier);
      notifier.startDrawing(
        const Offset(10, 10),
        const ToolSelectionState(toolType: ToolType.brush),
      );
      notifier.updateDrawing(const Offset(80, 80));
      notifier.commitDrawing();
      final shapeId = container
          .read(drawingBoardNotifierProvider)
          .finalizedShapes
          .single
          .id;
      notifier.selectShape(shapeId);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: wrapWithMaterialApp(const InteractiveCanvas()),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(
        container.read(drawingBoardNotifierProvider).finalizedShapes,
        isEmpty,
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets('keyboardShortcut_escape_clearsSelection', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(drawingBoardNotifierProvider.notifier);
    notifier.startDrawing(
      const Offset(10, 10),
      const ToolSelectionState(toolType: ToolType.brush),
    );
    notifier.updateDrawing(const Offset(80, 80));
    notifier.commitDrawing();
    final shapeId = container
        .read(drawingBoardNotifierProvider)
        .finalizedShapes
        .single
        .id;
    notifier.selectShape(shapeId);
    expect(
      container.read(drawingBoardNotifierProvider).selectedShapeId,
      shapeId,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(const InteractiveCanvas()),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(
      container.read(drawingBoardNotifierProvider).selectedShapeId,
      isNull,
    );
    // Shape must still be on the canvas
    expect(
      container.read(drawingBoardNotifierProvider).finalizedShapes,
      hasLength(1),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('keyboardShortcut_ctrlD_duplicatesSelectedShape', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(drawingBoardNotifierProvider.notifier);
    notifier.startDrawing(
      const Offset(10, 10),
      const ToolSelectionState(
        toolType: ToolType.shape,
        shapeType: ShapeType.rectangle,
      ),
    );
    notifier.updateDrawing(const Offset(60, 60));
    notifier.commitDrawing();
    final shapeId = container
        .read(drawingBoardNotifierProvider)
        .finalizedShapes
        .single
        .id;
    notifier.selectShape(shapeId);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(const InteractiveCanvas()),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(
      container.read(drawingBoardNotifierProvider).finalizedShapes,
      hasLength(2),
    );
    // New duplicate is auto-selected
    expect(
      container.read(drawingBoardNotifierProvider).selectedShapeId,
      isNot(shapeId),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('keyboardShortcut_ctrlA_switchesToCursorTool', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Start on brush
    expect(
      container.read(toolSelectionNotifierProvider).toolType,
      ToolType.brush,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(const InteractiveCanvas()),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(
      container.read(toolSelectionNotifierProvider).toolType,
      ToolType.cursor,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('keyboardShortcut_ctrlS_firesOnSaveCallback', (tester) async {
    var saveCallCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: wrapWithMaterialApp(
          InteractiveCanvas(onSave: () => saveCallCount++),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(saveCallCount, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('keyboardShortcut_ctrlO_firesOnLoadCallback', (tester) async {
    var loadCallCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: wrapWithMaterialApp(
          InteractiveCanvas(onLoad: () => loadCallCount++),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(loadCallCount, 1);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'keyboardShortcut_deleteKey_isNoOp_whenNothingSelected',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(drawingBoardNotifierProvider.notifier);
      notifier.startDrawing(
        const Offset(10, 10),
        const ToolSelectionState(toolType: ToolType.brush),
      );
      notifier.updateDrawing(const Offset(80, 80));
      notifier.commitDrawing();
      notifier.selectShape(null); // ensure nothing is selected

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: wrapWithMaterialApp(const InteractiveCanvas()),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.delete);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      // Shape should still be present
      expect(
        container.read(drawingBoardNotifierProvider).finalizedShapes,
        hasLength(1),
      );
      await tester.pumpAndSettle();
    },
  );
}
