import 'package:bif_simple_paint/features/canvas_list/models/canvas_metadata.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final canvasListNotifierProvider =
    NotifierProvider<CanvasListNotifier, CanvasListState>(
      CanvasListNotifier.new,
    );

class CanvasListState {
  const CanvasListState({
    this.canvases = const <CanvasMetadata>[],
    this.isLoading = false,
  });

  final List<CanvasMetadata> canvases;
  final bool isLoading;
}

class CanvasListNotifier extends Notifier<CanvasListState> {
  @override
  CanvasListState build() => const CanvasListState();

  Future<void> loadCanvases() async {
    throw UnimplementedError();
  }

  Future<void> deleteCanvas(String canvasId) async {
    throw UnimplementedError();
  }
}
