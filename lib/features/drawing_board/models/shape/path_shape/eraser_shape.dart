import 'dart:ui';

import '../base_shape.dart';
import 'path_shape.dart';

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
    Color strokeColor = defaultStrokeColor,
    double strokeWidth = defaultStrokeWidth,
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
