import 'dart:io';
import 'dart:typed_data';

import 'package:bif_simple_paint/core/services/database_service.dart';
import 'package:bif_simple_paint/features/canvas_list/providers/canvas_list_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CanvasListNotifier', () {
    late Directory tempDirectory;
    late DatabaseService databaseService;
    late ProviderContainer container;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'canvas-list-notifier',
      );
      databaseService = DatabaseService(storageRootDirectory: tempDirectory);
      container = ProviderContainer(
        overrides: <Override>[
          databaseServiceProvider.overrideWithValue(databaseService),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'loadCanvases populates state from the local metadata database',
      () async {
        await databaseService.persistCanvas(
          canvasId: 'canvas-a',
          name: 'Alpha Sketch',
          canvasBytes: Uint8List.fromList(<int>[1, 1, 1]),
          lastEditedTime: DateTime.utc(2024, 5, 1),
        );
        await databaseService.persistCanvas(
          canvasId: 'canvas-b',
          name: 'Beta Diagram',
          canvasBytes: Uint8List.fromList(<int>[2, 2, 2]),
          lastEditedTime: DateTime.utc(2025, 5, 1),
        );

        await container
            .read(canvasListNotifierProvider.notifier)
            .loadCanvases();

        final state = container.read(canvasListNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.canvases.map((canvas) => canvas.id), <String>[
          'canvas-b',
          'canvas-a',
        ]);
      },
    );

    test('setSearchQuery filters canvases by name and file path', () async {
      await databaseService.persistCanvas(
        canvasId: 'canvas-a',
        name: 'Wireframe',
        filePath: '${tempDirectory.path}/wireframe.mypt',
        canvasBytes: Uint8List.fromList(<int>[3, 3, 3]),
      );
      await databaseService.persistCanvas(
        canvasId: 'canvas-b',
        name: 'Landscape',
        filePath: '${tempDirectory.path}/paintings/landscape.mypt',
        canvasBytes: Uint8List.fromList(<int>[4, 4, 4]),
      );

      final notifier = container.read(canvasListNotifierProvider.notifier);
      await notifier.loadCanvases();

      notifier.setSearchQuery('paintings');
      expect(
        container
            .read(canvasListNotifierProvider)
            .filteredCanvases
            .map((canvas) => canvas.id),
        <String>['canvas-b'],
      );

      notifier.setSearchQuery('wire');
      expect(
        container
            .read(canvasListNotifierProvider)
            .filteredCanvases
            .map((canvas) => canvas.id),
        <String>['canvas-a'],
      );
    });

    test('deleteCanvas removes the item from notifier state', () async {
      await databaseService.persistCanvas(
        canvasId: 'canvas-a',
        name: 'Disposable Draft',
        canvasBytes: Uint8List.fromList(<int>[5, 5, 5]),
      );

      final notifier = container.read(canvasListNotifierProvider.notifier);
      await notifier.loadCanvases();
      await notifier.deleteCanvas('canvas-a');

      final state = container.read(canvasListNotifierProvider);
      expect(state.canvases, isEmpty);
    });
  });
}
