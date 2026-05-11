import 'dart:ui';

import 'package:bif_simple_paint/core/utils/geometry_helper.dart';

import '../base_shape.dart';
import 'two_point_shape.dart';

final class LineShape extends TwoPointShape {
  const LineShape({
    required super.startPoint,
    required super.endPoint,
    super.id,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  @override
  LineShape createWith({
    required Offset startPoint,
    required Offset endPoint,
    required String id,
    required Color? fillColor,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    return LineShape(
      startPoint: startPoint,
      endPoint: endPoint,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  LineShape resize(Offset delta, ResizeCorner corner) {
    final newStart =
        (corner == ResizeCorner.topLeft || corner == ResizeCorner.bottomLeft)
        ? startPoint + delta
        : startPoint;
    final newEnd =
        (corner == ResizeCorner.topRight || corner == ResizeCorner.bottomRight)
        ? endPoint + delta
        : endPoint;

    return createWith(
      startPoint: newStart,
      endPoint: newEnd,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool contains(Offset point) {
    final threshold = strokeWidth + 5.0;
    final distance = GeometryHelper.distanceToLineSegment(
      point,
      startPoint,
      endPoint,
    );

    return distance <= threshold;
  }
}
