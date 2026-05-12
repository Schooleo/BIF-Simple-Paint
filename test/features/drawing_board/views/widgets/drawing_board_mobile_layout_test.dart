import 'package:bif_simple_paint/core/theme/app_theme.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/views/screens/drawing_board_screen.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/canvas_title_field.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/eraser_tool_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FocusedTitleNotifier extends DrawingBoardNotifier {
  @override
  DrawingBoardState build() {
    return DrawingBoardState.initial(
      currentCanvasId: 'canvas_test',
      currentCanvasName: 'Untitled',
      shouldFocusCanvasTitle: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'mobile drawing board focuses title and removes redundant top bar actions',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            drawingBoardNotifierProvider.overrideWith(
              _FocusedTitleNotifier.new,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DrawingBoardScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CanvasTitleField), findsOneWidget);
      expect(find.byType(EditableText), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.byIcon(Icons.back_hand_outlined), findsOneWidget);
      expect(find.byIcon(Icons.near_me_outlined), findsNothing);
      expect(find.byIcon(Icons.pan_tool_alt), findsNothing);
      expect(find.byType(EraserToolIcon), findsOneWidget);
      expect(find.text('Stroke'), findsOneWidget);
      expect(find.text('Fill'), findsOneWidget);
      expect(find.byIcon(Icons.palette), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Stroke'), findsNothing);
      expect(find.text('Fill'), findsNothing);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    },
  );

  testWidgets('mobile select mode can reopen the style panel', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(toolSelectionNotifierProvider.notifier)
        .selectTool(ToolType.cursor);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DrawingBoardScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Stroke'), findsOneWidget);
    expect(find.text('Fill'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Stroke'), findsNothing);
    expect(find.text('Fill'), findsNothing);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Stroke'), findsOneWidget);
    expect(find.text('Fill'), findsOneWidget);
    expect(find.byIcon(Icons.palette), findsOneWidget);
  });
}
