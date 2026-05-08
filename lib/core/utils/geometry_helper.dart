import 'dart:math' as math;
import 'dart:ui';

class GeometryHelper {
  const GeometryHelper();

  static double distanceToLineSegment(Offset point, Offset p1, Offset p2) {
    final segmentDx = p2.dx - p1.dx;
    final segmentDy = p2.dy - p1.dy;
    final lengthSquared = segmentDx * segmentDx + segmentDy * segmentDy;

    if (lengthSquared == 0) {
      return (point - p1).distance;
    }

    final projectionFactor =
        ((point.dx - p1.dx) * segmentDx + (point.dy - p1.dy) * segmentDy) /
        lengthSquared;
    final clampedFactor = projectionFactor.clamp(0.0, 1.0);
    final closestPoint = Offset(
      p1.dx + segmentDx * clampedFactor,
      p1.dy + segmentDy * clampedFactor,
    );

    return (point - closestPoint).distance;
  }

  static List<Offset> calculateArrowHead(
    Offset startPoint,
    Offset endPoint, {
    double arrowSize = 12,
    double arrowAngle = math.pi / 6,
  }) {
    final direction = math.atan2(
      endPoint.dy - startPoint.dy,
      endPoint.dx - startPoint.dx,
    );

    final leftWingAngle = direction + math.pi - arrowAngle;
    final rightWingAngle = direction + math.pi + arrowAngle;

    final leftWing = Offset(
      endPoint.dx + arrowSize * math.cos(leftWingAngle),
      endPoint.dy + arrowSize * math.sin(leftWingAngle),
    );
    final rightWing = Offset(
      endPoint.dx + arrowSize * math.cos(rightWingAngle),
      endPoint.dy + arrowSize * math.sin(rightWingAngle),
    );

    return <Offset>[leftWing, endPoint, rightWing];
  }

  Path buildSpline(List<Offset> points) {
    throw UnimplementedError();
  }

  Rect calculateBoundingBox(List<Offset> points) {
    throw UnimplementedError();
  }
}
