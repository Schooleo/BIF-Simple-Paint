import 'dart:typed_data';
import 'dart:ui';

import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';
import 'package:bif_simple_paint/features/drawing_board/utils/canvas_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

bool _containsColor(
  img.Image image,
  Color color, {
  int tolerance = 8,
  int minMatches = 1,
}) {
  var matches = 0;

  for (final pixel in image) {
    if ((pixel.r - color.r * 255).abs() <= tolerance &&
        (pixel.g - color.g * 255).abs() <= tolerance &&
        (pixel.b - color.b * 255).abs() <= tolerance &&
        (pixel.a - color.a * 255).abs() <= tolerance) {
      matches += 1;
      if (matches >= minMatches) {
        return true;
      }
    }
  }

  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CanvasExporter', () {
    test('renders text shape fill and stroke into PNG exports', () async {
      const fillColor = Color(0xFFFFEB3B);
      const strokeColor = Color(0xFF1565C0);
      final bytes = await CanvasExporter.export(
        const <BaseShape>[
          TextShape(
            id: 'text_export',
            startPoint: Offset(0, 0),
            endPoint: Offset(1856, 1856),
            text: 'PNG',
            fontSize: 640,
            fillColor: fillColor,
            strokeColor: strokeColor,
            strokeWidth: 8,
          ),
        ],
        canvasWidth: 1856,
        canvasHeight: 1856,
        backgroundColor: const Color(0xFFFFFFFF),
      );

      expect(bytes, isNotNull);
      expect(bytes, isNotEmpty);
      expect(
        bytes!.sublist(0, 8),
        <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      );

      final image = img.decodePng(bytes);
      expect(image, isNotNull);
      expect(
        _containsColor(image!, fillColor, minMatches: 5000),
        isTrue,
        reason: 'PNG exports should keep the text box fill color',
      );
      expect(
        _containsColor(image, strokeColor, minMatches: 500),
        isTrue,
        reason: 'PNG exports should render the text box border/text color',
      );
    });

    test('can still export JPEG when the canvas includes text shapes', () async {
      final bytes = await CanvasExporter.export(
        const <BaseShape>[
          TextShape(
            id: 'text_export_jpeg',
            startPoint: Offset(0, 0),
            endPoint: Offset(1856, 1856),
            text: 'JPEG',
            fontSize: 640,
            fillColor: Color(0xFFFFEB3B),
            strokeColor: Color(0xFF1565C0),
            strokeWidth: 8,
          ),
        ],
        canvasWidth: 1856,
        canvasHeight: 1856,
        backgroundColor: const Color(0xFFFFFFFF),
        asJpeg: true,
      );

      expect(bytes, isNotNull);
      expect(bytes, isNotEmpty);
      expect(img.decodeJpg(Uint8List.fromList(bytes!)), isNotNull);
    });
  });
}
