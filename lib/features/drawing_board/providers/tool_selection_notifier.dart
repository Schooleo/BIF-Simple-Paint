import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final toolSelectionNotifierProvider =
    NotifierProvider<ToolSelectionNotifier, ToolSelectionState>(
      ToolSelectionNotifier.new,
    );

class ToolSelectionState {
  const ToolSelectionState({
    this.toolType = ToolType.brush,
    this.currentFillColor = const Color(0x00000000),
    this.currentStrokeColor = const Color(0xFF000000),
    this.currentStrokeWidth = 2,
  });

  final ToolType toolType;
  final Color currentFillColor;
  final Color currentStrokeColor;
  final double currentStrokeWidth;

  ToolSelectionState copyWith({
    ToolType? toolType,
    Color? currentFillColor,
    Color? currentStrokeColor,
    double? currentStrokeWidth,
  }) {
    return ToolSelectionState(
      toolType: toolType ?? this.toolType,
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
    state = state.copyWith(toolType: toolType);
  }

  void updateFillColor(Color fillColor) {
    state = state.copyWith(currentFillColor: fillColor);
  }

  void updateStrokeColor(Color strokeColor) {
    state = state.copyWith(currentStrokeColor: strokeColor);
  }

  void updateStrokeWidth(double strokeWidth) {
    state = state.copyWith(currentStrokeWidth: strokeWidth);
  }
}
