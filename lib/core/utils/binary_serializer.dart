// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FILE BINARY FORMAT (little-endian throughout)
// ─────────────────────────────────────────────────────────────────────────────
//
// FILE HEADER  (3 bytes)
//   0xBF 0x50 0x01          magic[2] + version
//
// SHAPE RECORD  (repeated for each shape)
//   [1B]  TypeID            see ShapeTypeId constants below
//
//   ── Common header ──
//   [4B]  strokeColor       ARGB as Uint32 (big-endian ARGB component order)
//   [8B]  strokeWidth       Float64
//   [2B]  id length         Uint16  (max 65 535 chars)
//   [?B]  id bytes          UTF-8
//
//   ── TwoPointShape body ──  (Line / Arrow / Rect / Oval / Circle / Square)
//   [1B]  hasFill           0x00 = no fill, 0x01 = has fill
//   [4B]  fillColor         ARGB Uint32  (only present when hasFill == 0x01)
//   [8B]  startPoint.dx     Float64
//   [8B]  startPoint.dy     Float64
//   [8B]  endPoint.dx       Float64
//   [8B]  endPoint.dy       Float64
//
//   ── TextShape extra ──     (after TwoPointShape body)
//   [8B]  fontSize          Float64
//   [4B]  text byte length  Uint32
//   [?B]  text bytes        UTF-8
//
//   ── PathShape body ──      (Brush / Eraser)
//   [1B]  isFinalized       0x00 / 0x01
//   [4B]  pointCount        Uint32
//   [?B]  points            pointCount × (Float64 dx + Float64 dy) = 16B each
//
// ─────────────────────────────────────────────────────────────────────────────

/// TypeID constants – stored as a single byte in the stream.
abstract final class ShapeTypeId {
  static const int line = 0x01;
  static const int arrow = 0x02;
  static const int rectangle = 0x03;
  static const int oval = 0x04;
  static const int circle = 0x05;
  static const int square = 0x06;
  static const int text = 0x07;
  static const int brush = 0x08;
  static const int eraser = 0x09;
}

/// File magic bytes + version byte.
const List<int> _kMagic = [0xBF, 0x50, 0x01];

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Encodes [shapes] into a binary [Uint8List].
///
/// The heavy loop runs inside [Isolate.run] so the main thread is never
/// blocked, keeping the UI jank-free even for large canvases.
Future<Uint8List> encodeShapes(
  List<BaseShape> shapes,
  double canvasWidth,
  double canvasHeight,
) async {
  // Isolate.run requires the closure to be top-level or static; we pass the
  // plain List which is sendable (all fields are primitives / Dart-native).
  return Isolate.run(() => _encodeSync(shapes, canvasWidth, canvasHeight));
}

/// Decodes a [Uint8List] produced by [encodeShapes] back into shapes.
///
/// Throws [FormatException] on magic/version mismatch.
/// Returns an empty list for a zero-length input.
Future<({List<BaseShape> shapes, double canvasWidth, double canvasHeight})>
decodeShapes(Uint8List data) async {
  return Isolate.run(() => _decodeSync(data));
}

// ─────────────────────────────────────────────────────────────────────────────
// Synchronous encode  (runs inside Isolate)
// ─────────────────────────────────────────────────────────────────────────────

void _validateDouble(double value, String name) {
  if (value.isNaN || value.isInfinite) {
    throw FormatException('Invalid $name: $value (cannot be NaN or Infinity)');
  }
  if (name == 'strokeWidth' && (value < 0 || value > 1000)) {
    throw FormatException('Invalid $name: $value (must be in 0..1000)');
  }
}

Uint8List _encodeSync(
  List<BaseShape> shapes,
  double canvasWidth,
  double canvasHeight,
) {
  final builder =
      BytesBuilder(); // Default copy: true to allow reusing the shared buffer safely.

  // File header
  builder.add(_kMagic);

  final sharedBuf = ByteData(32);

  // Write canvas dimensions
  sharedBuf.setFloat64(0, canvasWidth, Endian.little);
  sharedBuf.setFloat64(8, canvasHeight, Endian.little);
  builder.add(sharedBuf.buffer.asUint8List(0, 16));

  for (final shape in shapes) {
    if (shape is BrushShape) {
      _writePathShape(
        builder,
        ShapeTypeId.brush,
        shape.id,
        shape.strokeColor.toARGB32(),
        shape.strokeWidth,
        shape.isFinalized == true,
        shape.points,
        sharedBuf,
      );
    } else if (shape is EraserShape) {
      _writePathShape(
        builder,
        ShapeTypeId.eraser,
        shape.id,
        shape.strokeColor.toARGB32(),
        shape.strokeWidth,
        shape.isFinalized == true,
        shape.points,
        sharedBuf,
      );
    } else if (shape is TextShape) {
      _writeTextShape(
        builder,
        shape.id,
        shape.strokeColor.toARGB32(),
        shape.strokeWidth,
        shape.fillColor?.toARGB32(),
        shape.startPoint.dx,
        shape.startPoint.dy,
        shape.endPoint.dx,
        shape.endPoint.dy,
        shape.fontSize,
        shape.text,
        sharedBuf,
      );
    } else if (shape is LineShape) {
      _writeTwoPointShape(
        builder,
        ShapeTypeId.line,
        shape.id,
        shape.strokeColor.toARGB32(),
        shape.strokeWidth,
        shape.fillColor?.toARGB32(),
        shape.startPoint.dx,
        shape.startPoint.dy,
        shape.endPoint.dx,
        shape.endPoint.dy,
        sharedBuf,
      );
    } else if (shape is ArrowShape) {
      _writeTwoPointShape(
        builder,
        ShapeTypeId.arrow,
        shape.id,
        shape.strokeColor.toARGB32(),
        shape.strokeWidth,
        shape.fillColor?.toARGB32(),
        shape.startPoint.dx,
        shape.startPoint.dy,
        shape.endPoint.dx,
        shape.endPoint.dy,
        sharedBuf,
      );
    } else if (shape is RectangleShape) {
      _writeTwoPointShape(
        builder,
        ShapeTypeId.rectangle,
        shape.id,
        shape.strokeColor.toARGB32(),
        shape.strokeWidth,
        shape.fillColor?.toARGB32(),
        shape.start.dx,
        shape.start.dy,
        shape.end.dx,
        shape.end.dy,
        sharedBuf,
      );
    } else if (shape is OvalShape) {
      _writeTwoPointShape(
        builder,
        ShapeTypeId.oval,
        shape.id,
        shape.strokeColor.toARGB32(),
        shape.strokeWidth,
        shape.fillColor?.toARGB32(),
        shape.startPoint.dx,
        shape.startPoint.dy,
        shape.endPoint.dx,
        shape.endPoint.dy,
        sharedBuf,
      );
    } else if (shape is CircleShape) {
      _writeTwoPointShape(
        builder,
        ShapeTypeId.circle,
        shape.id,
        shape.strokeColor.toARGB32(),
        shape.strokeWidth,
        shape.fillColor?.toARGB32(),
        shape.startPoint.dx,
        shape.startPoint.dy,
        shape.endPoint.dx,
        shape.endPoint.dy,
        sharedBuf,
      );
    } else if (shape is SquareShape) {
      _writeTwoPointShape(
        builder,
        ShapeTypeId.square,
        shape.id,
        shape.strokeColor.toARGB32(),
        shape.strokeWidth,
        shape.fillColor?.toARGB32(),
        shape.startPoint.dx,
        shape.startPoint.dy,
        shape.endPoint.dx,
        shape.endPoint.dy,
        sharedBuf,
      );
    } else {
      throw UnsupportedError(
        'Unsupported shape type: ${shape.runtimeType}. Add serializer support before encoding.',
      );
    }
  }

  return builder.takeBytes();
}

// ── Writers ──────────────────────────────────────────────────────────────────

void _writeCommonHeader(
  BytesBuilder builder,
  int typeId,
  String id,
  int strokeColorValue,
  double strokeWidth,
  ByteData sharedBuf,
) {
  final idBytes = utf8.encode(id);
  if (idBytes.length > 65535) {
    throw const FormatException('Shape ID exceeds 65535 bytes limit.');
  }
  _validateDouble(strokeWidth, 'strokeWidth');

  // TypeID
  builder.addByte(typeId);

  // strokeColor as ARGB Uint32
  sharedBuf.setUint32(0, strokeColorValue, Endian.big);
  builder.add(sharedBuf.buffer.asUint8List(0, 4));

  // strokeWidth Float64
  sharedBuf.setFloat64(0, strokeWidth, Endian.little);
  builder.add(sharedBuf.buffer.asUint8List(0, 8));

  // id as UTF-8 with Uint16 length prefix
  sharedBuf.setUint16(0, idBytes.length, Endian.little);
  builder.add(sharedBuf.buffer.asUint8List(0, 2));
  builder.add(idBytes);
}

void _writeTwoPointShape(
  BytesBuilder builder,
  int typeId,
  String id,
  int strokeColorValue,
  double strokeWidth,
  int? fillColorValue,
  double startDx,
  double startDy,
  double endDx,
  double endDy,
  ByteData sharedBuf,
) {
  _writeCommonHeader(
    builder,
    typeId,
    id,
    strokeColorValue,
    strokeWidth,
    sharedBuf,
  );

  // fill
  if (fillColorValue == null) {
    builder.addByte(0x00);
  } else {
    builder.addByte(0x01);
    sharedBuf.setUint32(0, fillColorValue, Endian.big);
    builder.add(sharedBuf.buffer.asUint8List(0, 4));
  }

  _validateDouble(startDx, 'startPoint.dx');
  _validateDouble(startDy, 'startPoint.dy');
  _validateDouble(endDx, 'endPoint.dx');
  _validateDouble(endDy, 'endPoint.dy');

  // startPoint + endPoint
  sharedBuf.setFloat64(0, startDx, Endian.little);
  sharedBuf.setFloat64(8, startDy, Endian.little);
  sharedBuf.setFloat64(16, endDx, Endian.little);
  sharedBuf.setFloat64(24, endDy, Endian.little);
  builder.add(sharedBuf.buffer.asUint8List(0, 32));
}

void _writeTextShape(
  BytesBuilder builder,
  String id,
  int strokeColorValue,
  double strokeWidth,
  int? fillColorValue,
  double startDx,
  double startDy,
  double endDx,
  double endDy,
  double fontSize,
  String text,
  ByteData sharedBuf,
) {
  // Reuse TwoPointShape writer for the common + coordinate parts
  _writeTwoPointShape(
    builder,
    ShapeTypeId.text,
    id,
    strokeColorValue,
    strokeWidth,
    fillColorValue,
    startDx,
    startDy,
    endDx,
    endDy,
    sharedBuf,
  );

  _validateDouble(fontSize, 'fontSize');

  // fontSize
  sharedBuf.setFloat64(0, fontSize, Endian.little);
  builder.add(sharedBuf.buffer.asUint8List(0, 8));

  // text  (Uint32 length + UTF-8 bytes)
  final textBytes = utf8.encode(text);
  if (textBytes.length > 5000) {
    throw const FormatException('Text length exceeds 5000 bytes limit.');
  }

  sharedBuf.setUint32(0, textBytes.length, Endian.little);
  builder.add(sharedBuf.buffer.asUint8List(0, 4));
  builder.add(textBytes);
}

void _writePathShape(
  BytesBuilder builder,
  int typeId,
  String id,
  int strokeColorValue,
  double strokeWidth,
  bool isFinalized,
  List<Offset> points,
  ByteData sharedBuf,
) {
  _writeCommonHeader(
    builder,
    typeId,
    id,
    strokeColorValue,
    strokeWidth,
    sharedBuf,
  );

  // isFinalized flag
  builder.addByte(isFinalized ? 0x01 : 0x00);

  // pointCount Uint32
  sharedBuf.setUint32(0, points.length, Endian.little);
  builder.add(sharedBuf.buffer.asUint8List(0, 4));

  // Each point: dx Float64 + dy Float64 = 16 bytes
  for (final pt in points) {
    _validateDouble(pt.dx, 'point.dx');
    _validateDouble(pt.dy, 'point.dy');
    sharedBuf.setFloat64(0, pt.dx, Endian.little);
    sharedBuf.setFloat64(8, pt.dy, Endian.little);
    builder.add(sharedBuf.buffer.asUint8List(0, 16));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Synchronous decode  (runs inside Isolate)
// ─────────────────────────────────────────────────────────────────────────────

({List<BaseShape> shapes, double canvasWidth, double canvasHeight}) _decodeSync(
  Uint8List data,
) {
  if (data.isEmpty) {
    return (shapes: const [], canvasWidth: 0.0, canvasHeight: 0.0);
  }

  if (data.length < 3) {
    throw const FormatException('Truncated binary data: missing file header.');
  }

  try {
    final view = ByteData.sublistView(data);
    int cursor = 0;

    // ── Validate magic + version ──────────────────────────────────────────
    if (data[0] != _kMagic[0] ||
        data[1] != _kMagic[1] ||
        data[2] != _kMagic[2]) {
      throw const FormatException(
        'Invalid magic bytes or unsupported version.',
      );
    }

    cursor = 3;

    // Read canvas dimensions
    _checkBounds(cursor, 16, data.length, 'canvas dimensions');
    final canvasWidth = view.getFloat64(cursor, Endian.little);
    final canvasHeight = view.getFloat64(cursor + 8, Endian.little);
    cursor += 16;

    final shapes = <BaseShape>[];

    while (cursor < data.length) {
      // ── TypeID ───────────────────────────────────────────────────────────
      _checkBounds(cursor, 1, data.length, 'TypeID');
      final typeId = data[cursor];
      cursor += 1;

      // ── Common header ────────────────────────────────────────────────────
      _checkBounds(cursor, 4, data.length, 'strokeColor');
      final strokeColor = _readColor(view, cursor);
      cursor += 4;

      _checkBounds(cursor, 8, data.length, 'strokeWidth');
      final strokeWidth = view.getFloat64(cursor, Endian.little);
      cursor += 8;

      _checkBounds(cursor, 2, data.length, 'id length');
      final idLen = view.getUint16(cursor, Endian.little);
      cursor += 2;

      _checkBounds(cursor, idLen, data.length, 'id bytes');
      final id = utf8.decode(data.sublist(cursor, cursor + idLen));
      cursor += idLen;

      // ── Shape-specific decode ─────────────────────────────────────────────
      switch (typeId) {
        case ShapeTypeId.brush:
        case ShapeTypeId.eraser:
          final result = _readPathShape(
            view,
            data,
            cursor,
            typeId,
            id,
            strokeColor,
            strokeWidth,
          );
          shapes.add(result.shape);
          cursor = result.cursor;

        case ShapeTypeId.text:
          final result = _readTextShape(
            view,
            data,
            cursor,
            id,
            strokeColor,
            strokeWidth,
          );
          shapes.add(result.shape);
          cursor = result.cursor;

        case ShapeTypeId.line:
        case ShapeTypeId.arrow:
        case ShapeTypeId.rectangle:
        case ShapeTypeId.oval:
        case ShapeTypeId.circle:
        case ShapeTypeId.square:
          final result = _readTwoPointShape(
            view,
            cursor,
            typeId,
            id,
            strokeColor,
            strokeWidth,
            data.length,
          );
          shapes.add(result.shape);
          cursor = result.cursor;

        default:
          // Unknown TypeID – abort to avoid corrupt reads.
          throw FormatException(
            'Unknown ShapeTypeId: 0x${typeId.toRadixString(16)}',
          );
      }
    }

    return (
      shapes: shapes,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );
  } on FormatException {
    rethrow;
  } catch (e) {
    throw FormatException('Binary decode failed: $e');
  }
}

// ── Readers ───────────────────────────────────────────────────────────────────

({BaseShape shape, int cursor}) _readTwoPointShape(
  ByteData view,
  int cursor,
  int typeId,
  String id,
  Color strokeColor,
  double strokeWidth,
  int dataLength,
) {
  // hasFill byte
  _checkBounds(cursor, 1, dataLength, 'hasFill');
  final hasFill = view.getUint8(cursor) == 0x01;
  cursor += 1;

  Color? fillColor;
  if (hasFill) {
    _checkBounds(cursor, 4, dataLength, 'fillColor');
    fillColor = _readColor(view, cursor);
    cursor += 4;
  }

  // 4 × Float64 = 32 bytes
  _checkBounds(cursor, 32, dataLength, 'coordinates');
  final sx = view.getFloat64(cursor, Endian.little);
  final sy = view.getFloat64(cursor + 8, Endian.little);
  final ex = view.getFloat64(cursor + 16, Endian.little);
  final ey = view.getFloat64(cursor + 24, Endian.little);
  cursor += 32;

  final start = Offset(sx, sy);
  final end = Offset(ex, ey);

  final BaseShape shape;
  switch (typeId) {
    case ShapeTypeId.line:
      shape = LineShape(
        startPoint: start,
        endPoint: end,
        id: id,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      );
    case ShapeTypeId.arrow:
      shape = ArrowShape(
        startPoint: start,
        endPoint: end,
        id: id,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      );
    case ShapeTypeId.rectangle:
      shape = RectangleShape(
        start: start,
        end: end,
        id: id,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      );
    case ShapeTypeId.oval:
      shape = OvalShape(
        startPoint: start,
        endPoint: end,
        id: id,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      );
    case ShapeTypeId.circle:
      shape = CircleShape.fromBounds(
        startPoint: start,
        endPoint: end,
        id: id,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      );
    case ShapeTypeId.square:
      shape = SquareShape.fromBounds(
        startPoint: start,
        endPoint: end,
        id: id,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      );
    default:
      throw FormatException('Unhandled TwoPointShape TypeID: $typeId');
  }

  return (shape: shape, cursor: cursor);
}

({BaseShape shape, int cursor}) _readTextShape(
  ByteData view,
  Uint8List data,
  int cursor,
  String id,
  Color strokeColor,
  double strokeWidth,
) {
  // Reuse two-point reader (without final shape construction)
  _checkBounds(cursor, 1, data.length, 'hasFill');
  final hasFill = view.getUint8(cursor) == 0x01;
  cursor += 1;

  Color? fillColor;
  if (hasFill) {
    _checkBounds(cursor, 4, data.length, 'fillColor');
    fillColor = _readColor(view, cursor);
    cursor += 4;
  }

  _checkBounds(cursor, 32, data.length, 'text coordinates');
  final sx = view.getFloat64(cursor, Endian.little);
  final sy = view.getFloat64(cursor + 8, Endian.little);
  final ex = view.getFloat64(cursor + 16, Endian.little);
  final ey = view.getFloat64(cursor + 24, Endian.little);
  cursor += 32;

  // fontSize
  _checkBounds(cursor, 8, data.length, 'fontSize');
  final fontSize = view.getFloat64(cursor, Endian.little);
  cursor += 8;

  // text bytes
  _checkBounds(cursor, 4, data.length, 'text length');
  final textLen = view.getUint32(cursor, Endian.little);
  cursor += 4;

  _checkBounds(cursor, textLen, data.length, 'text content');
  final text = utf8.decode(data.sublist(cursor, cursor + textLen));
  cursor += textLen;

  final shape = TextShape(
    startPoint: Offset(sx, sy),
    endPoint: Offset(ex, ey),
    text: text,
    fontSize: fontSize,
    id: id,
    fillColor: fillColor,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
  );

  return (shape: shape, cursor: cursor);
}

({BaseShape shape, int cursor}) _readPathShape(
  ByteData view,
  Uint8List data,
  int cursor,
  int typeId,
  String id,
  Color strokeColor,
  double strokeWidth,
) {
  _checkBounds(cursor, 1, data.length, 'isFinalized');
  final isFinalized = view.getUint8(cursor) == 0x01;
  cursor += 1;

  _checkBounds(cursor, 4, data.length, 'pointCount');
  final pointCount = view.getUint32(cursor, Endian.little);
  cursor += 4;

  // Each point = 16 bytes  (dx: F64 + dy: F64)
  _checkBounds(cursor, pointCount * 16, data.length, 'points array');
  final points = <Offset>[];
  for (var i = 0; i < pointCount; i++) {
    final dx = view.getFloat64(cursor, Endian.little);
    final dy = view.getFloat64(cursor + 8, Endian.little);
    points.add(Offset(dx, dy));
    cursor += 16;
  }

  if (points.isEmpty) {
    throw const FormatException('PathShape must have at least one point.');
  }

  final BaseShape shape;
  if (typeId == ShapeTypeId.brush) {
    shape = BrushShape(
      points: points,
      isFinalized: isFinalized,
      id: id,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  } else {
    shape = EraserShape(
      points: points,
      isFinalized: isFinalized,
      id: id,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  return (shape: shape, cursor: cursor);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _readColor(ByteData view, int offset) {
  final value = view.getUint32(offset, Endian.big);
  return Color(value);
}

/// Validates that [cursor] + [need] bytes are available in a buffer of
/// [bufLen] bytes.  Throws [FormatException] instead of a raw RangeError so
/// callers can distinguish corrupt data from programming errors.
void _checkBounds(int cursor, int need, int bufLen, String field) {
  if (cursor + need > bufLen) {
    throw FormatException(
      'Unexpected end of data while reading "$field" '
      '(need ${cursor + need} bytes, have $bufLen).',
    );
  }
}
