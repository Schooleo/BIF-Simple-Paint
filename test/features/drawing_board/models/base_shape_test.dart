import 'dart:ui';

import 'package:bif_simple_paint/features/drawing_board/models/base_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BrushShape.seed creates a single-point path with defaults', () {
    const point = Offset(10, 20);

    final shape = BrushShape.seed(point);

    expect(shape.points, <Offset>[point]);
    expect(shape.strokeColor, const Color(0xFF000000));
    expect(shape.strokeWidth, 2.0);
  });

  test('BrushShape.extendTo appends point and preserves stroke', () {
    const pointA = Offset(1, 2);
    const pointB = Offset(3, 4);
    const strokeColor = Color(0xFFFF0000);

    final shape = BrushShape(
      points: <Offset>[pointA],
      strokeColor: strokeColor,
    );

    final updated = shape.extendTo(pointB) as BrushShape;

    expect(updated.points, <Offset>[pointA, pointB]);
    expect(updated.strokeColor, strokeColor);
    expect(updated.strokeWidth, 2.0);
  });

  test('PathShape.finalize freezes points list', () {
    const pointA = Offset(1, 2);
    const pointB = Offset(3, 4);

    final shape = BrushShape(points: <Offset>[pointA]);
    shape.extendTo(pointB);

    final finalized = shape.finalize() as BrushShape;

    expect(finalized.isFinalized, isTrue);
    expect(
      () => finalized.points.add(const Offset(5, 6)),
      throwsUnsupportedError,
    );
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
        const RectangleShape(start: start, end: end).extendTo(next);

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

  test('OvalShape.extendTo preserves styling', () {
    const start = Offset(2, 4);
    const end = Offset(6, 10);
    const next = Offset(12, 14);
    const fill = Color(0x33000000);
    const stroke = Color(0xFF00FF00);

    final shape = const OvalShape(
      startPoint: start,
      endPoint: end,
      fillColor: fill,
      strokeColor: stroke,
      strokeWidth: 3.5,
    ).extendTo(next);

    expect(shape.startPoint, start);
    expect(shape.endPoint, next);
    expect(shape.fillColor, fill);
    expect(shape.strokeColor, stroke);
    expect(shape.strokeWidth, 3.5);
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
