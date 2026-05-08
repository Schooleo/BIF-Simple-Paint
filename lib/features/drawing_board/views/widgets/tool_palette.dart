import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ToolPalette extends StatefulWidget {
  const ToolPalette({super.key});

  @override
  State<ToolPalette> createState() => _ToolPaletteState();
}

const Duration _hoverDuration = Duration(milliseconds: 160);
const Duration _selectDuration = Duration(milliseconds: 200);

class _ToolPaletteState extends State<ToolPalette> {
  static const List<IconData> _tools = <IconData>[
    Icons.near_me_outlined,
    Icons.edit_outlined,
    Icons.remove,
  ];

  static const List<_ShapeOption> _shapeOptions = <_ShapeOption>[
    _ShapeOption(label: 'Triangle', icon: Icons.change_history),
    _ShapeOption(label: 'Square', icon: Icons.crop_square),
    _ShapeOption(label: 'Circle', icon: Icons.circle_outlined),
  ];

  int _selectedStrokeIndex = 0;
  int _selectedFillIndex = 0;
  int _selectedToolIndex = 0;
  int _selectedShapeIndex = 0;
  int? _hoveredStrokeIndex;
  int? _hoveredFillIndex;
  int? _hoveredToolIndex;
  bool _isShapeHovered = false;
  double _strokeWidth = 2;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
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
                          value: _strokeWidth,
                          min: 1,
                          max: 12,
                          onChanged: (double value) {
                            setState(() {
                              _strokeWidth = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_strokeWidth.round()}px',
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
                  selectedIndex: _selectedStrokeIndex,
                  hoveredIndex: _hoveredStrokeIndex,
                  onHover: (int? index) {
                    setState(() {
                      _hoveredStrokeIndex = index;
                    });
                  },
                  onSelected: (int index) {
                    setState(() {
                      _selectedStrokeIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'FILL COLOR', colors: colors),
                const SizedBox(height: 10),
                _ColorRow(
                  colors: colors,
                  swatches: fillColors,
                  selectedIndex: _selectedFillIndex,
                  hoveredIndex: _hoveredFillIndex,
                  showTransparent: true,
                  onHover: (int? index) {
                    setState(() {
                      _hoveredFillIndex = index;
                    });
                  },
                  onSelected: (int index) {
                    setState(() {
                      _selectedFillIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'TOOLS', colors: colors),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    ...List<Widget>.generate(_tools.length, (int index) {
                      final bool isSelected = _selectedToolIndex == index;
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
                          message: 'Tool ${index + 1}',
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
                                  setState(() {
                                    _selectedToolIndex = index;
                                  });
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
                    _buildShapeMenu(context, colors),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapeMenu(BuildContext context, AppColors colors) {
    final bool isSelected = _selectedToolIndex == -1;
    final Color background = isSelected
        ? colors.accentPrimary
        : _isShapeHovered
        ? colors.overlayHover
        : colors.surfaceSecondary;
    final Color iconColor = isSelected
        ? colors.backgroundPrimary
        : colors.iconPrimary;
    final _ShapeOption selected = _shapeOptions[_selectedShapeIndex];

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
              setState(() {
                _selectedShapeIndex = index;
                _selectedToolIndex = -1;
              });
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
                            color: colors.error,
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
  const _ShapeOption({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
