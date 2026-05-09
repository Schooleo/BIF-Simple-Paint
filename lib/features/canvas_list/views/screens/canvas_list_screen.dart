import 'package:bif_simple_paint/core/routing/app_router.dart';
import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CanvasListScreen extends StatelessWidget {
  const CanvasListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.backgroundPrimary;
    final Color titleColor = colors.textPrimary;

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
                  children: <Widget>[
                    _FileCard(
                      fileName: 'Diagram_01.bif',
                      updatedLabel: 'Edited 2 hrs ago',
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRouter.drawingBoardPath);
                      },
                    ),
                    const SizedBox(height: 12),
                    _FileCard(
                      fileName: 'App_Wireframe.bif',
                      updatedLabel: 'Edited yesterday',
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRouter.drawingBoardPath);
                      },
                    ),
                    const SizedBox(height: 12),
                    _FileCard(
                      fileName: 'Untitled_Artwork.bif',
                      updatedLabel: 'Edited last week',
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRouter.drawingBoardPath);
                      },
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

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.fileName,
    required this.updatedLabel,
    required this.onTap,
  });

  final String fileName;
  final String updatedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.surfacePrimary;
    final Color border = colors.borderSubtle;
    final Color titleColor = colors.textPrimary;
    final Color subtitleColor = colors.textMuted;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
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
        ),
      ),
    );
  }
}
