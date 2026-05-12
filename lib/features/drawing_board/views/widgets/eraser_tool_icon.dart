import 'dart:math' as math;

import 'package:flutter/material.dart';

class EraserToolIcon extends StatelessWidget {
  const EraserToolIcon({super.key, required this.color, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double bodyWidth = size * 0.78;
    final double bodyHeight = size * 0.5;
    final double trimWidth = bodyWidth * 0.34;
    final double handleHeight = size * 0.14;

    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Transform.translate(
          offset: Offset(0, size * 0.08),
          child: Transform.rotate(
            angle: -math.pi / 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: bodyWidth,
                  height: bodyHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.16),
                    border: Border.all(color: color, width: size * 0.09),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: trimWidth,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: color, width: size * 0.09),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: bodyWidth * 0.84,
                  height: handleHeight,
                  margin: EdgeInsets.only(top: size * 0.05),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.06),
                    border: Border.all(color: color, width: size * 0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
