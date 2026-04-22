import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => const DatabaseService(),
);

class DatabaseService {
  const DatabaseService();

  Future<List<Map<String, Object?>>> fetchCanvasMetadata() async {
    throw UnimplementedError();
  }

  Future<void> insertCanvasMetadata(Map<String, Object?> values) async {
    throw UnimplementedError();
  }

  Future<void> deleteCanvasMetadata(String canvasId) async {
    throw UnimplementedError();
  }
}
