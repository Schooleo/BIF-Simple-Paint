import 'dart:collection';

import 'package:bif_simple_paint/features/drawing_board/models/base_shape.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drawing_board_notifier.g.dart';

@riverpod
class DrawingBoardNotifier extends _$DrawingBoardNotifier {
  @override
  DrawingBoardState build() => DrawingBoardState.initial();

  void startDrawing(Offset point, ToolType currentTool) {
    state = state.copyWith(
      activeTempShape: _shapeFromTool(point: point, toolType: currentTool),
    );
  }

  void updateDrawing(Offset point) {
    final activeTempShape = state.activeTempShape;

    if (activeTempShape == null) {
      return;
    }

    state = state.copyWith(activeTempShape: activeTempShape.extendTo(point));
  }

  void commitDrawing() {
    final activeTempShape = state.activeTempShape;

    if (activeTempShape == null) {
      return;
    }

    state = state.commit(activeTempShape.finalize());
  }

  BaseShape _shapeFromTool({
    required Offset point,
    required ToolType toolType,
  }) {
    return switch (toolType) {
      ToolType.brush => BrushShape.seed(point),
      ToolType.eraser => EraserShape.seed(point),
      ToolType.shape => RectangleShape(start: point, end: point),
    };
  }
}

class DrawingBoardState {
  DrawingBoardState._({
    required List<BaseShape> finalizedShapesBacking,
    required List<BaseShape> finalizedShapesView,
    required this.activeTempShape,
  }) : _finalizedShapesBacking = finalizedShapesBacking,
       finalizedShapes = finalizedShapesView;

  factory DrawingBoardState.initial() {
    final finalizedShapesBacking = <BaseShape>[];
    return DrawingBoardState._(
      finalizedShapesBacking: finalizedShapesBacking,
      finalizedShapesView: UnmodifiableListView<BaseShape>(
        finalizedShapesBacking,
      ),
      activeTempShape: null,
    );
  }

  final List<BaseShape> _finalizedShapesBacking;
  final List<BaseShape> finalizedShapes;
  final BaseShape? activeTempShape;

  DrawingBoardState copyWith({Object? activeTempShape = _sentinel}) {
    return DrawingBoardState._(
      finalizedShapesBacking: _finalizedShapesBacking,
      finalizedShapesView: finalizedShapes,
      activeTempShape: identical(activeTempShape, _sentinel)
          ? this.activeTempShape
          : activeTempShape as BaseShape?,
    );
  }

  DrawingBoardState commit(BaseShape shape) {
    final finalizedShapesBacking = List<BaseShape>.of(_finalizedShapesBacking)
      ..add(shape);

    return DrawingBoardState._(
      finalizedShapesBacking: finalizedShapesBacking,
      finalizedShapesView: UnmodifiableListView<BaseShape>(
        finalizedShapesBacking,
      ),
      activeTempShape: null,
    );
  }
}

const Object _sentinel = Object();
