import 'dart:ui';

import 'package:bif_simple_paint/core/utils/geometry_helper.dart';

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
