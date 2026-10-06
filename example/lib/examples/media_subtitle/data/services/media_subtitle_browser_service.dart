import 'dart:io' show Platform, Process;

import 'package:flutter/foundation.dart';

/// Opens a URL in the desktop system browser (no-op on web / mobile).
class MediaSubtitleBrowserService {
  Future<void> open(String url) async {
    if (!kIsWeb) {
      if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    }
  }
}
