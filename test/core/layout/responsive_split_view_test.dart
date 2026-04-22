import 'package:bif_simple_paint/core/layout/responsive_split_view.dart';
import 'package:bif_simple_paint/features/canvas_list/views/screens/canvas_list_screen.dart';
import 'package:bif_simple_paint/features/drawing_board/views/screens/drawing_board_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ResponsiveSplitView returns child on mobile widths', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveSplitView(
          child: Scaffold(body: Center(child: Text('MobileChild'))),
        ),
      ),
    );

    expect(find.text('MobileChild'), findsOneWidget);
    expect(find.byType(Row), findsNothing);
    expect(find.byType(CanvasListScreen), findsNothing);
    expect(find.byType(DrawingBoardScreen), findsNothing);
  });

  testWidgets('ResponsiveSplitView returns split layout on desktop widths', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ResponsiveSplitView(child: SizedBox.shrink())),
    );

    expect(find.byType(Row), findsOneWidget);
    expect(find.byType(CanvasListScreen), findsOneWidget);
    expect(find.byType(DrawingBoardScreen), findsOneWidget);

    final row = tester.widget<Row>(find.byType(Row));
    final flexValues = row.children
        .whereType<Expanded>()
        .map((Expanded widget) => widget.flex)
        .toList();

    expect(flexValues, <int>[1, 3]);
  });
}
