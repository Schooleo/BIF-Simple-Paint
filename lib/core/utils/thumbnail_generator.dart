import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';

abstract final class ThumbnailGenerator {
  /// Generates a PNG thumbnail from a list of [BaseShape]s.
  ///
  /// The algorithm finds the bounding box of all shapes, then scales
  /// and translates the canvas to perfectly fit the drawing within
  /// [targetWidth] and [targetHeight], minus the [padding].
  ///
  /// Uses off-screen `dart:ui` rendering for zero-UI dependencies.
  static Future<Uint8List?> generate(
    List<BaseShape> shapes, {
    double targetWidth = 200,
    double targetHeight = 200,
    double padding = 10,
    ui.Color backgroundColor = const ui.Color(0xFFFFFFFF),
  }) async {
    if (shapes.isEmpty) return null;

    _validateCanvasArgs(targetWidth, targetHeight, padding);

    // Prepare Canvas
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, targetWidth, targetHeight),
    );

    // 1. Fill background color BEFORE any other drawing commands
    canvas.drawColor(backgroundColor, ui.BlendMode.srcOver);

    // 2. Transformation Logic (Mandatory)
    final drawingBounds =
        _calculateDrawingBounds(shapes) ??
        ui.Rect.fromLTWH(0, 0, targetWidth, targetHeight);

    final boxWidth = drawingBounds.width;
    final boxHeight = drawingBounds.height;

    // Prevent division by zero if drawing is a single point
    final safeBoxWidth = boxWidth > 0 ? boxWidth : 1.0;
    final safeBoxHeight = boxHeight > 0 ? boxHeight : 1.0;

    final availableWidth = targetWidth - padding * 2;
    final availableHeight = targetHeight - padding * 2;

    final scale = math.min(
      availableWidth / safeBoxWidth,
      availableHeight / safeBoxHeight,
    );

    // Apply transformations: center -> scale -> move to origin
    canvas.translate(targetWidth / 2, targetHeight / 2);
    canvas.scale(scale);
    canvas.translate(
      -(drawingBounds.left + boxWidth / 2),
      -(drawingBounds.top + boxHeight / 2),
    );

    // 4. Optimize Paint Object: Initialize EXACTLY ONE ui.Paint outside the loop
    final paint = ui.Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.medium;

    ui.Picture? picture;
    ui.Image? image;
    try {
      // Draw Shapes in a layer so eraser clears only drawn content.
      canvas.saveLayer(drawingBounds, ui.Paint());
      try {
        for (final shape in shapes) {
          _drawShape(canvas, shape, paint);
        }
      } finally {
        canvas.restore();
      }

      // Extract Image to Uint8List
      picture = recorder.endRecording();
      image = await picture.toImage(targetWidth.toInt(), targetHeight.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } finally {
      image?.dispose();
      picture?.dispose();
    }
  }

  // 3. Fix Type Mismatch & Add Shapes: _drawShape handles all base shapes
  static void _drawShape(ui.Canvas canvas, BaseShape shape, ui.Paint paint) {
    paint.strokeWidth = shape.strokeWidth;
    paint.blendMode = shape is EraserShape
        ? ui.BlendMode.clear
        : ui.BlendMode.srcOver;
    paint.strokeCap = ui.StrokeCap.round;
    paint.strokeJoin = ui.StrokeJoin.round;

    if (shape is PathShape) {
      paint.style = ui.PaintingStyle.stroke;
      paint.color = shape.strokeColor;

      final path = ui.Path();
      if (shape.points.isNotEmpty) {
        path.moveTo(shape.points.first.dx, shape.points.first.dy);
        for (int i = 1; i < shape.points.length; i++) {
          path.lineTo(shape.points[i].dx, shape.points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    } else if (shape is TextShape) {
      final builder =
          ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: shape.fontSize))
            ..pushStyle(ui.TextStyle(color: shape.strokeColor))
            ..addText(shape.text);
      final paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
      canvas.drawParagraph(paragraph, shape.startPoint);
    } else if (shape is TwoPointShape) {
      void drawGeometry(ui.Paint p) {
        if (shape is LineShape) {
          canvas.drawLine(shape.startPoint, shape.endPoint, p);
        } else if (shape is RectangleShape || shape is SquareShape) {
          canvas.drawRect(
            ui.Rect.fromPoints(shape.startPoint, shape.endPoint),
            p,
          );
        } else if (shape is OvalShape) {
          canvas.drawOval(
            ui.Rect.fromPoints(shape.startPoint, shape.endPoint),
            p,
          );
        } else if (shape is CircleShape) {
          canvas.drawCircle(shape.center, shape.radius, p);
        } else if (shape is ArrowShape) {
          canvas.drawLine(shape.startPoint, shape.endPoint, p);

          final dx = shape.endPoint.dx - shape.startPoint.dx;
          final dy = shape.endPoint.dy - shape.startPoint.dy;
          final angle = math.atan2(dy, dx);
          // Arrow head size relative to stroke width, ensuring minimum visibility
          final arrowLength = math.max(10.0, p.strokeWidth * 2);

          final path = ui.Path();
          path.moveTo(shape.endPoint.dx, shape.endPoint.dy);
          path.lineTo(
            shape.endPoint.dx - arrowLength * math.cos(angle - math.pi / 6),
            shape.endPoint.dy - arrowLength * math.sin(angle - math.pi / 6),
          );
          path.moveTo(shape.endPoint.dx, shape.endPoint.dy);
          path.lineTo(
            shape.endPoint.dx - arrowLength * math.cos(angle + math.pi / 6),
            shape.endPoint.dy - arrowLength * math.sin(angle + math.pi / 6),
          );
          canvas.drawPath(path, p);
        }
      }

      // Draw Fill if present
      if (shape.fillColor != null &&
          shape is! LineShape &&
          shape is! ArrowShape) {
        paint.style = ui.PaintingStyle.fill;
        paint.color = shape.fillColor!;
        drawGeometry(paint);
      }

      // Draw Stroke
      paint.style = ui.PaintingStyle.stroke;
      paint.color = shape.strokeColor;
      drawGeometry(paint);
    }
  }

  static void _validateCanvasArgs(
    double targetWidth,
    double targetHeight,
    double padding,
  ) {
    if (targetWidth <= 0 || targetHeight <= 0) {
      throw const FormatException(
        'targetWidth and targetHeight must be greater than zero.',
      );
    }
    if (padding < 0) {
      throw const FormatException('padding must be non-negative.');
    }
    if (targetWidth <= padding * 2 || targetHeight <= padding * 2) {
      throw const FormatException('padding leaves no drawable area.');
    }
  }

  static ui.Rect? _calculateDrawingBounds(List<BaseShape> shapes) {
    ui.Rect? bounds;

    for (final shape in shapes) {
      final shapeBounds = _shapeBounds(shape);
      if (shapeBounds == null) {
        continue;
      }

      bounds = bounds == null
          ? shapeBounds
          : bounds.expandToInclude(shapeBounds);
    }

    return bounds;
  }

  static ui.Rect? _shapeBounds(BaseShape shape) {
    if (shape is PathShape) {
      if (shape.points.isEmpty) {
        return null;
      }

      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (final pt in shape.points) {
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dy > maxY) maxY = pt.dy;
      }

      final halfStroke = shape.strokeWidth / 2;
      return ui.Rect.fromLTRB(minX, minY, maxX, maxY).inflate(halfStroke);
    }

    if (shape is TextShape) {
      final paragraph =
          ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: shape.fontSize))
            ..pushStyle(ui.TextStyle(color: shape.strokeColor))
            ..addText(shape.text);

      final builtParagraph = paragraph.build();
      builtParagraph.layout(
        const ui.ParagraphConstraints(width: double.infinity),
      );

      final textBounds = ui.Rect.fromLTWH(
        shape.startPoint.dx,
        shape.startPoint.dy,
        builtParagraph.maxIntrinsicWidth,
        builtParagraph.height,
      );

      final halfStroke = shape.strokeWidth / 2;
      return textBounds.inflate(halfStroke);
    }

    if (shape is TwoPointShape) {
      final baseBounds = ui.Rect.fromPoints(shape.startPoint, shape.endPoint);
      final halfStroke = shape.strokeWidth / 2;

      if (shape is ArrowShape) {
        final arrowLength = math.max(10.0, shape.strokeWidth * 2);
        return baseBounds.inflate(halfStroke + arrowLength);
      }

      return baseBounds.inflate(halfStroke);
    }

    return null;
  }
}
