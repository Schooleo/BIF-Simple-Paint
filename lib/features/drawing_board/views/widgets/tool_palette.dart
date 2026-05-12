import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/models/shape/shapes.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/eraser_tool_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ToolPalette extends ConsumerStatefulWidget {
  const ToolPalette({
    super.key,
    this.onSave,
    this.onLoad,
    this.onExport,
    this.onStrokePreviewChanged,
  });

  final VoidCallback? onSave;
  final VoidCallback? onLoad;
  final VoidCallback? onExport;
  final ValueChanged<double?>? onStrokePreviewChanged;

  @override
  ConsumerState<ToolPalette> createState() => ToolPaletteState();
}

const Duration _hoverDuration = Duration(milliseconds: 160);
const Duration _selectDuration = Duration(milliseconds: 200);

class ToolPaletteState extends ConsumerState<ToolPalette> {
  static const List<ToolType> _toolTypes = <ToolType>[
    ToolType.cursor,
    ToolType.brush,
    ToolType.eraser,
  ];

  static const List<_ShapeOption> _shapeOptions = <_ShapeOption>[
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

  int? _hoveredStrokeIndex;
  int? _hoveredFillIndex;
  int? _hoveredToolIndex;
  int? _hoveredFileIndex;
  int? _keyboardShapeIndex;
  bool _isShapeHovered = false;
  bool _isShapeMenuOpen = false;

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
    final DrawingBoardState drawingState = ref.watch(
      drawingBoardNotifierProvider,
    );
    final bool isCursor = toolSelection.toolType == ToolType.cursor;
    final List<Color> strokeColors = <Color>[
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
    final int selectedStrokeIndex = _indexForColor(
      strokeColors,
      toolSelection.currentStrokeColor,
    );
    final int selectedFillIndex = _indexForColor(
      fillColors,
      toolSelection.currentFillColor,
    );
    final int selectedShapeIndex = _indexForShapeType(toolSelection.shapeType);
    final int selectedToolIndex = _toolTypes.indexOf(toolSelection.toolType);
    final bool isShapeSelected = toolSelection.toolType == ToolType.shape;
    final bool isEraserSelection =
        toolSelection.toolType == ToolType.eraser ||
        (toolSelection.toolType == ToolType.cursor &&
            drawingState.selectedShape is EraserShape);
    final ToolType widthTool = isEraserSelection
        ? ToolType.eraser
        : toolSelection.toolType;
    final double strokeWidth = strokeWidthForTool(toolSelection, widthTool);
    final double maxStrokeWidth = maxStrokeWidthForTool(widthTool);
    final int strokeDivisions =
        ((maxStrokeWidth - kMinStrokeWidth) / kStrokeWidthStep).round();
    final double clampedStrokeWidth = strokeWidth
        .clamp(kMinStrokeWidth, maxStrokeWidth)
        .toDouble();
    final List<_FileAction> otherActions = <_FileAction>[
      _FileAction(
        label: 'Undo',
        icon: Icons.undo,
        onTap: drawingState.canUndo ? drawingBoardNotifier.undo : null,
      ),
      _FileAction(
        label: 'Redo',
        icon: Icons.redo,
        onTap: drawingState.canRedo ? drawingBoardNotifier.redo : null,
      ),
      _FileAction(
        label: 'Export',
        icon: Icons.ios_share,
        onTap: widget.onExport,
      ),
    ];

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Material(
          color: colors.surfaceFloating,
          elevation: 16,
          shadowColor: colors.shadowColor,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SectionTitle(title: 'STROKE WIDTH', colors: colors),
                const SizedBox(height: 8),
                Tooltip(
                  message: 'Stroke width',
                  child: Slider(
                    value: clampedStrokeWidth,
                    min: kMinStrokeWidth,
                    max: maxStrokeWidth,
                    divisions: strokeDivisions,
                    onChangeStart: _handleStrokePreviewStart,
                    onChangeEnd: _handleStrokePreviewEnd,
                    onChanged: (double value) {
                      toolSelectionNotifier.updateStrokeWidthForTool(
                        widthTool,
                        value,
                      );
                      widget.onStrokePreviewChanged?.call(value);
                      if (isCursor) {
                        drawingBoardNotifier.updateSelectedShapeStyle(
                          strokeWidth: value,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'STROKE COLOR', colors: colors),
                const SizedBox(height: 10),
                _ColorRow(
                  colors: colors,
                  swatches: strokeColors,
                  selectedIndex: selectedStrokeIndex,
                  hoveredIndex: _hoveredStrokeIndex,
                  onHover: (int? index) {
                    setState(() {
                      _hoveredStrokeIndex = index;
                    });
                  },
                  onSelected: (int index) {
                    final Color color = strokeColors[index];
                    toolSelectionNotifier.updateStrokeColor(color);
                    if (isCursor) {
                      drawingBoardNotifier.updateSelectedShapeStyle(
                        strokeColor: color,
                      );
                    }
                  },
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'FILL COLOR', colors: colors),
                const SizedBox(height: 10),
                _ColorRow(
                  colors: colors,
                  swatches: fillColors,
                  selectedIndex: selectedFillIndex,
                  hoveredIndex: _hoveredFillIndex,
                  showTransparent: true,
                  onHover: (int? index) {
                    setState(() {
                      _hoveredFillIndex = index;
                    });
                  },
                  onSelected: (int index) {
                    final Color color = fillColors[index];
                    toolSelectionNotifier.updateFillColor(color);
                    if (isCursor) {
                      drawingBoardNotifier.updateSelectedShapeStyle(
                        fillColor: color,
                        updateFillColor: true,
                      );
                    }
                  },
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'TOOLS', colors: colors),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    ...List<Widget>.generate(_toolTypes.length, (int index) {
                      final bool isSelected = selectedToolIndex == index;
                      final bool isHovered = _hoveredToolIndex == index;
                      final Color background = isSelected
                          ? colors.accentPrimary
                          : isHovered
                          ? colors.overlayHover
                          : colors.surfaceSecondary;
                      final Color iconColor = isSelected
                          ? colors.backgroundPrimary
                          : colors.iconPrimary;

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Tooltip(
                          message: _toolLabel(_toolTypes[index]),
                          child: MouseRegion(
                            onEnter: (_) {
                              setState(() {
                                _hoveredToolIndex = index;
                              });
                            },
                            onExit: (_) {
                              setState(() {
                                _hoveredToolIndex = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: _selectDuration,
                              curve: Curves.easeOutCubic,
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.accentPrimary
                                      : colors.borderSubtle,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  selectToolShortcut(_toolTypes[index]);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: _toolIcon(
                                    _toolTypes[index],
                                    color: iconColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    _buildShapeMenu(
                      colors,
                      isShapeSelected: isShapeSelected,
                      selectedShapeIndex: selectedShapeIndex,
                      onSelectShape: () {
                        toolSelectionNotifier.selectTool(ToolType.shape);
                      },
                      onSelectShapeType: (ShapeType type) {
                        toolSelectionNotifier.selectShapeType(type);
                      },
                    ),
                  ],
                ),
                if (_isShapeMenuOpen) ...<Widget>[
                  const SizedBox(height: 12),
                  _DesktopShapeMenu(
                    colors: colors,
                    options: _shapeOptions,
                    selectedIndex: _keyboardShapeIndex ?? selectedShapeIndex,
                    onSelected: (int index) {
                      _selectShapeIndex(index);
                    },
                  ),
                ],
                const SizedBox(height: 18),
                _SectionTitle(title: 'OTHER', colors: colors),
                const SizedBox(height: 10),
                Row(
                  children: List<Widget>.generate(otherActions.length, (
                    int index,
                  ) {
                    final _FileAction action = otherActions[index];
                    final bool isEnabled = action.onTap != null;
                    final bool isHovered = _hoveredFileIndex == index;
                    final Color background = isHovered
                        ? colors.overlayHover
                        : colors.surfaceSecondary;
                    final Color iconColor = isEnabled
                        ? colors.iconPrimary
                        : colors.iconPrimary.withValues(alpha: 0.4);

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Tooltip(
                        message: action.label,
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _hoveredFileIndex = index;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _hoveredFileIndex = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: _hoverDuration,
                            curve: Curves.easeOutCubic,
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: InkWell(
                              onTap: action.onTap,
                              borderRadius: BorderRadius.circular(14),
                              child: Center(
                                child: Icon(
                                  action.icon,
                                  color: iconColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void selectToolShortcut(ToolType toolType) {
    ref.read(toolSelectionNotifierProvider.notifier).selectTool(toolType);
    if (_isShapeMenuOpen) {
      setState(() {
        _isShapeMenuOpen = false;
      });
    }
  }

  void openShapeMenuForKeyboard() {
    final toolSelection = ref.read(toolSelectionNotifierProvider);
    ref.read(toolSelectionNotifierProvider.notifier).selectTool(ToolType.shape);
    setState(() {
      _isShapeMenuOpen = true;
      _keyboardShapeIndex = _indexForShapeType(toolSelection.shapeType);
    });
  }

  bool handleShapeMenuShortcut(LogicalKeyboardKey key) {
    if (!_isShapeMenuOpen) {
      return false;
    }

    final currentIndex =
        _keyboardShapeIndex ??
        _indexForShapeType(ref.read(toolSelectionNotifierProvider).shapeType);

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _keyboardShapeIndex =
            (currentIndex - 1 + _shapeOptions.length) % _shapeOptions.length;
      });
      return true;
    }

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _keyboardShapeIndex = (currentIndex + 1) % _shapeOptions.length;
      });
      return true;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      _selectShapeIndex(currentIndex);
      return true;
    }

    if (key == LogicalKeyboardKey.escape) {
      setState(() {
        _isShapeMenuOpen = false;
      });
      return true;
    }

    return false;
  }

  void _handleStrokePreviewStart(double value) {
    widget.onStrokePreviewChanged?.call(value);
  }

  void _handleStrokePreviewEnd(double value) {
    widget.onStrokePreviewChanged?.call(null);
  }

  void _selectShapeIndex(int index) {
    final notifier = ref.read(toolSelectionNotifierProvider.notifier);
    notifier.selectShapeType(_shapeOptions[index].shapeType);
    notifier.selectTool(ToolType.shape);
    setState(() {
      _keyboardShapeIndex = index;
      _isShapeMenuOpen = false;
    });
  }

  Widget _buildShapeMenu(
    AppColors colors, {
    required bool isShapeSelected,
    required int selectedShapeIndex,
    required VoidCallback onSelectShape,
    required ValueChanged<ShapeType> onSelectShapeType,
  }) {
    final bool isSelected = isShapeSelected;
    final Color background = isSelected
        ? colors.accentPrimary
        : _isShapeHovered
        ? colors.overlayHover
        : colors.surfaceSecondary;
    final Color iconColor = isSelected
        ? colors.backgroundPrimary
        : colors.iconPrimary;
    final _ShapeOption selected = _shapeOptions[selectedShapeIndex];

    return Tooltip(
      message: 'Shapes',
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isShapeHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isShapeHovered = false;
          });
        },
        child: AnimatedContainer(
          duration: _selectDuration,
          curve: Curves.easeOutCubic,
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderSubtle,
            ),
          ),
          child: InkWell(
            onTap: () {
              final nextOpen = !_isShapeMenuOpen;
              setState(() {
                _isShapeMenuOpen = nextOpen;
                _keyboardShapeIndex = selectedShapeIndex;
              });
              if (nextOpen) {
                onSelectShapeType(_shapeOptions[selectedShapeIndex].shapeType);
                onSelectShape();
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Icon(selected.icon, color: iconColor, size: 20),
            ),
          ),
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
    final int index = _shapeOptions.indexWhere((option) {
      return option.shapeType == shapeType;
    });

    return index == -1 ? 0 : index;
  }

  Widget _toolIcon(ToolType type, {required Color color}) {
    return switch (type) {
      ToolType.cursor => Icon(Icons.near_me_outlined, color: color, size: 20),
      ToolType.brush => Icon(Icons.edit_outlined, color: color, size: 20),
      ToolType.eraser => EraserToolIcon(color: color),
      ToolType.shape => const SizedBox.shrink(),
    };
  }

  String _toolLabel(ToolType type) {
    return switch (type) {
      ToolType.cursor => 'Select',
      ToolType.brush => 'Brush',
      ToolType.eraser => 'Eraser',
      ToolType.shape => 'Shape',
    };
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.colors});

  final String title;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: colors.textSecondary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DesktopShapeMenu extends StatelessWidget {
  const _DesktopShapeMenu({
    required this.colors,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final AppColors colors;
  final List<_ShapeOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: List<Widget>.generate(options.length, (int index) {
          final option = options[index];
          final isSelected = index == selectedIndex;

          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: _hoverDuration,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accentPrimary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    option.icon,
                    size: 18,
                    color: isSelected
                        ? colors.accentPrimary
                        : colors.iconPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.keyboard_return,
                      size: 16,
                      color: colors.accentPrimary,
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.colors,
    required this.swatches,
    required this.selectedIndex,
    required this.hoveredIndex,
    required this.onHover,
    required this.onSelected,
    this.showTransparent = false,
  });

  final AppColors colors;
  final List<Color> swatches;
  final int selectedIndex;
  final int? hoveredIndex;
  final ValueChanged<int?> onHover;
  final ValueChanged<int> onSelected;
  final bool showTransparent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(swatches.length, (int index) {
        final bool isSelected = selectedIndex == index;
        final bool isHovered = hoveredIndex == index;
        final Color ringColor = isSelected
            ? colors.accentPrimary
            : isHovered
            ? colors.borderStrong
            : colors.borderSubtle;
        final Color fill = swatches[index];
        final bool isTransparent = fill.a == 0 && showTransparent;

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Tooltip(
            message: isTransparent ? 'No fill' : 'Color',
            child: MouseRegion(
              onEnter: (_) => onHover(index),
              onExit: (_) => onHover(null),
              child: AnimatedContainer(
                duration: _hoverDuration,
                curve: Curves.easeOutCubic,
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 2),
                  color: isTransparent ? colors.surfaceSecondary : fill,
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
                              width: 20,
                              color: colors.error,
                              transform: Matrix4.rotationZ(-0.6),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      }),
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

class _FileAction {
  const _FileAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}
