import 'dart:async';

import 'package:example/live_audio_player.dart';
import 'package:example/soloud_live_audio_player.dart';
import 'package:flutter/foundation.dart';

/// Plays the translated PCM voice stream.
///
/// Uses the low-latency SoLoud player, or the buffered [LiveAudioPlayer]
/// fallback (always on web).
class TranslationAudioService {
  final SoloudLiveAudioPlayer _audioPlayer = SoloudLiveAudioPlayer();
  final LiveAudioPlayer _fallbackAudioPlayer = LiveAudioPlayer();
  bool _useFallbackAudio = false;

  bool get useFallbackAudio => _useFallbackAudio;

  Future<void> init() async {
    if (!kIsWeb) {
      await _audioPlayer.init();
    } else {
      _useFallbackAudio = true;
    }
  }

  void clear() {
    if (!_useFallbackAudio) {
      _audioPlayer.clear();
    } else {
      _fallbackAudioPlayer.clear();
    }
  }

  Future<void> stop() async {
    if (!_useFallbackAudio) {
      await _audioPlayer.stop();
    } else {
      await _fallbackAudioPlayer.stop();
    }
  }

  void appendBase64Chunk(String base64Data) {
    if (!_useFallbackAudio) {
      _audioPlayer.appendBase64Chunk(base64Data);
    } else {
      _fallbackAudioPlayer.appendBase64Chunk(base64Data);
    }
  }

  /// SoLoud player only.
  void onTurnComplete() => _audioPlayer.onTurnComplete();

  bool get fallbackHasBufferedAudio => _fallbackAudioPlayer.hasBufferedAudio;
  bool get fallbackIsPlaying => _fallbackAudioPlayer.isPlaying;

  Future<void> playFallbackBufferedAudio() =>
      _fallbackAudioPlayer.playBufferedAudio();

  void dispose() {
    unawaited(_audioPlayer.dispose());
    _fallbackAudioPlayer.dispose();
  }
}
