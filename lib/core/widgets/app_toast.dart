import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _activeToastEntry;
Timer? _activeToastTimer;

void showAppToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  _activeToastTimer?.cancel();
  _activeToastEntry?.remove();

  final overlay = Overlay.of(context, rootOverlay: true);
  final isDesktop = MediaQuery.sizeOf(context).width >= 800;

  _activeToastEntry = OverlayEntry(
    builder: (context) {
      final theme = Theme.of(context);
      return IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: isDesktop
                ? Alignment.bottomRight
                : Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(
                right: isDesktop ? 24 : 16,
                bottom: 24,
                left: isDesktop ? 16 : 16,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(_activeToastEntry!);
  _activeToastTimer = Timer(duration, () {
    _activeToastEntry?.remove();
    _activeToastEntry = null;
    _activeToastTimer = null;
  });
}
