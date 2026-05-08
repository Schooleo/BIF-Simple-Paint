import 'dart:ui';

abstract base class BaseShape {
  const BaseShape({
    this.id = '',
    this.strokeColor = defaultStrokeColor,
    this.strokeWidth = defaultStrokeWidth,
  });

  final String id;
  final Color strokeColor;
  final double strokeWidth;

  BlendMode get blendMode => BlendMode.srcOver;

  BaseShape extendTo(Offset point);

  bool contains(Offset point);

  BaseShape translate(Offset delta);

  BaseShape resize(Offset delta, ResizeCorner corner);

  BaseShape finalize() => this;

  BaseShape clone();

  BaseShape copyStyle({
    Color? fillColor,
    bool applyFillColor = false,
    Color? strokeColor,
    double? strokeWidth,
  });
}

enum ResizeCorner { topLeft, topRight, bottomLeft, bottomRight }

const Color defaultFillColor = Color(0x00000000);
const Color defaultStrokeColor = Color(0xFF000000);
const double defaultStrokeWidth = 2.0;
