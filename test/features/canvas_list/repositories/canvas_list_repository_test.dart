import 'dart:io';
import 'dart:typed_data';

import 'package:bif_simple_paint/core/services/database_service.dart';
import 'package:bif_simple_paint/features/canvas_list/repositories/canvas_list_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CanvasListRepository', () {
    late Directory tempDirectory;
    late DatabaseService databaseService;
    late CanvasListRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('canvas-list-repo');
      databaseService = DatabaseService(storageRootDirectory: tempDirectory);
      repository = CanvasListRepository(databaseService: databaseService);
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'fetchCanvases returns persisted metadata in last-edited order',
      () async {
        await databaseService.persistCanvas(
          canvasId: 'older',
          name: 'Older Project',
          canvasBytes: Uint8List.fromList(<int>[1, 2, 3]),
          lastEditedTime: DateTime.utc(2024, 1, 1),
        );
        await databaseService.persistCanvas(
          canvasId: 'newer',
          name: 'Newer Project',
          canvasBytes: Uint8List.fromList(<int>[4, 5, 6]),
          lastEditedTime: DateTime.utc(2025, 1, 1),
        );

        final canvases = await repository.fetchCanvases();

        expect(canvases, hasLength(2));
        expect(canvases.first.id, 'newer');
        expect(canvases.first.name, 'Newer Project');
        expect(canvases.first.filePath, endsWith('newer.mypt'));
        expect(canvases.last.id, 'older');
      },
    );

    test('deleteCanvas removes the persisted recent-project entry', () async {
      await databaseService.persistCanvas(
        canvasId: 'draft-1',
        name: 'Draft',
        canvasBytes: Uint8List.fromList(<int>[7, 8, 9]),
      );

      final beforeDelete = await repository.fetchCanvases();
      final draftPath = beforeDelete.single.filePath;

      await repository.deleteCanvas('draft-1');

      final afterDelete = await repository.fetchCanvases();
      expect(afterDelete, isEmpty);
      expect(await File(draftPath).exists(), isFalse);
    });

    test(
      'deleteCanvas also removes the shadow draft for external saves',
      () async {
        const canvasId = 'external-1';
        final externalPath = '${tempDirectory.path}/manual/external.mypt';
        await databaseService.persistCanvas(
          canvasId: canvasId,
          name: 'External Draft',
          filePath: externalPath,
          canvasBytes: Uint8List.fromList(<int>[7, 8, 9]),
        );
        final draftPath = await databaseService.writeDraftCopy(
          canvasId: canvasId,
          canvasBytes: Uint8List.fromList(<int>[1, 2, 3]),
        );

        expect(await File(externalPath).exists(), isTrue);
        expect(await File(draftPath).exists(), isTrue);

        await repository.deleteCanvas(canvasId);

        expect(await File(externalPath).exists(), isTrue);
        expect(await File(draftPath).exists(), isFalse);
      },
    );
  });
}
