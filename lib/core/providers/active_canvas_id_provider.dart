import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeCanvasIdProvider =
    NotifierProvider<ActiveCanvasIdNotifier, String?>(
      ActiveCanvasIdNotifier.new,
    );

class ActiveCanvasIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setActiveCanvasId(String? canvasId) {
    state = canvasId;
  }

  void clear() {
    state = null;
  }
}
