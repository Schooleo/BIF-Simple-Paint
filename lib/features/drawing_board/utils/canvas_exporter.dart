import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

abstract final class CanvasExporter {
  static const double _defaultTargetSize = 2048;
  static const double _defaultPadding = 96;

  static Future<Uint8List?> export(
    List<BaseShape> shapes, {
    required double canvasWidth,
    required double canvasHeight,
    required Color backgroundColor,
    bool asJpeg = false,
  }) async {
    const resolvedSize = _defaultTargetSize;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, resolvedSize, resolvedSize),
    );
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.medium;

    canvas.drawColor(backgroundColor, BlendMode.srcOver);
    final bounds = _calculateDrawingBounds(shapes);
    if (bounds != null && !bounds.isEmpty) {
      final available = resolvedSize - (_defaultPadding * 2);
      final safeWidth = bounds.width <= 0 ? 1.0 : bounds.width;
      final safeHeight = bounds.height <= 0 ? 1.0 : bounds.height;
      final scale = math.min(available / safeWidth, available / safeHeight);
      canvas.translate(resolvedSize / 2, resolvedSize / 2);
      canvas.scale(scale);
      canvas.translate(
        -(bounds.left + (bounds.width / 2)),
        -(bounds.top + (bounds.height / 2)),
      );
    }

    canvas.saveLayer(
      const Rect.fromLTWH(0, 0, resolvedSize, resolvedSize),
      Paint(),
    );
    try {
      for (final shape in shapes) {
        _drawShape(canvas, shape, paint);
      }
    } finally {
      canvas.restore();
    }

    ui.Picture? picture;
    ui.Image? image;
    try {
      picture = recorder.endRecording();
      image = await picture.toImage(
        resolvedSize.round().clamp(1, 16384),
        resolvedSize.round().clamp(1, 16384),
      );

      if (!asJpeg) {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      }

      final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) {
        return null;
      }

      final overlay = img.decodePng(pngData.buffer.asUint8List());
      if (overlay == null) {
        return null;
      }

      final composed = img.Image(width: image.width, height: image.height);
      img.fill(
        composed,
        color: img.ColorRgba8(
          (backgroundColor.r * 255.0).round().clamp(0, 255),
          (backgroundColor.g * 255.0).round().clamp(0, 255),
          (backgroundColor.b * 255.0).round().clamp(0, 255),
          255,
        ),
      );
      img.compositeImage(composed, overlay);

      return Uint8List.fromList(img.encodeJpg(composed, quality: 92));
    } finally {
      image?.dispose();
      picture?.dispose();
    }
  }

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
      return;
    }

    if (shape is TextShape) {
      final builder =
          ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: shape.fontSize))
            ..pushStyle(ui.TextStyle(color: shape.strokeColor))
            ..addText(shape.text);
      final paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
      canvas.drawParagraph(paragraph, shape.startPoint);
      return;
    }

    if (shape is! TwoPointShape) {
      return;
    }

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

    if (shape.fillColor != null &&
        shape is! LineShape &&
        shape is! ArrowShape) {
      paint.style = ui.PaintingStyle.fill;
      paint.color = shape.fillColor!;
      drawGeometry(paint);
    }

    paint.style = ui.PaintingStyle.stroke;
    paint.color = shape.strokeColor;
    drawGeometry(paint);
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
      double maxX = double.negativeInfinity;
      double minY = double.infinity;
      double maxY = double.negativeInfinity;

      for (final point in shape.points) {
        minX = math.min(minX, point.dx);
        maxX = math.max(maxX, point.dx);
        minY = math.min(minY, point.dy);
        maxY = math.max(maxY, point.dy);
      }

      return ui.Rect.fromLTRB(
        minX,
        minY,
        maxX,
        maxY,
      ).inflate(shape.strokeWidth / 2);
    }

    if (shape is TextShape) {
      return ui.Rect.fromPoints(
        shape.startPoint,
        shape.endPoint,
      ).inflate(shape.strokeWidth / 2);
    }

    if (shape is TwoPointShape) {
      return ui.Rect.fromPoints(
        shape.startPoint,
        shape.endPoint,
      ).inflate(shape.strokeWidth / 2);
    }

    return null;
  }
}
