import 'dart:ui';

import 'package:bif_simple_paint/core/utils/geometry_helper.dart';

import 'two_point_shape.dart';

final class ArrowShape extends TwoPointShape {
  const ArrowShape({
    required super.startPoint,
    required super.endPoint,
    super.id,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  @override
  ArrowShape createWith({
    required Offset startPoint,
    required Offset endPoint,
    required String id,
    required Color? fillColor,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    return ArrowShape(
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
