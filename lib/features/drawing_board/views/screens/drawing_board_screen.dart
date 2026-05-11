import 'package:bif_simple_paint/core/theme/app_colors.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/drawing_board_mobile_layout.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/interactive_canvas.dart';
import 'package:bif_simple_paint/features/drawing_board/views/widgets/tool_palette.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  final GlobalKey<CanvasCapture> _canvasExportKey = GlobalKey<CanvasCapture>();

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingBoardNotifierProvider);
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final Color background = colors.backgroundCanvas;
    final Color textColor = colors.textMuted;

    return Container(
      color: background,
      child: DropTarget(
        onDragDone: (details) async {
          if (details.files.isEmpty) {
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

          await ref
              .read(drawingBoardNotifierProvider.notifier)
              .loadFromBytes(bytes);
        },
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: InteractiveCanvas(key: _canvasExportKey)),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  drawingState.currentCanvasName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: textColor),
                ),
              ),
            ),
            Positioned(
              top: 24,
              right: 24,
              child: ToolPalette(
                onSave: () => _saveCanvas(context),
                onLoad: () => _loadCanvas(context),
                onExport: () => _exportCanvas(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCanvas(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
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

      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open the selected file.')),
      );
      return;
    }

    if (!path.toLowerCase().endsWith('.mypt')) {
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a .mypt file.')),
      );
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Selected file no longer exists.')),
      );
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

      messenger.showSnackBar(
        SnackBar(content: Text(_loadFailureMessage(failure))),
      );
      return;
    }

    drawingNotifier.setCurrentFilePath(path);
  }

  Future<void> _saveCanvas(BuildContext context) async {
    final drawingState = ref.read(drawingBoardNotifierProvider);
    final drawingNotifier = ref.read(drawingBoardNotifierProvider.notifier);
    final fallbackName = drawingState.currentCanvasName.trim().isEmpty
        ? 'untitled'
        : drawingState.currentCanvasName;
    final suggestedName = _ensureMyptExtension(
      drawingState.currentFilePath?.isNotEmpty == true
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${_fileNameFromPath(resolvedPath)}.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Save failed.')));
    }
  }

  Future<void> _exportCanvas(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final drawingState = ref.read(drawingBoardNotifierProvider);
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
    final state = _canvasExportKey.currentState;
    final bytes = await state?.captureImage(asJpeg: false);
    if (!context.mounted) {
      return;
    }

    if (bytes == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Export failed.')));
      return;
    }

    try {
      final file = File(resolvedPath);
      await file.writeAsBytes(bytes, flush: true);
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Exported ${_fileNameFromPath(resolvedPath)}.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(const SnackBar(content: Text('Export failed.')));
    }
  }

  String _ensureMyptExtension(String path) {
    final normalized = path.trim();
    if (normalized.toLowerCase().endsWith('.mypt')) {
      return normalized;
    }
    return '$normalized.mypt';
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
