import 'dart:typed_data';

import 'package:example/soloud_live_audio_player.dart';

/// Plays the Lyria RealTime 48kHz stereo PCM stream and exposes live
/// FFT / waveform data for the visualizer.
class DjAudioService {
  late final SoloudLiveAudioPlayer _audioPlayer;

  DjAudioService() {
    _audioPlayer = SoloudLiveAudioPlayer(sampleRate: 48000, channels: 2);
  }

  /// The wrapped player (the visualizer polls FFT / waveform from it).
  SoloudLiveAudioPlayer get player => _audioPlayer;

  Future<void> init() => _audioPlayer.init();

  void appendPcmBytes(Uint8List bytes) => _audioPlayer.appendPcmBytes(bytes);

  void clear() => _audioPlayer.clear();

  Future<void> dispose() => _audioPlayer.dispose();
}
