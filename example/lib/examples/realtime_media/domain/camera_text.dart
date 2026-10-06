import 'package:camera/camera.dart';

/// Human readable label for a camera device.
String cameraLabel(CameraDescription description) {
  if (description.name.isNotEmpty) {
    return description.name;
  }
  return description.lensDirection.name;
}

/// Human readable explanation of a [CameraException].
String describeCameraError(CameraException error) {
  switch (error.code) {
    case 'CameraAccessDenied':
    case 'CameraAccessDeniedWithoutPrompt':
    case 'CameraAccessRestricted':
      return 'camera permission was denied';
    case 'AudioAccessDenied':
    case 'AudioAccessDeniedWithoutPrompt':
    case 'AudioAccessRestricted':
      return 'microphone permission was denied by the camera plugin';
    default:
      return '${error.code}: ${error.description ?? 'unknown camera error'}';
  }
}
