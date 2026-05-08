import 'dart:ui';

import '../base_shape.dart';
import 'two_point_shape.dart';

final class SquareShape extends TwoPointShape {
  SquareShape({
    required this.center,
    required this.sideLength,
    super.id,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  }) : super(
         startPoint: Offset(
           center.dx - sideLength / 2,
           center.dy - sideLength / 2,
         ),
         endPoint: Offset(
           center.dx + sideLength / 2,
           center.dy + sideLength / 2,
         ),
       );

  final Offset center;
  final double sideLength;

  factory SquareShape.fromBounds({
    required Offset startPoint,
    required Offset endPoint,
    String id = '',
    Color? fillColor,
    Color strokeColor = defaultStrokeColor,
    double strokeWidth = defaultStrokeWidth,
  }) {
    final center = Offset(
      (startPoint.dx + endPoint.dx) / 2,
      (startPoint.dy + endPoint.dy) / 2,
    );
    final width = (endPoint.dx - startPoint.dx).abs();
    final height = (endPoint.dy - startPoint.dy).abs();
    final sideLength = width < height ? width : height;

    return SquareShape(
      center: center,
      sideLength: sideLength,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  SquareShape createWith({
    required Offset startPoint,
    required Offset endPoint,
    required String id,
    required Color? fillColor,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    return SquareShape.fromBounds(
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
