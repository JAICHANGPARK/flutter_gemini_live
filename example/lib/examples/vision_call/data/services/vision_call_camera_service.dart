import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Wraps the `camera` plugin and JPEG post-processing for snapshot frames.
class VisionCallCameraService {
  Future<List<CameraDescription>> listCameras() => availableCameras();

  CameraController createController(CameraDescription description) {
    return CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );
  }

  /// Takes a still picture and returns its bytes.
  Future<Uint8List> takePictureBytes(CameraController controller) async {
    final file = await controller.takePicture();
    return file.readAsBytes();
  }

  /// Returns [bytes] flipped horizontally as JPEG (quality 75), or [bytes]
  /// itself when decoding fails.
  Uint8List flipHorizontalJpeg(Uint8List bytes) {
    Uint8List sendBytes = bytes;
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      final flipped = img.flipHorizontal(decoded);
      sendBytes = Uint8List.fromList(img.encodeJpg(flipped, quality: 75));
    }
    return sendBytes;
  }
}
