import 'package:flutter/material.dart';
import 'dart:collection';
sealed class BaseShape {
  const BaseShape({
    this.strokeColor = _defaultStrokeColor,
    this.strokeWidth = _defaultStrokeWidth,
  });

  final Color strokeColor;
  final double strokeWidth;

  BlendMode get blendMode => BlendMode.srcOver;

  BaseShape extendTo(Offset point);

  BaseShape finalize() => this;
}

abstract base class PathShape extends BaseShape {
  PathShape({
    required List<Offset> points,
    this.isFinalized = false,
    super.strokeColor,
    super.strokeWidth,
  }) : assert(points.isNotEmpty, 'PathShape requires at least one point.'),
       _points = List<Offset>.of(points, growable: !isFinalized) {
    _pointsView = UnmodifiableListView<Offset>(_points);
  }

  final bool isFinalized;
  final List<Offset> _points;
  late final UnmodifiableListView<Offset> _pointsView;

  List<Offset> get points => _pointsView;

  PathShape createWithPoints(List<Offset> points, {required bool isFinalized});

  @override
  PathShape extendTo(Offset point) {
    if (isFinalized) {
      final nextPoints = List<Offset>.of(_points, growable: true)..add(point);
      return createWithPoints(nextPoints, isFinalized: false);
    }

    _points.add(point);
    return this;
  }

  @override
  PathShape finalize() {
    if (isFinalized) {
      return this;
    }

    return createWithPoints(
      List<Offset>.unmodifiable(_points),
      isFinalized: true,
    );
  }
}

abstract base class TwoPointShape extends BaseShape {
  const TwoPointShape({
    required this.startPoint,
    required this.endPoint,
    this.fillColor = _defaultFillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  final Offset startPoint;
  final Offset endPoint;
  final Color? fillColor;
}

final class BrushShape extends PathShape {
  BrushShape({
    required super.points,
    super.isFinalized,
    super.strokeColor,
    super.strokeWidth,
  });

  factory BrushShape.seed(Offset point) {
    return BrushShape(points: <Offset>[point]);
  }

  @override
  BrushShape createWithPoints(
    List<Offset> points, {
    required bool isFinalized,
  }) => BrushShape(
    points: points,
    isFinalized: isFinalized,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
  );
}

final class EraserShape extends PathShape {
  EraserShape({
    required super.points,
    super.isFinalized,
    super.strokeColor,
    super.strokeWidth,
  });

  @override
  BlendMode get blendMode => BlendMode.clear;

  factory EraserShape.seed(Offset point) {
    return EraserShape(points: <Offset>[point]);
  }

  @override
  EraserShape createWithPoints(
    List<Offset> points, {
    required bool isFinalized,
  }) => EraserShape(
    points: points,
    isFinalized: isFinalized,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
  );
}

final class LineShape extends TwoPointShape {
  const LineShape({
    required super.startPoint,
    required super.endPoint,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  @override
  LineShape extendTo(Offset point) {
    return LineShape(
      startPoint: startPoint,
      endPoint: point,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LineShape &&
            other.startPoint == startPoint &&
            other.endPoint == endPoint &&
            other.fillColor == fillColor &&
            other.strokeColor == strokeColor &&
            other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode =>
      Object.hash(startPoint, endPoint, fillColor, strokeColor, strokeWidth);
}

final class RectangleShape extends TwoPointShape {
  const RectangleShape({
    required Offset start,
    required Offset end,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  }) : super(startPoint: start, endPoint: end);

  Offset get start => startPoint;
  Offset get end => endPoint;

  @override
  RectangleShape extendTo(Offset point) {
    return RectangleShape(
      start: startPoint,
      end: point,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RectangleShape &&
            other.startPoint == startPoint &&
            other.endPoint == endPoint &&
            other.fillColor == fillColor &&
            other.strokeColor == strokeColor &&
            other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode =>
      Object.hash(startPoint, endPoint, fillColor, strokeColor, strokeWidth);
}

final class OvalShape extends TwoPointShape {
  const OvalShape({
    required super.startPoint,
    required super.endPoint,
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
  OvalShape extendTo(Offset point) {
    return OvalShape(
      startPoint: startPoint,
      endPoint: point,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OvalShape &&
            other.startPoint == startPoint &&
            other.endPoint == endPoint &&
            other.fillColor == fillColor &&
            other.strokeColor == strokeColor &&
            other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode =>
      Object.hash(startPoint, endPoint, fillColor, strokeColor, strokeWidth);
}

final class CircleShape extends TwoPointShape {
  CircleShape({
    required this.center,
    required this.radius,
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
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  CircleShape extendTo(Offset point) {
    return CircleShape.fromBounds(
      startPoint: startPoint,
      endPoint: point,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CircleShape &&
            other.center == center &&
            other.radius == radius &&
            other.fillColor == fillColor &&
            other.strokeColor == strokeColor &&
            other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode =>
      Object.hash(center, radius, fillColor, strokeColor, strokeWidth);
}

final class SquareShape extends TwoPointShape {
  SquareShape({
    required this.center,
    required this.sideLength,
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
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  SquareShape extendTo(Offset point) {
    return SquareShape.fromBounds(
      startPoint: startPoint,
      endPoint: point,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SquareShape &&
            other.center == center &&
            other.sideLength == sideLength &&
            other.fillColor == fillColor &&
            other.strokeColor == strokeColor &&
            other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode =>
      Object.hash(center, sideLength, fillColor, strokeColor, strokeWidth);
}

const Color _defaultFillColor = Color(0x00000000);
const Color _defaultStrokeColor = Color(0xFF000000);
const double _defaultStrokeWidth = 2.0;
