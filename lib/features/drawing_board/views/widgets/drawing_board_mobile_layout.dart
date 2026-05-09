import 'dart:ui';

import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/tool_selection_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_tool_button.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/interactive_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Duration _animationDuration = Duration(milliseconds: 180);

class MobileLayout extends ConsumerStatefulWidget {
  const MobileLayout({super.key});

  @override
  ConsumerState<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<MobileLayout> {
  ToolType _lastNonCursorTool = ToolType.brush;

  @override
  void initState() {
    super.initState();
    ref.listen<ToolSelectionState>(toolSelectionNotifierProvider, (
      ToolSelectionState? previous,
      ToolSelectionState next,
    ) {
      if (next.toolType != ToolType.cursor) {
        _lastNonCursorTool = next.toolType;
      }
    });
  }

  void _toggleMode() {
    final ToolSelectionState toolSelection = ref.read(
      toolSelectionNotifierProvider,
    );
    final ToolSelectionNotifier notifier = ref.read(
      toolSelectionNotifierProvider.notifier,
    );

    if (toolSelection.toolType == ToolType.cursor) {
      notifier.selectTool(_lastNonCursorTool);
    } else {
      _lastNonCursorTool = toolSelection.toolType;
      notifier.selectTool(ToolType.cursor);
    }
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
            const Positioned.fill(child: MobileCanvasArea()),
            const Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: MobileTopBar(),
            ),
            const Positioned(right: 16, top: 120, child: MobileQuickActions()),
            AnimatedPositioned(
              duration: _animationDuration,
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: isSelectionMode ? 8 : 16,
              child: MobileFloatingToolbars(
                isSelectionMode: isSelectionMode,
                onToggleMode: _toggleMode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileTopBar extends ConsumerWidget {
  const MobileTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final DrawingBoardState drawingState = ref.watch(
      drawingBoardNotifierProvider,
    );
    final DrawingBoardNotifier drawingBoardNotifier = ref.read(
      drawingBoardNotifierProvider.notifier,
    );
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
            child: Text(
              'Untitled',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: textColor),
            ),
          ),
          IconButton(
            onPressed: drawingState.canUndo
                ? drawingBoardNotifier.undo
                : null,
            icon: Icon(Icons.undo, color: iconColor, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Undo',
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: drawingState.canRedo
                ? drawingBoardNotifier.redo
                : null,
            icon: Icon(Icons.redo, color: iconColor, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Redo',
          ),
          const SizedBox(width: 12),
          Icon(Icons.more_vert, color: iconColor, size: 18),
        ],
      ),
    );
  }
}

class MobileCanvasArea extends StatelessWidget {
  const MobileCanvasArea({super.key});

  @override
  Widget build(BuildContext context) {
    return const InteractiveCanvas();
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
    required this.onToggleMode,
  });

  final bool isSelectionMode;
  final VoidCallback onToggleMode;

  @override
  ConsumerState<MobileFloatingToolbars> createState() =>
      _MobileFloatingToolbarsState();
}

class _MobileFloatingToolbarsState
    extends ConsumerState<MobileFloatingToolbars> {
  int _selectedShapeIndex = 0;

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
    final int selectedColorIndex = _indexForColor(
      paletteColors,
      toolSelection.currentStrokeColor,
    );
    final double strokeWidth = toolSelection.currentStrokeWidth;

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
              child: widget.isSelectionMode
                  ? const SizedBox.shrink()
                  : _FrostedPill(
                      key: const ValueKey<String>('stroke-panel'),
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                'STROKE',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.textSecondary,
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                '${strokeWidth.round()}px',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Slider(
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
                          const SizedBox(height: 10),
                          _ColorDotRow(
                            colors: colors,
                            swatches: paletteColors,
                            selectedIndex: selectedColorIndex,
                            onSelected: (int index) {
                              final Color color = paletteColors[index];
                              toolSelectionNotifier.updateStrokeColor(color);
                              if (isCursor) {
                                drawingBoardNotifier.updateSelectedShapeStyle(
                                  strokeColor: color,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
            ),
            AnimatedOpacity(
              duration: _animationDuration,
              opacity: widget.isSelectionMode ? 0 : 1,
              child: const SizedBox(height: 10),
            ),
            _FrostedPill(
              colors: colors,
              child: Row(
                children: <Widget>[
                  _ToolChip(
                    icon: Icons.near_me_outlined,
                    isSelected: toolSelection.toolType == ToolType.cursor,
                    colors: colors,
                    onTap: () {
                      toolSelectionNotifier.selectTool(ToolType.cursor);
                    },
                  ),
                  const SizedBox(width: 10),
                  _ToolChip(
                    icon: Icons.edit_outlined,
                    isSelected: toolSelection.toolType == ToolType.brush,
                    colors: colors,
                    onTap: () {
                      toolSelectionNotifier.selectTool(ToolType.brush);
                    },
                  ),
                  const SizedBox(width: 10),
                  _ToolChip(
                    icon: Icons.remove,
                    isSelected: toolSelection.toolType == ToolType.eraser,
                    colors: colors,
                    onTap: () {
                      toolSelectionNotifier.selectTool(ToolType.eraser);
                    },
                  ),
                  const SizedBox(width: 10),
                  _ShapeMenu(
                    colors: colors,
                    isSelected: toolSelection.toolType == ToolType.shape,
                    selectedIndex: _selectedShapeIndex,
                    onSelected: (int index) {
                      setState(() {
                        _selectedShapeIndex = index;
                      });
                      toolSelectionNotifier.selectTool(ToolType.shape);
                    },
                  ),
                  const Spacer(),
                  _ToolChip(
                    icon: widget.isSelectionMode
                        ? Icons.select_all
                        : Icons.pan_tool_alt,
                    isSelected: widget.isSelectionMode,
                    colors: colors,
                    onTap: widget.onToggleMode,
                  ),
                  const SizedBox(width: 8),
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
      return item.value == color.value;
    });

    return index == -1 ? 0 : index;
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

class _ColorDotRow extends StatelessWidget {
  const _ColorDotRow({
    required this.colors,
    required this.swatches,
    required this.selectedIndex,
    required this.onSelected,
  });

  final AppColors colors;
  final List<Color> swatches;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(swatches.length, (int index) {
        final bool isSelected = selectedIndex == index;
        final Color fill = swatches[index];
        final bool isTransparent = fill.a == 0;
        final Color ringColor = isSelected
            ? colors.accentPrimary
            : colors.borderSubtle;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
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
                      child: Container(
                        height: 2,
                        width: 18,
                        color: colors.error,
                        transform: Matrix4.rotationZ(-0.6),
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

  final IconData icon;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
      height: 44,
      width: 44,
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
        child: Icon(
          icon,
          color: isSelected ? colors.backgroundPrimary : colors.iconPrimary,
          size: 20,
        ),
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
    _ShapeOption(label: 'Rectangle', icon: Icons.crop_square),
    _ShapeOption(label: 'Circle', icon: Icons.circle_outlined),
    _ShapeOption(label: 'Triangle', icon: Icons.change_history),
  ];

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
          icon: selected.icon,
          isSelected: isSelected,
          colors: colors,
          onTap: () {},
        ),
      ),
    );
  }
}

class _ShapeOption {
  const _ShapeOption({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
