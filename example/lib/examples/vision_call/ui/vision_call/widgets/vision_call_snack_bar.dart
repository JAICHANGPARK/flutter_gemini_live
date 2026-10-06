import 'package:flutter/material.dart';

import '../view_models/vision_call_notice.dart';

void showVisionCallSnackBar(BuildContext context, VisionCallNotice notice) {
  final messenger = ScaffoldMessenger.of(context);
  switch (notice.kind) {
    case VisionCallNoticeKind.info:
      messenger.showSnackBar(SnackBar(content: Text(notice.message)));
    case VisionCallNoticeKind.cameraFlip:
      final next = notice.flipped;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(
                next ? Icons.flip_rounded : Icons.swap_horiz_rounded,
                color: Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                notice.message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
  }
}
