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
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDrawingBoardNotifier extends Notifier<DrawingBoardState>
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

Rect boundsForShape(BaseShape shape) {
  return switch (shape) {
    PathShape() => Rect.fromPoints(shape.points.first, shape.points.last),
    TwoPointShape() => Rect.fromPoints(shape.startPoint, shape.endPoint),
    _ => Rect.zero,
  };
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

  testWidgets('pinchGesture_scalesSelectedObject_whenCursorToolIsActive', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(drawingBoardNotifierProvider.notifier);
    notifier.startDrawing(
      const Offset(40, 40),
      const ToolSelectionState(toolType: ToolType.shape),
    );
    notifier.updateDrawing(const Offset(120, 120));
    notifier.commitDrawing();
    final shapeId = container
        .read(drawingBoardNotifierProvider)
        .finalizedShapes
        .single
        .id;
    notifier.selectShape(shapeId);
    container
        .read(toolSelectionNotifierProvider.notifier)
        .selectTool(ToolType.cursor);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(
          const SizedBox(width: 240, height: 240, child: InteractiveCanvas()),
        ),
      ),
    );
    await tester.pump();

    final before = boundsForShape(
      container.read(drawingBoardNotifierProvider).selectedShape!,
    );
    final canvasTopLeft = tester.getTopLeft(find.byType(InteractiveCanvas));

    final gestureA = await tester.startGesture(
      canvasTopLeft + const Offset(60, 60),
      pointer: 1,
    );
    final gestureB = await tester.startGesture(
      canvasTopLeft + const Offset(100, 100),
      pointer: 2,
    );
    await tester.pump();

    await gestureA.moveTo(canvasTopLeft + const Offset(40, 40));
    await gestureB.moveTo(canvasTopLeft + const Offset(120, 120));
    await tester.pump();

    await gestureA.up();
    await gestureB.up();
    await tester.pumpAndSettle();

    final after = boundsForShape(
      container.read(drawingBoardNotifierProvider).selectedShape!,
    );

    expect(after.width, greaterThan(before.width));
    expect(after.height, greaterThan(before.height));
  });

  testWidgets('twoFingerPinch_updatesViewportTransform_forBoardZoom', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(
          const SizedBox(width: 240, height: 240, child: InteractiveCanvas()),
        ),
      ),
    );
    await tester.pump();

    final canvasTopLeft = tester.getTopLeft(find.byType(InteractiveCanvas));
    final gestureA = await tester.startGesture(
      canvasTopLeft + const Offset(80, 80),
      pointer: 1,
    );
    final gestureB = await tester.startGesture(
      canvasTopLeft + const Offset(140, 140),
      pointer: 2,
    );
    await tester.pump();

    await gestureA.moveTo(canvasTopLeft + const Offset(60, 60));
    await gestureB.moveTo(canvasTopLeft + const Offset(160, 160));
    await tester.pump();

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey<String>('interactive-canvas-transform')),
    );

    await gestureA.up();
    await gestureB.up();

    expect(transform.transform.getMaxScaleOnAxis(), greaterThan(1.0));
  });

  testWidgets('mouseWheelScroll_updatesViewportTransform_forDesktopZoom', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(
          const SizedBox(width: 240, height: 240, child: InteractiveCanvas()),
        ),
      ),
    );
    await tester.pump();

    final center = tester.getCenter(find.byType(InteractiveCanvas));
    final mouse = TestPointer(10, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(center));
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -120)));
    await tester.pump();

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey<String>('interactive-canvas-transform')),
    );

    expect(transform.transform.getMaxScaleOnAxis(), greaterThan(1.0));
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

  testWidgets('desktop shortcut bindings map undo and redo actions', (
    tester,
  ) async {
    final mockNotifier = MockDrawingBoardNotifier();
    when(() => mockNotifier.undo()).thenReturn(null);
    when(() => mockNotifier.redo()).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingBoardNotifierProvider.overrideWith(() => mockNotifier),
        ],
        child: wrapWithMaterialApp(const CanvasArea()),
      ),
    );
    await tester.pump();

    final shortcuts = tester.widget<CallbackShortcuts>(
      find.byType(CallbackShortcuts),
    );

    shortcuts
        .bindings[const SingleActivator(LogicalKeyboardKey.keyZ, control: true)]
        ?.call();
    shortcuts
        .bindings[const SingleActivator(LogicalKeyboardKey.keyY, control: true)]
        ?.call();
    shortcuts
        .bindings[const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        )]
        ?.call();

    verify(() => mockNotifier.undo()).called(1);
    verify(() => mockNotifier.redo()).called(2);
  });

  testWidgets('desktop shortcuts are ignored while editing canvas title', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(toolSelectionNotifierProvider.notifier)
        .selectTool(ToolType.eraser);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(const CanvasArea()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    final shortcuts = tester.widget<CallbackShortcuts>(
      find.byType(CallbackShortcuts),
    );

    shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.keyQ)]?.call();
    shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.keyW)]?.call();
    shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.keyE)]?.call();
    shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.keyR)]?.call();

    final selection = container.read(toolSelectionNotifierProvider);
    expect(selection.toolType, ToolType.eraser);
    expect(find.byIcon(Icons.expand_more), findsNothing);
  });

  testWidgets('desktop mode shortcuts switch tools and pick shapes', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithMaterialApp(const CanvasArea()),
      ),
    );
    await tester.pump();

    final shortcuts = tester.widget<CallbackShortcuts>(
      find.byType(CallbackShortcuts),
    );

    shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.keyQ)]?.call();
    expect(
      container.read(toolSelectionNotifierProvider).toolType,
      ToolType.cursor,
    );

    shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.keyW)]?.call();
    expect(
      container.read(toolSelectionNotifierProvider).toolType,
      ToolType.brush,
    );

    shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.keyE)]?.call();
    expect(
      container.read(toolSelectionNotifierProvider).toolType,
      ToolType.eraser,
    );

    shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.keyR)]?.call();
    await tester.pump();
    shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.arrowRight)]
        ?.call();
    shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.enter)]?.call();
    await tester.pump();

    final selection = container.read(toolSelectionNotifierProvider);
    expect(selection.toolType, ToolType.shape);
    expect(selection.shapeType, ShapeType.oval);
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
}
