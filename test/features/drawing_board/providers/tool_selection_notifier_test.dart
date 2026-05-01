import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolSelectionNotifier', () {
    late ProviderContainer container;
    late ToolSelectionNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(toolSelectionNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state exposes default active styling', () {
      final state = container.read(toolSelectionNotifierProvider);

      expect(state.toolType, ToolType.brush);
      expect(state.currentFillColor, const Color(0x00000000));
      expect(state.currentStrokeColor, const Color(0xFF000000));
      expect(state.currentStrokeWidth, 2);
    });

    test('selection and style updates are persisted', () {
      notifier.selectTool(ToolType.shape);
      notifier.updateFillColor(const Color(0x2200FF00));
      notifier.updateStrokeColor(const Color(0xFFFF0000));
      notifier.updateStrokeWidth(5);

      final state = container.read(toolSelectionNotifierProvider);

      expect(state.toolType, ToolType.shape);
      expect(state.currentFillColor, const Color(0x2200FF00));
      expect(state.currentStrokeColor, const Color(0xFFFF0000));
      expect(state.currentStrokeWidth, 5);
    });
  });
}
