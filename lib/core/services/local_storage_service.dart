import 'package:flutter_riverpod/flutter_riverpod.dart';

final localStorageServiceProvider = Provider<LocalStorageService>(
  (ref) => const LocalStorageService(),
);

class LocalStorageService {
  const LocalStorageService();

  Future<String> readDrawing(String canvasId) async {
    throw UnimplementedError();
  }

  Future<void> writeDrawing({
    required String canvasId,
    required String data,
  }) async {
    throw UnimplementedError();
  }

  Future<void> deleteDrawing(String canvasId) async {
    throw UnimplementedError();
  }
}
