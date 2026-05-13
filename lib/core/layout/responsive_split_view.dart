import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../theme/app_colors.dart';

const double _desktopBreakpoint = 800;

class ResponsiveSplitView extends StatefulWidget {
  const ResponsiveSplitView({
    super.key,
    required this.mobile,
    required this.sidebar,
    required this.content,
    this.desktopBreakpoint = _desktopBreakpoint,
    this.sidebarWidth = 280,
    this.sidebarCollapsedWidth = 64,
  });

  final Widget mobile;
  final Widget sidebar;
  final Widget content;
  final double desktopBreakpoint;
  final double sidebarWidth;
  final double sidebarCollapsedWidth;

  @override
  State<ResponsiveSplitView> createState() => _ResponsiveSplitViewState();
}

class _ResponsiveSplitViewState extends State<ResponsiveSplitView> {
  static const Duration _animationDuration = Duration(milliseconds: 220);

  bool _isCollapsed = false;

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;

    if (screenWidth < widget.desktopBreakpoint) {
      return widget.mobile;
    }

    final AppColors colors =
        Theme.of(context).extension<AppColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double targetSidebarWidth = _isCollapsed
            ? widget.sidebarCollapsedWidth
            : widget.sidebarWidth;
        final double safeSidebarWidth = math.min(targetSidebarWidth, maxWidth);

        return Row(
          children: <Widget>[
            AnimatedContainer(
              duration: _animationDuration,
              curve: Curves.easeOutCubic,
              width: safeSidebarWidth,
              decoration: BoxDecoration(
                color: colors.backgroundSidebar,
                border: Border(right: BorderSide(color: colors.borderSubtle)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _SidebarHeader(
                    isCollapsed: _isCollapsed,
                    colors: colors,
                    onToggle: _toggleSidebar,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: _animationDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _isCollapsed
                          ? const SizedBox.shrink()
                          : widget.sidebar,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: _animationDuration,
                curve: Curves.easeOutCubic,
                child: ClipRect(child: widget.content),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.isCollapsed,
    required this.colors,
    required this.onToggle,
  });

  final bool isCollapsed;
  final AppColors colors;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final IconData icon = isCollapsed
        ? Icons.chevron_right
        : Icons.chevron_left;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Tooltip(
          message: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
          child: Material(
            color: colors.surfaceFloating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: colors.borderSubtle),
            ),
            elevation: 8,
            shadowColor: colors.shadowColor,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 32,
                width: 32,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Icon(
                      icon,
                      key: ValueKey<IconData>(icon),
                      size: 18,
                      color: colors.iconPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
