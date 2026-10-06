import 'package:flutter/material.dart';

import '../view_models/math_tutor_notice.dart';

/// Shows [notice] as a floating snackbar (replacing any current one).
void showMathTutorSnackBar(
  BuildContext context,
  MathTutorNotice notice, {
  Duration duration = const Duration(seconds: 2),
}) {
  if (!context.mounted) return;
  final (icon, color) = switch (notice.kind) {
    MathTutorNoticeKind.keyOff => (Icons.key_off_rounded, Colors.amberAccent),
    MathTutorNoticeKind.error => (
      Icons.error_outline_rounded,
      Colors.redAccent,
    ),
    MathTutorNoticeKind.sync => (Icons.sync_rounded, null),
    MathTutorNoticeKind.cloudOff => (Icons.cloud_off_rounded, Colors.redAccent),
    MathTutorNoticeKind.camera => (Icons.camera_alt_rounded, null),
    MathTutorNoticeKind.gallery => (Icons.photo_library_rounded, null),
    MathTutorNoticeKind.info => (Icons.info_outline_rounded, null),
    MathTutorNoticeKind.copy => (Icons.copy_rounded, Colors.amberAccent),
    MathTutorNoticeKind.success => (
      Icons.check_circle_rounded,
      Colors.greenAccent,
    ),
  };
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      content: Row(
        children: [
          Icon(icon, color: color ?? Colors.amberAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notice.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}
