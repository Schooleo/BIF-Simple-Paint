import 'package:bif_simple_paint/features/canvas_list/models/canvas_metadata.dart';
import 'package:flutter/material.dart';

class CanvasListItem extends StatelessWidget {
  const CanvasListItem({
    super.key,
    required this.viewData,
    this.onTap,
    this.onDelete,
  });

  final CanvasListItemData viewData;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailData = viewData.thumbnailBytes;

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
                      ? ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.brush_outlined),
                        )
                      : RepaintBoundary(
                          child: Image.memory(
                            thumbnailData,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            cacheWidth: 96,
                            cacheHeight: 96,
                            filterQuality: FilterQuality.medium,
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
              if (onDelete != null) ...<Widget>[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
