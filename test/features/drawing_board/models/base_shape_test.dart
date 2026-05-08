import 'dart:ui';

import 'package:bif_simple_paint/features/drawing_board/models/base_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BrushShape.seed creates a single-point path with styled defaults', () {
    const point = Offset(10, 20);

    final shape = BrushShape.seed(point);

    expect(shape.points, <Offset>[point]);
    expect(shape.strokeColor, const Color(0xFF000000));
    expect(shape.strokeWidth, 2.0);
  });

  test('PathShape.extendTo returns a new path and preserves the original', () {
    const pointA = Offset(1, 2);
    const pointB = Offset(3, 4);
    const strokeColor = Color(0xFFFF0000);

    final shape = BrushShape(
      id: 'brush-1',
      points: <Offset>[pointA],
      strokeColor: strokeColor,
    );

    final updated = shape.extendTo(pointB) as BrushShape;

    expect(shape.points, <Offset>[pointA]);
    expect(updated.points, <Offset>[pointA, pointB]);
    expect(updated.id, 'brush-1');
    expect(updated.strokeColor, strokeColor);
    expect(updated.strokeWidth, 2.0);
  });

  test('PathShape.finalize freezes points list', () {
    const pointA = Offset(1, 2);
    const pointB = Offset(3, 4);

    final shape =
        BrushShape(points: <Offset>[pointA]).extendTo(pointB) as BrushShape;
    final finalized = shape.finalize() as BrushShape;

    expect(finalized.isFinalized, isTrue);
    expect(
      () => finalized.points.add(const Offset(5, 6)),
      throwsUnsupportedError,
    );
  });

  test('every shape clone returns an equivalent detached instance', () {
    final shapes = <BaseShape>[
      BrushShape(
        id: 'brush',
        points: const <Offset>[Offset(1, 1), Offset(2, 2)],
        strokeColor: const Color(0xFF123456),
        strokeWidth: 3,
      ),
      EraserShape(
        id: 'eraser',
        points: const <Offset>[Offset(2, 2), Offset(3, 3)],
        strokeWidth: 5,
      ),
      const LineShape(
        id: 'line',
        startPoint: Offset(0, 0),
        endPoint: Offset(5, 5),
        strokeColor: Color(0xFF111111),
      ),
      const ArrowShape(
        id: 'arrow',
        startPoint: Offset(2, 2),
        endPoint: Offset(8, 8),
        strokeColor: Color(0xFF222222),
      ),
      const TextShape(
        id: 'text',
        startPoint: Offset(1, 1),
        endPoint: Offset(6, 6),
        text: 'Hello',
        fontSize: 16,
        strokeColor: Color(0xFF333333),
      ),
      const RectangleShape(
        id: 'rect',
        start: Offset(0, 0),
        end: Offset(10, 10),
        fillColor: Color(0x2200FF00),
      ),
      const OvalShape(
        id: 'oval',
        startPoint: Offset(1, 1),
        endPoint: Offset(7, 9),
        fillColor: Color(0x220000FF),
      ),
      CircleShape.fromBounds(
        id: 'circle',
        startPoint: const Offset(0, 0),
        endPoint: const Offset(10, 20),
        fillColor: const Color(0x220000FF),
      ),
      SquareShape.fromBounds(
        id: 'square',
        startPoint: const Offset(0, 0),
        endPoint: const Offset(10, 20),
        fillColor: const Color(0x220000FF),
      ),
    ];

    for (final shape in shapes) {
      final clone = shape.clone();

      expect(clone, equals(shape));
      expect(identical(clone, shape), isFalse);
      expect(clone.runtimeType, shape.runtimeType);

      if (shape is PathShape && clone is PathShape) {
        expect(identical(clone.points, shape.points), isFalse);
      }
    }
  });

  test('copyStyle preserves identity fields while updating styles', () {
    final pathShape =
        BrushShape.seed(
              const Offset(0, 0),
              id: 'brush-style',
            ).copyStyle(strokeColor: const Color(0xFFABCDEF), strokeWidth: 4)
            as BrushShape;
    final rectangle =
        const RectangleShape(
              id: 'rect-style',
              start: Offset(0, 0),
              end: Offset(4, 6),
            ).copyStyle(
              fillColor: const Color(0x3300FF00),
              applyFillColor: true,
              strokeColor: const Color(0xFFFF00FF),
              strokeWidth: 6,
            )
            as RectangleShape;

    expect(pathShape.id, 'brush-style');
    expect(pathShape.strokeColor, const Color(0xFFABCDEF));
    expect(pathShape.strokeWidth, 4);

    expect(rectangle.id, 'rect-style');
    expect(rectangle.start, const Offset(0, 0));
    expect(rectangle.end, const Offset(4, 6));
    expect(rectangle.fillColor, const Color(0x3300FF00));
    expect(rectangle.strokeColor, const Color(0xFFFF00FF));
    expect(rectangle.strokeWidth, 6);
  });

  test('EraserShape uses clear blend mode', () {
    const point = Offset(1, 2);

    final shape = EraserShape(points: <Offset>[point]);

    expect(shape.blendMode, BlendMode.clear);
  });

  test('RectangleShape defaults fill to transparent and extends end', () {
    const start = Offset(0, 0);
    const end = Offset(5, 5);
    const next = Offset(7, 9);

    final shape =
        const RectangleShape(start: start, end: end).extendTo(next)
            as RectangleShape;

    expect(shape.start, start);
    expect(shape.end, next);
    expect(shape.fillColor, const Color(0x00000000));
  });

  test('OvalShape derives center and radii from bounds', () {
    const start = Offset(0, 0);
    const end = Offset(10, 20);

    const shape = OvalShape(startPoint: start, endPoint: end);

    expect(shape.center, const Offset(5, 10));
    expect(shape.radiusX, 5);
    expect(shape.radiusY, 10);
  });

  test('CircleShape.fromBounds keeps circle semantics', () {
    const start = Offset(0, 0);
    const end = Offset(10, 20);

    final shape = CircleShape.fromBounds(startPoint: start, endPoint: end);

    expect(shape.center, const Offset(5, 10));
    expect(shape.radius, 5);
    expect(shape.startPoint, const Offset(0, 5));
    expect(shape.endPoint, const Offset(10, 15));
  });

  test('SquareShape.fromBounds keeps square semantics', () {
    const start = Offset(0, 0);
    const end = Offset(10, 20);

    final shape = SquareShape.fromBounds(startPoint: start, endPoint: end);

    expect(shape.center, const Offset(5, 10));
    expect(shape.sideLength, 10);
    expect(shape.startPoint, const Offset(0, 5));
    expect(shape.endPoint, const Offset(10, 15));
  });

  test('ArrowShape.extendTo updates end point', () {
    const start = Offset(1, 1);
    const end = Offset(4, 4);
    const next = Offset(9, 7);

    final shape =
        const ArrowShape(startPoint: start, endPoint: end).extendTo(next)
            as ArrowShape;

    expect(shape.startPoint, start);
    expect(shape.endPoint, next);
  });

  test('TextShape clone and copyStyle preserve text and fontSize', () {
    const start = Offset(2, 3);
    const end = Offset(6, 9);

    const shape = TextShape(
      id: 'text-1',
      startPoint: start,
      endPoint: end,
      text: 'Hi',
      fontSize: 14,
      fillColor: Color(0x2200FF00),
      strokeColor: Color(0xFF112233),
      strokeWidth: 3,
    );

    final clone = shape.clone();
    final styled = shape.copyStyle(
      fillColor: const Color(0x3300FF00),
      applyFillColor: true,
      strokeColor: const Color(0xFF445566),
      strokeWidth: 5,
    );

    expect(clone, equals(shape));
    expect(identical(clone, shape), isFalse);
    expect(clone.text, 'Hi');
    expect(clone.fontSize, 14);

    expect(styled.text, 'Hi');
    expect(styled.fontSize, 14);
    expect(styled.fillColor, const Color(0x3300FF00));
    expect(styled.strokeColor, const Color(0xFF445566));
    expect(styled.strokeWidth, 5);
  });

  test('TextShape equality includes text and fontSize', () {
    const start = Offset(0, 0);
    const end = Offset(5, 5);

    const base = TextShape(
      startPoint: start,
      endPoint: end,
      text: 'A',
      fontSize: 12,
    );
    const differentText = TextShape(
      startPoint: start,
      endPoint: end,
      text: 'B',
      fontSize: 12,
    );
    const differentSize = TextShape(
      startPoint: start,
      endPoint: end,
      text: 'A',
      fontSize: 13,
    );

    expect(base == differentText, isFalse);
    expect(base == differentSize, isFalse);
  });

  // contains() tests for PathShape (BrushShape, EraserShape)
  group('contains() - PathShape', () {
    test('BrushShape single point contains itself within threshold', () {
      const point = Offset(10, 20);
      final shape = BrushShape.seed(point, strokeWidth: 2.0);

      expect(shape.contains(point), isTrue);
    });

    test('BrushShape single point rejects points beyond threshold', () {
      const point = Offset(10, 20);
      const farPoint = Offset(20, 30);
      final shape = BrushShape.seed(point, strokeWidth: 2.0);

      expect(shape.contains(farPoint), isFalse);
    });

    test('BrushShape detects point near first segment', () {
      const p1 = Offset(0, 0);
      const p2 = Offset(10, 0);
      final shape = BrushShape(points: <Offset>[p1, p2], strokeWidth: 2.0);

      expect(shape.contains(const Offset(5, 1)), isTrue);
      expect(shape.contains(const Offset(5, 0)), isTrue);
    });

    test('BrushShape detects point near intermediate segment', () {
      final shape = BrushShape(
        points: <Offset>[
          const Offset(0, 0),
          const Offset(10, 0),
          const Offset(20, 10),
        ],
        strokeWidth: 3.0,
      );

      expect(shape.contains(const Offset(10, 1)), isTrue);
      expect(shape.contains(const Offset(15, 5)), isTrue);
    });

    test('BrushShape rejects points beyond all segments', () {
      final shape = BrushShape(
        points: <Offset>[const Offset(0, 0), const Offset(10, 0)],
        strokeWidth: 1.0,
      );

      expect(shape.contains(const Offset(5, 10)), isFalse);
    });

    test('EraserShape contains() works same as BrushShape', () {
      final shape = EraserShape(
        points: <Offset>[const Offset(0, 0), const Offset(10, 10)],
        strokeWidth: 2.0,
      );

      expect(shape.contains(const Offset(5, 5)), isTrue);
      expect(shape.contains(const Offset(0, 10)), isFalse);
    });
  });

  // contains() tests for LineShape & ArrowShape
  group('contains() - LineShape & ArrowShape', () {
    test('LineShape contains point on the line', () {
      const shape = LineShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 0),
        strokeWidth: 2.0,
      );

      expect(shape.contains(const Offset(5, 0)), isTrue);
    });

    test('LineShape contains point near line within threshold', () {
      const shape = LineShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 0),
        strokeWidth: 4.0,
      );

      expect(shape.contains(const Offset(5, 3)), isTrue);
    });

    test('LineShape rejects point far from line', () {
      const shape = LineShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 0),
        strokeWidth: 2.0,
      );

      expect(shape.contains(const Offset(5, 20)), isFalse);
    });

    test('LineShape threshold includes strokeWidth + 5.0', () {
      const shape = LineShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 0),
        strokeWidth: 2.0,
      );

      // threshold = 2.0 + 5.0 = 7.0
      expect(shape.contains(const Offset(5, 6.5)), isTrue);
      expect(shape.contains(const Offset(5, 7.5)), isFalse);
    });

    test('ArrowShape contains point on the arrow line', () {
      const shape = ArrowShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 10),
        strokeWidth: 2.0,
      );

      expect(shape.contains(const Offset(5, 5)), isTrue);
    });

    test('ArrowShape rejects point outside threshold', () {
      const shape = ArrowShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 10),
        strokeWidth: 1.0,
      );

      expect(shape.contains(const Offset(0, 10)), isFalse);
    });

    test('LineShape contains points beyond endpoints if near segment', () {
      const shape = LineShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 0),
        strokeWidth: 2.0,
      );

      // Points near the endpoints but within threshold still count
      // threshold = 2.0 + 5.0 = 7.0
      // distance from (-1, 1) to (0, 0) = sqrt(2) ≈ 1.41 <= 7.0
      expect(shape.contains(const Offset(-1, 1)), isTrue);
      // distance from (11, 1) to (10, 0) = sqrt(2) ≈ 1.41 <= 7.0
      expect(shape.contains(const Offset(11, 1)), isTrue);
      // But far outside threshold
      expect(shape.contains(const Offset(-10, 5)), isFalse);
    });
  });

  // contains() tests for RectangleShape & SquareShape
  group('contains() - RectangleShape & SquareShape', () {
    test('RectangleShape contains point inside bounds', () {
      const shape = RectangleShape(start: Offset(0, 0), end: Offset(10, 10));

      expect(shape.contains(const Offset(5, 5)), isTrue);
      expect(shape.contains(const Offset(0, 0)), isTrue);
      expect(shape.contains(const Offset(10, 10)), isTrue);
    });

    test('RectangleShape contains point on edge', () {
      const shape = RectangleShape(start: Offset(0, 0), end: Offset(10, 10));

      expect(shape.contains(const Offset(0, 5)), isTrue);
      expect(shape.contains(const Offset(10, 5)), isTrue);
      expect(shape.contains(const Offset(5, 0)), isTrue);
      expect(shape.contains(const Offset(5, 10)), isTrue);
    });

    test('RectangleShape rejects point outside bounds', () {
      const shape = RectangleShape(start: Offset(0, 0), end: Offset(10, 10));

      expect(shape.contains(const Offset(-1, 5)), isFalse);
      expect(shape.contains(const Offset(11, 5)), isFalse);
      expect(shape.contains(const Offset(5, -1)), isFalse);
      expect(shape.contains(const Offset(5, 11)), isFalse);
    });

    test('RectangleShape works with inverted bounds', () {
      const shape = RectangleShape(start: Offset(10, 10), end: Offset(0, 0));

      expect(shape.contains(const Offset(5, 5)), isTrue);
      expect(shape.contains(const Offset(15, 5)), isFalse);
    });

    test('SquareShape contains point inside bounds', () {
      final shape = SquareShape(center: const Offset(5, 5), sideLength: 10);

      expect(shape.contains(const Offset(5, 5)), isTrue);
      expect(shape.contains(const Offset(0, 0)), isTrue);
      expect(shape.contains(const Offset(10, 10)), isTrue);
    });

    test('SquareShape rejects point outside bounds', () {
      final shape = SquareShape(center: const Offset(5, 5), sideLength: 10);

      expect(shape.contains(const Offset(-1, 5)), isFalse);
      expect(shape.contains(const Offset(11, 5)), isFalse);
    });
  });

  // contains() tests for CircleShape
  group('contains() - CircleShape', () {
    test('CircleShape contains point at center', () {
      final shape = CircleShape(center: const Offset(5, 5), radius: 5);

      expect(shape.contains(const Offset(5, 5)), isTrue);
    });

    test('CircleShape contains point on circumference', () {
      final shape = CircleShape(center: const Offset(0, 0), radius: 5);

      expect(shape.contains(const Offset(5, 0)), isTrue);
      expect(shape.contains(const Offset(0, 5)), isTrue);
      expect(shape.contains(const Offset(-5, 0)), isTrue);
      expect(shape.contains(const Offset(0, -5)), isTrue);
    });

    test('CircleShape contains point inside radius', () {
      final shape = CircleShape(center: const Offset(0, 0), radius: 5);

      expect(shape.contains(const Offset(3, 4)), isTrue);
      expect(shape.contains(const Offset(1, 1)), isTrue);
    });

    test('CircleShape rejects point outside radius', () {
      final shape = CircleShape(center: const Offset(0, 0), radius: 5);

      expect(shape.contains(const Offset(6, 0)), isFalse);
      expect(shape.contains(const Offset(5, 5)), isFalse);
      expect(shape.contains(const Offset(10, 10)), isFalse);
    });

    test('CircleShape.fromBounds contains correct points', () {
      final shape = CircleShape.fromBounds(
        startPoint: const Offset(0, 0),
        endPoint: const Offset(10, 10),
      );

      expect(shape.contains(const Offset(5, 5)), isTrue);
      expect(shape.contains(const Offset(5, 0)), isTrue);
      expect(shape.contains(const Offset(10, 5)), isTrue); // On circumference
      expect(
        shape.contains(const Offset(9, 9)),
        isFalse,
      ); // Outside: sqrt(32) ≈ 5.66 > 5
    });
  });

  // contains() tests for OvalShape
  group('contains() - OvalShape', () {
    test('OvalShape contains point at center', () {
      const shape = OvalShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 20),
      );

      expect(shape.contains(const Offset(5, 10)), isTrue);
    });

    test('OvalShape contains point on ellipse boundary', () {
      const shape = OvalShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 20),
      );

      expect(shape.contains(const Offset(5, 0)), isTrue);
      expect(shape.contains(const Offset(5, 20)), isTrue);
      expect(shape.contains(const Offset(0, 10)), isTrue);
      expect(shape.contains(const Offset(10, 10)), isTrue);
    });

    test('OvalShape contains point inside ellipse', () {
      const shape = OvalShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 20),
      );

      expect(shape.contains(const Offset(5, 10)), isTrue);
      expect(shape.contains(const Offset(3, 8)), isTrue);
    });

    test('OvalShape rejects point outside ellipse', () {
      const shape = OvalShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 20),
      );

      expect(shape.contains(const Offset(6, 0)), isFalse);
      expect(shape.contains(const Offset(0, 12)), isFalse);
      expect(shape.contains(const Offset(10, 15)), isFalse);
    });

    test('OvalShape handles zero radiusX', () {
      const shape = OvalShape(
        startPoint: Offset(5, 0),
        endPoint: Offset(5, 20),
      );

      expect(shape.contains(const Offset(5, 10)), isTrue);
      expect(shape.contains(const Offset(5, 0)), isTrue);
      expect(shape.contains(const Offset(4, 10)), isFalse);
    });

    test('OvalShape handles zero radiusY', () {
      const shape = OvalShape(
        startPoint: Offset(0, 5),
        endPoint: Offset(10, 5),
      );

      expect(shape.contains(const Offset(5, 5)), isTrue);
      expect(shape.contains(const Offset(0, 5)), isTrue);
      expect(shape.contains(const Offset(5, 4)), isFalse);
    });

    test('OvalShape handles zero radii (degenerate point)', () {
      const shape = OvalShape(startPoint: Offset(5, 5), endPoint: Offset(5, 5));

      expect(shape.contains(const Offset(5, 5)), isTrue);
      expect(shape.contains(const Offset(5, 6)), isFalse);
    });

    test('OvalShape ellipse equation verification', () {
      const shape = OvalShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 20),
      );

      // Center: (5, 10), radiusX: 5, radiusY: 10
      // For point (5, 10): (0/5)^2 + (0/10)^2 = 0 <= 1 (center, inside)
      expect(shape.contains(const Offset(5, 10)), isTrue);

      // For point (8, 10): (3/5)^2 + (0/10)^2 = 0.36 <= 1 (inside)
      expect(shape.contains(const Offset(8, 10)), isTrue);

      // For point (6, 10): (1/5)^2 + (0/10)^2 = 0.04 <= 1 (inside)
      expect(shape.contains(const Offset(6, 10)), isTrue);

      // For point (10, 10): (5/5)^2 + (0/10)^2 = 1 <= 1 (on boundary)
      expect(shape.contains(const Offset(10, 10)), isTrue);

      // For point (3, 6): (2/5)^2 + (4/10)^2 = 0.16 + 0.16 = 0.32 <= 1 (inside)
      expect(shape.contains(const Offset(3, 6)), isTrue);

      // For point (6, 6): (1/5)^2 + (4/10)^2 = 0.04 + 0.16 = 0.20 <= 1 (inside)
      expect(shape.contains(const Offset(6, 6)), isTrue);

      // For point (8, 6): (3/5)^2 + (4/10)^2 = 0.36 + 0.16 = 0.52 <= 1 (inside)
      expect(shape.contains(const Offset(8, 6)), isTrue);

      // For point (9, 6): (4/5)^2 + (4/10)^2 = 0.64 + 0.16 = 0.80 <= 1 (inside)
      expect(shape.contains(const Offset(9, 6)), isTrue);

      // For point (10, 6): (5/5)^2 + (4/10)^2 = 1 + 0.16 = 1.16 > 1 (outside)
      expect(shape.contains(const Offset(10, 6)), isFalse);
    });
  });

  // contains() tests for TextShape
  group('contains() - TextShape', () {
    test('TextShape contains point inside bounding box', () {
      const shape = TextShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 10),
        text: 'Hello',
        fontSize: 16,
      );

      expect(shape.contains(const Offset(5, 5)), isTrue);
      expect(shape.contains(const Offset(0, 0)), isTrue);
      expect(shape.contains(const Offset(10, 10)), isTrue);
    });

    test('TextShape rejects point outside bounding box', () {
      const shape = TextShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 10),
        text: 'Hello',
        fontSize: 16,
      );

      expect(shape.contains(const Offset(-1, 5)), isFalse);
      expect(shape.contains(const Offset(11, 5)), isFalse);
      expect(shape.contains(const Offset(5, -1)), isFalse);
      expect(shape.contains(const Offset(5, 11)), isFalse);
    });

    test('TextShape handles inverted bounds', () {
      const shape = TextShape(
        startPoint: Offset(10, 10),
        endPoint: Offset(0, 0),
        text: 'Hello',
        fontSize: 16,
      );

      expect(shape.contains(const Offset(5, 5)), isTrue);
      expect(shape.contains(const Offset(15, 5)), isFalse);
    });

    test('TextShape contains point on edge', () {
      const shape = TextShape(
        startPoint: Offset(0, 0),
        endPoint: Offset(10, 10),
        text: 'A',
        fontSize: 12,
      );

      expect(shape.contains(const Offset(0, 5)), isTrue);
      expect(shape.contains(const Offset(10, 5)), isTrue);
      expect(shape.contains(const Offset(5, 0)), isTrue);
      expect(shape.contains(const Offset(5, 10)), isTrue);
    });
  });
}
