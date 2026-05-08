import 'dart:ui';

import 'package:bif_simple_paint/features/drawing_board/models/base_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BrushShape.seed creates a single-point path with styled defaults', () {
    const point = Offset(10, 20);

    final shape = BrushShape.seed(point);

    expect(shape.points, <Offset>[point]);
    expect(shape.strokeColor, const Color(0xFF000000));
    expect(shape.strokeWidth, 2.0);
  });

  test('PathShape.extendTo returns a new path and preserves the original', () {
    const pointA = Offset(1, 2);
    const pointB = Offset(3, 4);
    const strokeColor = Color(0xFFFF0000);

    final shape = BrushShape(
      id: 'brush-1',
      points: <Offset>[pointA],
      strokeColor: strokeColor,
    );

    final updated = shape.extendTo(pointB) as BrushShape;

    expect(shape.points, <Offset>[pointA]);
    expect(updated.points, <Offset>[pointA, pointB]);
    expect(updated.id, 'brush-1');
    expect(updated.strokeColor, strokeColor);
    expect(updated.strokeWidth, 2.0);
  });

  test('PathShape.finalize freezes points list', () {
    const pointA = Offset(1, 2);
    const pointB = Offset(3, 4);

    final shape =
        BrushShape(points: <Offset>[pointA]).extendTo(pointB) as BrushShape;
    final finalized = shape.finalize() as BrushShape;

    expect(finalized.isFinalized, isTrue);
    expect(
      () => finalized.points.add(const Offset(5, 6)),
      throwsUnsupportedError,
    );
  });

  test('every shape clone returns an equivalent detached instance', () {
    final shapes = <BaseShape>[
      BrushShape(
        id: 'brush',
        points: const <Offset>[Offset(1, 1), Offset(2, 2)],
        strokeColor: const Color(0xFF123456),
        strokeWidth: 3,
      ),
      EraserShape(
        id: 'eraser',
        points: const <Offset>[Offset(2, 2), Offset(3, 3)],
        strokeWidth: 5,
      ),
      const LineShape(
        id: 'line',
        startPoint: Offset(0, 0),
        endPoint: Offset(5, 5),
        strokeColor: Color(0xFF111111),
      ),
      const ArrowShape(
        id: 'arrow',
        startPoint: Offset(2, 2),
        endPoint: Offset(8, 8),
        strokeColor: Color(0xFF222222),
      ),
      const TextShape(
        id: 'text',
        startPoint: Offset(1, 1),
        endPoint: Offset(6, 6),
        text: 'Hello',
        fontSize: 16,
        strokeColor: Color(0xFF333333),
      ),
      const RectangleShape(
        id: 'rect',
        start: Offset(0, 0),
        end: Offset(10, 10),
        fillColor: Color(0x2200FF00),
      ),
      const OvalShape(
        id: 'oval',
        startPoint: Offset(1, 1),
        endPoint: Offset(7, 9),
        fillColor: Color(0x220000FF),
      ),
      CircleShape.fromBounds(
        id: 'circle',
        startPoint: const Offset(0, 0),
        endPoint: const Offset(10, 20),
        fillColor: const Color(0x220000FF),
      ),
      SquareShape.fromBounds(
        id: 'square',
        startPoint: const Offset(0, 0),
        endPoint: const Offset(10, 20),
        fillColor: const Color(0x220000FF),
      ),
    ];

    for (final shape in shapes) {
      final clone = shape.clone();

      expect(clone, equals(shape));
      expect(identical(clone, shape), isFalse);
      expect(clone.runtimeType, shape.runtimeType);

      if (shape is PathShape && clone is PathShape) {
        expect(identical(clone.points, shape.points), isFalse);
      }
    }
  });

  test('copyStyle preserves identity fields while updating styles', () {
    final pathShape =
        BrushShape.seed(
              const Offset(0, 0),
              id: 'brush-style',
            ).copyStyle(strokeColor: const Color(0xFFABCDEF), strokeWidth: 4)
            as BrushShape;
    final rectangle =
        const RectangleShape(
              id: 'rect-style',
              start: Offset(0, 0),
              end: Offset(4, 6),
            ).copyStyle(
              fillColor: const Color(0x3300FF00),
              applyFillColor: true,
              strokeColor: const Color(0xFFFF00FF),
              strokeWidth: 6,
            )
            as RectangleShape;

    expect(pathShape.id, 'brush-style');
    expect(pathShape.strokeColor, const Color(0xFFABCDEF));
    expect(pathShape.strokeWidth, 4);

    expect(rectangle.id, 'rect-style');
    expect(rectangle.start, const Offset(0, 0));
    expect(rectangle.end, const Offset(4, 6));
    expect(rectangle.fillColor, const Color(0x3300FF00));
    expect(rectangle.strokeColor, const Color(0xFFFF00FF));
    expect(rectangle.strokeWidth, 6);
  });

  test('EraserShape uses clear blend mode', () {
    const point = Offset(1, 2);

    final shape = EraserShape(points: <Offset>[point]);

    expect(shape.blendMode, BlendMode.clear);
  });

  test('RectangleShape defaults fill to transparent and extends end', () {
    const start = Offset(0, 0);
    const end = Offset(5, 5);
    const next = Offset(7, 9);

    final shape =
        const RectangleShape(start: start, end: end).extendTo(next)
            as RectangleShape;

    expect(shape.start, start);
    expect(shape.end, next);
    expect(shape.fillColor, const Color(0x00000000));
  });

  test('OvalShape derives center and radii from bounds', () {
    const start = Offset(0, 0);
    const end = Offset(10, 20);

    const shape = OvalShape(startPoint: start, endPoint: end);

    expect(shape.center, const Offset(5, 10));
    expect(shape.radiusX, 5);
    expect(shape.radiusY, 10);
  });

  test('CircleShape.fromBounds keeps circle semantics', () {
    const start = Offset(0, 0);
    const end = Offset(10, 20);

    final shape = CircleShape.fromBounds(startPoint: start, endPoint: end);

    expect(shape.center, const Offset(5, 10));
    expect(shape.radius, 5);
    expect(shape.startPoint, const Offset(0, 5));
    expect(shape.endPoint, const Offset(10, 15));
  });

  test('SquareShape.fromBounds keeps square semantics', () {
    const start = Offset(0, 0);
    const end = Offset(10, 20);

    final shape = SquareShape.fromBounds(startPoint: start, endPoint: end);

    expect(shape.center, const Offset(5, 10));
    expect(shape.sideLength, 10);
    expect(shape.startPoint, const Offset(0, 5));
    expect(shape.endPoint, const Offset(10, 15));
  });

  test('ArrowShape.extendTo updates end point', () {
    const start = Offset(1, 1);
    const end = Offset(4, 4);
    const next = Offset(9, 7);

    final shape =
        const ArrowShape(startPoint: start, endPoint: end).extendTo(next)
            as ArrowShape;

    expect(shape.startPoint, start);
    expect(shape.endPoint, next);
  });

  test('TextShape clone and copyStyle preserve text and fontSize', () {
    const start = Offset(2, 3);
    const end = Offset(6, 9);

    const shape = TextShape(
      id: 'text-1',
      startPoint: start,
      endPoint: end,
      text: 'Hi',
      fontSize: 14,
      fillColor: Color(0x2200FF00),
      strokeColor: Color(0xFF112233),
      strokeWidth: 3,
    );

    final clone = shape.clone();
    final styled = shape.copyStyle(
      fillColor: const Color(0x3300FF00),
      applyFillColor: true,
      strokeColor: const Color(0xFF445566),
      strokeWidth: 5,
    );

    expect(clone, equals(shape));
    expect(identical(clone, shape), isFalse);
    expect(clone.text, 'Hi');
    expect(clone.fontSize, 14);

    expect(styled.text, 'Hi');
    expect(styled.fontSize, 14);
    expect(styled.fillColor, const Color(0x3300FF00));
    expect(styled.strokeColor, const Color(0xFF445566));
    expect(styled.strokeWidth, 5);
  });

  test('TextShape equality includes text and fontSize', () {
    const start = Offset(0, 0);
    const end = Offset(5, 5);

    const base = TextShape(
      startPoint: start,
      endPoint: end,
      text: 'A',
      fontSize: 12,
    );
    const differentText = TextShape(
      startPoint: start,
      endPoint: end,
      text: 'B',
      fontSize: 12,
    );
    const differentSize = TextShape(
      startPoint: start,
      endPoint: end,
      text: 'A',
      fontSize: 13,
    );

    expect(base == differentText, isFalse);
    expect(base == differentSize, isFalse);
  });
}
