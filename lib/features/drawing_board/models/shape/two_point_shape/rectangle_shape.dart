import 'dart:ui';

import 'two_point_shape.dart';

final class RectangleShape extends TwoPointShape {
  const RectangleShape({
    required Offset start,
    required Offset end,
    super.id,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  }) : super(startPoint: start, endPoint: end);

  Offset get start => startPoint;

  Offset get end => endPoint;

  @override
  RectangleShape createWith({
    required Offset startPoint,
    required Offset endPoint,
    required String id,
    required Color? fillColor,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    return RectangleShape(
      start: startPoint,
      end: endPoint,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool contains(Offset point) {
    final minDx = startPoint.dx < endPoint.dx ? startPoint.dx : endPoint.dx;
    final maxDx = startPoint.dx > endPoint.dx ? startPoint.dx : endPoint.dx;
    final minDy = startPoint.dy < endPoint.dy ? startPoint.dy : endPoint.dy;
    final maxDy = startPoint.dy > endPoint.dy ? startPoint.dy : endPoint.dy;

    return point.dx >= minDx &&
        point.dx <= maxDx &&
        point.dy >= minDy &&
        point.dy <= maxDy;
  }
}
