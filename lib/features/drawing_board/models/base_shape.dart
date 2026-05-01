import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  PathShape finalize() {
    if (isFinalized) {
      return clone();
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
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other is PathShape &&
            other.id == id &&
            other.isFinalized == isFinalized &&
            listEquals(other.points, points) &&
            other.strokeColor == strokeColor &&
            other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    isFinalized,
    Object.hashAll(points),
    strokeColor,
    strokeWidth,
  );
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
}

const Color _defaultFillColor = Color(0x00000000);
const Color _defaultStrokeColor = Color(0xFF000000);
const double _defaultStrokeWidth = 2.0;
