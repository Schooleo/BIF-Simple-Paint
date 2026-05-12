import 'package:bif_simple_paint/core/routing/app_router.dart';
import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/canvas_list/models/canvas_metadata.dart';
import 'package:bif_simple_paint/features/canvas_list/providers/canvas_list_notifier.dart';
import 'package:bif_simple_paint/features/canvas_list/repositories/canvas_list_repository.dart';
import 'package:bif_simple_paint/features/canvas_list/views/widgets/canvas_list_item.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CanvasListScreen extends ConsumerStatefulWidget {
  const CanvasListScreen({super.key});

  @override
  ConsumerState<CanvasListScreen> createState() => _CanvasListScreenState();
}

class _CanvasListScreenState extends ConsumerState<CanvasListScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(canvasListNotifierProvider.notifier).loadCanvases(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.backgroundPrimary;
    final Color titleColor = colors.textPrimary;
    final canvasState = ref.watch(canvasListNotifierProvider);

    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createCanvas(context),
        tooltip: 'New canvas',
        child: const Icon(Icons.add),
      ),
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
                child: Builder(
                  builder: (context) {
                    if (canvasState.isLoading && canvasState.canvases.isEmpty) {
                      return const _CanvasListSkeleton();
                    }

                    final canvases = canvasState.filteredCanvases;
                    if (canvases.isEmpty) {
                      return const _EmptyCanvasState();
                    }

                    final viewDataList = canvases
                        .map((metadata) => metadata.toListItemData())
                        .toList(growable: false);

                    return Stack(
                      children: <Widget>[
                        RefreshIndicator(
                          onRefresh: () => ref
                              .read(canvasListNotifierProvider.notifier)
                              .loadCanvases(),
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: canvases.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final metadata = canvases[index];
                              final viewData = viewDataList[index];
                              return CanvasListItem(
                                key: ValueKey(metadata.id),
                                viewData: viewData,
                                onTap: () => _openCanvas(context, metadata),
                                onRename: () =>
                                    _renameCanvas(context, metadata),
                                onDelete: () =>
                                    _deleteCanvas(context, metadata),
                              );
                            },
                          ),
                        ),
                        if (canvasState.isLoading)
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: LinearProgressIndicator(),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCanvas(
    BuildContext context,
    CanvasMetadata metadata,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final shouldNavigate = MediaQuery.sizeOf(context).width < 800;
    final repository = ref.read(canvasListRepositoryProvider);

    try {
      final exists = await repository.canvasFileExists(metadata.filePath);
      if (!exists) {
        if (!mounted) {
          return;
        }

        messenger.showSnackBar(
          SnackBar(content: Text('${metadata.name} file is missing.')),
        );
        return;
      }

      final bytes = await repository.loadCanvasBytes(metadata.filePath);
      if (!mounted) {
        return;
      }

      final drawingNotifier = ref.read(drawingBoardNotifierProvider.notifier);
      final failure = await drawingNotifier.loadFromBytes(bytes);
      if (failure != null) {
        if (!mounted) {
          return;
        }

        messenger.showSnackBar(
          SnackBar(content: Text(_loadFailureMessage(metadata.name, failure))),
        );
        return;
      }

      drawingNotifier.setCurrentFilePath(
        metadata.filePath,
        canvasId: metadata.id,
        canvasName: metadata.name,
      );

      if (!mounted) {
        return;
      }

      if (shouldNavigate) {
        navigator.pushNamed(AppRouter.drawingBoardPath);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Unable to open ${metadata.name}.')),
      );
    }
  }

  Future<void> _createCanvas(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final shouldNavigate = MediaQuery.sizeOf(context).width < 800;
    final success = await ref
        .read(drawingBoardNotifierProvider.notifier)
        .createNewCanvas();

    if (!mounted) {
      return;
    }

    if (!success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to create a new canvas.')),
      );
      return;
    }

    if (shouldNavigate) {
      navigator.pushNamed(AppRouter.drawingBoardPath);
    }
  }

  String _loadFailureMessage(String canvasName, CanvasLoadFailure failure) {
    switch (failure) {
      case CanvasLoadFailure.unsupportedVersion:
        return 'Unsupported file version for $canvasName.';
      case CanvasLoadFailure.corruptedFile:
        return '$canvasName is corrupted and can\'t be opened.';
    }
  }

  Future<void> _deleteCanvas(
    BuildContext context,
    CanvasMetadata metadata,
  ) async {
    final success = await ref
        .read(canvasListNotifierProvider.notifier)
        .deleteCanvas(metadata.id);
    if (!context.mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to remove ${metadata.name}.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${metadata.name} removed from recent projects.')),
    );
  }

  Future<void> _renameCanvas(
    BuildContext context,
    CanvasMetadata metadata,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    var draftName = metadata.name;
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Canvas'),
          content: TextFormField(
            initialValue: draftName,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Canvas title'),
            onChanged: (value) {
              draftName = value;
            },
            onFieldSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(draftName),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName == null) {
      return;
    }

    final trimmedName = newName.trim();
    final resolvedName = trimmedName.isEmpty ? 'Untitled' : trimmedName;
    final success = await ref
        .read(canvasListNotifierProvider.notifier)
        .renameCanvas(metadata.id, resolvedName);
    if (!context.mounted) {
      return;
    }

    if (!success) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to rename ${metadata.name}.')),
      );
      return;
    }

    final activeCanvasId =
      ref.read(drawingBoardNotifierProvider).currentCanvasId;
    if (activeCanvasId == metadata.id) {
      ref
          .read(drawingBoardNotifierProvider.notifier)
          .updateCanvasTitle(resolvedName);
    }

    messenger.showSnackBar(
      SnackBar(content: Text('Renamed to $resolvedName.')),
    );
  }
}

class _CanvasSearchField extends ConsumerWidget {
  const _CanvasSearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.surfaceSecondary;
    final Color border = colors.borderSubtle;
    final Color iconColor = colors.iconPrimary;
    final Color hintColor = colors.textMuted;
    final Color textColor = colors.textPrimary;
    final canvasState = ref.watch(canvasListNotifierProvider);

    return TextFormField(
      onChanged: ref.read(canvasListNotifierProvider.notifier).setSearchQuery,
      initialValue: canvasState.searchQuery,
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

class _EmptyCanvasState extends StatelessWidget {
  const _EmptyCanvasState();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.collections_bookmark_outlined,
            size: 40,
            color: colors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No saved canvases yet.',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first canvas to see it here.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CanvasListSkeleton extends StatelessWidget {
  const _CanvasListSkeleton();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color surface = colors.surfaceSecondary;
    final Color border = colors.borderSubtle;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: colors.surfaceFloating,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: colors.surfaceFloating,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 140,
                      color: colors.surfaceFloating,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 180,
                      color: colors.surfaceFloating,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
