import 'package:flutter/services.dart';

/// Wraps the system clipboard.
class MediaSubtitleClipboardService {
  void copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}
