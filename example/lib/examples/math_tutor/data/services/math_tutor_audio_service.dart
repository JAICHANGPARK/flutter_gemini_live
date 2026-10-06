import 'dart:async';

import 'package:example/live_audio_player.dart';
import 'package:example/soloud_live_audio_player.dart';
import 'package:flutter/foundation.dart';

/// Plays the tutor's PCM voice stream.
///
/// Prefers the low-latency SoLoud player and transparently falls back to the
/// buffered `audioplayers` based [LiveAudioPlayer] (always on web).
class MathTutorAudioService {
  final SoloudLiveAudioPlayer _audioPlayer = SoloudLiveAudioPlayer();
  final LiveAudioPlayer _fallbackAudioPlayer = LiveAudioPlayer();
  bool _useFallbackAudio = kIsWeb;
  DateTime? _lastAiAudioReceivedTime;

  bool get useFallbackAudio => _useFallbackAudio;

  Future<void> init() async {
    if (!kIsWeb) {
      try {
        await _audioPlayer.init();
      } catch (e) {
        debugPrint('SoLoud init error, fallback to audioplayers: $e');
        _useFallbackAudio = true;
      }
    } else {
      _useFallbackAudio = true;
    }
  }

  /// True while audio is playing or was received within the last 1.2 seconds.
  bool get isAiSpeaking {
    final isPlaying = _useFallbackAudio
        ? _fallbackAudioPlayer.isPlaying
        : _audioPlayer.isPlaying;
    if (isPlaying) return true;
    if (_lastAiAudioReceivedTime != null) {
      final diff = DateTime.now()
          .difference(_lastAiAudioReceivedTime!)
          .inMilliseconds;
      if (diff < 1200) return true;
    }
    return false;
  }

  void appendBase64Chunk(String base64Chunk) {
    _lastAiAudioReceivedTime = DateTime.now();
    if (_useFallbackAudio) {
      _fallbackAudioPlayer.appendBase64Chunk(base64Chunk);
    } else {
      _audioPlayer.appendBase64Chunk(base64Chunk);
    }
  }

  /// Drops queued audio (barge-in).
  void clear() {
    if (_useFallbackAudio) {
      _fallbackAudioPlayer.clear();
    } else {
      _audioPlayer.clear();
    }
    _lastAiAudioReceivedTime = null;
  }

  void onTurnComplete() {
    if (_useFallbackAudio && _fallbackAudioPlayer.hasBufferedAudio) {
      unawaited(_fallbackAudioPlayer.playBufferedAudio());
    } else if (!_useFallbackAudio) {
      _audioPlayer.onTurnComplete();
    }
  }

  void dispose() {
    unawaited(_audioPlayer.dispose());
    unawaited(_fallbackAudioPlayer.dispose());
  }
}
