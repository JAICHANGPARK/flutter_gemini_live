import 'package:example/live_audio_player.dart';

/// Wraps the [LiveAudioPlayer] that plays the model's buffered audio replies.
class LiveApiAudioService {
  final LiveAudioPlayer _player = LiveAudioPlayer();

  bool get hasBufferedAudio => _player.hasBufferedAudio;

  Future<void> stop() => _player.stop();

  void clear() => _player.clear();

  void appendBase64Chunk(String data) => _player.appendBase64Chunk(data);

  Future<void> playBufferedAudio() => _player.playBufferedAudio();

  Future<void> dispose() => _player.dispose();
}
