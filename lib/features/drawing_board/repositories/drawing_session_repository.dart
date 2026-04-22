import 'package:bif_simple_paint/core/services/local_storage_service.dart';
import 'package:bif_simple_paint/features/drawing_board/models/stroke_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final drawingSessionRepositoryProvider = Provider<DrawingSessionRepository>((
  ref,
) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return DrawingSessionRepository(localStorageService: localStorageService);
});

class DrawingSessionRepository {
  const DrawingSessionRepository({required this.localStorageService});

  final LocalStorageService localStorageService;

  Future<List<StrokeData>> loadSession(String canvasId) async {
    throw UnimplementedError();
  }

  Future<void> saveSession({
    required String canvasId,
    required List<StrokeData> strokes,
  }) async {
    throw UnimplementedError();
  }
}
