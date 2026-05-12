import 'dart:math';

import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/utils/canvas_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

const double _kHandleRadius = 6.0;
const double _kHandleHitSize = 44.0;
const double _kSelectionPadding = 4.0;
const double _kDashLength = 6.0;
const double _kDashGap = 4.0;
const Color _kSelectionColor = Color(0xFF2196F3);
const double _kMinViewportScale = 0.2;
const double _kMaxViewportScale = 4.0;
const double _kMinObjectScale = 0.25;
const double _kMaxObjectScale = 8.0;
const double _kExportCanvasWidth = 4096;
const double _kExportCanvasHeight = 4096;

class InteractiveCanvas extends ConsumerStatefulWidget {
  const InteractiveCanvas({super.key, this.onViewportScaleChanged});

  final ValueChanged<double>? onViewportScaleChanged;

  @override
  ConsumerState<InteractiveCanvas> createState() => _InteractiveCanvasState();
}

mixin CanvasCapture on State<InteractiveCanvas> {
  Future<Uint8List?> captureImage({bool asJpeg = false});
}

class _InteractiveCanvasState extends ConsumerState<InteractiveCanvas>
    with CanvasCapture {
  Matrix4 _viewTransform = Matrix4.identity();
  _DragMode _dragMode = _DragMode.none;
  _ScaleGestureMode _scaleGestureMode = _ScaleGestureMode.none;
  ResizeCorner? _resizeCorner;
  Offset? _resizeFixedCorner;
  Offset? _resizeMovingCorner;
  Offset? _resizeRawMovingCorner;
  _ResizeAxis? _resizeLockAxis;
  Offset? _lastCanvasFocalPoint;
  BaseShape? _gestureStartShape;
  Offset? _gestureStartShapeFocalPoint;
  double _lastGestureScale = 1;
  bool _isShiftPressed = false;
  bool _isMiddleMousePanning = false;
  int _activePointerCount = 0;
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _canvasKey = GlobalKey();
  Offset? _lastMiddleMousePosition;
  Offset? _eraserPreviewPosition;
  ProviderSubscription<ToolSelectionState>? _toolSelectionSubscription;

  @override
  void initState() {
    super.initState();
    _toolSelectionSubscription = ref.listenManual<ToolSelectionState>(
      toolSelectionNotifierProvider,
      (previous, next) {
        if (next.toolType != ToolType.eraser) {
          _clearEraserPreview();
        }
      },
    );
  }

  @override
  void dispose() {
    _toolSelectionSubscription?.close();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingBoardNotifierProvider);
    final toolSelection = ref.watch(toolSelectionNotifierProvider);
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final bool showEraserPreview = toolSelection.toolType == ToolType.eraser;
    final double? eraserPreviewDiameter = showEraserPreview
        ? strokeWidthForTool(toolSelection, ToolType.eraser)
        : null;
    final Offset? eraserPreviewPosition = showEraserPreview
        ? _eraserPreviewPosition
        : null;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Listener(
        onPointerDown: (event) {
          _activePointerCount += 1;
          if (toolSelection.toolType == ToolType.eraser) {
            _setEraserPreviewViewport(event.localPosition);
          }
          if (event.kind == PointerDeviceKind.mouse &&
              event.buttons == kMiddleMouseButton) {
            _focusNode.requestFocus();
            _isMiddleMousePanning = true;
            _lastMiddleMousePosition = event.localPosition;
          }
        },
        onPointerMove: (event) {
          if (!_isMiddleMousePanning || _lastMiddleMousePosition == null) {
            return;
          }

          final delta = event.localPosition - _lastMiddleMousePosition!;
          _lastMiddleMousePosition = event.localPosition;
          _translateViewport(delta);
        },
        onPointerUp: (_) {
          _activePointerCount = max(0, _activePointerCount - 1);
          _isMiddleMousePanning = false;
          _lastMiddleMousePosition = null;
          _clearEraserPreview();
        },
        onPointerCancel: (_) {
          _activePointerCount = max(0, _activePointerCount - 1);
          _isMiddleMousePanning = false;
          _lastMiddleMousePosition = null;
          _clearEraserPreview();
        },
        onPointerSignal: _handlePointerSignal,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleTapDown,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: RepaintBoundary(
            key: _canvasKey,
            child: ClipRect(
              child: Transform(
                key: const ValueKey<String>('interactive-canvas-transform'),
                transform: _viewTransform,
                child: CustomPaint(
                  painter: CanvasPainter(
                    state: drawingState,
                    viewportScale: _matrixScale(_viewTransform),
                    eraserPreviewPosition: eraserPreviewPosition,
                    eraserPreviewDiameter: eraserPreviewDiameter,
                    eraserPreviewColor: colors.iconPrimary,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<Uint8List?> captureImage({bool asJpeg = false}) async {
    final background =
        Theme.of(context).extension<AppColors>()?.backgroundCanvas ??
        Colors.white;
    final drawingState = ref.read(drawingBoardNotifierProvider);

    return CanvasExporter.export(
      drawingState.finalizedShapes,
      canvasWidth: _kExportCanvasWidth,
      canvasHeight: _kExportCanvasHeight,
      backgroundColor: background,
      asJpeg: asJpeg,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final bool isShift =
        event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight;
    if (!isShift) {
      return KeyEventResult.ignored;
    }

    final bool pressed = event is KeyDownEvent || event is KeyRepeatEvent;
    if (_isShiftPressed != pressed) {
      setState(() {
        _isShiftPressed = pressed;
      });

      if (!pressed) {
        _resizeLockAxis = null;
      } else if (_dragMode == _DragMode.resize &&
          _resizeFixedCorner != null &&
          _resizeRawMovingCorner != null) {
        _resizeLockAxis = _pickResizeAxis(
          _resizeFixedCorner!,
          _resizeRawMovingCorner!,
        );
      }
    }

    return KeyEventResult.handled;
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isMiddleMousePanning) {
      return;
    }
    _focusNode.requestFocus();
    final toolSelection = ref.read(toolSelectionNotifierProvider);
    if (toolSelection.toolType != ToolType.cursor) {
      return;
    }

    final drawingState = ref.read(drawingBoardNotifierProvider);
    final canvasPoint = _toCanvasSpace(details.localPosition);

    final selectedShape = drawingState.selectedShape;
    if (selectedShape != null) {
      final viewportScale = _matrixScale(_viewTransform);
      final selectionBounds = _selectionBoundsFor(
        selectedShape,
        viewportScale: viewportScale,
      );
      final hitCorner = _hitTestResizeHandle(
        selectionBounds,
        canvasPoint,
        viewportScale: viewportScale,
      );

      if (hitCorner != null) {
        return;
      }
    }

    final hitShape = _hitTestShapes(drawingState.finalizedShapes, canvasPoint);

    ref.read(drawingBoardNotifierProvider.notifier).selectShape(hitShape?.id);

    _syncToolPaletteToShape(hitShape);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (_isMiddleMousePanning) {
      return;
    }
    _focusNode.requestFocus();
    final toolSelection = ref.read(toolSelectionNotifierProvider);
    final drawingBoardNotifier = ref.read(
      drawingBoardNotifierProvider.notifier,
    );
    final canvasPoint = _toCanvasSpace(details.localFocalPoint);
    _lastCanvasFocalPoint = canvasPoint;
    if (toolSelection.toolType == ToolType.eraser) {
      _setEraserPreviewCanvas(canvasPoint);
    }

    if (_activePointerCount >= 2) {
      _startMultiTouchGesture(
        details.localFocalPoint,
        canvasPoint,
        toolSelection: toolSelection,
        drawingBoardNotifier: drawingBoardNotifier,
      );
      return;
    }

    _scaleGestureMode = _ScaleGestureMode.singleTouch;
    _lastGestureScale = 1;
    if (toolSelection.toolType == ToolType.cursor) {
      _startCursorDrag(canvasPoint, drawingBoardNotifier);
      return;
    }

    drawingBoardNotifier.startDrawing(canvasPoint, toolSelection);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isMiddleMousePanning) {
      return;
    }
    final toolSelection = ref.read(toolSelectionNotifierProvider);
    final drawingBoardNotifier = ref.read(
      drawingBoardNotifierProvider.notifier,
    );
    final canvasPoint = _toCanvasSpace(details.localFocalPoint);
    if (toolSelection.toolType == ToolType.eraser) {
      _setEraserPreviewCanvas(canvasPoint);
    }

    if (_activePointerCount >= 2) {
      if (_scaleGestureMode == _ScaleGestureMode.singleTouch) {
        _promoteSingleTouchGestureToMultiTouch(
          toolSelection: toolSelection,
          drawingBoardNotifier: drawingBoardNotifier,
          viewportPoint: details.localFocalPoint,
          canvasPoint: canvasPoint,
        );
      }

      if (_scaleGestureMode == _ScaleGestureMode.shapeScale) {
        _updateSelectedShapeScale(
          details,
          drawingBoardNotifier: drawingBoardNotifier,
        );
      } else if (_scaleGestureMode == _ScaleGestureMode.viewportTransform) {
        _updateViewportTransform(details);
      }
      return;
    }

    if (toolSelection.toolType == ToolType.cursor) {
      final selectedShape = ref
          .read(drawingBoardNotifierProvider)
          .selectedShape;
      if (selectedShape == null || _dragMode == _DragMode.none) {
        return;
      }

      final previousCanvasPoint = _lastCanvasFocalPoint ?? canvasPoint;
      final delta = canvasPoint - previousCanvasPoint;
      _lastCanvasFocalPoint = canvasPoint;
      if (_dragMode == _DragMode.move) {
        drawingBoardNotifier.updateSelectedShape(
          selectedShape.translate(delta),
        );
      } else if (_dragMode == _DragMode.resize && _resizeCorner != null) {
        if (selectedShape is TwoPointShape &&
            _resizeFixedCorner != null &&
            _resizeRawMovingCorner != null) {
          final rawMovingCorner = _resizeRawMovingCorner! + delta;
          _resizeRawMovingCorner = rawMovingCorner;

          final bool shouldLock =
              _isShiftPressed && _shouldLockAspect(selectedShape);
          if (!shouldLock) {
            _resizeLockAxis = null;
          }

          final lockAxis = shouldLock
              ? (_resizeLockAxis ??
                    _pickResizeAxis(_resizeFixedCorner!, rawMovingCorner))
              : null;

          _resizeLockAxis = lockAxis;

          final newMovingCorner = lockAxis == null
              ? rawMovingCorner
              : _lockAspect(_resizeFixedCorner!, rawMovingCorner, lockAxis);

          _resizeMovingCorner = newMovingCorner;
          drawingBoardNotifier.updateSelectedShape(
            selectedShape.resizeFromAnchors(
              fixedCorner: _resizeFixedCorner!,
              movingCorner: newMovingCorner,
            ),
          );
        } else {
          drawingBoardNotifier.updateSelectedShape(
            selectedShape.resize(delta, _resizeCorner!),
          );
        }
      }

      return;
    }

    drawingBoardNotifier.updateDrawing(
      canvasPoint,
      toolSelection: toolSelection,
      constrainToSquare: _isShiftPressed,
    );
    _lastCanvasFocalPoint = canvasPoint;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isMiddleMousePanning) {
      return;
    }
    final toolSelection = ref.read(toolSelectionNotifierProvider);
    final drawingBoardNotifier = ref.read(
      drawingBoardNotifierProvider.notifier,
    );
    if (toolSelection.toolType == ToolType.eraser) {
      _clearEraserPreview();
    }

    if (_scaleGestureMode == _ScaleGestureMode.shapeScale) {
      drawingBoardNotifier.endTransform();
      _resetGestureState();
      return;
    }

    if (_scaleGestureMode == _ScaleGestureMode.viewportTransform) {
      _resetGestureState();
      return;
    }

    if (toolSelection.toolType == ToolType.cursor &&
        _scaleGestureMode == _ScaleGestureMode.singleTouch) {
      if (_dragMode != _DragMode.none) {
        drawingBoardNotifier.endTransform();
      }
      _resetGestureState();
      return;
    }

    if (_scaleGestureMode == _ScaleGestureMode.singleTouch) {
      drawingBoardNotifier.commitDrawing();

      // Show text input dialog after committing a text shape
      if (toolSelection.toolType == ToolType.shape &&
          toolSelection.shapeType == ShapeType.text) {
        _showTextInputDialog();
      }
    }

    _resetGestureState();
  }

  Future<void> _showTextInputDialog() async {
    final drawingState = ref.read(drawingBoardNotifierProvider);
    final selectedShape = drawingState.selectedShape;

    if (selectedShape is! TextShape) return;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          _TextInputDialog(initialText: selectedShape.text),
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      ref
          .read(drawingBoardNotifierProvider.notifier)
          .updateSelectedShape(selectedShape.copyWithText(text: result));
    } else {
      // User cancelled or entered empty text — undo the empty text shape
      ref.read(drawingBoardNotifierProvider.notifier).undo();
    }
  }

  void _startCursorDrag(
    Offset position,
    DrawingBoardNotifier drawingBoardNotifier,
  ) {
    _dragMode = _DragMode.none;
    _resizeCorner = null;
    _resizeFixedCorner = null;
    _resizeMovingCorner = null;
    _resizeRawMovingCorner = null;
    _resizeLockAxis = null;

    final selectedShape = ref.read(drawingBoardNotifierProvider).selectedShape;
    if (selectedShape == null) {
      return;
    }

    final viewportScale = _matrixScale(_viewTransform);
    final selectionBounds = _selectionBoundsFor(
      selectedShape,
      viewportScale: viewportScale,
    );
    final hitCorner = _hitTestResizeHandle(
      selectionBounds,
      position,
      viewportScale: viewportScale,
    );
    if (hitCorner != null) {
      _dragMode = _DragMode.resize;
      _resizeCorner = hitCorner;
      final shapeBounds = _shapeBounds(selectedShape);
      _resizeMovingCorner = _cornerOffset(shapeBounds, hitCorner);
      _resizeRawMovingCorner = _resizeMovingCorner;
      _resizeFixedCorner = _cornerOffset(
        shapeBounds,
        _oppositeCorner(hitCorner),
      );
      _resizeLockAxis = _isShiftPressed
          ? _pickResizeAxis(_resizeFixedCorner!, _resizeRawMovingCorner!)
          : null;
      drawingBoardNotifier.beginTransform();
      return;
    }

    if (selectedShape.contains(position)) {
      _dragMode = _DragMode.move;
      drawingBoardNotifier.beginTransform();
    }
  }

  void _startMultiTouchGesture(
    Offset viewportPoint,
    Offset canvasPoint, {
    required ToolSelectionState toolSelection,
    required DrawingBoardNotifier drawingBoardNotifier,
  }) {
    _scaleGestureMode = _ScaleGestureMode.viewportTransform;
    _gestureStartShape = null;
    _gestureStartShapeFocalPoint = null;

    final selectedShape = ref.read(drawingBoardNotifierProvider).selectedShape;
    if (toolSelection.toolType == ToolType.cursor &&
        selectedShape != null &&
        _selectionBoundsFor(
              selectedShape,
              viewportScale: _matrixScale(_viewTransform),
            )
            .inflate(_kHandleHitSize / _matrixScale(_viewTransform))
            .contains(canvasPoint)) {
      _scaleGestureMode = _ScaleGestureMode.shapeScale;
      _gestureStartShape = selectedShape.clone();
      _gestureStartShapeFocalPoint = canvasPoint;
      drawingBoardNotifier.beginTransform();
    }

    _lastCanvasFocalPoint = canvasPoint;
  }

  void _promoteSingleTouchGestureToMultiTouch({
    required ToolSelectionState toolSelection,
    required DrawingBoardNotifier drawingBoardNotifier,
    required Offset viewportPoint,
    required Offset canvasPoint,
  }) {
    if (toolSelection.toolType == ToolType.cursor &&
        _dragMode != _DragMode.none) {
      drawingBoardNotifier.endTransform();
    } else if (toolSelection.toolType != ToolType.cursor) {
      drawingBoardNotifier.commitDrawing();
    }

    _dragMode = _DragMode.none;
    _resizeCorner = null;
    _resizeFixedCorner = null;
    _resizeMovingCorner = null;
    _resizeRawMovingCorner = null;
    _resizeLockAxis = null;

    _startMultiTouchGesture(
      viewportPoint,
      canvasPoint,
      toolSelection: toolSelection,
      drawingBoardNotifier: drawingBoardNotifier,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.kind != PointerDeviceKind.mouse) {
      return;
    }

    final scaleFactor = exp(-event.scrollDelta.dy * 0.0015);
    _zoomViewportAt(event.localPosition, scaleFactor);
  }

  void _zoomViewportAt(Offset viewportPoint, double scaleFactor) {
    final currentScale = _matrixScale(_viewTransform);
    final nextScale = (currentScale * scaleFactor).clamp(
      _kMinViewportScale,
      _kMaxViewportScale,
    );
    final scenePoint = _toCanvasSpace(viewportPoint);
    final translationX = viewportPoint.dx - (scenePoint.dx * nextScale);
    final translationY = viewportPoint.dy - (scenePoint.dy * nextScale);

    setState(() {
      _viewTransform = Matrix4.diagonal3Values(nextScale, nextScale, 1)
        ..setTranslationRaw(translationX, translationY, 0);
    });
    widget.onViewportScaleChanged?.call(nextScale);
  }

  void _updateViewportTransform(ScaleUpdateDetails details) {
    final previousGestureScale = _lastGestureScale == 0
        ? 1.0
        : _lastGestureScale;
    final incrementalScale = details.scale / previousGestureScale;
    _lastGestureScale = details.scale;
    _zoomViewportAt(details.localFocalPoint, incrementalScale);
  }

  void _translateViewport(Offset delta) {
    final currentScale = _matrixScale(_viewTransform);
    final translation = _viewTransform.getTranslation();

    setState(() {
      _viewTransform = Matrix4.diagonal3Values(currentScale, currentScale, 1)
        ..setTranslationRaw(
          translation.x + delta.dx,
          translation.y + delta.dy,
          0,
        );
    });
  }

  void _updateSelectedShapeScale(
    ScaleUpdateDetails details, {
    required DrawingBoardNotifier drawingBoardNotifier,
  }) {
    final startShape = _gestureStartShape;
    final startFocalPoint = _gestureStartShapeFocalPoint;
    if (startShape == null || startFocalPoint == null) {
      return;
    }

    final currentSceneFocalPoint = _toCanvasSpace(details.localFocalPoint);
    final translation = currentSceneFocalPoint - startFocalPoint;
    final scaleFactor = details.scale.clamp(_kMinObjectScale, _kMaxObjectScale);

    drawingBoardNotifier.updateSelectedShape(
      _translateShape(_scaleShape(startShape, scaleFactor), translation),
    );
  }

  BaseShape _scaleShape(BaseShape shape, double scaleFactor) {
    final bounds = _shapeBounds(shape);
    if (bounds.isEmpty) {
      return shape.clone();
    }

    final center = bounds.center;
    Offset scalePoint(Offset point) => Offset(
      center.dx + ((point.dx - center.dx) * scaleFactor),
      center.dy + ((point.dy - center.dy) * scaleFactor),
    );

    return switch (shape) {
      BrushShape() => BrushShape(
        points: shape.points.map(scalePoint).toList(growable: false),
        id: shape.id,
        isFinalized: shape.isFinalized,
        strokeColor: shape.strokeColor,
        strokeWidth: (shape.strokeWidth * scaleFactor).clamp(
          kMinStrokeWidth,
          kMaxStrokeWidth,
        ),
      ),
      EraserShape() => EraserShape(
        points: shape.points.map(scalePoint).toList(growable: false),
        id: shape.id,
        isFinalized: shape.isFinalized,
        strokeColor: shape.strokeColor,
        strokeWidth: (shape.strokeWidth * scaleFactor).clamp(
          kMinStrokeWidth,
          kMaxEraserStrokeWidth,
        ),
      ),
      TextShape() => TextShape(
        startPoint: scalePoint(shape.startPoint),
        endPoint: scalePoint(shape.endPoint),
        text: shape.text,
        fontSize: (shape.fontSize * scaleFactor).clamp(8.0, 240.0),
        id: shape.id,
        fillColor: shape.fillColor,
        strokeColor: shape.strokeColor,
        strokeWidth: (shape.strokeWidth * scaleFactor).clamp(
          kMinStrokeWidth,
          kMaxStrokeWidth,
        ),
      ),
      TwoPointShape() => shape.resizeFromAnchors(
        fixedCorner: scalePoint(shape.startPoint),
        movingCorner: scalePoint(shape.endPoint),
      ),
      _ => shape.clone(),
    };
  }

  BaseShape _translateShape(BaseShape shape, Offset delta) {
    return shape.translate(delta);
  }

  Offset _toCanvasSpace(Offset viewportPoint) {
    final inverted = Matrix4.inverted(_viewTransform);
    return MatrixUtils.transformPoint(inverted, viewportPoint);
  }

  void _setEraserPreviewViewport(Offset viewportPoint) {
    _setEraserPreviewCanvas(_toCanvasSpace(viewportPoint));
  }

  void _setEraserPreviewCanvas(Offset canvasPoint) {
    if (_eraserPreviewPosition == canvasPoint) {
      return;
    }
    setState(() {
      _eraserPreviewPosition = canvasPoint;
    });
  }

  void _clearEraserPreview() {
    if (_eraserPreviewPosition == null) {
      return;
    }
    setState(() {
      _eraserPreviewPosition = null;
    });
  }

  double _matrixScale(Matrix4 matrix) {
    return matrix.getMaxScaleOnAxis();
  }

  void _resetGestureState() {
    _scaleGestureMode = _ScaleGestureMode.none;
    _lastCanvasFocalPoint = null;
    _gestureStartShape = null;
    _gestureStartShapeFocalPoint = null;
    _lastGestureScale = 1;
    _dragMode = _DragMode.none;
    _resizeCorner = null;
    _resizeFixedCorner = null;
    _resizeMovingCorner = null;
    _resizeRawMovingCorner = null;
    _resizeLockAxis = null;
  }

  bool _shouldLockAspect(BaseShape shape) {
    return shape is RectangleShape ||
        shape is OvalShape ||
        shape is SquareShape ||
        shape is CircleShape;
  }

  _ResizeAxis _pickResizeAxis(Offset fixedCorner, Offset movingCorner) {
    final dx = movingCorner.dx - fixedCorner.dx;
    final dy = movingCorner.dy - fixedCorner.dy;
    return dx.abs() >= dy.abs() ? _ResizeAxis.horizontal : _ResizeAxis.vertical;
  }

  Offset _lockAspect(
    Offset fixedCorner,
    Offset movingCorner,
    _ResizeAxis lockAxis,
  ) {
    final dx = movingCorner.dx - fixedCorner.dx;
    final dy = movingCorner.dy - fixedCorner.dy;
    if (dx == 0 || dy == 0) {
      return movingCorner;
    }

    final size = lockAxis == _ResizeAxis.horizontal ? dx.abs() : dy.abs();
    final signX = dx >= 0 ? 1.0 : -1.0;
    final signY = dy >= 0 ? 1.0 : -1.0;

    return Offset(
      fixedCorner.dx + (signX * size),
      fixedCorner.dy + (signY * size),
    );
  }

  void _syncToolPaletteToShape(BaseShape? shape) {
    if (shape == null) {
      return;
    }

    final toolSelectionNotifier = ref.read(
      toolSelectionNotifierProvider.notifier,
    );

    toolSelectionNotifier.updateStrokeColor(shape.strokeColor);
    toolSelectionNotifier.updateStrokeWidthForTool(
      shape is EraserShape ? ToolType.eraser : ToolType.brush,
      shape.strokeWidth,
    );

    if (shape is TwoPointShape && shape.fillColor != null) {
      toolSelectionNotifier.updateFillColor(shape.fillColor!);
    }

    final shapeType = _shapeTypeFor(shape);
    if (shapeType != null) {
      toolSelectionNotifier.selectShapeType(shapeType);
    }
  }
}

enum _DragMode { none, move, resize }

enum _ResizeAxis { horizontal, vertical }

enum _ScaleGestureMode { none, singleTouch, viewportTransform, shapeScale }

// ---------------------------------------------------------------------------
// Text input dialog shown after drawing a TextShape bounding box
// ---------------------------------------------------------------------------
class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({this.initialText = ''});

  final String initialText;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Text'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: null,
        decoration: const InputDecoration(
          hintText: 'Type your text here…',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }
}

// ---------------------------------------------------------------------------
// Canvas painter — dual-pass fill+stroke for all shapes
// ---------------------------------------------------------------------------
class CanvasPainter extends CustomPainter {
  const CanvasPainter({
    required this.state,
    this.viewportScale = 1,
    this.eraserPreviewPosition,
    this.eraserPreviewDiameter,
    this.eraserPreviewColor = _kSelectionColor,
  });

  final DrawingBoardState state;
  final double viewportScale;
  final Offset? eraserPreviewPosition;
  final double? eraserPreviewDiameter;
  final Color eraserPreviewColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bool needsLayer = _usesClearBlend(state);
    if (needsLayer) {
      canvas.saveLayer(Offset.zero & size, Paint());
    }

    for (final shape in state.finalizedShapes) {
      _drawShape(canvas, shape);
    }

    final activeTempShape = state.activeTempShape;
    if (activeTempShape != null) {
      _drawShape(canvas, activeTempShape);
    }
    if (needsLayer) {
      canvas.restore();
    }

    final selectedShape = state.selectedShape;
    if (selectedShape != null) {
      _drawSelection(canvas, selectedShape);
    }

    if (eraserPreviewPosition != null && eraserPreviewDiameter != null) {
      final previewPaint = Paint()
        ..color = eraserPreviewColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2 / viewportScale).clamp(0.6, 3.0).toDouble()
        ..isAntiAlias = true;
      canvas.drawCircle(
        eraserPreviewPosition!,
        eraserPreviewDiameter! / 2,
        previewPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.viewportScale != viewportScale ||
        oldDelegate.eraserPreviewPosition != eraserPreviewPosition ||
        oldDelegate.eraserPreviewDiameter != eraserPreviewDiameter ||
        oldDelegate.eraserPreviewColor != eraserPreviewColor;
  }

  void _drawShape(Canvas canvas, BaseShape shape) {
    switch (shape) {
      case PathShape():
        _drawPathShape(canvas, shape);
      case LineShape():
        _drawLineShape(canvas, shape);
      case ArrowShape():
        _drawArrowShape(canvas, shape);
      case RectangleShape():
        _drawRectShape(canvas, shape);
      case OvalShape():
        _drawOvalShape(canvas, shape);
      case CircleShape():
        _drawCircleShape(canvas, shape);
      case SquareShape():
        _drawSquareShape(canvas, shape);
      case TextShape():
        _drawTextShape(canvas, shape);
      case _:
        return;
    }
  }

  void _drawPathShape(Canvas canvas, PathShape shape) {
    final paint = Paint()
      ..color = shape.strokeColor
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..blendMode = shape.blendMode;

    final points = shape.points;
    if (points.length == 1) {
      canvas.drawCircle(points.first, shape.strokeWidth / 2, paint);
      return;
    }

    for (var index = 0; index < points.length - 1; index += 1) {
      canvas.drawLine(points[index], points[index + 1], paint);
    }
  }

  void _drawLineShape(Canvas canvas, LineShape shape) {
    final paint = _strokePaint(shape, cap: StrokeCap.round);
    canvas.drawLine(shape.startPoint, shape.endPoint, paint);
  }

  void _drawArrowShape(Canvas canvas, ArrowShape shape) {
    final strokePaint = _strokePaint(shape, cap: StrokeCap.round);
    canvas.drawLine(shape.startPoint, shape.endPoint, strokePaint);

    final direction = shape.endPoint - shape.startPoint;
    if (direction.distance == 0) {
      return;
    }

    final unit = direction / direction.distance;
    final arrowLength = 12 + shape.strokeWidth * 2;
    const arrowAngle = 0.5;
    final left = Offset(
      unit.dx * -arrowLength * cos(arrowAngle) -
          unit.dy * -arrowLength * sin(arrowAngle),
      unit.dx * -arrowLength * sin(arrowAngle) +
          unit.dy * -arrowLength * cos(arrowAngle),
    );
    final right = Offset(
      unit.dx * -arrowLength * cos(-arrowAngle) -
          unit.dy * -arrowLength * sin(-arrowAngle),
      unit.dx * -arrowLength * sin(-arrowAngle) +
          unit.dy * -arrowLength * cos(-arrowAngle),
    );

    // Build arrowhead triangle path
    final arrowPath = Path()
      ..moveTo(shape.endPoint.dx, shape.endPoint.dy)
      ..lineTo(shape.endPoint.dx + left.dx, shape.endPoint.dy + left.dy)
      ..lineTo(shape.endPoint.dx + right.dx, shape.endPoint.dy + right.dy)
      ..close();

    // Dual-pass: fill arrowhead with stroke color, then stroke outline
    final fillPaint = Paint()
      ..color = shape.strokeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = shape.blendMode;

    canvas.drawPath(arrowPath, fillPaint);
    canvas.drawPath(arrowPath, strokePaint);
  }

  void _drawRectShape(Canvas canvas, RectangleShape shape) {
    final rect = Rect.fromPoints(shape.startPoint, shape.endPoint);
    _drawFilledRect(canvas, rect, shape);
  }

  void _drawOvalShape(Canvas canvas, OvalShape shape) {
    final rect = Rect.fromPoints(shape.startPoint, shape.endPoint);
    _drawFilledOval(canvas, rect, shape);
  }

  void _drawCircleShape(Canvas canvas, CircleShape shape) {
    final rect = Rect.fromCircle(center: shape.center, radius: shape.radius);
    _drawFilledOval(canvas, rect, shape);
  }

  void _drawSquareShape(Canvas canvas, SquareShape shape) {
    final rect = Rect.fromCenter(
      center: shape.center,
      width: shape.sideLength,
      height: shape.sideLength,
    );
    _drawFilledRect(canvas, rect, shape);
  }

  void _drawTextShape(Canvas canvas, TextShape shape) {
    final rect = Rect.fromPoints(shape.startPoint, shape.endPoint);

    // Dual-pass: fill background then stroke border
    _drawFilledRect(canvas, rect, shape);

    // Render text centered within bounds using TextPainter
    if (shape.text.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: shape.text,
        style: TextStyle(color: shape.strokeColor, fontSize: shape.fontSize),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width.abs().clamp(1.0, double.infinity));

    final offset = Offset(
      rect.left + (rect.width - textPainter.width) / 2,
      rect.top + (rect.height - textPainter.height) / 2,
    );

    canvas.save();
    canvas.clipRect(rect);
    textPainter.paint(canvas, offset);
    canvas.restore();
  }

  void _drawFilledRect(Canvas canvas, Rect rect, TwoPointShape shape) {
    _drawFillIfNeeded(canvas, rect, shape, canvas.drawRect);
    canvas.drawRect(rect, _strokePaint(shape));
  }

  void _drawFilledOval(Canvas canvas, Rect rect, TwoPointShape shape) {
    _drawFillIfNeeded(canvas, rect, shape, canvas.drawOval);
    canvas.drawOval(rect, _strokePaint(shape));
  }

  void _drawFillIfNeeded(
    Canvas canvas,
    Rect rect,
    TwoPointShape shape,
    void Function(Rect, Paint) draw,
  ) {
    final fillColor = shape.fillColor;

    if (fillColor == null || fillColor.a == 0) {
      return;
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = shape.blendMode;

    draw(rect, fillPaint);
  }

  Paint _strokePaint(
    BaseShape shape, {
    StrokeCap cap = StrokeCap.square,
    StrokeJoin join = StrokeJoin.miter,
  }) {
    return Paint()
      ..color = shape.strokeColor
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = cap
      ..strokeJoin = join
      ..isAntiAlias = true
      ..blendMode = shape.blendMode;
  }

  void _drawSelection(Canvas canvas, BaseShape shape) {
    final scale = viewportScale <= 0 ? 1.0 : viewportScale;
    final bounds = _selectionBoundsFor(shape, viewportScale: scale);
    if (bounds.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = _kSelectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / scale
      ..isAntiAlias = true;

    final dashedPath = _dashPath(
      Path()..addRect(bounds),
      dashLength: _kDashLength / scale,
      dashGap: _kDashGap / scale,
    );

    canvas.drawPath(dashedPath, paint);

    final handlePaint = Paint()
      ..color = _kSelectionColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final corner in ResizeCorner.values) {
      final position = _cornerOffset(bounds, corner);
      canvas.drawCircle(position, _kHandleRadius / scale, handlePaint);
    }
  }

  bool _usesClearBlend(DrawingBoardState state) {
    if (state.activeTempShape?.blendMode == BlendMode.clear) {
      return true;
    }

    for (final shape in state.finalizedShapes) {
      if (shape.blendMode == BlendMode.clear) {
        return true;
      }
    }

    return false;
  }
}

// ---------------------------------------------------------------------------
// Hit-testing helpers (Z-index: reverse iteration for top-most-first)
// ---------------------------------------------------------------------------

BaseShape? _hitTestShapes(List<BaseShape> shapes, Offset point) {
  for (final shape in shapes.reversed) {
    if (shape is EraserShape) {
      continue;
    }
    if (shape.contains(point)) {
      return shape;
    }
  }

  return null;
}

ResizeCorner? _hitTestResizeHandle(
  Rect bounds,
  Offset point, {
  double viewportScale = 1,
}) {
  final scale = viewportScale <= 0 ? 1.0 : viewportScale;
  for (final corner in ResizeCorner.values) {
    final rect = Rect.fromCenter(
      center: _cornerOffset(bounds, corner),
      width: _kHandleHitSize / scale,
      height: _kHandleHitSize / scale,
    );

    if (rect.contains(point)) {
      return corner;
    }
  }

  return null;
}

Rect _selectionBoundsFor(BaseShape shape, {double viewportScale = 1}) {
  final scale = viewportScale <= 0 ? 1.0 : viewportScale;
  final bounds = _shapeBounds(shape);
  if (bounds.isEmpty) {
    return bounds.inflate(_kSelectionPadding / scale);
  }

  return bounds.inflate((shape.strokeWidth / 2) + (_kSelectionPadding / scale));
}

Rect _shapeBounds(BaseShape shape) {
  if (shape is PathShape) {
    final points = shape.points;
    if (points.isEmpty) {
      return Rect.zero;
    }

    var minDx = points.first.dx;
    var maxDx = points.first.dx;
    var minDy = points.first.dy;
    var maxDy = points.first.dy;

    for (final point in points.skip(1)) {
      if (point.dx < minDx) minDx = point.dx;
      if (point.dx > maxDx) maxDx = point.dx;
      if (point.dy < minDy) minDy = point.dy;
      if (point.dy > maxDy) maxDy = point.dy;
    }

    return Rect.fromLTRB(minDx, minDy, maxDx, maxDy);
  }

  if (shape is TwoPointShape) {
    return Rect.fromPoints(shape.startPoint, shape.endPoint);
  }

  return Rect.zero;
}

ShapeType? _shapeTypeFor(BaseShape shape) {
  return switch (shape) {
    RectangleShape() => ShapeType.rectangle,
    SquareShape() => ShapeType.rectangle,
    OvalShape() => ShapeType.oval,
    CircleShape() => ShapeType.oval,
    LineShape() => ShapeType.line,
    ArrowShape() => ShapeType.arrow,
    TextShape() => ShapeType.text,
    _ => null,
  };
}

Offset _cornerOffset(Rect bounds, ResizeCorner corner) {
  return switch (corner) {
    ResizeCorner.topLeft => bounds.topLeft,
    ResizeCorner.topRight => bounds.topRight,
    ResizeCorner.bottomLeft => bounds.bottomLeft,
    ResizeCorner.bottomRight => bounds.bottomRight,
  };
}

ResizeCorner _oppositeCorner(ResizeCorner corner) {
  return switch (corner) {
    ResizeCorner.topLeft => ResizeCorner.bottomRight,
    ResizeCorner.topRight => ResizeCorner.bottomLeft,
    ResizeCorner.bottomLeft => ResizeCorner.topRight,
    ResizeCorner.bottomRight => ResizeCorner.topLeft,
  };
}

Path _dashPath(
  Path source, {
  required double dashLength,
  required double dashGap,
}) {
  final dashed = Path();

  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = distance + dashLength;
      dashed.addPath(metric.extractPath(distance, next), Offset.zero);
      distance = next + dashGap;
    }
  }

  return dashed;
}
