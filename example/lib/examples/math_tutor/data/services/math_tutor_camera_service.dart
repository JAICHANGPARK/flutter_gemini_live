import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Thin wrapper over the `camera` plugin. The service is stateless; the
/// active [CameraController] is owned by the view model.
class MathTutorCameraService {
  Future<List<CameraDescription>> listCameras() => availableCameras();

  /// Index of the back camera (preferred for scanning documents), else 0.
  int preferredCameraIndex(List<CameraDescription> cameras) {
    final backCamIdx = cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    return backCamIdx >= 0 ? backCamIdx : 0;
  }

  /// Creates and initializes a controller. Throws if initialization fails.
  Future<CameraController> createAndInitialize(CameraDescription desc) async {
    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    return controller;
  }

  Future<Uint8List> capture(CameraController controller) async {
    final file = await controller.takePicture();
    return file.readAsBytes();
  }

  Future<void> setTorch(CameraController controller, bool on) {
    return controller.setFlashMode(on ? FlashMode.torch : FlashMode.off);
  }
}
