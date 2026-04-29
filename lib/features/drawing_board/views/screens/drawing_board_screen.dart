import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/core/theme/app_colors_dark.dart';
import 'package:flutter/material.dart';

class DrawingBoardScreen extends StatelessWidget {
  const DrawingBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: DesktopLayout());
  }
}

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Sidebar(),
        Expanded(child: CanvasArea()),
      ],
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark ? AppColorsDark.sidebar : AppColors.sidebar;

    return Container(
      width: 260,
      color: background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          SidebarHeader(),
          SizedBox(height: 16),
          FileCard(
            fileName: 'Diagram_01.bif',
            updatedLabel: 'Edited 2 hrs ago',
          ),
          SizedBox(height: 12),
          FileCard(
            fileName: 'App_Wireframe.bif',
            updatedLabel: 'Edited yesterday',
          ),
          SizedBox(height: 12),
          FileCard(
            fileName: 'Untitled_Artwork.bif',
            updatedLabel: 'Edited last week',
          ),
        ],
      ),
    );
  }
}

class SidebarHeader extends StatelessWidget {
  const SidebarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor = isDark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;
    final Color iconColor = isDark ? AppColorsDark.icon : AppColors.icon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Canvas List',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: titleColor),
            ),
            Icon(Icons.search, size: 18, color: iconColor),
          ],
        ),
        const SizedBox(height: 12),
        const SidebarSearchField(),
      ],
    );
  }
}

class SidebarSearchField extends StatelessWidget {
  const SidebarSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark ? AppColorsDark.surface : AppColors.surface;
    final Color border = isDark ? AppColorsDark.border : AppColors.border;
    final Color iconColor = isDark ? AppColorsDark.icon : AppColors.icon;
    final Color hintColor = isDark
        ? AppColorsDark.textMuted
        : AppColors.textMuted;
    final Color textColor = isDark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;

    return TextField(
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search canvas',
        hintStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: hintColor),
        prefixIcon: Icon(Icons.search, size: 18, color: iconColor),
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
      ),
    );
  }
}

class FileCard extends StatelessWidget {
  const FileCard({
    super.key,
    required this.fileName,
    required this.updatedLabel,
  });

  final String fileName;
  final String updatedLabel;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark ? AppColorsDark.surface : AppColors.surface;
    final Color border = isDark ? AppColorsDark.border : AppColors.border;
    final Color titleColor = isDark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;
    final Color subtitleColor = isDark
        ? AppColorsDark.textMuted
        : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            fileName,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: titleColor),
          ),
          const SizedBox(height: 8),
          Text(
            updatedLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }
}

class CanvasArea extends StatelessWidget {
  const CanvasArea({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark
        ? AppColorsDark.canvas
        : AppColors.background;
    final Color textColor = isDark
        ? AppColorsDark.textMuted
        : AppColors.textMuted;

    return Container(
      color: background,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Drawing Board',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: textColor),
              ),
            ),
          ),
          Center(
            child: Text(
              'Canvas Area',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: textColor),
            ),
          ),
          const Positioned(top: 16, right: 16, child: ToolRail()),
        ],
      ),
    );
  }
}

class ToolRail extends StatelessWidget {
  const ToolRail({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark ? AppColorsDark.surface : AppColors.surface;
    final Color border = isDark ? AppColorsDark.border : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: <Widget>[
          ToolButton(icon: Icons.show_chart, isActive: true),
          SizedBox(height: 8),
          ToolButton(icon: Icons.crop_square),
          SizedBox(height: 8),
          ToolButton(icon: Icons.circle),
        ],
      ),
    );
  }
}

class ToolButton extends StatelessWidget {
  const ToolButton({super.key, required this.icon, this.isActive = false});

  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color border = isDark ? AppColorsDark.border : AppColors.border;
    final Color activeBackground = isDark
        ? AppColorsDark.selectionLight
        : AppColors.selectionLight;
    final Color idleBackground = isDark
        ? AppColorsDark.surface
        : AppColors.surface;
    final Color iconColor = isActive
        ? (isDark ? AppColorsDark.iconActive : AppColors.icon)
        : (isDark ? AppColorsDark.icon : AppColors.iconInactive);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? activeBackground : idleBackground,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}
