import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/core/widgets/app_toast.dart';
import 'package:bif_simple_paint/features/drawing_board/models/tool_type.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/canvas_title_field.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_mobile_layout.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/interactive_canvas.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/stroke_width_preview.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/tool_palette.dart';
import 'package:bif_simple_paint/features/drawing_board/utils/canvas_exporter.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return const CanvasArea();
  }
}

class CanvasArea extends ConsumerStatefulWidget {
  const CanvasArea({super.key});

  @override
  ConsumerState<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends ConsumerState<CanvasArea> {
  bool _isTitleEditing = false;
  final GlobalKey<CanvasCapture> _canvasExportKey = GlobalKey<CanvasCapture>();
  final GlobalKey<ToolPaletteState> _toolPaletteKey =
      GlobalKey<ToolPaletteState>();
  final StrokeWidthPreviewController _strokePreviewController =
      StrokeWidthPreviewController();

  @override
  void dispose() {
    _strokePreviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.backgroundCanvas;
    final Color textColor = colors.textMuted;
    final bool allowShortcuts = _shouldHandleGlobalShortcut();

    return Container(
      color: background,
      child: Focus(
        autofocus: true,
        child: CallbackShortcuts(
          bindings: allowShortcuts
              ? <ShortcutActivator, VoidCallback>{
                  const SingleActivator(
                    LogicalKeyboardKey.keyZ,
                    control: true,
                  ): () =>
                      ref.read(drawingBoardNotifierProvider.notifier).undo(),
                  const SingleActivator(
                    LogicalKeyboardKey.keyY,
                    control: true,
                  ): () =>
                      ref.read(drawingBoardNotifierProvider.notifier).redo(),
                  const SingleActivator(
                    LogicalKeyboardKey.keyZ,
                    control: true,
                    shift: true,
                  ): () =>
                      ref.read(drawingBoardNotifierProvider.notifier).redo(),
                  const SingleActivator(
                    LogicalKeyboardKey.keyE,
                    control: true,
                  ): () =>
                      _exportCanvas(context),
                  const SingleActivator(
                    LogicalKeyboardKey.keyO,
                    control: true,
                  ): () =>
                      _loadCanvas(context),
                  const SingleActivator(LogicalKeyboardKey.keyQ): () =>
                      _toolPaletteKey.currentState?.selectToolShortcut(
                        ToolType.cursor,
                      ),
                  const SingleActivator(LogicalKeyboardKey.keyW): () =>
                      _toolPaletteKey.currentState?.selectToolShortcut(
                        ToolType.brush,
                      ),
                  const SingleActivator(LogicalKeyboardKey.keyE): () =>
                      _toolPaletteKey.currentState?.selectToolShortcut(
                        ToolType.eraser,
                      ),
                  const SingleActivator(LogicalKeyboardKey.keyR): () =>
                      _toolPaletteKey.currentState?.openShapeMenuForKeyboard(),
                  const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                      _toolPaletteKey.currentState?.handleShapeMenuShortcut(
                        LogicalKeyboardKey.arrowLeft,
                      ),
                  const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                      _toolPaletteKey.currentState?.handleShapeMenuShortcut(
                        LogicalKeyboardKey.arrowRight,
                      ),
                  const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                      _toolPaletteKey.currentState?.handleShapeMenuShortcut(
                        LogicalKeyboardKey.arrowUp,
                      ),
                  const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                      _toolPaletteKey.currentState?.handleShapeMenuShortcut(
                        LogicalKeyboardKey.arrowDown,
                      ),
                  const SingleActivator(LogicalKeyboardKey.enter): () =>
                      _toolPaletteKey.currentState?.handleShapeMenuShortcut(
                        LogicalKeyboardKey.enter,
                      ),
                  const SingleActivator(LogicalKeyboardKey.escape): () =>
                      _toolPaletteKey.currentState?.handleShapeMenuShortcut(
                        LogicalKeyboardKey.escape,
                      ),
                }
              : const <ShortcutActivator, VoidCallback>{},
          child: DropTarget(
            onDragDone: (details) async {
              if (details.files.isEmpty) {
                return;
              }

              if (details.files.length > 1) {
                if (!context.mounted) {
                  return;
                }

                _showToast(context, 'Please drop only one file at a time.');
                return;
              }

              final file = details.files.first;
              final name = file.name.toLowerCase();
              if (!name.endsWith('.mypt')) {
                return;
              }

              final bytes = await file.readAsBytes();
              if (!context.mounted) {
                return;
              }

              final rawPath = file.path;
              final filePath = rawPath.trim().isEmpty ? null : rawPath;
              final drawingNotifier = ref.read(
                drawingBoardNotifierProvider.notifier,
              );
              await drawingNotifier.loadFromBytes(bytes);
              if (filePath != null) {
                drawingNotifier.setCurrentFilePath(filePath);
              }
            },
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: InteractiveCanvas(
                    key: _canvasExportKey,
                    onViewportScaleChanged:
                        _strokePreviewController.setViewportScale,
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceFloating,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: CanvasTitleField(
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Untitled',
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: textColor),
                        onEditingChanged: (isEditing) {
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _isTitleEditing = isEditing;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: ToolPalette(
                    key: _toolPaletteKey,
                    onSave: () => _saveCanvas(context),
                    onLoad: () => _loadCanvas(context),
                    onExport: () => _exportCanvas(context),
                    onStrokePreviewChanged: (double? width) {
                      if (width == null) {
                        _strokePreviewController.hide();
                        return;
                      }
                      _strokePreviewController.show(width);
                    },
                  ),
                ),
                StrokeWidthPreviewOverlay(controller: _strokePreviewController),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldHandleGlobalShortcut() {
    if (_isTitleEditing) {
      return false;
    }

    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) {
      return true;
    }

    final widget = focusedContext.widget;
    if (widget is EditableText ||
        focusedContext.findAncestorWidgetOfExactType<EditableText>() != null ||
        focusedContext.findAncestorWidgetOfExactType<TextField>() != null ||
        focusedContext.findAncestorWidgetOfExactType<TextFormField>() != null) {
      return false;
    }

    return true;
  }

  Future<void> _loadCanvas(BuildContext context) async {
    final drawingNotifier = ref.read(drawingBoardNotifierProvider.notifier);
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Open canvas',
      type: FileType.custom,
      allowedExtensions: const ['mypt'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final selected = result.files.first;
    final path = selected.path;
    if (path == null || path.trim().isEmpty) {
      if (!context.mounted) {
        return;
      }

      _showToast(context, 'Unable to open the selected file.');
      return;
    }

    if (!path.toLowerCase().endsWith('.mypt')) {
      if (!context.mounted) {
        return;
      }

      _showToast(context, 'Please select a .mypt file.');
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      if (!context.mounted) {
        return;
      }

      _showToast(context, 'Selected file no longer exists.');
      return;
    }

    final bytes = await file.readAsBytes();
    if (!context.mounted) {
      return;
    }

    final failure = await drawingNotifier.loadFromBytes(bytes);
    if (failure != null) {
      if (!context.mounted) {
        return;
      }

      _showToast(context, _loadFailureMessage(failure));
      return;
    }

    drawingNotifier.setCurrentFilePath(path);
  }

  Future<void> _saveCanvas(BuildContext context) async {
    final drawingNotifier = ref.read(drawingBoardNotifierProvider.notifier);
    final drawingState = ref.read(drawingBoardNotifierProvider);
    final isFirstSave = await drawingNotifier.isUsingDraftPath();
    if (!context.mounted) {
      return;
    }
    var canvasTitle = drawingState.currentCanvasName;
    if (isFirstSave) {
      final inputTitle = await _promptForCanvasTitle(context, canvasTitle);
      if (!context.mounted) {
        return;
      }
      if (inputTitle == null) {
        return;
      }

      final trimmedTitle = inputTitle.trim();
      final resolvedTitle = trimmedTitle.isEmpty ? 'Untitled' : trimmedTitle;
      drawingNotifier.updateCanvasTitle(resolvedTitle);
      canvasTitle = resolvedTitle;
    }

    final fallbackName = canvasTitle.trim().isEmpty ? 'untitled' : canvasTitle;
    final suggestedName = _ensureMyptExtension(
      !isFirstSave && drawingState.currentFilePath?.isNotEmpty == true
          ? _fileNameFromPath(drawingState.currentFilePath!)
          : fallbackName,
    );
    final pickedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save canvas',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: const ['mypt'],
    );
    if (pickedPath == null) {
      return;
    }

    final targetPath = _ensureMyptExtension(pickedPath);

    try {
      final resolvedPath = await drawingNotifier.saveToFilePath(targetPath);
      if (!context.mounted || resolvedPath == null) {
        return;
      }

      _showToast(context, 'Saved to ${_fileNameFromPath(resolvedPath)}.');
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      _showToast(context, 'Save failed.');
    }
  }

  Future<void> _exportCanvas(BuildContext context) async {
    final drawingState = ref.read(drawingBoardNotifierProvider);

    final background =
        Theme.of(context).extension<AppColors>()?.backgroundCanvas ??
        Colors.white;

    final state = _canvasExportKey.currentState;
    var bytes = await state?.captureImage(asJpeg: false);

    bytes ??= await CanvasExporter.export(
      drawingState.finalizedShapes,
      canvasWidth: 4096,
      canvasHeight: 4096,
      backgroundColor: background,
      asJpeg: false,
    );

    if (bytes == null) {
      if (context.mounted) {
        _showToast(context, 'Export failed to capture image.');
      }
      return;
    }

    final baseName = drawingState.currentCanvasName.trim().isEmpty
        ? 'untitled'
        : drawingState.currentCanvasName;
    final suggestedName = _ensurePngExtension(baseName);

    final exportPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export canvas',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: const ['png'],
    );

    if (exportPath == null) {
      return;
    }

    final resolvedPath = _ensurePngExtension(exportPath);

    try {
      final file = File(resolvedPath);
      await file.writeAsBytes(bytes, flush: true);

      if (!context.mounted) {
        return;
      }
      _showToast(context, 'Exported ${_fileNameFromPath(resolvedPath)}.');
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showToast(context, 'Export failed.');
    }
  }

  void _showToast(BuildContext context, String message) {
    showAppToast(context, message);
  }

  String _ensureMyptExtension(String path) {
    final normalized = path.trim();
    if (normalized.toLowerCase().endsWith('.mypt')) {
      return normalized;
    }
    return '$normalized.mypt';
  }

  Future<String?> _promptForCanvasTitle(
    BuildContext context,
    String currentTitle,
  ) async {
    final controller = TextEditingController(text: currentTitle);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Canvas Title'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Enter a title for this canvas',
            ),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index == -1 || index == normalized.length - 1) {
      return normalized;
    }
    return normalized.substring(index + 1);
  }

  String _ensurePngExtension(String path) {
    final normalized = path.trim();
    if (normalized.toLowerCase().endsWith('.png')) {
      return normalized;
    }
    return '$normalized.png';
  }

  String _loadFailureMessage(CanvasLoadFailure failure) {
    switch (failure) {
      case CanvasLoadFailure.unsupportedVersion:
        return 'Unsupported file version.';
      case CanvasLoadFailure.corruptedFile:
        return 'This file appears to be corrupted.';
    }
  }
}
