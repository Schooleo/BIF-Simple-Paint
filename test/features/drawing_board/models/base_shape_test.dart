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
}
