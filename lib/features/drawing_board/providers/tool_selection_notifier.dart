import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final toolSelectionNotifierProvider =
    NotifierProvider<ToolSelectionNotifier, ToolSelectionState>(
      ToolSelectionNotifier.new,
    );

class ToolSelectionState {
  const ToolSelectionState({
    this.toolType = ToolType.brush,
    this.brushSize = 1,
  });

  final ToolType toolType;
  final double brushSize;
}

class ToolSelectionNotifier extends Notifier<ToolSelectionState> {
  @override
  ToolSelectionState build() => const ToolSelectionState();

  void selectTool(ToolType toolType) {
    throw UnimplementedError();
  }

  void updateBrushSize(double brushSize) {
    throw UnimplementedError();
  }
}
