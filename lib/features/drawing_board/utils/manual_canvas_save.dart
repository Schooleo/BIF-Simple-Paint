import 'dart:io';
import 'dart:typed_data';

import 'package:bif_simple_paint/core/services/document_file_service.dart';
import 'package:bif_simple_paint/core/widgets/app_toast.dart';
import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> saveCanvasManually(BuildContext context, WidgetRef ref) async {
  final isMobile = Platform.isAndroid || Platform.isIOS;
  final documentFileService = ref.read(documentFileServiceProvider);
  final drawingNotifier = ref.read(drawingBoardNotifierProvider.notifier);
  final drawingState = ref.read(drawingBoardNotifierProvider);
  final isFirstSave = await drawingNotifier.isUsingDraftPath();
  if (!context.mounted) {
    return;
  }

  var canvasTitle = drawingState.currentCanvasName;
  if (isFirstSave && shouldPromptForCanvasTitle(canvasTitle)) {
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
  final Uint8List? pickerBytes = Platform.isAndroid || Platform.isIOS
      ? await drawingNotifier.buildSerializedCanvasBytes()
      : null;

  try {
    String? resolvedPath;
    final canUseDocumentService =
        isMobile && await documentFileService.isSupported();
    if (canUseDocumentService) {
      final existingDocumentUri = drawingState.currentDocumentUri?.trim();
      if (existingDocumentUri != null && existingDocumentUri.isNotEmpty) {
        final existingReference = DocumentFileReference(
          uri: existingDocumentUri,
          displayName: drawingState.currentFilePath ?? suggestedName,
        );
        await drawingNotifier.saveToDocumentReference(
          existingReference,
          canvasBytes: pickerBytes,
        );
        resolvedPath = existingReference.displayName;
      } else {
        final createdDocument = await documentFileService.createDocument(
          suggestedFileName: suggestedName,
          bytes: pickerBytes!,
        );
        if (createdDocument == null) {
          resolvedPath = await _saveCanvasWithFilePicker(
            suggestedName: suggestedName,
            drawingNotifier: drawingNotifier,
            pickerBytes: pickerBytes,
            isMobile: isMobile,
          );
        } else {
          await drawingNotifier.saveToDocumentReference(
            createdDocument,
            canvasBytes: pickerBytes,
          );
          resolvedPath = createdDocument.displayName;
        }
      }
    } else {
      resolvedPath = await _saveCanvasWithFilePicker(
        suggestedName: suggestedName,
        drawingNotifier: drawingNotifier,
        pickerBytes: pickerBytes,
        isMobile: isMobile,
      );
    }
    if (!context.mounted || resolvedPath == null) {
      return;
    }

    showAppToast(context, 'Saved to ${_fileNameFromPath(resolvedPath)}.');
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'manual_canvas_save',
        context: ErrorDescription('while manually saving the current canvas'),
      ),
    );
    if (!context.mounted) {
      return;
    }

    showAppToast(context, 'Save failed.');
  }
}

Future<String?> _saveCanvasWithFilePicker({
  required String suggestedName,
  required DrawingBoardNotifier drawingNotifier,
  required Uint8List? pickerBytes,
  required bool isMobile,
}) async {
  final pickedPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save canvas',
    fileName: suggestedName,
    type: isMobile ? FileType.any : FileType.custom,
    allowedExtensions: isMobile ? null : const ['mypt'],
    bytes: isMobile ? pickerBytes : null,
  );
  if (pickedPath == null) {
    return null;
  }
  final targetPath = _ensureMyptExtension(pickedPath);
  return drawingNotifier.saveToFilePathWithBytes(
    targetPath,
    canvasBytes: pickerBytes,
  );
}

bool shouldPromptForCanvasTitle(String title) {
  final normalized = title.trim().toLowerCase();
  return normalized.isEmpty || normalized == 'untitled';
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
  var draftTitle = currentTitle;
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Canvas Title'),
        content: TextFormField(
          initialValue: draftTitle,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Enter a title for this canvas',
          ),
          onChanged: (value) {
            draftTitle = value;
          },
          onFieldSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(draftTitle),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
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
