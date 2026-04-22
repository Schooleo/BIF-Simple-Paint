import 'package:bif_simple_paint/core/services/database_service.dart';
import 'package:bif_simple_paint/features/canvas_list/models/canvas_metadata.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final canvasListRepositoryProvider = Provider<CanvasListRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return CanvasListRepository(databaseService: databaseService);
});

class CanvasListRepository {
  const CanvasListRepository({required this.databaseService});

  final DatabaseService databaseService;

  Future<List<CanvasMetadata>> fetchCanvases() async {
    throw UnimplementedError();
  }

  Future<void> deleteCanvas(String canvasId) async {
    throw UnimplementedError();
  }
}
