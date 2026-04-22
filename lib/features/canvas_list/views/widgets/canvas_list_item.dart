import 'package:bif_simple_paint/features/canvas_list/models/canvas_metadata.dart';
import 'package:flutter/material.dart';

class CanvasListItem extends StatelessWidget {
  const CanvasListItem({super.key, required this.metadata, this.onTap});

  final CanvasMetadata metadata;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(metadata.title),
      subtitle: Text(metadata.thumbnailPath),
      onTap: onTap,
    );
  }
}
