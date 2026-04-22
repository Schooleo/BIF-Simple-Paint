import 'package:bif_simple_paint/features/drawing_board/models/stroke_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final drawingBoardNotifierProvider =
    NotifierProvider<DrawingBoardNotifier, DrawingBoardState>(
      DrawingBoardNotifier.new,
    );

class DrawingBoardState {
  const DrawingBoardState({
    this.activeStrokes = const <StrokeData>[],
    this.undoStack = const <StrokeData>[],
    this.redoStack = const <StrokeData>[],
  });

  final List<StrokeData> activeStrokes;
  final List<StrokeData> undoStack;
  final List<StrokeData> redoStack;
}

class DrawingBoardNotifier extends Notifier<DrawingBoardState> {
  @override
  DrawingBoardState build() => const DrawingBoardState();

  Future<void> loadSession(String canvasId) async {
    throw UnimplementedError();
  }

  void addStroke(StrokeData stroke) {
    throw UnimplementedError();
  }

  void undo() {
    throw UnimplementedError();
  }

  void redo() {
    throw UnimplementedError();
  }
}
