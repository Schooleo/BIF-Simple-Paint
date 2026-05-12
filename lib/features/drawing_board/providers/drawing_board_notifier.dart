import 'dart:async';
import 'dart:typed_data';

import 'package:bif_simple_paint/core/services/database_service.dart';
import 'package:bif_simple_paint/core/services/document_file_service.dart';
import 'package:bif_simple_paint/core/utils/binary_serializer.dart';
import 'package:bif_simple_paint/core/utils/thumbnail_generator.dart';
import 'package:bif_simple_paint/features/canvas_list/providers/canvas_list_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drawing_board_notifier.g.dart';

const Duration _autoSaveDebounce = Duration(seconds: 2);
const double _serializedCanvasWidth = 4096;
const double _serializedCanvasHeight = 4096;

enum CanvasLoadFailure { unsupportedVersion, corruptedFile }

@Riverpod(keepAlive: true)
class DrawingBoardNotifier extends _$DrawingBoardNotifier
    with WidgetsBindingObserver {
  int _shapeIdCounter = 0;
  int _revision = 0;
  int _lastSavedRevision = -1;
  bool _isDisposed = false;
  List<BaseShape>? _transformSnapshot;
  Timer? _autoSaveTimer;
  Future<void> _saveSequence = Future<void>.value();

  @override
  DrawingBoardState build() {
    _isDisposed = false;
    WidgetsFlutterBinding.ensureInitialized().addObserver(this);
    ref.onDispose(() {
      _isDisposed = true;
      _autoSaveTimer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });

    return DrawingBoardState.initial(
      currentCanvasId: _generateCanvasId(),
      currentCanvasName: 'Untitled',
    );
  }

  Future<bool> createNewCanvas({String? title}) async {
    _autoSaveTimer?.cancel();
    _transformSnapshot = null;
    _shapeIdCounter = 0;
    _revision = 0;
    _lastSavedRevision = -1;
    _saveSequence = Future<void>.value();

    final resolvedTitle = (title ?? 'Untitled').trim();
    state = DrawingBoardState.initial(
      currentCanvasId: _generateCanvasId(),
      currentCanvasName: resolvedTitle.isEmpty ? 'Untitled' : resolvedTitle,
      shouldFocusCanvasTitle: true,
    );

    try {
      await _persistCurrentCanvas();
      _lastSavedRevision = _revision;
      return true;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'drawing_board_notifier',
          context: ErrorDescription('while creating a new canvas'),
        ),
      );
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) {
      return;
    }

    _autoSaveTimer?.cancel();
    unawaited(_flushAutoSave(writeSynchronously: true));
  }

  void startDrawing(Offset point, ToolSelectionState toolSelection) {
    if (toolSelection.toolType == ToolType.cursor) {
      return;
    }

    final nextShape = _shapeFromTool(
      point: point,
      toolSelection: toolSelection,
    );
    if (nextShape == null) {
      return;
    }

    state = state.copyWith(activeTempShape: nextShape);
  }

  void updateDrawing(
    Offset point, {
    ToolSelectionState? toolSelection,
    bool constrainToSquare = false,
  }) {
    final activeTempShape = state.activeTempShape;

    if (activeTempShape == null) {
      return;
    }

    if (toolSelection != null &&
        toolSelection.toolType == ToolType.shape &&
        activeTempShape is TwoPointShape) {
      state = state.copyWith(
        activeTempShape: _shapeFromBounds(
          toolSelection,
          activeTempShape.startPoint,
          point,
          activeTempShape.id,
          constrain: constrainToSquare,
        ),
      );
      return;
    }

    state = state.copyWith(activeTempShape: activeTempShape.extendTo(point));
  }

  void commitDrawing() {
    final activeTempShape = state.activeTempShape;

    if (activeTempShape == null) {
      return;
    }

    final committedShape = activeTempShape.finalize().clone();
    _commitState(
      finalizedShapes: <BaseShape>[...state.finalizedShapes, committedShape],
      activeTempShape: null,
      selectedShapeId: committedShape.id,
    );
  }

  void undo() {
    if (!state.canUndo) {
      return;
    }

    final previousSnapshot = _cloneSnapshot(state.undoStack.last);
    final nextUndoStack = state.undoStack
        .take(state.undoStack.length - 1)
        .map(_cloneSnapshot)
        .toList(growable: false);
    final nextRedoStack = <List<BaseShape>>[
      ...state.redoStack.map(_cloneSnapshot),
      _cloneSnapshot(state.finalizedShapes),
    ];

    state = state.copyWith(
      finalizedShapes: previousSnapshot,
      undoStack: nextUndoStack,
      redoStack: nextRedoStack,
      activeTempShape: null,
      selectedShapeId: _selectedShapeIdFor(
        previousSnapshot,
        preferredId: state.selectedShapeId,
      ),
    );

    _markDirty();
  }

  void redo() {
    if (!state.canRedo) {
      return;
    }

    final nextSnapshot = _cloneSnapshot(state.redoStack.last);
    final nextUndoStack = <List<BaseShape>>[
      ...state.undoStack.map(_cloneSnapshot),
      _cloneSnapshot(state.finalizedShapes),
    ];
    final nextRedoStack = state.redoStack
        .take(state.redoStack.length - 1)
        .map(_cloneSnapshot)
        .toList(growable: false);

    state = state.copyWith(
      finalizedShapes: nextSnapshot,
      undoStack: nextUndoStack,
      redoStack: nextRedoStack,
      activeTempShape: null,
      selectedShapeId: _selectedShapeIdFor(
        nextSnapshot,
        preferredId: state.selectedShapeId,
      ),
    );

    _markDirty();
  }

  Future<CanvasLoadFailure?> loadFromBytes(Uint8List data) async {
    try {
      final decoded = await decodeShapes(data);
      final shapes = decoded.shapes;
      final nextCanvasId = _generateCanvasId();

      _transformSnapshot = null;
      _shapeIdCounter = _nextIdFromShapes(shapes);

      state = DrawingBoardState.initial(
        currentCanvasId: nextCanvasId,
        currentCanvasName: 'Untitled',
        shouldFocusCanvasTitle: false,
      ).copyWith(finalizedShapes: _cloneSnapshot(shapes));
      _markDirty();
      return null;
    } on FormatException catch (error) {
      return _mapLoadFailure(error);
    } catch (_) {
      return CanvasLoadFailure.corruptedFile;
    }
  }

  CanvasLoadFailure _mapLoadFailure(FormatException error) {
    final message = error.message;
    if (message.contains('unsupported version') ||
        message.contains('Invalid magic bytes')) {
      return CanvasLoadFailure.unsupportedVersion;
    }
    return CanvasLoadFailure.corruptedFile;
  }

  void setCurrentFilePath(
    String? filePath, {
    String? canvasId,
    String? canvasName,
    String? currentDocumentUri,
  }) {
    state = state.copyWith(
      currentCanvasId: canvasId,
      currentFilePath: filePath,
      currentDocumentUri: currentDocumentUri,
      currentCanvasName: canvasName ?? _canvasNameFor(filePath),
      shouldFocusCanvasTitle: false,
    );
  }

  void updateCanvasTitle(String title) {
    final trimmed = title.trim();
    final resolvedTitle = trimmed.isEmpty ? 'Untitled' : trimmed;
    final hasChanged =
        resolvedTitle != state.currentCanvasName ||
        state.shouldFocusCanvasTitle;
    if (!hasChanged) {
      return;
    }

    state = state.copyWith(
      currentCanvasName: resolvedTitle,
      shouldFocusCanvasTitle: false,
    );
    _markDirty();
  }

  void consumeCanvasTitleFocusRequest() {
    if (!state.shouldFocusCanvasTitle) {
      return;
    }

    state = state.copyWith(shouldFocusCanvasTitle: false);
  }

  Future<void> flushPendingChanges({bool writeSynchronously = false}) {
    if (writeSynchronously) {
      _autoSaveTimer?.cancel();
    }

    return _flushAutoSave(writeSynchronously: writeSynchronously);
  }

  Future<bool> isUsingDraftPath() async {
    if (state.currentDocumentUri?.trim().isNotEmpty == true) {
      return false;
    }

    final currentPath = state.currentFilePath;
    if (currentPath == null || currentPath.trim().isEmpty) {
      return true;
    }

    final databaseService = ref.read(databaseServiceProvider);
    final draftPath = await databaseService.resolveDraftFilePath(
      state.currentCanvasId,
    );
    return _normalizePath(currentPath) == _normalizePath(draftPath);
  }

  void selectShape(String? id) {
    if (id == null) {
      state = state.copyWith(selectedShapeId: null);
      return;
    }

    state = state.copyWith(selectedShapeId: state.hasShape(id) ? id : null);
  }

  void beginTransform() {
    _transformSnapshot ??= _cloneSnapshot(state.finalizedShapes);
  }

  void updateSelectedShape(BaseShape updatedShape) {
    final selectedShapeId = state.selectedShapeId;
    if (selectedShapeId == null || updatedShape.id != selectedShapeId) {
      return;
    }

    final updatedShapes = state.finalizedShapes
        .map(
          (shape) => shape.id == selectedShapeId ? updatedShape : shape.clone(),
        )
        .toList(growable: false);

    if (_transformSnapshot != null) {
      state = state.copyWith(finalizedShapes: updatedShapes);
      return;
    }

    _commitState(
      finalizedShapes: updatedShapes,
      activeTempShape: null,
      selectedShapeId: selectedShapeId,
    );
  }

  void endTransform() {
    final previousSnapshot = _transformSnapshot;
    if (previousSnapshot == null) {
      return;
    }

    _transformSnapshot = null;

    final currentSnapshot = _cloneSnapshot(state.finalizedShapes);
    if (_snapshotsEqual(previousSnapshot, currentSnapshot)) {
      return;
    }

    final nextUndoStack = <List<BaseShape>>[
      ...state.undoStack.map(_cloneSnapshot),
      _cloneSnapshot(previousSnapshot),
    ];

    state = state.copyWith(
      finalizedShapes: currentSnapshot,
      undoStack: nextUndoStack,
      redoStack: const <List<BaseShape>>[],
      activeTempShape: null,
      selectedShapeId: _selectedShapeIdFor(
        currentSnapshot,
        preferredId: state.selectedShapeId,
      ),
    );

    _markDirty();
  }

  void updateSelectedShapeStyle({
    Color? fillColor,
    bool updateFillColor = false,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    final selectedShapeId = state.selectedShapeId;
    if (selectedShapeId == null) {
      return;
    }

    final applyFillColor = updateFillColor || fillColor != null;
    var hasChanges = false;
    final updatedShapes = state.finalizedShapes
        .map((shape) {
          if (shape.id != selectedShapeId) {
            return shape.clone();
          }

          final updatedShape = shape.copyStyle(
            fillColor: fillColor,
            applyFillColor: applyFillColor,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
          );
          if (updatedShape != shape) {
            hasChanges = true;
          }
          return updatedShape;
        })
        .toList(growable: false);

    if (!hasChanges) {
      return;
    }

    _commitState(
      finalizedShapes: updatedShapes,
      activeTempShape: null,
      selectedShapeId: selectedShapeId,
    );
  }

  void _commitState({
    required List<BaseShape> finalizedShapes,
    BaseShape? activeTempShape,
    String? selectedShapeId,
  }) {
    final previousSnapshot = _cloneSnapshot(state.finalizedShapes);
    final nextSnapshot = _cloneSnapshot(finalizedShapes);
    final nextUndoStack = <List<BaseShape>>[
      ...state.undoStack.map(_cloneSnapshot),
      previousSnapshot,
    ];

    state = state.copyWith(
      finalizedShapes: nextSnapshot,
      undoStack: nextUndoStack,
      redoStack: const <List<BaseShape>>[],
      activeTempShape: activeTempShape,
      selectedShapeId: _selectedShapeIdFor(
        nextSnapshot,
        preferredId: selectedShapeId,
      ),
    );

    _markDirty();
  }

  void _markDirty() {
    _revision += 1;
    _autoSaveTimer?.cancel();
    if (!_autoSaveEnabled) {
      return;
    }
    _autoSaveTimer = Timer(_autoSaveDebounce, () {
      unawaited(_flushAutoSave());
    });
  }

  Future<void> _flushAutoSave({bool writeSynchronously = false}) {
    final targetRevision = _revision;
    if (targetRevision == _lastSavedRevision && !writeSynchronously) {
      return _saveSequence;
    }

    _saveSequence = _saveSequence.then((_) async {
      if (targetRevision == _lastSavedRevision && !writeSynchronously) {
        return;
      }

      try {
        await _persistCurrentCanvas(writeSynchronously: writeSynchronously);
        _lastSavedRevision = targetRevision;
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'drawing_board_notifier',
            context: ErrorDescription('while auto-saving the current canvas'),
          ),
        );
      }
    });

    return _saveSequence;
  }

  Future<void> _persistCurrentCanvas({bool writeSynchronously = false}) async {
    final databaseService = ref.read(databaseServiceProvider);
    final snapshot = _cloneSnapshot(state.finalizedShapes);
    final serialized = await buildSerializedCanvasBytes();
    final thumbnailData = await ThumbnailGenerator.generate(snapshot);
    final currentDocumentUri = state.currentDocumentUri?.trim();
    final draftPath = await databaseService.resolveDraftFilePath(
      state.currentCanvasId,
    );
    final currentFilePath = state.currentFilePath;
    final usesDraftPath =
        currentDocumentUri == null &&
        (currentFilePath == null ||
            _normalizePath(currentFilePath) == _normalizePath(draftPath));

    if (!usesDraftPath) {
      await databaseService.writeDraftCopy(
        canvasId: state.currentCanvasId,
        canvasBytes: serialized,
        synchronous: writeSynchronously,
      );
    }

    if (currentDocumentUri != null && currentDocumentUri.isNotEmpty) {
      await ref
          .read(documentFileServiceProvider)
          .writeDocument(uri: currentDocumentUri, bytes: serialized);
      await databaseService.insertCanvasMetadata(<String, Object?>{
        DatabaseService.idKey: state.currentCanvasId,
        DatabaseService.nameKey: state.currentCanvasName,
        DatabaseService.filePathKey:
            state.currentFilePath ?? _canvasNameFor(state.currentCanvasName),
        DatabaseService.documentUriKey: currentDocumentUri,
        DatabaseService.lastEditedTimeKey: DateTime.now().toIso8601String(),
        DatabaseService.thumbnailDataKey: thumbnailData,
      });

      if (_isDisposed) {
        return;
      }

      unawaited(ref.read(canvasListNotifierProvider.notifier).loadCanvases());
      return;
    }

    final resolvedPath = await databaseService.persistCanvas(
      canvasId: state.currentCanvasId,
      name: state.currentCanvasName,
      filePath: state.currentFilePath,
      documentUri: state.currentDocumentUri,
      canvasBytes: serialized,
      thumbnailData: thumbnailData,
      lastEditedTime: DateTime.now(),
      synchronous: writeSynchronously,
    );

    if (_isDisposed) {
      return;
    }

    unawaited(ref.read(canvasListNotifierProvider.notifier).loadCanvases());

    if (state.currentFilePath == null) {
      state = state.copyWith(currentFilePath: resolvedPath);
    }
  }

  Future<String?> saveToFilePath(String? filePath) async {
    return saveToFilePathWithBytes(filePath);
  }

  Future<Uint8List> buildSerializedCanvasBytes() async {
    final snapshot = _cloneSnapshot(state.finalizedShapes);
    return encodeShapes(
      snapshot,
      _serializedCanvasWidth,
      _serializedCanvasHeight,
    );
  }

  Future<String?> saveToFilePathWithBytes(
    String? filePath, {
    Uint8List? canvasBytes,
  }) async {
    final databaseService = ref.read(databaseServiceProvider);
    final snapshot = _cloneSnapshot(state.finalizedShapes);
    final serialized = canvasBytes ?? await buildSerializedCanvasBytes();
    final thumbnailData = await ThumbnailGenerator.generate(snapshot);
    final resolvedTargetPath = filePath ?? state.currentFilePath;
    final draftPath = await databaseService.resolveDraftFilePath(
      state.currentCanvasId,
    );
    if (resolvedTargetPath == null ||
        _normalizePath(resolvedTargetPath) != _normalizePath(draftPath)) {
      await databaseService.writeDraftCopy(
        canvasId: state.currentCanvasId,
        canvasBytes: serialized,
      );
    }
    final resolvedPath = await databaseService.persistCanvas(
      canvasId: state.currentCanvasId,
      name: state.currentCanvasName,
      filePath: resolvedTargetPath,
      documentUri: null,
      canvasBytes: serialized,
      thumbnailData: thumbnailData,
      lastEditedTime: DateTime.now(),
    );

    if (_isDisposed) {
      return null;
    }

    _lastSavedRevision = _revision;
    await ref.read(canvasListNotifierProvider.notifier).loadCanvases();
    final resolvedName = state.currentCanvasName.trim().isEmpty
        ? _canvasNameFor(resolvedPath)
        : state.currentCanvasName;
    state = state.copyWith(
      currentFilePath: resolvedPath,
      currentDocumentUri: null,
      currentCanvasName: resolvedName,
    );

    return resolvedPath;
  }

  Future<void> saveToDocumentReference(
    DocumentFileReference document, {
    Uint8List? canvasBytes,
    bool writeDocument = true,
  }) async {
    final databaseService = ref.read(databaseServiceProvider);
    final snapshot = _cloneSnapshot(state.finalizedShapes);
    final serialized = canvasBytes ?? await buildSerializedCanvasBytes();
    final thumbnailData = await ThumbnailGenerator.generate(snapshot);
    final displayName = document.displayName.trim().isEmpty
        ? _canvasNameFor(document.uri)
        : document.displayName;
    final resolvedName = state.currentCanvasName.trim().isEmpty
        ? _canvasNameFor(displayName)
        : state.currentCanvasName;

    await databaseService.writeDraftCopy(
      canvasId: state.currentCanvasId,
      canvasBytes: serialized,
    );

    if (writeDocument) {
      await ref
          .read(documentFileServiceProvider)
          .writeDocument(uri: document.uri, bytes: serialized);
    }

    await databaseService.insertCanvasMetadata(<String, Object?>{
      DatabaseService.idKey: state.currentCanvasId,
      DatabaseService.nameKey: resolvedName,
      DatabaseService.filePathKey: displayName,
      DatabaseService.documentUriKey: document.uri,
      DatabaseService.lastEditedTimeKey: DateTime.now().toIso8601String(),
      DatabaseService.thumbnailDataKey: thumbnailData,
    });
    await ref.read(canvasListNotifierProvider.notifier).loadCanvases();
    _lastSavedRevision = _revision;

    state = state.copyWith(
      currentCanvasName: resolvedName,
      currentFilePath: displayName,
      currentDocumentUri: document.uri,
    );
  }

  String _generateCanvasId() =>
      'canvas_${DateTime.now().microsecondsSinceEpoch}';

  bool get _autoSaveEnabled {
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return !bindingType.contains('TestWidgetsFlutterBinding');
  }

  String _canvasNameFor(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return 'Untitled';
    }

    final normalizedPath = filePath.replaceAll('\\', '/');
    final rawName = normalizedPath.split('/').last;
    if (rawName.toLowerCase().endsWith('.mypt')) {
      return rawName.substring(0, rawName.length - 5);
    }

    return rawName.isEmpty ? 'Untitled' : rawName;
  }

  String _normalizePath(String path) => path.replaceAll('\\', '/').trim();

  BaseShape? _shapeFromTool({
    required Offset point,
    required ToolSelectionState toolSelection,
  }) {
    final id = _nextShapeId();

    return switch (toolSelection.toolType) {
      ToolType.brush => BrushShape.seed(
        point,
        id: id,
        strokeColor: toolSelection.currentStrokeColor,
        strokeWidth: strokeWidthForTool(toolSelection, ToolType.brush),
      ),
      ToolType.eraser => EraserShape.seed(
        point,
        id: id,
        strokeColor: toolSelection.currentStrokeColor,
        strokeWidth: strokeWidthForTool(toolSelection, ToolType.eraser),
      ),
      ToolType.shape => _shapeFromBounds(toolSelection, point, point, id),
      ToolType.cursor => null,
    };
  }

  BaseShape _shapeFromBounds(
    ToolSelectionState toolSelection,
    Offset start,
    Offset end,
    String id, {
    bool constrain = false,
  }) {
    return switch (toolSelection.shapeType) {
      ShapeType.rectangle =>
        constrain
            ? SquareShape.fromBounds(
                startPoint: start,
                endPoint: end,
                id: id,
                fillColor: toolSelection.currentFillColor,
                strokeColor: toolSelection.currentStrokeColor,
                strokeWidth: toolSelection.currentStrokeWidth,
              )
            : RectangleShape(
                start: start,
                end: end,
                id: id,
                fillColor: toolSelection.currentFillColor,
                strokeColor: toolSelection.currentStrokeColor,
                strokeWidth: toolSelection.currentStrokeWidth,
              ),
      ShapeType.oval =>
        constrain
            ? CircleShape.fromBounds(
                startPoint: start,
                endPoint: end,
                id: id,
                fillColor: toolSelection.currentFillColor,
                strokeColor: toolSelection.currentStrokeColor,
                strokeWidth: toolSelection.currentStrokeWidth,
              )
            : OvalShape(
                startPoint: start,
                endPoint: end,
                id: id,
                fillColor: toolSelection.currentFillColor,
                strokeColor: toolSelection.currentStrokeColor,
                strokeWidth: toolSelection.currentStrokeWidth,
              ),
      ShapeType.line => LineShape(
        startPoint: start,
        endPoint: end,
        id: id,
        strokeColor: toolSelection.currentStrokeColor,
        strokeWidth: toolSelection.currentStrokeWidth,
      ),
      ShapeType.arrow => ArrowShape(
        startPoint: start,
        endPoint: end,
        id: id,
        strokeColor: toolSelection.currentStrokeColor,
        strokeWidth: toolSelection.currentStrokeWidth,
      ),
      ShapeType.text => TextShape(
        startPoint: start,
        endPoint: end,
        text: '',
        fontSize: 16.0,
        id: id,
        fillColor: toolSelection.currentFillColor,
        strokeColor: toolSelection.currentStrokeColor,
        strokeWidth: toolSelection.currentStrokeWidth,
      ),
    };
  }

  List<BaseShape> _cloneSnapshot(List<BaseShape> shapes) {
    return shapes.map((shape) => shape.clone()).toList(growable: false);
  }

  bool _snapshotsEqual(List<BaseShape> a, List<BaseShape> b) {
    if (identical(a, b)) {
      return true;
    }

    if (a.length != b.length) {
      return false;
    }

    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) {
        return false;
      }
    }

    return true;
  }

  String? _selectedShapeIdFor(
    List<BaseShape> shapes, {
    required String? preferredId,
  }) {
    if (preferredId == null) {
      return null;
    }

    return shapes.any((shape) => shape.id == preferredId) ? preferredId : null;
  }

  int _nextIdFromShapes(List<BaseShape> shapes) {
    var maxId = -1;
    for (final shape in shapes) {
      final id = shape.id;
      if (!id.startsWith('shape_')) {
        continue;
      }

      final value = int.tryParse(id.substring(6));
      if (value != null && value > maxId) {
        maxId = value;
      }
    }

    return maxId + 1;
  }

  String _nextShapeId() => 'shape_${_shapeIdCounter++}';
}

class DrawingBoardState {
  DrawingBoardState._({
    required List<BaseShape> finalizedShapes,
    required List<List<BaseShape>> undoStack,
    required List<List<BaseShape>> redoStack,
    required this.activeTempShape,
    required this.selectedShapeId,
    required this.currentCanvasId,
    required this.currentCanvasName,
    required this.currentFilePath,
    required this.currentDocumentUri,
    required this.shouldFocusCanvasTitle,
  }) : finalizedShapes = List<BaseShape>.unmodifiable(finalizedShapes),
       undoStack = List<List<BaseShape>>.unmodifiable(
         undoStack
             .map((snapshot) => List<BaseShape>.unmodifiable(snapshot))
             .toList(growable: false),
       ),
       redoStack = List<List<BaseShape>>.unmodifiable(
         redoStack
             .map((snapshot) => List<BaseShape>.unmodifiable(snapshot))
             .toList(growable: false),
       );

  factory DrawingBoardState.initial({
    String currentCanvasId = 'canvas_initial',
    String currentCanvasName = 'Untitled',
    String? currentFilePath,
    String? currentDocumentUri,
    bool shouldFocusCanvasTitle = false,
  }) {
    return DrawingBoardState._(
      finalizedShapes: const <BaseShape>[],
      undoStack: const <List<BaseShape>>[],
      redoStack: const <List<BaseShape>>[],
      activeTempShape: null,
      selectedShapeId: null,
      currentCanvasId: currentCanvasId,
      currentCanvasName: currentCanvasName,
      currentFilePath: currentFilePath,
      currentDocumentUri: currentDocumentUri,
      shouldFocusCanvasTitle: shouldFocusCanvasTitle,
    );
  }

  final List<BaseShape> finalizedShapes;
  final List<List<BaseShape>> undoStack;
  final List<List<BaseShape>> redoStack;
  final BaseShape? activeTempShape;
  final String? selectedShapeId;
  final String currentCanvasId;
  final String currentCanvasName;
  final String? currentFilePath;
  final String? currentDocumentUri;
  final bool shouldFocusCanvasTitle;

  bool get canUndo => undoStack.isNotEmpty;

  bool get canRedo => redoStack.isNotEmpty;

  BaseShape? get selectedShape {
    final selectedShapeId = this.selectedShapeId;
    if (selectedShapeId == null) {
      return null;
    }

    for (final shape in finalizedShapes) {
      if (shape.id == selectedShapeId) {
        return shape;
      }
    }

    return null;
  }

  bool hasShape(String id) {
    return finalizedShapes.any((shape) => shape.id == id);
  }

  DrawingBoardState copyWith({
    List<BaseShape>? finalizedShapes,
    List<List<BaseShape>>? undoStack,
    List<List<BaseShape>>? redoStack,
    Object? activeTempShape = _stateSentinel,
    Object? selectedShapeId = _stateSentinel,
    String? currentCanvasId,
    String? currentCanvasName,
    Object? currentFilePath = _stateSentinel,
    Object? currentDocumentUri = _stateSentinel,
    bool? shouldFocusCanvasTitle,
  }) {
    return DrawingBoardState._(
      finalizedShapes: finalizedShapes ?? this.finalizedShapes,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      activeTempShape: identical(activeTempShape, _stateSentinel)
          ? this.activeTempShape
          : activeTempShape as BaseShape?,
      selectedShapeId: identical(selectedShapeId, _stateSentinel)
          ? this.selectedShapeId
          : selectedShapeId as String?,
      currentCanvasId: currentCanvasId ?? this.currentCanvasId,
      currentCanvasName: currentCanvasName ?? this.currentCanvasName,
      currentFilePath: identical(currentFilePath, _stateSentinel)
          ? this.currentFilePath
          : currentFilePath as String?,
      currentDocumentUri: identical(currentDocumentUri, _stateSentinel)
          ? this.currentDocumentUri
          : currentDocumentUri as String?,
      shouldFocusCanvasTitle:
          shouldFocusCanvasTitle ?? this.shouldFocusCanvasTitle,
    );
  }
}

const Object _stateSentinel = Object();
