import 'dart:ui';

import 'two_point_shape.dart';

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

  TextShape copyWithText({String? text, double? fontSize}) {
    return TextShape(
      startPoint: startPoint,
      endPoint: endPoint,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      id: id,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
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
