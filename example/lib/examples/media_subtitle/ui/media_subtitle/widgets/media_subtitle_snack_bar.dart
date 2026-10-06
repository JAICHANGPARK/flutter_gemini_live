import 'package:flutter/material.dart';

import '../view_models/media_subtitle_notice.dart';

/// Shows [notice] as a snackbar on the nearest [ScaffoldMessenger].
void showMediaSubtitleSnackBar(
  BuildContext context,
  MediaSubtitleNotice notice,
) {
  switch (notice.kind) {
    case MediaSubtitleNoticeKind.plain:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(notice.message)));
    case MediaSubtitleNoticeKind.brief:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notice.message),
          duration: const Duration(seconds: 2),
        ),
      );
    case MediaSubtitleNoticeKind.error:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notice.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    case MediaSubtitleNoticeKind.playing:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notice.message),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.indigo.shade800,
        ),
      );
  }
}
