import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:bif_simple_paint/core/utils/binary_serializer.dart';
import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';

void main() {
  group('BinarySerializer Tests', () {
    // 1. Setup: Khởi tạo danh sách mockShapes đa dạng
    final mockShapes = <BaseShape>[
      BrushShape(
        id: 'brush_1',
        points: const [Offset(10, 10), Offset(20, 20), Offset(30, 15)],
        strokeColor: const Color(0xFFFF0000), // Red
        strokeWidth: 3.5,
        isFinalized: true,
      ),
      const RectangleShape(
        id: 'rect_1',
        start: Offset(50, 50),
        end: Offset(100, 150),
        strokeColor: Color(0xFF00FF00), // Green
        strokeWidth: 2.0,
        fillColor: Color(0x800000FF), // Semi-transparent Blue
      ),
      const TextShape(
        id: 'text_1',
        startPoint: Offset(200, 200),
        endPoint: Offset(300, 250),
        text: 'BIF Paint Testing',
        fontSize: 24.0,
        strokeColor: Color(0xFF000000),
        strokeWidth: 1.0,
      ),
      const ArrowShape(
        id: 'arrow_1',
        startPoint: Offset(10, 100),
        endPoint: Offset(200, 100),
        strokeColor: Color(0xFF00FFFF),
        strokeWidth: 4.0,
      ),
    ];

    test(
      'Case 1 (Lossless): Encode and decode shapes perfectly without data loss',
      () async {
        // Thực hiện Encode (với width: 800, height: 600)
        final encodedData = await encodeShapes(mockShapes, 800.0, 600.0);

        expect(encodedData, isA<Uint8List>());
        expect(
          encodedData.isNotEmpty,
          true,
          reason: 'Mảng byte không được rỗng sau khi encode',
        );

        // Thực hiện Decode
        final decodedResult = await decodeShapes(encodedData);
        final decodedShapes = decodedResult.shapes;

        // Asserts
        expect(
          decodedShapes.length,
          mockShapes.length,
          reason: 'Số lượng shape sau decode phải bằng lúc đầu',
        );
        expect(
          decodedResult.canvasWidth,
          800.0,
          reason: 'Canvas Width phải khớp',
        );
        expect(
          decodedResult.canvasHeight,
          600.0,
          reason: 'Canvas Height phải khớp',
        );

        for (int i = 0; i < mockShapes.length; i++) {
          final original = mockShapes[i];
          final decoded = decodedShapes[i];

          // Kiểm tra cơ bản
          expect(decoded.id, original.id, reason: 'ID phải khớp');
          expect(
            decoded.runtimeType,
            original.runtimeType,
            reason: 'Loại Shape phải khớp',
          );
          expect(
            decoded.strokeColor,
            original.strokeColor,
            reason: 'Stroke Color phải khớp',
          );
          expect(
            decoded.strokeWidth,
            original.strokeWidth,
            reason: 'Stroke Width phải khớp',
          );

          // Kiểm tra cấu trúc sâu bên trong (operator == đã được override trong các model)
          expect(
            decoded,
            original,
            reason: 'Toàn bộ thuộc tính của shape phải khớp 100%',
          );
        }
      },
    );

    test(
      'Case 2 (Corrupted Data): Decoding invalid data throws FormatException',
      () async {
        // 1. Decode mảng rỗng (theo logic trong code sẽ return record rỗng)
        final emptyDecode = await decodeShapes(Uint8List(0));
        expect(
          emptyDecode.shapes,
          isEmpty,
          reason: 'Dữ liệu rỗng trả về mảng rỗng thay vì crash',
        );

        // 1b. Header bị cắt trước đủ 3 byte phải bị báo lỗi thay vì nuốt im lặng
        final shortHeader = Uint8List.fromList([0xBF, 0x50]);
        expect(
          () => decodeShapes(shortHeader),
          throwsA(isA<FormatException>()),
          reason: 'Header bị cắt ngắn phải throw FormatException',
        );

        // 2. Decode dữ liệu bị sai Magic Bytes / Version Header
        final badMagic = Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);
        expect(
          () => decodeShapes(badMagic),
          throwsA(isA<FormatException>()),
          reason: 'Header sai phải throw FormatException',
        );

        // 3. Decode dữ liệu bị cắt xén (Truncated bytes -> Index out of bounds)
        final validEncoded = await encodeShapes(mockShapes, 800.0, 600.0);
        // Cắt bỏ 10 byte cuối cùng để làm hỏng dữ liệu của shape cuối
        final truncatedData = validEncoded.sublist(0, validEncoded.length - 10);

        expect(
          () => decodeShapes(truncatedData),
          throwsA(isA<FormatException>()),
          reason:
              'Dữ liệu bị thiếu byte (out of bounds) phải throw FormatException',
        );
      },
    );
  });
}
