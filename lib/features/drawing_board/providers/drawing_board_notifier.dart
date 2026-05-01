import 'package:bif_simple_paint/features/drawing_board/models/base_shape.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drawing_board_notifier.g.dart';

@riverpod
class DrawingBoardNotifier extends _$DrawingBoardNotifier {
  int _shapeIdCounter = 0;

  @override
  DrawingBoardState build() => DrawingBoardState.initial();

  void startDrawing(Offset point, ToolSelectionState toolSelection) {
    state = state.copyWith(
      activeTempShape: _shapeFromTool(
        point: point,
        toolSelection: toolSelection,
      ),
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

    final committedShape = activeTempShape.finalize().clone();
    _commitState(
      finalizedShapes: <BaseShape>[...state.finalizedShapes, committedShape],
      activeTempShape: null,
      selectedShapeId: committedShape.id,
    );
  }

  void undo() {
    if (!state.canUndo) {
      return;
    }

    final previousSnapshot = _cloneSnapshot(state.undoStack.last);
    final nextUndoStack = state.undoStack
        .take(state.undoStack.length - 1)
        .map(_cloneSnapshot)
        .toList(growable: false);
    final nextRedoStack = <List<BaseShape>>[
      ...state.redoStack.map(_cloneSnapshot),
      _cloneSnapshot(state.finalizedShapes),
    ];

    state = state.copyWith(
      finalizedShapes: previousSnapshot,
      undoStack: nextUndoStack,
      redoStack: nextRedoStack,
      activeTempShape: null,
      selectedShapeId: _selectedShapeIdFor(
        previousSnapshot,
        preferredId: state.selectedShapeId,
      ),
    );
  }

  void redo() {
    if (!state.canRedo) {
      return;
    }

    final nextSnapshot = _cloneSnapshot(state.redoStack.last);
    final nextUndoStack = <List<BaseShape>>[
      ...state.undoStack.map(_cloneSnapshot),
      _cloneSnapshot(state.finalizedShapes),
    ];
    final nextRedoStack = state.redoStack
        .take(state.redoStack.length - 1)
        .map(_cloneSnapshot)
        .toList(growable: false);

    state = state.copyWith(
      finalizedShapes: nextSnapshot,
      undoStack: nextUndoStack,
      redoStack: nextRedoStack,
      activeTempShape: null,
      selectedShapeId: _selectedShapeIdFor(
        nextSnapshot,
        preferredId: state.selectedShapeId,
      ),
    );
  }

  void selectShape(String id) {
    state = state.copyWith(selectedShapeId: state.hasShape(id) ? id : null);
  }

  void updateSelectedShapeStyle({
    Color? fillColor,
    bool updateFillColor = false,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    final selectedShapeId = state.selectedShapeId;
    if (selectedShapeId == null) {
      return;
    }

    final applyFillColor = updateFillColor || fillColor != null;
    var hasChanges = false;
    final updatedShapes = state.finalizedShapes
        .map((shape) {
          if (shape.id != selectedShapeId) {
            return shape.clone();
          }

          final updatedShape = shape.copyStyle(
            fillColor: fillColor,
            applyFillColor: applyFillColor,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
          );
          if (updatedShape != shape) {
            hasChanges = true;
          }
          return updatedShape;
        })
        .toList(growable: false);

    if (!hasChanges) {
      return;
    }

    _commitState(
      finalizedShapes: updatedShapes,
      activeTempShape: null,
      selectedShapeId: selectedShapeId,
    );
  }

  void _commitState({
    required List<BaseShape> finalizedShapes,
    BaseShape? activeTempShape,
    String? selectedShapeId,
  }) {
    final previousSnapshot = _cloneSnapshot(state.finalizedShapes);
    final nextSnapshot = _cloneSnapshot(finalizedShapes);
    final nextUndoStack = <List<BaseShape>>[
      ...state.undoStack.map(_cloneSnapshot),
      previousSnapshot,
    ];

    state = state.copyWith(
      finalizedShapes: nextSnapshot,
      undoStack: nextUndoStack,
      redoStack: const <List<BaseShape>>[],
      activeTempShape: activeTempShape,
      selectedShapeId: _selectedShapeIdFor(
        nextSnapshot,
        preferredId: selectedShapeId,
      ),
    );
  }

  BaseShape _shapeFromTool({
    required Offset point,
    required ToolSelectionState toolSelection,
  }) {
    final id = _nextShapeId();

    return switch (toolSelection.toolType) {
      ToolType.brush => BrushShape.seed(
        point,
        id: id,
        strokeColor: toolSelection.currentStrokeColor,
        strokeWidth: toolSelection.currentStrokeWidth,
      ),
      ToolType.eraser => EraserShape.seed(
        point,
        id: id,
        strokeColor: toolSelection.currentStrokeColor,
        strokeWidth: toolSelection.currentStrokeWidth,
      ),
      ToolType.shape => RectangleShape(
        start: point,
        end: point,
        id: id,
        fillColor: toolSelection.currentFillColor,
        strokeColor: toolSelection.currentStrokeColor,
        strokeWidth: toolSelection.currentStrokeWidth,
      ),
    };
  }

  List<BaseShape> _cloneSnapshot(List<BaseShape> shapes) {
    return shapes.map((shape) => shape.clone()).toList(growable: false);
  }

  String? _selectedShapeIdFor(
    List<BaseShape> shapes, {
    required String? preferredId,
  }) {
    if (preferredId == null) {
      return null;
    }

    return shapes.any((shape) => shape.id == preferredId) ? preferredId : null;
  }

  String _nextShapeId() => 'shape_${_shapeIdCounter++}';
}

class DrawingBoardState {
  DrawingBoardState._({
    required List<BaseShape> finalizedShapes,
    required List<List<BaseShape>> undoStack,
    required List<List<BaseShape>> redoStack,
    required this.activeTempShape,
    required this.selectedShapeId,
  }) : finalizedShapes = List<BaseShape>.unmodifiable(finalizedShapes),
       undoStack = List<List<BaseShape>>.unmodifiable(
         undoStack
             .map((snapshot) => List<BaseShape>.unmodifiable(snapshot))
             .toList(growable: false),
       ),
       redoStack = List<List<BaseShape>>.unmodifiable(
         redoStack
             .map((snapshot) => List<BaseShape>.unmodifiable(snapshot))
             .toList(growable: false),
       );

  factory DrawingBoardState.initial() {
    return DrawingBoardState._(
      finalizedShapes: const <BaseShape>[],
      undoStack: const <List<BaseShape>>[],
      redoStack: const <List<BaseShape>>[],
      activeTempShape: null,
      selectedShapeId: null,
    );
  }

  final List<BaseShape> finalizedShapes;
  final List<List<BaseShape>> undoStack;
  final List<List<BaseShape>> redoStack;
  final BaseShape? activeTempShape;
  final String? selectedShapeId;

  bool get canUndo => undoStack.isNotEmpty;

  bool get canRedo => redoStack.isNotEmpty;

  BaseShape? get selectedShape {
    final selectedShapeId = this.selectedShapeId;
    if (selectedShapeId == null) {
      return null;
    }

    for (final shape in finalizedShapes) {
      if (shape.id == selectedShapeId) {
        return shape;
      }
    }

    return null;
  }

  bool hasShape(String id) {
    return finalizedShapes.any((shape) => shape.id == id);
  }

  DrawingBoardState copyWith({
    List<BaseShape>? finalizedShapes,
    List<List<BaseShape>>? undoStack,
    List<List<BaseShape>>? redoStack,
    Object? activeTempShape = _stateSentinel,
    Object? selectedShapeId = _stateSentinel,
  }) {
    return DrawingBoardState._(
      finalizedShapes: finalizedShapes ?? this.finalizedShapes,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      activeTempShape: identical(activeTempShape, _stateSentinel)
          ? this.activeTempShape
          : activeTempShape as BaseShape?,
      selectedShapeId: identical(selectedShapeId, _stateSentinel)
          ? this.selectedShapeId
          : selectedShapeId as String?,
    );
  }
}

const Object _stateSentinel = Object();
