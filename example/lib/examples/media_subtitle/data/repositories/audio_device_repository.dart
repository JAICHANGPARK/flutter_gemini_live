import 'package:example/api_key_store.dart';

/// Persisted audio input device selection and API key availability, backed by
/// the shared [ApiKeyStore].
class AudioDeviceRepository {
  String get savedDeviceId => ApiKeyStore.audioDeviceId;

  bool get hasApiKey => ApiKeyStore.hasApiKey;

  Future<void> save(String id, String label) =>
      ApiKeyStore.saveAudioDevice(id, label);
}
