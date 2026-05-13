import 'package:bif_simple_paint/features/drawing_board/utils/manual_canvas_save.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldPromptForCanvasTitle', () {
    test('returns true for untitled canvases', () {
      expect(shouldPromptForCanvasTitle('Untitled'), isTrue);
      expect(shouldPromptForCanvasTitle(' untitled '), isTrue);
      expect(shouldPromptForCanvasTitle(''), isTrue);
    });

    test('returns false for already named canvases', () {
      expect(shouldPromptForCanvasTitle('My Sketch'), isFalse);
    });
  });
}
