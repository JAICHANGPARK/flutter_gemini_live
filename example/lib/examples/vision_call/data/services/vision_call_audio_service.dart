import 'dart:async';

import 'package:example/live_audio_player.dart';
import 'package:example/soloud_live_audio_player.dart';
import 'package:flutter/foundation.dart';

/// Wraps the two audio output paths: SoLoud (native) with an audioplayers
/// based fallback (web, or when SoLoud fails to initialise).
class VisionCallAudioService {
  final SoloudLiveAudioPlayer _audioPlayer = SoloudLiveAudioPlayer();
  final LiveAudioPlayer _fallbackAudioPlayer = LiveAudioPlayer();
  bool useFallbackAudio = kIsWeb;

  Future<void> init() async {
    if (!kIsWeb) {
      try {
        await _audioPlayer.init();
      } catch (e) {
        debugPrint('SoLoud init error, fallback to audioplayers: $e');
        useFallbackAudio = true;
      }
    } else {
      useFallbackAudio = true;
    }
  }

  /// Whether the currently selected output path is playing.
  bool get isPlaying => useFallbackAudio
      ? _fallbackAudioPlayer.isPlaying
      : _audioPlayer.isPlaying;

  /// Whether either output path is playing.
  bool get isAnyPlaying =>
      _audioPlayer.isPlaying || _fallbackAudioPlayer.isPlaying;

  void clear() {
    if (useFallbackAudio) {
      _fallbackAudioPlayer.clear();
    } else {
      _audioPlayer.clear();
    }
  }

  void appendBase64Chunk(String data) {
    if (useFallbackAudio) {
      _fallbackAudioPlayer.appendBase64Chunk(data);
    } else {
      _audioPlayer.appendBase64Chunk(data);
    }
  }

  void onTurnComplete() {
    if (useFallbackAudio) {
      if (_fallbackAudioPlayer.hasBufferedAudio) {
        unawaited(_fallbackAudioPlayer.playBufferedAudio());
      }
    } else {
      _audioPlayer.onTurnComplete();
    }
  }

  /// Stops only the SoLoud player (used when ending the call).
  Future<void> stopPrimary() => _audioPlayer.stop();

  /// Stops both players, SoLoud first.
  Future<void> stopAll() async {
    await _audioPlayer.stop();
    await _fallbackAudioPlayer.stop();
  }

  void dispose() {
    unawaited(_audioPlayer.dispose());
    unawaited(_fallbackAudioPlayer.dispose());
  }
}
