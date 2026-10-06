import 'package:example/api_key_store.dart';

/// Persists the user's preferred audio input device.
class AudioDeviceRepository {
  String get savedDeviceId => ApiKeyStore.audioDeviceId;

  Future<void> save(String id, String label) =>
      ApiKeyStore.saveAudioDevice(id, label);
}
