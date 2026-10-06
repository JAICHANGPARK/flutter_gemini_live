import 'package:image_picker/image_picker.dart';

/// Wraps the gallery image picker.
class ChatImageService {
  final ImagePicker _picker =
      ImagePicker(); // An instance of the image picker utility.

  Future<XFile?> pickFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compress image to reduce size.
    );
  }
}
