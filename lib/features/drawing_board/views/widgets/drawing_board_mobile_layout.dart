import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/core/theme/app_colors_dark.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_tool_button.dart';
import 'package:flutter/material.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark
        ? AppColorsDark.canvas
        : AppColors.background;

    return Container(
      color: background,
      child: SafeArea(
        child: Stack(
          children: const <Widget>[
            Positioned.fill(child: MobileCanvasArea()),
            Positioned(top: 12, left: 16, right: 16, child: MobileTopBar()),
            Positioned(right: 16, top: 120, child: MobileQuickActions()),
            Positioned(
              left: 16,
              right: 16,
              bottom: 96,
              child: MobileBottomBar(),
            ),
            Positioned(left: 16, right: 16, bottom: 20, child: MobileToolBar()),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark ? AppColorsDark.surface : AppColors.surface;
    final Color border = isDark ? AppColorsDark.border : AppColors.border;
    final Color textColor = isDark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;
    final Color iconColor = isDark ? AppColorsDark.icon : AppColors.icon;

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark
        ? AppColorsDark.textMuted
        : AppColors.textMuted;

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark ? AppColorsDark.surface : AppColors.surface;
    final Color border = isDark ? AppColorsDark.border : AppColors.border;

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

class MobileBottomBar extends StatelessWidget {
  const MobileBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark ? AppColorsDark.surface : AppColors.surface;
    final Color border = isDark ? AppColorsDark.border : AppColors.border;
    final Color iconColor = isDark ? AppColorsDark.icon : AppColors.icon;
    final Color textColor = isDark
        ? AppColorsDark.textSecondary
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.menu, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.circle, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'FILL',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: textColor),
          ),
          const SizedBox(width: 6),
          Icon(Icons.circle_outlined, color: iconColor, size: 18),
        ],
      ),
    );
  }
}

class MobileToolBar extends StatelessWidget {
  const MobileToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark ? AppColorsDark.surface : AppColors.surface;
    final Color border = isDark ? AppColorsDark.border : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ToolButton(icon: Icons.pan_tool),
          ToolButton(icon: Icons.edit, isActive: true),
          ToolButton(icon: Icons.show_chart),
          ToolButton(icon: Icons.change_history),
        ],
      ),
    );
  }
}
