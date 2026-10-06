import 'dart:typed_data';

import 'package:example/soloud_live_audio_player.dart';

/// Plays the Lyria 48 kHz stereo PCM stream through SoLoud.
class MusicStudioAudioService {
  final SoloudLiveAudioPlayer _audioPlayer = SoloudLiveAudioPlayer(
    sampleRate: 48000,
    channels: 2,
  );

  Future<void> init() => _audioPlayer.init();

  void appendPcmBytes(Uint8List bytes) => _audioPlayer.appendPcmBytes(bytes);

  void clear() => _audioPlayer.clear();

  Future<void> stop() => _audioPlayer.stop();

  Future<void> dispose() => _audioPlayer.dispose();
}
