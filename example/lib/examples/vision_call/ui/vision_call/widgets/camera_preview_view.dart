import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Live camera preview, optionally mirrored, scaled to cover its parent.
class CameraPreviewView extends StatelessWidget {
  const CameraPreviewView({
    super.key,
    required this.controller,
    required this.isFlipped,
  });

  final CameraController? controller;
  final ValueNotifier<bool> isFlipped;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final previewSize = controller.value.previewSize;

    // On mobile devices (Android/iOS portrait), width and height are swapped because sensors are naturally landscape.
    // On Web and Desktop, sensors match window orientation and should NOT be swapped.
    final bool swapDimensions =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    final double? previewWidth = previewSize != null
        ? (swapDimensions ? previewSize.height : previewSize.width)
        : null;
    final double? previewHeight = previewSize != null
        ? (swapDimensions ? previewSize.width : previewSize.height)
        : null;

    return ValueListenableBuilder<bool>(
      valueListenable: isFlipped,
      builder: (context, isFlipped, _) {
        final preview = CameraPreview(
          controller,
          key: ValueKey(controller.hashCode),
        );
        final flippedPreview = isFlipped
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: preview,
              )
            : preview;

        if (previewWidth == null || previewHeight == null) {
          return flippedPreview;
        }

        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: flippedPreview,
          ),
        );
      },
    );
  }
}
