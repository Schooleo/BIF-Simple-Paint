import 'package:bif_simple_paint/features/canvas_list/models/canvas_metadata.dart';
import 'package:flutter/material.dart';

enum _CanvasListAction { rename, export, delete }

class CanvasListItem extends StatelessWidget {
  const CanvasListItem({
    super.key,
    required this.viewData,
    this.onTap,
    this.onRename,
    this.onExport,
    this.onDelete,
  });

  final CanvasListItemData viewData;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailData = viewData.thumbnailBytes;
    final placeholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.brush_outlined),
    );

    return Material(
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 48,
                  child: thumbnailData == null
                      ? placeholder
                      : RepaintBoundary(
                          child: Image.memory(
                            thumbnailData,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            cacheWidth: 96,
                            cacheHeight: 96,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (context, error, stackTrace) =>
                                placeholder,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      viewData.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      viewData.editedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      viewData.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRename != null ||
                  onExport != null ||
                  onDelete != null) ...<Widget>[
                const SizedBox(width: 8),
                PopupMenuButton<_CanvasListAction>(
                  tooltip: 'Canvas actions',
                  onSelected: (action) {
                    switch (action) {
                      case _CanvasListAction.rename:
                        onRename?.call();
                        break;
                      case _CanvasListAction.export:
                        onExport?.call();
                        break;
                      case _CanvasListAction.delete:
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    return <PopupMenuEntry<_CanvasListAction>>[
                      if (onRename != null)
                        const PopupMenuItem<_CanvasListAction>(
                          value: _CanvasListAction.rename,
                          child: Text('Rename'),
                        ),
                      if (onExport != null)
                        const PopupMenuItem<_CanvasListAction>(
                          value: _CanvasListAction.export,
                          child: Text('Export'),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem<_CanvasListAction>(
                          value: _CanvasListAction.delete,
                          child: Text('Delete'),
                        ),
                    ];
                  },
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
