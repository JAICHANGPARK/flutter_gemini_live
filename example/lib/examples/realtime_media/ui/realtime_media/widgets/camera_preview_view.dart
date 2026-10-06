import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../domain/camera_text.dart';
import '../view_models/realtime_media_view_model.dart';

/// Camera preview with a device label chip, spinner or placeholder message.
class CameraPreviewView extends StatelessWidget {
  final RealtimeMediaViewModel viewModel;

  const CameraPreviewView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.isCameraInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = viewModel.cameraController;
    if (controller != null && controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          Positioned(
            left: 12,
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  cameraLabel(controller.description),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final hasKnownCameraDevices = viewModel.availableCameras.isNotEmpty;
    final message = hasKnownCameraDevices
        ? 'Camera preview is not ready yet. Tap Initialize Camera.'
        : 'Camera preview is unavailable on this device, permission has not been granted, or no camera is attached.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 40, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
