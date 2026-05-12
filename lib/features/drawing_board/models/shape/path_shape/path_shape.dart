import 'dart:collection';
import 'dart:ui';

import 'package:meta/meta.dart';

import 'package:bif_simple_paint/core/utils/geometry_helper.dart';

import '../base_shape.dart';

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
  PathShape translate(Offset delta) {
    return createWith(
      points: _points.map((point) => point + delta).toList(growable: false),
      isFinalized: isFinalized,
      id: id,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  PathShape resize(Offset delta, ResizeCorner corner) {
    throw UnsupportedError('Resize is not supported for PathShape.');
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
  PathShape withId(String newId) {
    return createWith(
      points: List<Offset>.of(_points),
      isFinalized: isFinalized,
      id: newId,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
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

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;

  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }

  return true;
}
