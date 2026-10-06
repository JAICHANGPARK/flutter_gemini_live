import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Gallery picking and JPEG down-scaling for real-time Live streaming.
class MathTutorImageService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Returns the raw bytes of a gallery photo, or `null` if cancelled.
  Future<Uint8List?> pickFromGallery() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return picked.readAsBytes();
  }

  /// Resizes to 1024px wide and re-encodes as JPEG (quality 80). Returns the
  /// original bytes if decoding or encoding fails.
  Uint8List compressForStreaming(
    Uint8List bytes, {
    String errorLabel = 'Image',
  }) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final resized = img.copyResize(decoded, width: 1024);
        return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
      }
    } catch (e) {
      debugPrint('$errorLabel compression error: $e');
    }
    return bytes;
  }
}
