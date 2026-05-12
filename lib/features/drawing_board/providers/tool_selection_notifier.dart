import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final toolSelectionNotifierProvider =
    NotifierProvider<ToolSelectionNotifier, ToolSelectionState>(
      ToolSelectionNotifier.new,
    );

const double kMinStrokeWidth = 1.0;
const double kMaxStrokeWidth = 30.0;
const double kMaxEraserStrokeWidth = 60.0;
const double kStrokeWidthStep = 0.5;

double maxStrokeWidthForTool(ToolType toolType) {
  return toolType == ToolType.eraser ? kMaxEraserStrokeWidth : kMaxStrokeWidth;
}

class ToolSelectionState {
  const ToolSelectionState({
    this.toolType = ToolType.brush,
    this.shapeType = ShapeType.rectangle,
    this.currentFillColor = AppColors.drawingFillTransparent,
    this.currentStrokeColor = AppColors.drawingStrokeDefault,
    this.currentStrokeWidth = 2,
  });

  final ToolType toolType;
  final ShapeType shapeType;
  final Color currentFillColor;
  final Color currentStrokeColor;
  final double currentStrokeWidth;

  ToolSelectionState copyWith({
    ToolType? toolType,
    ShapeType? shapeType,
    Color? currentFillColor,
    Color? currentStrokeColor,
    double? currentStrokeWidth,
  }) {
    return ToolSelectionState(
      toolType: toolType ?? this.toolType,
      shapeType: shapeType ?? this.shapeType,
      currentFillColor: currentFillColor ?? this.currentFillColor,
      currentStrokeColor: currentStrokeColor ?? this.currentStrokeColor,
      currentStrokeWidth: currentStrokeWidth ?? this.currentStrokeWidth,
    );
  }
}

class ToolSelectionNotifier extends Notifier<ToolSelectionState> {
  @override
  ToolSelectionState build() => const ToolSelectionState();

  void selectTool(ToolType toolType) {
    final double maxWidth = maxStrokeWidthForTool(toolType);
    final double clampedWidth = state.currentStrokeWidth
        .clamp(kMinStrokeWidth, maxWidth)
        .toDouble();
    state = state.copyWith(
      toolType: toolType,
      currentStrokeWidth: clampedWidth,
    );
  }

  void selectShapeType(ShapeType shapeType) {
    state = state.copyWith(shapeType: shapeType);
  }

  void updateFillColor(Color fillColor) {
    state = state.copyWith(currentFillColor: fillColor);
  }

  void updateStrokeColor(Color strokeColor) {
    state = state.copyWith(currentStrokeColor: strokeColor);
  }

  void updateStrokeWidth(double strokeWidth) {
    final double maxWidth = maxStrokeWidthForTool(state.toolType);
    final double clampedWidth = strokeWidth
        .clamp(kMinStrokeWidth, maxWidth)
        .toDouble();
    state = state.copyWith(currentStrokeWidth: clampedWidth);
  }
}
