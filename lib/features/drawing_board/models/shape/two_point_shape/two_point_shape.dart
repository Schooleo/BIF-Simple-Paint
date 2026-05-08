import 'dart:ui';

import 'package:meta/meta.dart';

import '../base_shape.dart';

abstract base class TwoPointShape extends BaseShape {
  const TwoPointShape({
    required this.startPoint,
    required this.endPoint,
    this.fillColor = defaultFillColor,
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
  TwoPointShape translate(Offset delta) {
    return createWith(
      startPoint: startPoint + delta,
      endPoint: endPoint + delta,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  TwoPointShape resize(Offset delta, ResizeCorner corner) {
    final minDx = startPoint.dx < endPoint.dx ? startPoint.dx : endPoint.dx;
    final maxDx = startPoint.dx > endPoint.dx ? startPoint.dx : endPoint.dx;
    final minDy = startPoint.dy < endPoint.dy ? startPoint.dy : endPoint.dy;
    final maxDy = startPoint.dy > endPoint.dy ? startPoint.dy : endPoint.dy;

    final topLeft = Offset(minDx, minDy);
    final topRight = Offset(maxDx, minDy);
    final bottomLeft = Offset(minDx, maxDy);
    final bottomRight = Offset(maxDx, maxDy);

    late final Offset fixedCorner;
    late final Offset movingCorner;

    if (corner == ResizeCorner.topLeft) {
      fixedCorner = bottomRight;
      movingCorner = topLeft + delta;
    } else if (corner == ResizeCorner.topRight) {
      fixedCorner = bottomLeft;
      movingCorner = topRight + delta;
    } else if (corner == ResizeCorner.bottomLeft) {
      fixedCorner = topRight;
      movingCorner = bottomLeft + delta;
    } else {
      fixedCorner = topLeft;
      movingCorner = bottomRight + delta;
    }

    final newStart = Offset(
      fixedCorner.dx < movingCorner.dx ? fixedCorner.dx : movingCorner.dx,
      fixedCorner.dy < movingCorner.dy ? fixedCorner.dy : movingCorner.dy,
    );
    final newEnd = Offset(
      fixedCorner.dx > movingCorner.dx ? fixedCorner.dx : movingCorner.dx,
      fixedCorner.dy > movingCorner.dy ? fixedCorner.dy : movingCorner.dy,
    );

    return createWith(
      startPoint: newStart,
      endPoint: newEnd,
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
