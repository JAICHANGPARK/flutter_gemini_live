import 'dart:typed_data';

import 'package:example/soloud_live_audio_player.dart';

/// Plays the generated 48 kHz stereo PCM music stream through SoLoud.
class ProDjAudioService {
  late final SoloudLiveAudioPlayer _audioPlayer;

  ProDjAudioService() {
    _audioPlayer = SoloudLiveAudioPlayer(sampleRate: 48000, channels: 2);
  }

  /// Not awaited by the caller (matches the original fire-and-forget init).
  void init() {
    _audioPlayer.init();
  }

  void appendPcmBytes(Uint8List bytes) => _audioPlayer.appendPcmBytes(bytes);

  void clear() => _audioPlayer.clear();

  void dispose() {
    _audioPlayer.dispose();
  }
}
