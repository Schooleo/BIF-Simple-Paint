import 'dart:io';
import 'dart:typed_data';

import 'package:bif_simple_paint/core/services/database_service.dart';
import 'package:bif_simple_paint/core/services/document_file_service.dart';
import 'package:bif_simple_paint/core/routing/app_router.dart';
import 'package:bif_simple_paint/core/utils/binary_serializer.dart';
import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/core/widgets/app_toast.dart';
import 'package:bif_simple_paint/features/canvas_list/models/canvas_metadata.dart';
import 'package:bif_simple_paint/features/canvas_list/providers/canvas_list_notifier.dart';
import 'package:bif_simple_paint/features/canvas_list/repositories/canvas_list_repository.dart';
import 'package:bif_simple_paint/features/canvas_list/views/widgets/canvas_list_item.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/utils/canvas_exporter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';

class CanvasListScreen extends ConsumerStatefulWidget {
  const CanvasListScreen({super.key});

  @override
  ConsumerState<CanvasListScreen> createState() => _CanvasListScreenState();
}

class _CanvasListScreenState extends ConsumerState<CanvasListScreen> {
  bool _isCanvasLoading = false;
  String _canvasLoadingLabel = 'Loading canvas...';

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
        onPressed: _isCanvasLoading ? null : () => _createCanvas(context),
        tooltip: 'New canvas',
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Canvas List',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: titleColor),
                        ),
                      ),
                      IconButton(
                        onPressed: _isCanvasLoading
                            ? null
                            : () => _loadCanvasFromFile(context),
                        tooltip: 'Load canvas',
                        icon: const Icon(Icons.folder_open),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _CanvasSearchField(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (canvasState.isLoading &&
                            canvasState.canvases.isEmpty) {
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
                                    onTap: _isCanvasLoading
                                        ? null
                                        : () => _openCanvas(context, metadata),
                                    onRename: () =>
                                        _renameCanvas(context, metadata),
                                    onExport: _isCanvasLoading
                                        ? null
                                        : () =>
                                              _exportCanvas(context, metadata),
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
          if (_isCanvasLoading) ...<Widget>[
            const ModalBarrier(dismissible: false, color: Colors.black38),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceFloating,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _canvasLoadingLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: titleColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openCanvas(
    BuildContext context,
    CanvasMetadata metadata,
  ) async {
    await _withCanvasLoading('Loading canvas...', () async {
      final navigator = Navigator.of(context);
      final shouldNavigate = MediaQuery.sizeOf(context).width < 800;
      final repository = ref.read(canvasListRepositoryProvider);
      final documentService = ref.read(documentFileServiceProvider);

      try {
        final documentUri = metadata.documentUri?.trim();
        if (documentUri != null &&
            documentUri.isNotEmpty &&
            await documentService.isSupported()) {
          try {
            final document = await documentService.readDocument(documentUri);
            final documentBytes = document.bytes;
            if (documentBytes == null) {
              throw StateError('Selected document did not return bytes.');
            }

            if (!context.mounted) {
              return;
            }

            final drawingNotifier = ref.read(
              drawingBoardNotifierProvider.notifier,
            );
            final failure = await drawingNotifier.loadFromBytes(documentBytes);
            if (failure != null) {
              if (!context.mounted) {
                return;
              }

              _showToast(context, _loadFailureMessage(metadata.name, failure));
              return;
            }

            drawingNotifier.setCurrentFilePath(
              document.displayName,
              canvasId: metadata.id,
              canvasName: metadata.name,
              currentDocumentUri: document.uri,
            );

            if (!context.mounted) {
              return;
            }

            if (shouldNavigate) {
              navigator.pushNamed(AppRouter.drawingBoardPath);
            }
            return;
          } catch (_) {
            // Fall through to the readable-path / draft fallback below.
          }
        }

        final resolvedPath = await _resolveReadableCanvasPath(metadata);
        if (resolvedPath == null) {
          if (!context.mounted) {
            return;
          }

          _showToast(context, '${metadata.name} file is missing.');
          return;
        }

        final bytes = await repository.loadCanvasBytes(resolvedPath);
        if (!context.mounted) {
          return;
        }

        final drawingNotifier = ref.read(drawingBoardNotifierProvider.notifier);
        final failure = await drawingNotifier.loadFromBytes(bytes);
        if (failure != null) {
          if (!context.mounted) {
            return;
          }

          _showToast(context, _loadFailureMessage(metadata.name, failure));
          return;
        }

        drawingNotifier.setCurrentFilePath(
          resolvedPath,
          canvasId: metadata.id,
          canvasName: metadata.name,
        );

        if (!context.mounted) {
          return;
        }

        if (shouldNavigate) {
          navigator.pushNamed(AppRouter.drawingBoardPath);
        }
      } catch (_) {
        if (!context.mounted) {
          return;
        }

        _showToast(context, 'Unable to open ${metadata.name}.');
      }
    });
  }

  Future<String?> _resolveReadableCanvasPath(CanvasMetadata metadata) async {
    final repository = ref.read(canvasListRepositoryProvider);
    if (await repository.canvasFileExists(metadata.filePath)) {
      return metadata.filePath;
    }

    final draftPath = await ref
        .read(databaseServiceProvider)
        .resolveDraftFilePath(metadata.id);
    if (await repository.canvasFileExists(draftPath)) {
      return draftPath;
    }

    return null;
  }

  Future<void> _createCanvas(BuildContext context) async {
    await _withCanvasLoading('Creating canvas...', () async {
      final navigator = Navigator.of(context);
      final shouldNavigate = MediaQuery.sizeOf(context).width < 800;
      final success = await ref
          .read(drawingBoardNotifierProvider.notifier)
          .createNewCanvas();

      if (!context.mounted) {
        return;
      }

      if (!success) {
        _showToast(context, 'Unable to create a new canvas.');
        return;
      }

      if (shouldNavigate) {
        navigator.pushNamed(AppRouter.drawingBoardPath);
      }
    });
  }

  Future<void> _loadCanvasFromFile(BuildContext context) async {
    await _withCanvasLoading('Loading canvas...', () async {
      final navigator = Navigator.of(context);
      final shouldNavigate = MediaQuery.sizeOf(context).width < 800;
      final drawingNotifier = ref.read(drawingBoardNotifierProvider.notifier);
      final isMobile = Platform.isAndroid || Platform.isIOS;
      if (isMobile &&
          await ref.read(documentFileServiceProvider).isSupported()) {
        try {
          final document = await ref
              .read(documentFileServiceProvider)
              .openDocument();
          if (document == null) {
            return;
          }

          if (!_isMyptFile(document.displayName)) {
            if (!context.mounted) {
              return;
            }

            _showToast(context, 'Please select a .mypt file.');
            return;
          }

          final bytes = document.bytes;
          if (bytes == null) {
            if (!context.mounted) {
              return;
            }

            _showToast(context, 'Unable to read the selected file.');
            return;
          }

          final failure = await drawingNotifier.loadFromBytes(bytes);
          if (failure != null) {
            if (!context.mounted) {
              return;
            }

            _showToast(
              context,
              _loadFailureMessage(document.displayName, failure),
            );
            return;
          }

          drawingNotifier.setCurrentFilePath(
            document.displayName,
            currentDocumentUri: document.uri,
          );

          if (!context.mounted) {
            return;
          }

          if (shouldNavigate) {
            navigator.pushNamed(AppRouter.drawingBoardPath);
          }
          return;
        } catch (_) {
          if (!context.mounted) {
            return;
          }

          _showToast(context, 'Unable to open the selected file.');
          return;
        }
      }

      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          dialogTitle: 'Open canvas',
          type: isMobile ? FileType.any : FileType.custom,
          allowedExtensions: isMobile ? null : const ['mypt'],
          withData: isMobile,
        );
      } catch (_) {
        if (!context.mounted) {
          return;
        }

        _showToast(context, 'Unable to open the selected file.');
        return;
      }
      if (result == null || result.files.isEmpty) {
        return;
      }

      final selected = result.files.first;
      final path = selected.path;
      final name = selected.name.trim();
      final hasPath = path != null && path.trim().isNotEmpty;
      final candidateName = hasPath ? path : name;
      if (candidateName.trim().isEmpty) {
        if (!context.mounted) {
          return;
        }

        _showToast(context, 'Unable to open the selected file.');
        return;
      }

      if (!_isMyptFile(candidateName)) {
        if (!context.mounted) {
          return;
        }

        _showToast(context, 'Please select a .mypt file.');
        return;
      }

      Uint8List? bytes = selected.bytes;
      if (bytes == null && hasPath) {
        final file = File(path);
        if (!await file.exists()) {
          if (!context.mounted) {
            return;
          }

          _showToast(context, 'Selected file no longer exists.');
          return;
        }

        bytes = await file.readAsBytes();
      }

      if (bytes == null) {
        if (!context.mounted) {
          return;
        }

        _showToast(context, 'Unable to read the selected file.');
        return;
      }
      if (!context.mounted) {
        return;
      }

      final failure = await drawingNotifier.loadFromBytes(bytes);
      if (failure != null) {
        if (!context.mounted) {
          return;
        }

        _showToast(
          context,
          _loadFailureMessage(_fileNameFromPath(candidateName), failure),
        );
        return;
      }

      drawingNotifier.setCurrentFilePath(path);

      if (!context.mounted) {
        return;
      }

      if (shouldNavigate) {
        navigator.pushNamed(AppRouter.drawingBoardPath);
      }
    });
  }

  bool _isMyptFile(String value) => value.toLowerCase().endsWith('.mypt');

  Future<void> _exportCanvas(
    BuildContext context,
    CanvasMetadata metadata,
  ) async {
    await _withCanvasLoading('Exporting canvas...', () async {
      final repository = ref.read(canvasListRepositoryProvider);
      final backgroundColor =
          Theme.of(context).extension<AppColors>()?.backgroundCanvas ??
          Colors.white;

      try {
        final exists = await repository.canvasFileExists(metadata.filePath);
        if (!exists) {
          if (!context.mounted) {
            return;
          }

          _showToast(context, '${metadata.name} file is missing.');
          return;
        }

        final canvasBytes = await repository.loadCanvasBytes(metadata.filePath);
        final decoded = await decodeShapes(canvasBytes);
        final pngBytes = await CanvasExporter.export(
          decoded.shapes,
          canvasWidth: decoded.canvasWidth,
          canvasHeight: decoded.canvasHeight,
          backgroundColor: backgroundColor,
        );
        if (!context.mounted) {
          return;
        }

        if (pngBytes == null) {
          _showToast(context, 'Export failed.');
          return;
        }

        if (Platform.isAndroid || Platform.isIOS) {
          await Gal.putImageBytes(pngBytes);
          if (!context.mounted) {
            return;
          }

          _showToast(context, 'Exported ${metadata.name} to gallery.');
          return;
        }

        final targetPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Export canvas',
          fileName: _ensurePngExtension(metadata.name),
          type: FileType.custom,
          allowedExtensions: const ['png'],
        );
        if (targetPath == null) {
          return;
        }

        final resolvedPath = _ensurePngExtension(targetPath);
        final file = File(resolvedPath);
        await file.writeAsBytes(pngBytes, flush: true);
        if (!context.mounted) {
          return;
        }

        _showToast(context, 'Exported ${_fileNameFromPath(resolvedPath)}.');
      } catch (_) {
        if (!context.mounted) {
          return;
        }

        _showToast(context, 'Unable to export ${metadata.name}.');
      }
    });
  }

  Future<void> _withCanvasLoading(
    String label,
    Future<void> Function() action,
  ) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isCanvasLoading = true;
      _canvasLoadingLabel = label;
    });

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isCanvasLoading = false;
        });
      }
    }
  }

  String _ensurePngExtension(String path) {
    final normalized = path.trim();
    if (normalized.toLowerCase().endsWith('.png')) {
      return normalized;
    }
    return '$normalized.png';
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index == -1 || index == normalized.length - 1) {
      return normalized;
    }
    return normalized.substring(index + 1);
  }

  void _showToast(BuildContext context, String message) {
    showAppToast(context, message);
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
      _showToast(context, 'Unable to remove ${metadata.name}.');
      return;
    }

    _showToast(context, '${metadata.name} removed from recent projects.');
  }

  Future<void> _renameCanvas(
    BuildContext context,
    CanvasMetadata metadata,
  ) async {
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
            onFieldSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(draftName),
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
      _showToast(context, 'Unable to rename ${metadata.name}.');
      return;
    }

    final activeCanvasId = ref
        .read(drawingBoardNotifierProvider)
        .currentCanvasId;
    if (activeCanvasId == metadata.id) {
      ref
          .read(drawingBoardNotifierProvider.notifier)
          .updateCanvasTitle(resolvedName);
    }

    _showToast(context, 'Renamed to $resolvedName.');
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
