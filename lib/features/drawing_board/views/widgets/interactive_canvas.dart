import 'package:flutter/material.dart';

class InteractiveCanvas extends StatelessWidget {
  const InteractiveCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: CustomPaint(
        painter: const _EmptyCanvasPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _EmptyCanvasPainter extends CustomPainter {
  const _EmptyCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant _EmptyCanvasPainter oldDelegate) => false;
}
