import 'package:bif_simple_paint/features/canvas_list/views/screens/canvas_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldResetDesktopBoardAfterDelete', () {
    test('returns true for active canvas deletion on desktop', () {
      expect(
        shouldResetDesktopBoardAfterDelete(
          screenWidth: 1200,
          activeCanvasId: 'canvas-a',
          deletedCanvasId: 'canvas-a',
        ),
        isTrue,
      );
    });

    test('returns false when a different canvas is deleted', () {
      expect(
        shouldResetDesktopBoardAfterDelete(
          screenWidth: 1200,
          activeCanvasId: 'canvas-a',
          deletedCanvasId: 'canvas-b',
        ),
        isFalse,
      );
    });

    test('returns false on mobile widths', () {
      expect(
        shouldResetDesktopBoardAfterDelete(
          screenWidth: 600,
          activeCanvasId: 'canvas-a',
          deletedCanvasId: 'canvas-a',
        ),
        isFalse,
      );
    });
  });
}
