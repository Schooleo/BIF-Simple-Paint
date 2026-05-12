import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ToolPalette extends ConsumerStatefulWidget {
  const ToolPalette({super.key, this.onSave, this.onLoad, this.onExport});

  final VoidCallback? onSave;
  final VoidCallback? onLoad;
  final VoidCallback? onExport;

  @override
  ConsumerState<ToolPalette> createState() => _ToolPaletteState();
}

const Duration _hoverDuration = Duration(milliseconds: 160);
const Duration _selectDuration = Duration(milliseconds: 200);

class _ToolPaletteState extends ConsumerState<ToolPalette> {
  static const List<IconData> _tools = <IconData>[
    Icons.near_me_outlined,
    Icons.edit_outlined,
    Icons.remove,
  ];
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
  bool _isShapeHovered = false;

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
    final double strokeWidth = toolSelection.currentStrokeWidth;
    final List<_FileAction> fileActions = <_FileAction>[
      _FileAction(
        label: 'Save',
        icon: Icons.save_outlined,
        onTap: widget.onSave,
      ),
      _FileAction(label: 'Load', icon: Icons.folder_open, onTap: widget.onLoad),
      _FileAction(
        label: 'Export',
        icon: Icons.ios_share,
        onTap: widget.onExport,
      ),
    ];
    final List<_FileAction> historyActions = <_FileAction>[
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
            width: 280,
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Tooltip(
                        message: 'Stroke width',
                        child: Slider(
                          value: strokeWidth,
                          min: 1,
                          max: 12,
                          onChanged: (double value) {
                            toolSelectionNotifier.updateStrokeWidth(value);
                            if (isCursor) {
                              drawingBoardNotifier.updateSelectedShapeStyle(
                                strokeWidth: value,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${strokeWidth.round()}px',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                    ...List<Widget>.generate(_tools.length, (int index) {
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
                                  toolSelectionNotifier.selectTool(
                                    _toolTypes[index],
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: Icon(
                                    _tools[index],
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
                    _buildShapeMenu(
                      context,
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
                const SizedBox(height: 18),
                _SectionTitle(title: 'FILE', colors: colors),
                const SizedBox(height: 10),
                Row(
                  children: List<Widget>.generate(fileActions.length, (
                    int index,
                  ) {
                    final _FileAction action = fileActions[index];
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
                const SizedBox(height: 12),
                Row(
                  children: List<Widget>.generate(historyActions.length, (
                    int index,
                  ) {
                    final _FileAction action = historyActions[index];
                    final bool isEnabled = action.onTap != null;
                    final Color background = colors.surfaceSecondary;
                    final Color iconColor = isEnabled
                        ? colors.iconPrimary
                        : colors.iconPrimary.withValues(alpha: 0.4);

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Tooltip(
                        message: action.label,
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

  Widget _buildShapeMenu(
    BuildContext context,
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
          child: PopupMenuButton<int>(
            tooltip: '',
            padding: EdgeInsets.zero,
            offset: const Offset(0, 48),
            color: colors.surfaceFloating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.borderSubtle),
            ),
            onSelected: (int index) {
              onSelectShapeType(_shapeOptions[index].shapeType);
              onSelectShape();
            },
            itemBuilder: (BuildContext context) {
              return List<PopupMenuEntry<int>>.generate(_shapeOptions.length, (
                int index,
              ) {
                final _ShapeOption option = _shapeOptions[index];
                return PopupMenuItem<int>(
                  value: index,
                  child: Row(
                    children: <Widget>[
                      Icon(option.icon, size: 18, color: colors.iconPrimary),
                      const SizedBox(width: 8),
                      Text(
                        option.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.textPrimary),
                      ),
                    ],
                  ),
                );
              });
            },
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
                          child: Container(
                            height: 2,
                            width: 20,
                            color: colors.transparent,
                            transform: Matrix4.rotationZ(-0.6),
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
