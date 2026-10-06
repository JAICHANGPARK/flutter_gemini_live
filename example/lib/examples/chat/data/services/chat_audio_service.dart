import 'package:example/live_audio_player.dart';
import 'package:example/message.dart';

/// Wraps the response audio player (buffering + clip extraction).
class ChatAudioService {
  final LiveAudioPlayer _player = LiveAudioPlayer();

  Future<void> stop() => _player.stop();

  void clear() => _player.clear();

  void appendBase64Chunk(String base64Chunk) =>
      _player.appendBase64Chunk(base64Chunk);

  ChatAudioClip? takeBufferedClip({required bool autoPlay}) =>
      _player.takeBufferedClip(autoPlay: autoPlay);

  Future<void> dispose() => _player.dispose();
}
