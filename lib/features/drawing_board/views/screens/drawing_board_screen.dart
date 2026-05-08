import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_mobile_layout.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_tool_button.dart';
import 'package:flutter/material.dart';

class DrawingBoardScreen extends StatelessWidget {
  const DrawingBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;

    if (screenWidth < _desktopBreakpoint) {
      return const Scaffold(body: MobileLayout());
    }

    return const Scaffold(body: DesktopLayout());
  }
}

const double _desktopBreakpoint = 800;

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
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.backgroundSidebar;

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
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color titleColor = colors.textPrimary;
    final Color iconColor = colors.iconPrimary;

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
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.surfaceSecondary;
    final Color border = colors.borderSubtle;
    final Color iconColor = colors.iconPrimary;
    final Color hintColor = colors.textMuted;
    final Color textColor = colors.textPrimary;

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
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.surfacePrimary;
    final Color border = colors.borderSubtle;
    final Color titleColor = colors.textPrimary;
    final Color subtitleColor = colors.textMuted;

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
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.backgroundCanvas;
    final Color textColor = colors.textMuted;

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
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.surfaceFloating;
    final Color border = colors.borderSubtle;

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
