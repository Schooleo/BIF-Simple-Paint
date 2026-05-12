import 'dart:ui';

import 'package:bif_simple_paint/core/theme/app_colors.dart';

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

  /// Returns a copy of this shape with [newId] as the identifier.
  BaseShape withId(String newId);
}

enum ResizeCorner { topLeft, topRight, bottomLeft, bottomRight }

const Color defaultFillColor = AppColors.drawingFillTransparent;
const Color defaultStrokeColor = AppColors.drawingStrokeDefault;
const double defaultStrokeWidth = 2.0;
