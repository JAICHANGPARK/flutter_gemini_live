import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Thin wrapper over the `camera` plugin. The active [CameraController] is
/// owned by the view model.
class RealtimeMediaCameraService {
  Future<List<CameraDescription>> listCameras() => availableCameras();

  /// Creates and initializes a controller (flash off when supported). Throws
  /// if initialization fails.
  Future<CameraController> createAndInitialize(
    CameraDescription description,
  ) async {
    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    try {
      await controller.setFlashMode(FlashMode.off);
    } catch (_) {
      // Flash mode may be unsupported on some cameras.
    }
    return controller;
  }

  /// Takes a still picture and returns its bytes.
  Future<Uint8List> capture(CameraController controller) async {
    final image = await controller.takePicture();
    return image.readAsBytes();
  }
}
