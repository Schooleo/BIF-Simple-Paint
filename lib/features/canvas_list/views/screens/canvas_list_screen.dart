import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/core/theme/app_colors_dark.dart';
import 'package:flutter/material.dart';

class CanvasListScreen extends StatelessWidget {
  const CanvasListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark
        ? AppColorsDark.background
        : AppColors.background;
    final Color titleColor = isDark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Canvas List',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: titleColor),
              ),
              const SizedBox(height: 12),
              const _CanvasSearchField(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: const <Widget>[
                    _FileCard(
                      fileName: 'Diagram_01.bif',
                      updatedLabel: 'Edited 2 hrs ago',
                    ),
                    SizedBox(height: 12),
                    _FileCard(
                      fileName: 'App_Wireframe.bif',
                      updatedLabel: 'Edited yesterday',
                    ),
                    SizedBox(height: 12),
                    _FileCard(
                      fileName: 'Untitled_Artwork.bif',
                      updatedLabel: 'Edited last week',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CanvasSearchField extends StatelessWidget {
  const _CanvasSearchField();

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

class _FileCard extends StatelessWidget {
  const _FileCard({required this.fileName, required this.updatedLabel});

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
