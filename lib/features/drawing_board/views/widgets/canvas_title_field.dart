import 'dart:async';

import 'package:bif_simple_paint/features/drawing_board/providers/drawing_board_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CanvasTitleField extends ConsumerStatefulWidget {
  const CanvasTitleField({
    super.key,
    this.decoration = const InputDecoration.collapsed(hintText: 'Untitled'),
    this.style,
    this.textAlign = TextAlign.start,
    this.onEditingChanged,
  });

  final InputDecoration decoration;
  final TextStyle? style;
  final TextAlign textAlign;
  final ValueChanged<bool>? onEditingChanged;

  @override
  ConsumerState<CanvasTitleField> createState() => _CanvasTitleFieldState();
}

class _CanvasTitleFieldState extends ConsumerState<CanvasTitleField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focusScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    widget.onEditingChanged?.call(_focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      return;
    }

    _commitTitle();
  }

  String _resolvedTitle(String rawTitle) {
    final String trimmedTitle = rawTitle.trim();
    return trimmedTitle.isEmpty ? 'Untitled' : trimmedTitle;
  }

  void _commitTitle() {
    final DrawingBoardState currentState = ref.read(
      drawingBoardNotifierProvider,
    );
    final String resolvedTitle = _resolvedTitle(_controller.text);
    final bool hasChanged = resolvedTitle != currentState.currentCanvasName;

    if (_controller.text != resolvedTitle) {
      _controller.value = TextEditingValue(
        text: resolvedTitle,
        selection: TextSelection.collapsed(offset: resolvedTitle.length),
      );
    }

    if (!hasChanged) {
      return;
    }

    final DrawingBoardNotifier notifier = ref.read(
      drawingBoardNotifierProvider.notifier,
    );
    notifier.updateCanvasTitle(resolvedTitle);
    unawaited(notifier.flushPendingChanges(writeSynchronously: true));
  }

  void _syncText(String title) {
    if (_focusNode.hasFocus || _controller.text == title) {
      return;
    }

    _controller.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );
  }

  void _scheduleAutofocus(String title) {
    if (_focusScheduled) {
      return;
    }

    _focusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusScheduled = false;
      if (!mounted) {
        return;
      }

      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: title.length,
      );
      _focusNode.requestFocus();
      ref
          .read(drawingBoardNotifierProvider.notifier)
          .consumeCanvasTitleFocusRequest();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DrawingBoardState drawingState = ref.watch(
      drawingBoardNotifierProvider,
    );
    final String title = drawingState.currentCanvasName;

    _syncText(title);
    if (drawingState.shouldFocusCanvasTitle) {
      _scheduleAutofocus(title);
    }

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: widget.textAlign,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.words,
      decoration: widget.decoration,
      style: widget.style,
      onSubmitted: (_) {
        _commitTitle();
        _focusNode.unfocus();
      },
      onTapOutside: (_) => _focusNode.unfocus(),
    );
  }
}
