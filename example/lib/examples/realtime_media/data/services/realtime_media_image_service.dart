import 'package:image_picker/image_picker.dart';

/// Gallery picking for the "Send Image" action.
class RealtimeMediaImageService {
  final ImagePicker _picker = ImagePicker();

  /// Returns the picked gallery image, or `null` if cancelled.
  Future<XFile?> pickFromGallery() {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
  }
}
