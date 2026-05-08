import 'dart:math';

import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingBoardNotifierProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: CustomPaint(
        painter: CanvasPainter(state: drawingState),
        child: const SizedBox.expand(),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final toolSelection = ref.read(toolSelectionNotifierProvider);
    if (toolSelection.toolType != ToolType.cursor) {
      return;
    }

    final drawingState = ref.read(drawingBoardNotifierProvider);
    final hitShape = _hitTestShapes(
      drawingState.finalizedShapes,
      details.localPosition,
    );

    ref
        .read(drawingBoardNotifierProvider.notifier)
        .selectShape(hitShape?.id);
  }

  void _handlePanStart(DragStartDetails details) {
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

    drawingBoardNotifier.updateDrawing(details.localPosition);
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

class CanvasPainter extends CustomPainter {
  const CanvasPainter({required this.state});

  final DrawingBoardState state;

  @override
  void paint(Canvas canvas, Size size) {
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
    final paint = _strokePaint(shape, cap: StrokeCap.round);
    canvas.drawLine(shape.startPoint, shape.endPoint, paint);

    final direction = shape.endPoint - shape.startPoint;
    if (direction.distance == 0) {
      return;
    }

    final unit = direction / direction.distance;
    final arrowLength = 12 + shape.strokeWidth * 2;
    final arrowAngle = 0.5;
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

    canvas.drawLine(shape.endPoint, shape.endPoint + left, paint);
    canvas.drawLine(shape.endPoint, shape.endPoint + right, paint);
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
    _drawFilledRect(canvas, rect, shape);

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
    )..layout(maxWidth: rect.width);

    final offset = Offset(
      rect.left + (rect.width - textPainter.width) / 2,
      rect.top + (rect.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, offset);
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
}

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
