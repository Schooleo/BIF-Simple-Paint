import 'dart:ui';

import 'two_point_shape.dart';

final class OvalShape extends TwoPointShape {
  const OvalShape({
    required super.startPoint,
    required super.endPoint,
    super.id,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  Offset get center {
    return Offset(
      (startPoint.dx + endPoint.dx) / 2,
      (startPoint.dy + endPoint.dy) / 2,
    );
  }

  double get radiusX {
    return (endPoint.dx - startPoint.dx).abs() / 2;
  }

  double get radiusY {
    return (endPoint.dy - startPoint.dy).abs() / 2;
  }

  @override
  OvalShape createWith({
    required Offset startPoint,
    required Offset endPoint,
    required String id,
    required Color? fillColor,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    return OvalShape(
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
    final radiusX = this.radiusX;
    final radiusY = this.radiusY;

    if (radiusX == 0 && radiusY == 0) {
      return point == center;
    }

    if (radiusX == 0) {
      final dy = (point.dy - center.dy).abs();
      return point.dx == center.dx && dy <= radiusY;
    }

    if (radiusY == 0) {
      final dx = (point.dx - center.dx).abs();
      return point.dy == center.dy && dx <= radiusX;
    }

    final normalizedX = (point.dx - center.dx) / radiusX;
    final normalizedY = (point.dy - center.dy) / radiusY;

    return normalizedX * normalizedX + normalizedY * normalizedY <= 1.0;
  }
}
