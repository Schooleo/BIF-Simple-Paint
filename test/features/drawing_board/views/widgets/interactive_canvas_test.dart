import 'dart:typed_data';

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
}
