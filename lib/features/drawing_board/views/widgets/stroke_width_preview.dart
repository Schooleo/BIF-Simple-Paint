import 'dart:async';
import 'dart:math' as math;

import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StrokeWidthPreviewController extends ChangeNotifier {
  double? _strokeWidth;
  double _viewportScale = 1;
  Timer? _hideTimer;

  double? get strokeWidth => _strokeWidth;
  double get viewportScale => _viewportScale;

  bool get isVisible => _strokeWidth != null;

  void show(double strokeWidth) {
    _hideTimer?.cancel();
    _strokeWidth = strokeWidth;
    notifyListeners();
  }

  void setViewportScale(double scale) {
    if (_viewportScale == scale) {
      return;
    }
    _viewportScale = scale;
    if (isVisible) {
      notifyListeners();
    }
  }

  void hide({Duration delay = const Duration(milliseconds: 450)}) {
    _hideTimer?.cancel();
    _hideTimer = Timer(delay, () {
      _strokeWidth = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}

class StrokeWidthPreviewOverlay extends ConsumerWidget {
  const StrokeWidthPreviewOverlay({super.key, required this.controller});

  final StrokeWidthPreviewController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final toolSelection = ref.watch(toolSelectionNotifierProvider);

    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final strokeWidth = controller.strokeWidth;
            final visible = strokeWidth != null;
            final dotDiameter = strokeWidth == null
                ? 0.0
                : strokeWidth * controller.viewportScale;
            final overlayDiameter = math.max(72.0, dotDiameter + 36.0);

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: visible ? 1 : 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 140),
                scale: visible ? 1 : 0.92,
                child: Container(
                  width: overlayDiameter,
                  height: overlayDiameter,
                  decoration: BoxDecoration(
                    color: colors.surfaceFloating.withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.borderSubtle),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.shadowColor,
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      width: dotDiameter,
                      height: dotDiameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: toolSelection.currentStrokeColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
