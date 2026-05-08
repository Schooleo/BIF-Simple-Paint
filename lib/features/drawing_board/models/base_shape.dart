import 'dart:collection';
import 'dart:ui';

import 'package:meta/meta.dart';

import 'package:bif_simple_paint/core/utils/geometry_helper.dart';

sealed class BaseShape {
  const BaseShape({
    this.id = '',
    this.strokeColor = _defaultStrokeColor,
    this.strokeWidth = _defaultStrokeWidth,
  });

  final String id;
  final Color strokeColor;
  final double strokeWidth;

  BlendMode get blendMode => BlendMode.srcOver;

  BaseShape extendTo(Offset point);

  bool contains(Offset point);

  BaseShape finalize() => this;

  BaseShape clone();

  BaseShape copyStyle({
    Color? fillColor,
    bool applyFillColor = false,
    Color? strokeColor,
    double? strokeWidth,
  });
}

abstract base class PathShape extends BaseShape {
  PathShape({
    required List<Offset> points,
    this.isFinalized = false,
    super.id,
    super.strokeColor,
    super.strokeWidth,
  }) : assert(points.isNotEmpty, 'PathShape requires at least one point.'),
       _points = isFinalized
           ? List<Offset>.unmodifiable(points)
           : List<Offset>.of(points, growable: false) {
    _pointsView = UnmodifiableListView<Offset>(_points);
  }

  final bool isFinalized;
  final List<Offset> _points;
  late final UnmodifiableListView<Offset> _pointsView;

  List<Offset> get points => _pointsView;

  @protected
  PathShape createWith({
    required List<Offset> points,
    required bool isFinalized,
    required String id,
    required Color strokeColor,
    required double strokeWidth,
  });

  @override
  PathShape extendTo(Offset point) {
    return createWith(
      points: <Offset>[..._points, point],
      isFinalized: false,
      id: id,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool contains(Offset point) {
    final threshold = strokeWidth + 5.0;

    if (_points.length == 1) {
      return (point - _points.first).distance <= threshold;
    }

    for (var index = 0; index < _points.length - 1; index++) {
      final distance = GeometryHelper.distanceToLineSegment(
        point,
        _points[index],
        _points[index + 1],
      );
      if (distance <= threshold) {
        return true;
      }
    }

    return false;
  }

  @override
  PathShape finalize() {
    if (isFinalized) {
      return this;
    }

    return createWith(
      points: List<Offset>.of(_points),
      isFinalized: true,
      id: id,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  PathShape clone() {
    return createWith(
      points: List<Offset>.of(_points),
      isFinalized: isFinalized,
      id: id,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  PathShape copyStyle({
    Color? fillColor,
    bool applyFillColor = false,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    return createWith(
      points: List<Offset>.of(_points),
      isFinalized: isFinalized,
      id: id,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType || other is! PathShape) return false;

    if (other.id != id ||
        other.isFinalized != isFinalized ||
        other.strokeColor != strokeColor ||
        other.strokeWidth != strokeWidth) {
      return false;
    }

    if (isFinalized) return true;

    if (points.length != other.points.length) return false;

    return _listEquals(points, other.points);
  }

  late final int _cachedHashCode = _computeHashCode();

  int _computeHashCode() {
    return Object.hash(
      runtimeType,
      id,
      isFinalized,
      Object.hashAll(points),
      strokeColor,
      strokeWidth,
    );
  }

  @override
  int get hashCode => _cachedHashCode;
}

abstract base class TwoPointShape extends BaseShape {
  const TwoPointShape({
    required this.startPoint,
    required this.endPoint,
    this.fillColor = _defaultFillColor,
    super.id,
    super.strokeColor,
    super.strokeWidth,
  });

  final Offset startPoint;
  final Offset endPoint;
  final Color? fillColor;

  @protected
  TwoPointShape createWith({
    required Offset startPoint,
    required Offset endPoint,
    required String id,
    required Color? fillColor,
    required Color strokeColor,
    required double strokeWidth,
  });

  @override
  TwoPointShape extendTo(Offset point) {
    return createWith(
      startPoint: startPoint,
      endPoint: point,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  TwoPointShape clone() {
    return createWith(
      startPoint: startPoint,
      endPoint: endPoint,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  TwoPointShape copyStyle({
    Color? fillColor,
    bool applyFillColor = false,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    return createWith(
      startPoint: startPoint,
      endPoint: endPoint,
      id: id,
      fillColor: applyFillColor ? fillColor : this.fillColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other is TwoPointShape &&
            other.id == id &&
            other.startPoint == startPoint &&
            other.endPoint == endPoint &&
            other.fillColor == fillColor &&
            other.strokeColor == strokeColor &&
            other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    startPoint,
    endPoint,
    fillColor,
    strokeColor,
    strokeWidth,
  );
}

final class BrushShape extends PathShape {
  BrushShape({
    required super.points,
    super.id,
    super.isFinalized,
    super.strokeColor,
    super.strokeWidth,
  });

  factory BrushShape.seed(
    Offset point, {
    String id = '',
    Color strokeColor = _defaultStrokeColor,
    double strokeWidth = _defaultStrokeWidth,
  }) {
    return BrushShape(
      points: <Offset>[point],
      id: id,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  BrushShape createWith({
    required List<Offset> points,
    required bool isFinalized,
    required String id,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    return BrushShape(
      points: points,
      id: id,
      isFinalized: isFinalized,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }
}

final class EraserShape extends PathShape {
  EraserShape({
    required super.points,
    super.id,
    super.isFinalized,
    super.strokeColor,
    super.strokeWidth,
  });

  @override
  BlendMode get blendMode => BlendMode.clear;

  factory EraserShape.seed(
    Offset point, {
    String id = '',
    Color strokeColor = _defaultStrokeColor,
    double strokeWidth = _defaultStrokeWidth,
  }) {
    return EraserShape(
      points: <Offset>[point],
      id: id,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  EraserShape createWith({
    required List<Offset> points,
    required bool isFinalized,
    required String id,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    return EraserShape(
      points: points,
      id: id,
      isFinalized: isFinalized,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }
}

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

final class TextShape extends TwoPointShape {
  const TextShape({
    required super.startPoint,
    required super.endPoint,
    required this.text,
    required this.fontSize,
    super.id,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  final String text;
  final double fontSize;

  @override
  TextShape createWith({
    required Offset startPoint,
    required Offset endPoint,
    required String id,
    required Color? fillColor,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    return TextShape(
      startPoint: startPoint,
      endPoint: endPoint,
      text: text,
      fontSize: fontSize,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  TextShape clone() {
    return TextShape(
      startPoint: startPoint,
      endPoint: endPoint,
      text: text,
      fontSize: fontSize,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  TextShape copyStyle({
    Color? fillColor,
    bool applyFillColor = false,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    return TextShape(
      startPoint: startPoint,
      endPoint: endPoint,
      text: text,
      fontSize: fontSize,
      id: id,
      fillColor: applyFillColor ? fillColor : this.fillColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other is TextShape &&
            other.id == id &&
            other.startPoint == startPoint &&
            other.endPoint == endPoint &&
            other.fillColor == fillColor &&
            other.strokeColor == strokeColor &&
            other.strokeWidth == strokeWidth &&
            other.text == text &&
            other.fontSize == fontSize;
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    startPoint,
    endPoint,
    fillColor,
    strokeColor,
    strokeWidth,
    text,
    fontSize,
  );

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
    Color strokeColor = _defaultStrokeColor,
    double strokeWidth = _defaultStrokeWidth,
  }) {
    final center = Offset(
      (startPoint.dx + endPoint.dx) / 2,
      (startPoint.dy + endPoint.dy) / 2,
    );
    final width = (endPoint.dx - startPoint.dx).abs();
    final height = (endPoint.dy - startPoint.dy).abs();
    final radius = (width < height ? width : height) / 2;

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
    Color strokeColor = _defaultStrokeColor,
    double strokeWidth = _defaultStrokeWidth,
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

const Color _defaultFillColor = Color(0x00000000);
const Color _defaultStrokeColor = Color(0xFF000000);
const double _defaultStrokeWidth = 2.0;

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;

  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }

  return true;
}
