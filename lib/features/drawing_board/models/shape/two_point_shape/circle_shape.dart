import 'dart:ui';

import '../base_shape.dart';
import 'two_point_shape.dart';

final class CircleShape extends TwoPointShape {
  CircleShape({
    required this.center,
    required this.radius,
    super.id,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  }) : super(
         startPoint: Offset(center.dx - radius, center.dy - radius),
         endPoint: Offset(center.dx + radius, center.dy + radius),
       );

  final Offset center;
  final double radius;

  factory CircleShape.fromBounds({
    required Offset startPoint,
    required Offset endPoint,
    String id = '',
    Color? fillColor,
    Color strokeColor = defaultStrokeColor,
    double strokeWidth = defaultStrokeWidth,
  }) {
    final dx = (endPoint.dx - startPoint.dx).abs();
    final dy = (endPoint.dy - startPoint.dy).abs();
    final radius = (dx < dy ? dx : dy) / 2;
    final signX = endPoint.dx >= startPoint.dx ? 1.0 : -1.0;
    final signY = endPoint.dy >= startPoint.dy ? 1.0 : -1.0;
    final center = Offset(
      startPoint.dx + (signX * radius),
      startPoint.dy + (signY * radius),
    );

    return CircleShape(
      center: center,
      radius: radius,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  CircleShape createWith({
    required Offset startPoint,
    required Offset endPoint,
    required String id,
    required Color? fillColor,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    return CircleShape.fromBounds(
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
    return (point - center).distance <= radius;
  }
}
