import 'dart:math';

import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

const double _kHandleRadius = 6.0;
const double _kHandleHitSize = 44.0;
const double _kSelectionPadding = 4.0;
const double _kDashLength = 6.0;
const double _kDashGap = 4.0;
const Color _kSelectionColor = Color(0xFF2196F3);

class InteractiveCanvas extends ConsumerStatefulWidget {
  const InteractiveCanvas({super.key});

  @override
  ConsumerState<InteractiveCanvas> createState() => _InteractiveCanvasState();
}

class _InteractiveCanvasState extends ConsumerState<InteractiveCanvas> {
  _DragMode _dragMode = _DragMode.none;
  ResizeCorner? _resizeCorner;
  bool _isShiftPressed = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingBoardNotifierProvider);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: CustomPaint(
          painter: CanvasPainter(state: drawingState),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final bool isShift = event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight;
    if (!isShift) {
      return KeyEventResult.ignored;
    }

    final bool pressed = event is KeyDownEvent || event is KeyRepeatEvent;
    if (_isShiftPressed != pressed) {
      setState(() {
        _isShiftPressed = pressed;
      });
    }

    return KeyEventResult.handled;
  }

  void _handleTapDown(TapDownDetails details) {
    _focusNode.requestFocus();
    final toolSelection = ref.read(toolSelectionNotifierProvider);
    if (toolSelection.toolType != ToolType.cursor) {
      return;
    }

    final drawingState = ref.read(drawingBoardNotifierProvider);
    
    final selectedShape = drawingState.selectedShape;
    if (selectedShape != null) {
      final selectionBounds = _selectionBoundsFor(selectedShape);
      final hitCorner = _hitTestResizeHandle(selectionBounds, details.localPosition);
      
      if (hitCorner != null) {
        return; 
      }
    }

    final hitShape = _hitTestShapes(
      drawingState.finalizedShapes,
      details.localPosition,
    );

    ref
        .read(drawingBoardNotifierProvider.notifier)
        .selectShape(hitShape?.id);
  }

  void _handlePanStart(DragStartDetails details) {
    _focusNode.requestFocus();
    final toolSelection = ref.read(toolSelectionNotifierProvider);
    final drawingBoardNotifier = ref.read(
      drawingBoardNotifierProvider.notifier,
    );

    if (toolSelection.toolType == ToolType.cursor) {
      _startCursorDrag(details.localPosition, drawingBoardNotifier);
      return;
    }

    drawingBoardNotifier.startDrawing(details.localPosition, toolSelection);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final toolSelection = ref.read(toolSelectionNotifierProvider);
    final drawingBoardNotifier = ref.read(
      drawingBoardNotifierProvider.notifier,
    );

    if (toolSelection.toolType == ToolType.cursor) {
      final selectedShape =
          ref.read(drawingBoardNotifierProvider).selectedShape;
      if (selectedShape == null || _dragMode == _DragMode.none) {
        return;
      }

      final delta = details.delta;
      if (_dragMode == _DragMode.move) {
        drawingBoardNotifier.updateSelectedShape(selectedShape.translate(delta));
      } else if (_dragMode == _DragMode.resize && _resizeCorner != null) {
        drawingBoardNotifier.updateSelectedShape(
          selectedShape.resize(delta, _resizeCorner!),
        );
      }

      return;
    }

    drawingBoardNotifier.updateDrawing(
      details.localPosition,
      toolSelection: toolSelection,
      constrainToSquare: _isShiftPressed,
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    final toolSelection = ref.read(toolSelectionNotifierProvider);
    final drawingBoardNotifier = ref.read(
      drawingBoardNotifierProvider.notifier,
    );

    if (toolSelection.toolType == ToolType.cursor) {
      if (_dragMode != _DragMode.none) {
        drawingBoardNotifier.endTransform();
      }
      _dragMode = _DragMode.none;
      _resizeCorner = null;
      return;
    }

    drawingBoardNotifier.commitDrawing();

    // Show text input dialog after committing a text shape
    if (toolSelection.toolType == ToolType.shape &&
        toolSelection.shapeType == ShapeType.text) {
      _showTextInputDialog();
    }
  }

  Future<void> _showTextInputDialog() async {
    final drawingState = ref.read(drawingBoardNotifierProvider);
    final selectedShape = drawingState.selectedShape;

    if (selectedShape is! TextShape) return;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _TextInputDialog(
        initialText: selectedShape.text,
      ),
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      ref.read(drawingBoardNotifierProvider.notifier).updateSelectedShape(
        selectedShape.copyWithText(text: result),
      );
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

    final selectedShape = ref.read(drawingBoardNotifierProvider).selectedShape;
    if (selectedShape == null) {
      return;
    }

    final selectionBounds = _selectionBoundsFor(selectedShape);
    final hitCorner = _hitTestResizeHandle(selectionBounds, position);
    if (hitCorner != null) {
      _dragMode = _DragMode.resize;
      _resizeCorner = hitCorner;
      drawingBoardNotifier.beginTransform();
      return;
    }

    if (selectedShape.contains(position)) {
      _dragMode = _DragMode.move;
      drawingBoardNotifier.beginTransform();
    }
  }
}

enum _DragMode { none, move, resize }

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
        FilledButton(
          onPressed: _submit,
          child: const Text('OK'),
        ),
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
  const CanvasPainter({required this.state});

  final DrawingBoardState state;

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

    final selectedShape = state.selectedShape;
    if (selectedShape != null) {
      _drawSelection(canvas, selectedShape);
    }

    if (needsLayer) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.state != state;
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
        style: TextStyle(
          color: shape.strokeColor,
          fontSize: shape.fontSize,
        ),
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
    final bounds = _selectionBoundsFor(shape);
    if (bounds.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = _kSelectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    final dashedPath = _dashPath(
      Path()..addRect(bounds),
      dashLength: _kDashLength,
      dashGap: _kDashGap,
    );

    canvas.drawPath(dashedPath, paint);

    final handlePaint = Paint()
      ..color = _kSelectionColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final corner in ResizeCorner.values) {
      final position = _cornerOffset(bounds, corner);
      canvas.drawCircle(position, _kHandleRadius, handlePaint);
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
    if (shape.contains(point)) {
      return shape;
    }
  }

  return null;
}

ResizeCorner? _hitTestResizeHandle(Rect bounds, Offset point) {
  for (final corner in ResizeCorner.values) {
    final rect = Rect.fromCenter(
      center: _cornerOffset(bounds, corner),
      width: _kHandleHitSize,
      height: _kHandleHitSize,
    );

    if (rect.contains(point)) {
      return corner;
    }
  }

  return null;
}

Rect _selectionBoundsFor(BaseShape shape) {
  final bounds = _shapeBounds(shape);
  if (bounds.isEmpty) {
    return bounds.inflate(_kSelectionPadding);
  }

  return bounds.inflate((shape.strokeWidth / 2) + _kSelectionPadding);
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

Offset _cornerOffset(Rect bounds, ResizeCorner corner) {
  return switch (corner) {
    ResizeCorner.topLeft => bounds.topLeft,
    ResizeCorner.topRight => bounds.topRight,
    ResizeCorner.bottomLeft => bounds.bottomLeft,
    ResizeCorner.bottomRight => bounds.bottomRight,
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
