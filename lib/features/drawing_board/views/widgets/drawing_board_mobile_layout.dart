import 'dart:typed_data';
import 'dart:ui';

import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/canvas_title_field.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_tool_button.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/eraser_tool_icon.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/interactive_canvas.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/stroke_width_preview.dart';
import 'package:gal/gal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Duration _animationDuration = Duration(milliseconds: 180);
typedef CaptureImageCallback = Future<Uint8List?> Function({bool asJpeg});

enum _ExportFormat { png, jpeg }

class MobileLayout extends ConsumerStatefulWidget {
  const MobileLayout({super.key});

  @override
  ConsumerState<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<MobileLayout> {
  final GlobalKey<CanvasCapture> _canvasExportKey = GlobalKey<CanvasCapture>();
  final StrokeWidthPreviewController _strokePreviewController =
      StrokeWidthPreviewController();

  @override
  void dispose() {
    _strokePreviewController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureImage({bool asJpeg = false}) async {
    final state = _canvasExportKey.currentState;
    return state?.captureImage(asJpeg: asJpeg);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final ToolSelectionState toolSelection = ref.watch(
      toolSelectionNotifierProvider,
    );
    final bool isSelectionMode = toolSelection.toolType == ToolType.cursor;
    final Color background = colors.backgroundCanvas;

    return Container(
      color: background,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: MobileCanvasArea(
                canvasKey: _canvasExportKey,
                onViewportScaleChanged:
                    _strokePreviewController.setViewportScale,
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: MobileTopBar(onCaptureImage: _captureImage),
            ),
            StrokeWidthPreviewOverlay(controller: _strokePreviewController),
            const Positioned(right: 16, top: 120, child: MobileQuickActions()),
            AnimatedPositioned(
              duration: _animationDuration,
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: isSelectionMode ? 8 : 16,
              child: MobileFloatingToolbars(
                isSelectionMode: isSelectionMode,
                strokePreviewController: _strokePreviewController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileTopBar extends ConsumerWidget {
  const MobileTopBar({super.key, required this.onCaptureImage});

  final CaptureImageCallback onCaptureImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.surfaceFloating;
    final Color border = colors.borderSubtle;
    final Color textColor = colors.textPrimary;
    final Color iconColor = colors.iconPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back, color: iconColor, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CanvasTitleField(
              decoration: const InputDecoration.collapsed(hintText: 'Untitled'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: textColor),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showExportSheet(context),
            icon: Icon(Icons.save_alt, color: iconColor, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Export',
          ),
        ],
      ),
    );
  }

  Future<void> _showExportSheet(BuildContext context) async {
    final selection = await showModalBottomSheet<_ExportFormat>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Save as PNG'),
              onTap: () => Navigator.of(sheetContext).pop(_ExportFormat.png),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Save as JPEG'),
              onTap: () => Navigator.of(sheetContext).pop(_ExportFormat.jpeg),
            ),
          ],
        );
      },
    );

    if (selection == null) {
      return;
    }

    final bytes = await onCaptureImage(asJpeg: selection == _ExportFormat.jpeg);
    if (!context.mounted) {
      return;
    }

    if (bytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export failed.')));
      return;
    }

    await Gal.putImageBytes(bytes);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved to gallery!')));
  }
}

class MobileCanvasArea extends StatelessWidget {
  const MobileCanvasArea({
    super.key,
    required this.canvasKey,
    this.onViewportScaleChanged,
  });

  final GlobalKey<CanvasCapture> canvasKey;
  final ValueChanged<double>? onViewportScaleChanged;

  @override
  Widget build(BuildContext context) {
    return InteractiveCanvas(
      key: canvasKey,
      onViewportScaleChanged: onViewportScaleChanged,
    );
  }
}

class MobileQuickActions extends StatelessWidget {
  const MobileQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.surfaceFloating;
    final Color border = colors.borderSubtle;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: const Column(
        children: <Widget>[
          ToolButton(icon: Icons.layers, isActive: true),
          SizedBox(height: 8),
          ToolButton(icon: Icons.zoom_in),
        ],
      ),
    );
  }
}

class MobileFloatingToolbars extends ConsumerStatefulWidget {
  const MobileFloatingToolbars({
    super.key,
    required this.isSelectionMode,
    required this.strokePreviewController,
  });

  final bool isSelectionMode;
  final StrokeWidthPreviewController strokePreviewController;

  @override
  ConsumerState<MobileFloatingToolbars> createState() =>
      _MobileFloatingToolbarsState();
}

class _MobileFloatingToolbarsState
    extends ConsumerState<MobileFloatingToolbars> {
  bool _isStylePanelExpanded = true;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final ToolSelectionState toolSelection = ref.watch(
      toolSelectionNotifierProvider,
    );
    final ToolSelectionNotifier toolSelectionNotifier = ref.read(
      toolSelectionNotifierProvider.notifier,
    );
    final DrawingBoardNotifier drawingBoardNotifier = ref.read(
      drawingBoardNotifierProvider.notifier,
    );
    final bool isCursor = toolSelection.toolType == ToolType.cursor;
    final List<Color> paletteColors = <Color>[
      colors.paletteBlue,
      colors.paletteInk,
      colors.paletteRed,
      colors.paletteGreen,
      colors.paletteAmber,
    ];
    final List<Color> fillColors = <Color>[
      AppColors.drawingFillTransparent,
      colors.paletteBlue,
      colors.paletteInk,
      colors.paletteRed,
      colors.paletteGreen,
    ];
    final int selectedColorIndex = _indexForColor(
      paletteColors,
      toolSelection.currentStrokeColor,
    );
    final int selectedFillIndex = _indexForColor(
      fillColors,
      toolSelection.currentFillColor,
    );
    final int selectedShapeIndex = _indexForShapeType(toolSelection.shapeType);
    final double strokeWidth = toolSelection.currentStrokeWidth;
    final double maxStrokeWidth = maxStrokeWidthForTool(toolSelection.toolType);
    final int strokeDivisions =
        ((maxStrokeWidth - kMinStrokeWidth) / kStrokeWidthStep).round();
    final double clampedStrokeWidth = strokeWidth
        .clamp(kMinStrokeWidth, maxStrokeWidth)
        .toDouble();
    final bool showStylePanel =
        !widget.isSelectionMode && _isStylePanelExpanded;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSwitcher(
              duration: _animationDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: showStylePanel
                  ? _FrostedPill(
                      key: const ValueKey<String>('stroke-panel'),
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                'STYLE',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.textSecondary,
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isStylePanelExpanded = false;
                                  });
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: colors.iconPrimary,
                                  size: 18,
                                ),
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 28,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: 'Hide colors',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Slider(
                            value: clampedStrokeWidth,
                            min: kMinStrokeWidth,
                            max: maxStrokeWidth,
                            divisions: strokeDivisions,
                            onChangeStart: (double value) {
                              widget.strokePreviewController.show(value);
                            },
                            onChangeEnd: (_) {
                              widget.strokePreviewController.hide();
                            },
                            onChanged: (double value) {
                              toolSelectionNotifier.updateStrokeWidth(value);
                              widget.strokePreviewController.show(value);
                              if (isCursor) {
                                drawingBoardNotifier.updateSelectedShapeStyle(
                                  strokeWidth: value,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _MobileColorSection(
                                  title: 'Stroke',
                                  colors: colors,
                                  swatches: paletteColors,
                                  selectedIndex: selectedColorIndex,
                                  onSelected: (int index) {
                                    final Color color = paletteColors[index];
                                    toolSelectionNotifier.updateStrokeColor(
                                      color,
                                    );
                                    if (isCursor) {
                                      drawingBoardNotifier
                                          .updateSelectedShapeStyle(
                                            strokeColor: color,
                                          );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MobileColorSection(
                                  title: 'Fill',
                                  colors: colors,
                                  swatches: fillColors,
                                  selectedIndex: selectedFillIndex,
                                  showTransparent: true,
                                  onSelected: (int index) {
                                    final Color color = fillColors[index];
                                    toolSelectionNotifier.updateFillColor(
                                      color,
                                    );
                                    if (isCursor) {
                                      drawingBoardNotifier
                                          .updateSelectedShapeStyle(
                                            fillColor: color,
                                            updateFillColor: true,
                                          );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            AnimatedOpacity(
              duration: _animationDuration,
              opacity: showStylePanel ? 1 : 0,
              child: const SizedBox(height: 10),
            ),
            _FrostedPill(
              colors: colors,
              child: Row(
                children: <Widget>[
                  _ToolChip(
                    icon: Icon(
                      Icons.back_hand_outlined,
                      color: toolSelection.toolType == ToolType.cursor
                          ? colors.backgroundPrimary
                          : colors.iconPrimary,
                      size: 20,
                    ),
                    isSelected: toolSelection.toolType == ToolType.cursor,
                    colors: colors,
                    onTap: () {
                      toolSelectionNotifier.selectTool(ToolType.cursor);
                    },
                  ),
                  const SizedBox(width: 8),
                  _ToolChip(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: toolSelection.toolType == ToolType.brush
                          ? colors.backgroundPrimary
                          : colors.iconPrimary,
                      size: 20,
                    ),
                    isSelected: toolSelection.toolType == ToolType.brush,
                    colors: colors,
                    onTap: () {
                      toolSelectionNotifier.selectTool(ToolType.brush);
                    },
                  ),
                  const SizedBox(width: 8),
                  _ToolChip(
                    icon: EraserToolIcon(
                      color: toolSelection.toolType == ToolType.eraser
                          ? colors.backgroundPrimary
                          : colors.iconPrimary,
                    ),
                    isSelected: toolSelection.toolType == ToolType.eraser,
                    colors: colors,
                    onTap: () {
                      toolSelectionNotifier.selectTool(ToolType.eraser);
                    },
                  ),
                  const SizedBox(width: 8),
                  _ShapeMenu(
                    colors: colors,
                    isSelected: toolSelection.toolType == ToolType.shape,
                    selectedIndex: selectedShapeIndex,
                    onSelected: (int index) {
                      final ShapeType shapeType = _ShapeMenu.shapeTypeForIndex(
                        index,
                      );
                      toolSelectionNotifier.selectShapeType(shapeType);
                      toolSelectionNotifier.selectTool(ToolType.shape);
                    },
                  ),
                  const SizedBox(width: 8),
                  _ToolChip(
                    icon: Icon(
                      _isStylePanelExpanded && !widget.isSelectionMode
                          ? Icons.palette
                          : Icons.palette_outlined,
                      color: _isStylePanelExpanded && !widget.isSelectionMode
                          ? colors.backgroundPrimary
                          : colors.iconPrimary,
                      size: 20,
                    ),
                    isSelected:
                        _isStylePanelExpanded && !widget.isSelectionMode,
                    colors: colors,
                    onTap: () {
                      if (widget.isSelectionMode) {
                        return;
                      }
                      setState(() {
                        _isStylePanelExpanded = !_isStylePanelExpanded;
                      });
                    },
                  ),
                  const Spacer(),
                  Container(
                    width: 1,
                    height: 24,
                    color: colors.borderSubtle,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  _ActionChip(
                    icon: Icons.undo,
                    colors: colors,
                    onTap: drawingBoardNotifier.undo,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.redo,
                    colors: colors,
                    onTap: drawingBoardNotifier.redo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _indexForColor(List<Color> swatches, Color color) {
    final int index = swatches.indexWhere((Color item) {
      return item == color;
    });

    return index == -1 ? 0 : index;
  }

  int _indexForShapeType(ShapeType shapeType) {
    return _ShapeMenu.indexForShapeType(shapeType);
  }
}

class _FrostedPill extends StatelessWidget {
  const _FrostedPill({super.key, required this.colors, required this.child});

  final AppColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceFloating.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MobileColorSection extends StatelessWidget {
  const _MobileColorSection({
    required this.title,
    required this.colors,
    required this.swatches,
    required this.selectedIndex,
    required this.onSelected,
    this.showTransparent = false,
  });

  final String title;
  final AppColors colors;
  final List<Color> swatches;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showTransparent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _ColorDotWrap(
          colors: colors,
          swatches: swatches,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
          showTransparent: showTransparent,
        ),
      ],
    );
  }
}

class _ColorDotWrap extends StatelessWidget {
  const _ColorDotWrap({
    required this.colors,
    required this.swatches,
    required this.selectedIndex,
    required this.onSelected,
    this.showTransparent = false,
  });

  final AppColors colors;
  final List<Color> swatches;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showTransparent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List<Widget>.generate(swatches.length, (int index) {
        final bool isSelected = selectedIndex == index;
        final Color fill = swatches[index];
        final bool isTransparent = fill.a == 0;
        final Color ringColor = isSelected
            ? colors.accentPrimary
            : colors.borderSubtle;

        return Padding(
          padding: EdgeInsets.zero,
          child: AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeOutCubic,
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTransparent ? colors.surfaceSecondary : fill,
              border: Border.all(color: ringColor, width: 2),
            ),
            child: InkWell(
              onTap: () => onSelected(index),
              customBorder: const CircleBorder(),
              child: isTransparent
                  ? Center(
                      child: Transform.translate(
                        offset: const Offset(0, 2),
                        child: Container(
                          height: 2,
                          width: 18,
                          color: colors.error,
                          transform: Matrix4.rotationZ(-0.6),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final Widget icon;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: isSelected ? colors.accentPrimary : colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? colors.accentPrimary : colors.borderSubtle,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(child: icon),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Icon(icon, color: colors.iconPrimary, size: 18),
      ),
    );
  }
}

class _ShapeMenu extends StatelessWidget {
  const _ShapeMenu({
    required this.colors,
    required this.isSelected,
    required this.selectedIndex,
    required this.onSelected,
  });

  final AppColors colors;
  final bool isSelected;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const List<_ShapeOption> _options = <_ShapeOption>[
    _ShapeOption(
      label: 'Rectangle',
      icon: Icons.crop_square,
      shapeType: ShapeType.rectangle,
    ),
    _ShapeOption(
      label: 'Oval',
      icon: Icons.circle_outlined,
      shapeType: ShapeType.oval,
    ),
    _ShapeOption(
      label: 'Line',
      icon: Icons.show_chart,
      shapeType: ShapeType.line,
    ),
    _ShapeOption(
      label: 'Arrow',
      icon: Icons.arrow_right_alt,
      shapeType: ShapeType.arrow,
    ),
    _ShapeOption(
      label: 'Text',
      icon: Icons.text_fields,
      shapeType: ShapeType.text,
    ),
  ];

  static int indexForShapeType(ShapeType shapeType) {
    final int index = _options.indexWhere((option) {
      return option.shapeType == shapeType;
    });

    return index == -1 ? 0 : index;
  }

  static ShapeType shapeTypeForIndex(int index) {
    return _options[index].shapeType;
  }

  @override
  Widget build(BuildContext context) {
    final _ShapeOption selected = _options[selectedIndex];

    return PopupMenuButton<int>(
      tooltip: '',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 48),
      color: colors.surfaceFloating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.borderSubtle),
      ),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return List<PopupMenuEntry<int>>.generate(_options.length, (int index) {
          final _ShapeOption option = _options[index];
          return PopupMenuItem<int>(
            value: index,
            child: Center(
              child: Icon(option.icon, size: 20, color: colors.iconPrimary),
            ),
          );
        });
      },
      child: AbsorbPointer(
        child: _ToolChip(
          icon: Icon(
            selected.icon,
            color: isSelected ? colors.backgroundPrimary : colors.iconPrimary,
            size: 20,
          ),
          isSelected: isSelected,
          colors: colors,
          onTap: () {},
        ),
      ),
    );
  }
}

class _ShapeOption {
  const _ShapeOption({
    required this.label,
    required this.icon,
    required this.shapeType,
  });

  final String label;
  final IconData icon;
  final ShapeType shapeType;
}
