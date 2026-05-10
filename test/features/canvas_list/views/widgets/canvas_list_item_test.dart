import 'package:bif_simple_paint/features/canvas_list/models/canvas_metadata.dart';
import 'package:bif_simple_paint/features/canvas_list/views/widgets/canvas_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CanvasListItem lays out within a narrow sidebar width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 248,
              child: CanvasListItem(
                metadata: CanvasMetadata(
                  id: 'canvas-1',
                  name: 'A very long canvas name that should truncate cleanly',
                  filePath:
                      '/Users/example/Documents/projects/really/long/path/draft.mypt',
                  lastEditedTime: DateTime.now(),
                ),
                onDelete: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CanvasListItem), findsOneWidget);
  });
}
