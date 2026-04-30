import 'package:bif_simple_paint/features/drawing_board/models/base_shape.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InteractiveCanvas extends ConsumerWidget {
  const InteractiveCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingState = ref.watch(drawingBoardNotifierProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        final currentTool = ref.read(toolSelectionNotifierProvider).toolType;
        ref
            .read(drawingBoardNotifierProvider.notifier)
            .startDrawing(details.localPosition, currentTool);
      },
      onPanUpdate: (details) {
        ref
            .read(drawingBoardNotifierProvider.notifier)
            .updateDrawing(details.localPosition);
      },
      onPanEnd: (_) {
        ref.read(drawingBoardNotifierProvider.notifier).commitDrawing();
      },
      child: CustomPaint(
        painter: CanvasPainter(state: drawingState),
        child: const SizedBox.expand(),
      ),
    );
  }
}

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
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.state != state;
  }

  void _drawShape(Canvas canvas, BaseShape shape) {
    if (shape is PathShape) {
      _drawPathShape(canvas, shape);
      return;
    }

    if (shape is LineShape) {
      _drawLineShape(canvas, shape);
      return;
    }

    if (shape is RectangleShape) {
      _drawRectShape(canvas, shape);
      return;
    }

    if (shape is OvalShape) {
      _drawOvalShape(canvas, shape);
      return;
    }

    if (shape is CircleShape) {
      _drawCircleShape(canvas, shape);
      return;
    }

    if (shape is SquareShape) {
      _drawSquareShape(canvas, shape);
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
    final paint = _strokePaint(shape);
    canvas.drawLine(shape.startPoint, shape.endPoint, paint);
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

  Paint _strokePaint(BaseShape shape) {
    return Paint()
      ..color = shape.strokeColor
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..blendMode = shape.blendMode;
  }
}
