import 'package:example/live_audio_player.dart';

/// Plays the model's buffered PCM response audio.
class RealtimeMediaAudioService {
  final LiveAudioPlayer _responseAudioPlayer = LiveAudioPlayer();

  bool get hasBufferedAudio => _responseAudioPlayer.hasBufferedAudio;

  Future<void> stop() => _responseAudioPlayer.stop();

  void clear() => _responseAudioPlayer.clear();

  void appendBase64Chunk(String base64Chunk) =>
      _responseAudioPlayer.appendBase64Chunk(base64Chunk);

  Future<void> playBufferedAudio() => _responseAudioPlayer.playBufferedAudio();

  Future<void> dispose() => _responseAudioPlayer.dispose();
}
