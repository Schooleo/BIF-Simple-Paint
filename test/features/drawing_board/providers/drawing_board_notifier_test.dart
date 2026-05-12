import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:bif_simple_paint/core/services/database_service.dart';
import 'package:bif_simple_paint/core/services/document_file_service.dart';
import 'package:bif_simple_paint/core/utils/binary_serializer.dart';
import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDocumentFileService implements DocumentFileService {
  final Map<String, Uint8List> writes = <String, Uint8List>{};
  int writeCount = 0;

  @override
  Future<DocumentFileReference?> createDocument({
    required String suggestedFileName,
    required Uint8List bytes,
  }) async {
    final uri = 'content://documents/$suggestedFileName';
    writes[uri] = bytes;
    return DocumentFileReference(
      uri: uri,
      displayName: suggestedFileName,
      bytes: bytes,
    );
  }

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<DocumentFileReference?> openDocument() async => null;

  @override
  Future<DocumentFileReference> readDocument(String uri) async {
    return DocumentFileReference(
      uri: uri,
      displayName: uri.split('/').last,
      bytes: writes[uri],
    );
  }

  @override
  Future<void> writeDocument({
    required String uri,
    required Uint8List bytes,
  }) async {
    writeCount += 1;
    writes[uri] = bytes;
  }
}

void main() {
  group('DrawingBoardNotifier', () {
    late ProviderContainer container;
    late DrawingBoardNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(drawingBoardNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    ToolSelectionState selection({
      ToolType toolType = ToolType.brush,
      ShapeType shapeType = ShapeType.rectangle,
      Color fillColor = const Color(0x00000000),
      Color strokeColor = const Color(0xFF000000),
      double strokeWidth = 2,
    }) {
      return ToolSelectionState(
        toolType: toolType,
        shapeType: shapeType,
        currentFillColor: fillColor,
        currentStrokeColor: strokeColor,
        currentStrokeWidth: strokeWidth,
      );
    }

    test('initial state is empty with no active preview or history', () {
      final state = container.read(drawingBoardNotifierProvider);

      expect(state.finalizedShapes, isEmpty);
      expect(state.activeTempShape, isNull);
      expect(state.selectedShapeId, isNull);
      expect(state.undoStack, isEmpty);
      expect(state.redoStack, isEmpty);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
    });

    test(
      'startDrawing seeds a styled brush preview without history changes',
      () {
        notifier.startDrawing(
          const Offset(1, 2),
          selection(strokeColor: const Color(0xFF00FF00), strokeWidth: 5),
        );

        final state = container.read(drawingBoardNotifierProvider);
        final activeTempShape = state.activeTempShape as BrushShape;

        expect(activeTempShape.points, <Offset>[const Offset(1, 2)]);
        expect(activeTempShape.strokeColor, const Color(0xFF00FF00));
        expect(activeTempShape.strokeWidth, 5);
        expect(state.undoStack, isEmpty);
        expect(state.redoStack, isEmpty);
      },
    );

    test('startDrawing maps ToolType.shape to styled rectangle preview', () {
      notifier.startDrawing(
        const Offset(5, 6),
        selection(
          toolType: ToolType.shape,
          shapeType: ShapeType.rectangle,
          fillColor: const Color(0x2200FF00),
          strokeColor: const Color(0xFF123456),
          strokeWidth: 7,
        ),
      );

      final activeTempShape =
          container.read(drawingBoardNotifierProvider).activeTempShape
              as RectangleShape;

      expect(activeTempShape.start, const Offset(5, 6));
      expect(activeTempShape.end, const Offset(5, 6));
      expect(activeTempShape.fillColor, const Color(0x2200FF00));
      expect(activeTempShape.strokeColor, const Color(0xFF123456));
      expect(activeTempShape.strokeWidth, 7);
      expect(activeTempShape.id, isNotEmpty);
    });

    test('startDrawing maps shape type to line preview', () {
      notifier.startDrawing(
        const Offset(2, 3),
        selection(toolType: ToolType.shape, shapeType: ShapeType.line),
      );

      final activeTempShape =
          container.read(drawingBoardNotifierProvider).activeTempShape
              as LineShape;

      expect(activeTempShape.startPoint, const Offset(2, 3));
      expect(activeTempShape.endPoint, const Offset(2, 3));
      expect(activeTempShape.id, isNotEmpty);
    });

    test('startDrawing is a no-op for cursor tool', () {
      notifier.startDrawing(
        const Offset(10, 12),
        selection(toolType: ToolType.cursor),
      );

      final state = container.read(drawingBoardNotifierProvider);

      expect(state.activeTempShape, isNull);
      expect(state.finalizedShapes, isEmpty);
      expect(state.undoStack, isEmpty);
      expect(state.redoStack, isEmpty);
    });

    test(
      'loaded canvas state survives listener gaps so opening a saved canvas does not reset to Untitled',
      () async {
        final bytes = await encodeShapes(
          <BaseShape>[
            const RectangleShape(start: Offset(20, 20), end: Offset(140, 120)),
          ],
          4096,
          4096,
        );

        final failure = await notifier.loadFromBytes(bytes);
        expect(failure, isNull);

        notifier.setCurrentFilePath(
          '/tmp/saved_canvas.mypt',
          canvasId: 'canvas_saved',
          canvasName: 'Saved Canvas',
        );

        await container.pump();

        final state = container.read(drawingBoardNotifierProvider);
        expect(state.currentCanvasId, 'canvas_saved');
        expect(state.currentCanvasName, 'Saved Canvas');
        expect(state.currentFilePath, '/tmp/saved_canvas.mypt');
        expect(state.finalizedShapes, hasLength(1));
      },
    );

    test('updateDrawing is a no-op before startDrawing', () {
      final before = container.read(drawingBoardNotifierProvider);

      notifier.updateDrawing(const Offset(7, 8));

      final after = container.read(drawingBoardNotifierProvider);

      expect(after.finalizedShapes, before.finalizedShapes);
      expect(after.activeTempShape, isNull);
    });

    test('commitDrawing pushes a finalized snapshot onto the undo stack', () {
      notifier.startDrawing(const Offset(1, 1), selection());
      notifier.updateDrawing(const Offset(2, 2));

      notifier.commitDrawing();

      final state = container.read(drawingBoardNotifierProvider);
      final committedShape = state.finalizedShapes.single as BrushShape;

      expect(state.activeTempShape, isNull);
      expect(state.finalizedShapes, hasLength(1));
      expect(committedShape.points, <Offset>[
        const Offset(1, 1),
        const Offset(2, 2),
      ]);
      expect(committedShape.isFinalized, isTrue);
      expect(state.undoStack, hasLength(1));
      expect(state.undoStack.single, isEmpty);
      expect(state.redoStack, isEmpty);
      expect(state.selectedShapeId, committedShape.id);
    });

    test('selectShape picks the committed shape by id', () {
      notifier.startDrawing(const Offset(1, 1), selection());
      notifier.commitDrawing();
      final shapeId = container
          .read(drawingBoardNotifierProvider)
          .finalizedShapes
          .single
          .id;

      notifier.selectShape(shapeId);

      final state = container.read(drawingBoardNotifierProvider);
      expect(state.selectedShapeId, shapeId);
      expect(state.selectedShape?.id, shapeId);
    });

    test('transform updates push an undo snapshot', () {
      notifier.startDrawing(
        const Offset(1, 1),
        selection(toolType: ToolType.shape),
      );
      notifier.updateDrawing(const Offset(10, 12));
      notifier.commitDrawing();
      final shapeId = container
          .read(drawingBoardNotifierProvider)
          .finalizedShapes
          .single
          .id;
      notifier.selectShape(shapeId);

      final before = container.read(drawingBoardNotifierProvider);
      notifier.beginTransform();
      notifier.updateSelectedShape(
        before.selectedShape!.translate(const Offset(10, 5)),
      );
      notifier.endTransform();

      final after = container.read(drawingBoardNotifierProvider);

      expect(after.undoStack.length, before.undoStack.length + 1);
      expect(after.redoStack, isEmpty);
      expect(after.selectedShapeId, shapeId);
    });

    test('transform end without changes does not push undo history', () {
      notifier.startDrawing(const Offset(2, 2), selection());
      notifier.commitDrawing();

      final before = container.read(drawingBoardNotifierProvider);
      notifier.beginTransform();
      notifier.endTransform();

      final after = container.read(drawingBoardNotifierProvider);
      expect(after.undoStack.length, before.undoStack.length);
      expect(after.redoStack, before.redoStack);
    });

    test(
      'updateSelectedShapeStyle commits a detached snapshot for undo history',
      () {
        notifier.startDrawing(const Offset(1, 1), selection());
        notifier.commitDrawing();
        final shapeId = container
            .read(drawingBoardNotifierProvider)
            .finalizedShapes
            .single
            .id;
        notifier.selectShape(shapeId);

        notifier.updateSelectedShapeStyle(
          strokeColor: const Color(0xFFFF0000),
          strokeWidth: 8,
        );

        final state = container.read(drawingBoardNotifierProvider);
        final currentShape = state.finalizedShapes.single as BrushShape;
        final historicalShape = state.undoStack.last.single as BrushShape;

        expect(currentShape.strokeColor, const Color(0xFFFF0000));
        expect(currentShape.strokeWidth, 8);
        expect(historicalShape.strokeColor, const Color(0xFF000000));
        expect(historicalShape.strokeWidth, 2);
        expect(identical(currentShape, historicalShape), isFalse);
        expect(state.redoStack, isEmpty);
      },
    );

    test(
      'undo and redo restore cloned snapshots without leaking style mutations',
      () {
        notifier.startDrawing(const Offset(1, 1), selection());
        notifier.commitDrawing();
        final shapeId = container
            .read(drawingBoardNotifierProvider)
            .finalizedShapes
            .single
            .id;
        notifier.selectShape(shapeId);
        notifier.updateSelectedShapeStyle(
          strokeColor: const Color(0xFFFF0000),
          strokeWidth: 8,
        );

        notifier.undo();
        var state = container.read(drawingBoardNotifierProvider);
        var shape = state.finalizedShapes.single as BrushShape;

        expect(shape.strokeColor, const Color(0xFF000000));
        expect(shape.strokeWidth, 2);
        expect(state.redoStack, hasLength(1));

        notifier.redo();
        state = container.read(drawingBoardNotifierProvider);
        shape = state.finalizedShapes.single as BrushShape;

        expect(shape.strokeColor, const Color(0xFFFF0000));
        expect(shape.strokeWidth, 8);
        expect(state.undoStack, hasLength(2));
        expect(state.redoStack, isEmpty);
      },
    );

    test('new actions after undo clear the redo stack', () {
      notifier.startDrawing(const Offset(1, 1), selection());
      notifier.commitDrawing();
      final shapeId = container
          .read(drawingBoardNotifierProvider)
          .finalizedShapes
          .single
          .id;
      notifier.selectShape(shapeId);
      notifier.updateSelectedShapeStyle(strokeWidth: 6);
      notifier.undo();

      notifier.updateSelectedShapeStyle(strokeColor: const Color(0xFF00FF00));

      final state = container.read(drawingBoardNotifierProvider);
      expect(state.redoStack, isEmpty);
      expect(
        (state.finalizedShapes.single as BrushShape).strokeColor,
        const Color(0xFF00FF00),
      );
    });

    test('updateSelectedShapeStyle is a no-op without a selection', () {
      notifier.startDrawing(const Offset(1, 1), selection());
      notifier.commitDrawing();
      notifier.selectShape('missing-shape');
      final before = container.read(drawingBoardNotifierProvider);

      notifier.updateSelectedShapeStyle(strokeWidth: 10);

      final after = container.read(drawingBoardNotifierProvider);
      expect(after.finalizedShapes.single, before.finalizedShapes.single);
      expect(after.undoStack, before.undoStack);
      expect(after.redoStack, before.redoStack);
      expect(after.selectedShapeId, isNull);
    });

    test('finalizedShapes exposure is unmodifiable', () {
      notifier.startDrawing(const Offset(1, 1), selection());
      notifier.commitDrawing();

      final finalizedShapes = container
          .read(drawingBoardNotifierProvider)
          .finalizedShapes;

      expect(
        () => finalizedShapes.add(BrushShape.seed(const Offset(3, 3))),
        throwsUnsupportedError,
      );
    });

    test(
      'saveToFilePath updates currentFilePath and future autosaves persist to the saved location',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'drawing-board-save',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        final databaseService = DatabaseService(
          storageRootDirectory: tempDirectory,
        );
        final saveContainer = ProviderContainer(
          overrides: <Override>[
            databaseServiceProvider.overrideWithValue(databaseService),
          ],
        );
        addTearDown(saveContainer.dispose);

        final saveNotifier = saveContainer.read(
          drawingBoardNotifierProvider.notifier,
        );
        saveNotifier.updateCanvasTitle('Manual Save');
        saveNotifier.startDrawing(const Offset(5, 5), selection());
        saveNotifier.updateDrawing(const Offset(35, 35));
        saveNotifier.commitDrawing();
        final serializedBytes = await saveNotifier.buildSerializedCanvasBytes();
        final decodedBeforeSave = await decodeShapes(serializedBytes);
        expect(decodedBeforeSave.shapes, hasLength(1));

        final savedPath = await saveNotifier.saveToFilePathWithBytes(
          '${tempDirectory.path}/manual/saved_canvas.mypt',
          canvasBytes: serializedBytes,
        );
        expect(savedPath, '${tempDirectory.path}/manual/saved_canvas.mypt');
        expect(
          saveContainer.read(drawingBoardNotifierProvider).currentFilePath,
          savedPath,
        );

        saveNotifier.startDrawing(const Offset(40, 40), selection());
        saveNotifier.updateDrawing(const Offset(60, 60));
        saveNotifier.commitDrawing();
        await saveNotifier.flushPendingChanges(writeSynchronously: true);

        final metadata = await databaseService.fetchCanvasMetadata();
        expect(metadata, hasLength(1));
        expect(metadata.single[DatabaseService.filePathKey], savedPath);
        expect(await File(savedPath!).exists(), isTrue);

        final savedBytes = await File(savedPath).readAsBytes();
        final decoded = await decodeShapes(savedBytes);
        expect(decoded.shapes, hasLength(2));

        final draftPath = await databaseService.resolveDraftFilePath(
          saveContainer.read(drawingBoardNotifierProvider).currentCanvasId,
        );
        expect(await File(draftPath).exists(), isTrue);
        final draftBytes = await File(draftPath).readAsBytes();
        final decodedDraft = await decodeShapes(draftBytes);
        expect(decodedDraft.shapes, hasLength(2));
      },
    );

    test(
      'saveToDocumentReference updates metadata and future saves can target the document URI',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'drawing-board-manual-ref',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        final databaseService = DatabaseService(
          storageRootDirectory: tempDirectory,
        );
        final documentFileService = FakeDocumentFileService();
        final saveContainer = ProviderContainer(
          overrides: <Override>[
            databaseServiceProvider.overrideWithValue(databaseService),
            documentFileServiceProvider.overrideWithValue(documentFileService),
          ],
        );
        addTearDown(saveContainer.dispose);

        final saveNotifier = saveContainer.read(
          drawingBoardNotifierProvider.notifier,
        );
        final created = await saveNotifier.createNewCanvas(
          title: 'Mobile Save',
        );
        expect(created, isTrue);
        saveNotifier.startDrawing(const Offset(5, 5), selection());
        saveNotifier.updateDrawing(const Offset(35, 35));
        saveNotifier.commitDrawing();
        final draftPathBefore = saveContainer
            .read(drawingBoardNotifierProvider)
            .currentFilePath;

        final serialized = await saveNotifier.buildSerializedCanvasBytes();
        await saveNotifier.saveToDocumentReference(
          const DocumentFileReference(
            uri: 'content://documents/mobile-save.mypt',
            displayName: 'Mobile Save.mypt',
          ),
          canvasBytes: serialized,
        );

        final state = saveContainer.read(drawingBoardNotifierProvider);
        expect(state.currentFilePath, 'Mobile Save.mypt');
        expect(
          state.currentDocumentUri,
          'content://documents/mobile-save.mypt',
        );
        expect(state.currentFilePath, isNot(draftPathBefore));

        final metadata = await databaseService.fetchCanvasMetadata();
        expect(metadata, hasLength(1));
        expect(
          metadata.single[DatabaseService.filePathKey],
          'Mobile Save.mypt',
        );
        expect(
          metadata.single[DatabaseService.documentUriKey],
          'content://documents/mobile-save.mypt',
        );
        expect(
          documentFileService.writes['content://documents/mobile-save.mypt'],
          isNotNull,
        );
        expect(documentFileService.writeCount, 1);

        saveNotifier.startDrawing(const Offset(40, 40), selection());
        saveNotifier.updateDrawing(const Offset(60, 60));
        saveNotifier.commitDrawing();
        await saveNotifier.flushPendingChanges(writeSynchronously: true);

        final draftPath = await databaseService.resolveDraftFilePath(
          saveContainer.read(drawingBoardNotifierProvider).currentCanvasId,
        );
        expect(await File(draftPath).exists(), isTrue);
        final draftBytes = await File(draftPath).readAsBytes();
        final decodedDraft = await decodeShapes(draftBytes);
        expect(decodedDraft.shapes, hasLength(2));

        final externalBytes =
            documentFileService.writes['content://documents/mobile-save.mypt'];
        expect(externalBytes, isNotNull);
        final decodedExternal = await decodeShapes(externalBytes!);
        expect(decodedExternal.shapes, hasLength(2));
      },
    );

    test(
      'saveToDocumentReference can skip an extra write for already-created mobile documents',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'drawing-board-manual-ref-skip-write',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        final databaseService = DatabaseService(
          storageRootDirectory: tempDirectory,
        );
        final documentFileService = FakeDocumentFileService();
        final saveContainer = ProviderContainer(
          overrides: <Override>[
            databaseServiceProvider.overrideWithValue(databaseService),
            documentFileServiceProvider.overrideWithValue(documentFileService),
          ],
        );
        addTearDown(saveContainer.dispose);

        final saveNotifier = saveContainer.read(
          drawingBoardNotifierProvider.notifier,
        );
        final created = await saveNotifier.createNewCanvas(
          title: 'Mobile Save',
        );
        expect(created, isTrue);

        final serialized = await saveNotifier.buildSerializedCanvasBytes();
        await saveNotifier.saveToDocumentReference(
          const DocumentFileReference(
            uri: 'content://documents/mobile-save.mypt',
            displayName: 'Mobile Save.mypt',
          ),
          canvasBytes: serialized,
          writeDocument: false,
        );

        expect(documentFileService.writeCount, 0);
      },
    );

    test('provider implementation stays isolated from repository concerns', () {
      final notifierSource = File(
        'lib/features/drawing_board/providers/drawing_board_notifier.dart',
      ).readAsStringSync();
      final shapeSource = File(
        'lib/features/drawing_board/models/shape/base_shape.dart',
      ).readAsStringSync();

      expect(shapeSource, contains('BaseShape copyStyle'));
      expect(shapeSource, contains('BaseShape clone'));
      expect(notifierSource, contains('void undo()'));
      expect(notifierSource, contains('void redo()'));
      expect(notifierSource, contains('void selectShape(String? id)'));
      expect(notifierSource, contains('void updateSelectedShapeStyle'));

      for (final source in <String>[notifierSource, shapeSource]) {
        expect(source, isNot(contains('loadSession')));
        expect(source, isNot(contains('addStroke')));
        expect(source, isNot(contains('stroke_data.dart')));
        expect(source, isNot(contains('drawingSessionRepositoryProvider')));
        expect(source, isNot(contains('drawing_session_repository.dart')));
      }
    });
  });
}
