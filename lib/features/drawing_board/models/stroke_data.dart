import 'package:flutter/material.dart';

class StrokeData {
  const StrokeData({
    required this.points,
    required this.color,
    required this.thickness,
  });

  final List<Offset> points;
  final Color color;
  final double thickness;
}
