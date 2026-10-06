import 'package:flutter/material.dart';

import '../view_models/dj_midi_box_notice.dart';

/// Shows [notice] as a snackbar.
void showDjMidiBoxSnackBar(BuildContext context, DjMidiBoxNotice notice) {
  switch (notice.kind) {
    case DjMidiBoxNoticeKind.connected:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notice.message),
          backgroundColor: Colors.deepPurpleAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    case DjMidiBoxNoticeKind.connectionFailed:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notice.message), backgroundColor: Colors.red),
      );
  }
}
