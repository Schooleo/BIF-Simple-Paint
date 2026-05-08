import 'dart:ui';

import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_tool_button.dart';
import 'package:flutter/material.dart';

const Duration _animationDuration = Duration(milliseconds: 180);

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  bool _isSelectionMode = false;

  void _toggleMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
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
              bottom: _isSelectionMode ? 8 : 16,
              child: MobileFloatingToolbars(
                isSelectionMode: _isSelectionMode,
                onToggleMode: _toggleMode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileTopBar extends StatelessWidget {
  const MobileTopBar({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              'Untitled',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: textColor),
            ),
          ),
          Icon(Icons.undo, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Icon(Icons.redo, color: iconColor, size: 18),
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
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color textColor = colors.textMuted;

    return Center(
      child: Text(
        'Canvas Area',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: textColor),
      ),
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

class MobileFloatingToolbars extends StatefulWidget {
  const MobileFloatingToolbars({
    super.key,
    required this.isSelectionMode,
    required this.onToggleMode,
  });

  final bool isSelectionMode;
  final VoidCallback onToggleMode;

  @override
  State<MobileFloatingToolbars> createState() => _MobileFloatingToolbarsState();
}

class _MobileFloatingToolbarsState extends State<MobileFloatingToolbars> {
  int _selectedColorIndex = 0;
  int _selectedToolIndex = 1;
  int _selectedShapeIndex = 0;
  double _strokeWidth = 2;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final List<Color> paletteColors = <Color>[
      colors.paletteBlue,
      colors.paletteInk,
      colors.paletteRed,
      colors.paletteGreen,
      colors.paletteAmber,
    ];

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
                                '${_strokeWidth.round()}px',
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
                            value: _strokeWidth,
                            min: 1,
                            max: 12,
                            onChanged: (double value) {
                              setState(() {
                                _strokeWidth = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _ColorDotRow(
                            colors: colors,
                            swatches: paletteColors,
                            selectedIndex: _selectedColorIndex,
                            onSelected: (int index) {
                              setState(() {
                                _selectedColorIndex = index;
                              });
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
                    isSelected: _selectedToolIndex == 0,
                    colors: colors,
                    onTap: () {
                      setState(() {
                        _selectedToolIndex = 0;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _ToolChip(
                    icon: Icons.edit_outlined,
                    isSelected: _selectedToolIndex == 1,
                    colors: colors,
                    onTap: () {
                      setState(() {
                        _selectedToolIndex = 1;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _ToolChip(
                    icon: Icons.remove,
                    isSelected: _selectedToolIndex == 2,
                    colors: colors,
                    onTap: () {
                      setState(() {
                        _selectedToolIndex = 2;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _ShapeMenu(
                    colors: colors,
                    selectedIndex: _selectedShapeIndex,
                    onSelected: (int index) {
                      setState(() {
                        _selectedShapeIndex = index;
                        _selectedToolIndex = -1;
                      });
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
                  _ActionChip(icon: Icons.undo, colors: colors, onTap: () {}),
                  const SizedBox(width: 8),
                  _ActionChip(icon: Icons.redo, colors: colors, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    required this.selectedIndex,
    required this.onSelected,
  });

  final AppColors colors;
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
          isSelected: false,
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
