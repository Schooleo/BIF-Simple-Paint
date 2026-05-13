import 'dart:typed_data';

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
    final entries = await databaseService.fetchCanvasMetadata();
    return entries.map(CanvasMetadata.fromMap).toList(growable: false);
  }

  Future<void> deleteCanvas(String canvasId) async {
    await databaseService.deleteCanvasMetadata(canvasId);
  }

  Future<void> renameCanvas(String canvasId, String name) async {
    await databaseService.updateCanvasName(canvasId: canvasId, name: name);
  }

  Future<bool> canvasFileExists(String filePath) async {
    return databaseService.canvasFileExists(filePath);
  }

  Future<Uint8List> loadCanvasBytes(String filePath) async {
    return databaseService.readCanvasBytes(filePath);
  }
}
