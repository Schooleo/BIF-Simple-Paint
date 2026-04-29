import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

sealed class BaseShape {
  const BaseShape();

  BaseShape extendTo(Offset point);
}

abstract base class PathShape extends BaseShape {
  PathShape({required List<Offset> points})
    : points = UnmodifiableListView<Offset>(List<Offset>.of(points));

  final List<Offset> points;

  PathShape createWithPoints(List<Offset> points);

  @override
  PathShape extendTo(Offset point) {
    return createWithPoints(<Offset>[...points, point]);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other is PathShape &&
            listEquals(other.points, points);
  }

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(points));
}

final class BrushShape extends PathShape {
  BrushShape({required super.points});

  factory BrushShape.seed(Offset point) {
    return BrushShape(points: <Offset>[point]);
  }

  @override
  BrushShape createWithPoints(List<Offset> points) =>
      BrushShape(points: points);
}

final class EraserShape extends PathShape {
  EraserShape({required super.points});

  factory EraserShape.seed(Offset point) {
    return EraserShape(points: <Offset>[point]);
  }

  @override
  EraserShape createWithPoints(List<Offset> points) =>
      EraserShape(points: points);
}

final class RectangleShape extends BaseShape {
  const RectangleShape({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  RectangleShape extendTo(Offset point) {
    return RectangleShape(start: start, end: point);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RectangleShape && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
