import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';

import 'package:bif_simple_paint/core/utils/thumbnail_generator.dart';
import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';

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
  // Required to allow dart:ui Canvas operations in a test environment
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThumbnailGenerator Tests', () {
    // 1. Setup mock data
    final mockShapes = <BaseShape>[
      BrushShape(
        id: 'brush_1',
        points: const [Offset(0, 0), Offset(50, 50), Offset(100, 100)],
        strokeColor: const Color(0xFF000000),
        strokeWidth: 5.0,
        isFinalized: true,
      ),
      CircleShape.fromBounds(
        id: 'circle_1',
        startPoint: const Offset(10, 10),
        endPoint: const Offset(90, 90),
        strokeColor: const Color(0xFFFF0000), // Red
        strokeWidth: 2.0,
      ),
      const TextShape(
        id: 'text_1',
        startPoint: Offset(20, 20),
        endPoint: Offset(80, 80),
        text: 'Thumbnail',
        fontSize: 16.0,
        strokeColor: Color(0xFF0000FF),
        strokeWidth: 1.0,
      ),
    ];

    test('Case 1: Generate valid PNG thumbnail from shapes', () async {
      // Tạo thumbnail
      final thumbnailBytes = await ThumbnailGenerator.generate(
        mockShapes,
        targetWidth: 250,
        targetHeight: 250,
        padding: 15,
      );

      // Đảm bảo không null và không rỗng
      expect(thumbnailBytes, isNotNull, reason: 'Hàm trả về Uint8List hợp lệ');
      expect(thumbnailBytes, isNotEmpty, reason: 'Độ dài byte phải lớn hơn 0');

      // Kiểm tra file header có đúng chuẩn PNG không
      // PNG Signature: 89 50 4E 47 0D 0A 1A 0A
      final pngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      final header = thumbnailBytes!.sublist(0, 8);

      expect(header, pngHeader, reason: 'Ảnh sinh ra phải đúng định dạng PNG');
    });

    test('Edge Case 1: Return null for empty shapes list', () async {
      final thumbnailBytes = await ThumbnailGenerator.generate([]);
      expect(
        thumbnailBytes,
        isNull,
        reason: 'Mảng rỗng thì không sinh thumbnail',
      );
    });

    test(
      'Edge Case 2: Handle single point drawing without dividing by zero',
      () async {
        // Trường hợp chỉ có 1 chấm cọ (boxWidth và boxHeight = 0)
        final dotShape = [
          BrushShape(
            id: 'dot',
            points: const [Offset(50, 50)],
            strokeColor: const Color(0xFF000000),
            strokeWidth: 5.0,
          ),
        ];

        final thumbnailBytes = await ThumbnailGenerator.generate(
          dotShape,
          targetWidth: 100,
          targetHeight: 100,
        );

        expect(thumbnailBytes, isNotNull);
        expect(thumbnailBytes, isNotEmpty);
      },
    );

    test('Edge Case 3: Reject padding that leaves no drawable area', () async {
      expect(
        () => ThumbnailGenerator.generate(
          mockShapes,
          targetWidth: 20,
          targetHeight: 20,
          padding: 20,
        ),
        throwsA(isA<FormatException>()),
        reason: 'Padding quá lớn phải bị từ chối sớm',
      );
    });

    test('renders text shape fill and stroke into the thumbnail output', () async {
      const fillColor = Color(0xFFFFEB3B);
      const strokeColor = Color(0xFF1565C0);
      final thumbnailBytes = await ThumbnailGenerator.generate(
        const <BaseShape>[
          TextShape(
            id: 'text_render',
            startPoint: Offset(20, 20),
            endPoint: Offset(180, 180),
            text: 'T',
            fontSize: 96,
            fillColor: fillColor,
            strokeColor: strokeColor,
            strokeWidth: 4,
          ),
        ],
        targetWidth: 200,
        targetHeight: 200,
        padding: 0,
      );

      expect(thumbnailBytes, isNotNull);
      final image = img.decodePng(thumbnailBytes!);

      expect(image, isNotNull);
      expect(
        _containsColor(image!, fillColor, minMatches: 500),
        isTrue,
        reason: 'Text thumbnails should keep the text box fill color',
      );
      expect(
        _containsColor(image, strokeColor, minMatches: 100),
        isTrue,
        reason: 'Text thumbnails should render the text box border/text color',
      );
    });
  });
}
