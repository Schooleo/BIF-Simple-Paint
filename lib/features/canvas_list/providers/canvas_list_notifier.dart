import 'package:bif_simple_paint/features/canvas_list/models/canvas_metadata.dart';
import 'package:bif_simple_paint/features/canvas_list/repositories/canvas_list_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final canvasListNotifierProvider =
    NotifierProvider<CanvasListNotifier, CanvasListState>(
      CanvasListNotifier.new,
    );

class CanvasListState {
  const CanvasListState({
    this.canvases = const <CanvasMetadata>[],
    this.isLoading = false,
    this.searchQuery = '',
  });

  final List<CanvasMetadata> canvases;
  final bool isLoading;
  final String searchQuery;

  List<CanvasMetadata> get filteredCanvases {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return canvases;
    }

    return canvases
        .where(
          (canvas) =>
              canvas.name.toLowerCase().contains(query) ||
              canvas.filePath.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  CanvasListState copyWith({
    List<CanvasMetadata>? canvases,
    bool? isLoading,
    String? searchQuery,
  }) {
    return CanvasListState(
      canvases: canvases ?? this.canvases,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CanvasListNotifier extends Notifier<CanvasListState> {
  @override
  CanvasListState build() => const CanvasListState();

  Future<void> loadCanvases() async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(canvasListRepositoryProvider);
      final canvases = await repository.fetchCanvases();
      state = state.copyWith(canvases: canvases);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> deleteCanvas(String canvasId) async {
    final repository = ref.read(canvasListRepositoryProvider);
    try {
      await repository.deleteCanvas(canvasId);
      state = state.copyWith(
        canvases: state.canvases
            .where((canvas) => canvas.id != canvasId)
            .toList(growable: false),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> renameCanvas(String canvasId, String name) async {
    final repository = ref.read(canvasListRepositoryProvider);
    final trimmedName = name.trim();
    final resolvedName = trimmedName.isEmpty ? 'Untitled' : trimmedName;
    try {
      await repository.renameCanvas(canvasId, resolvedName);
      final now = DateTime.now();
      state = state.copyWith(
        canvases: state.canvases
            .map(
              (canvas) => canvas.id == canvasId
                  ? CanvasMetadata(
                      id: canvas.id,
                      name: resolvedName,
                      filePath: canvas.filePath,
                      lastEditedTime: now,
                      documentUri: canvas.documentUri,
                      thumbnailData: canvas.thumbnailData,
                    )
                  : canvas,
            )
            .toList(growable: false),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
