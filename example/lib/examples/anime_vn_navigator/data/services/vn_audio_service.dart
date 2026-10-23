import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:example/live_audio_player.dart';
import 'package:example/soloud_live_audio_player.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

/// Plays Hikari's 24kHz PCM voice stream and provides real-time audio energy
/// (RMS + frequency envelope) for 60fps Live2D-style lip-sync and body motion.
class VnAudioService {
  final SoloudLiveAudioPlayer _audioPlayer = SoloudLiveAudioPlayer();
  LiveAudioPlayer? _fallbackAudioPlayer;
  bool _useFallbackAudio = kIsWeb;

  LiveAudioPlayer get _fallback => _fallbackAudioPlayer ??= LiveAudioPlayer();

  DateTime? _lastAiAudioReceivedTime;
  double _latestChunkRms = 0.0;
  double _smoothedLipSyncLevel = 0.0;

  /// Real-time vocal pitch shift factor (`1.0` = original, `1.16` = +2.6 semitones Moe Bishoujo voice).
  double _pitchShift = 1.16;
  double get pitchShift => _pitchShift;

  void setPitchShift(double shift) {
    _pitchShift = shift.clamp(0.85, 1.40);
    if (!_useFallbackAudio) {
      _audioPlayer.setPitchShift(_pitchShift);
    }
  }

  /// Queue of recent chunk RMS values so lip-sync stays active while buffered
  /// audio plays out through the speaker.
  final List<double> _rmsEnvelopeQueue = <double>[];
  DateTime _lastEnvelopePopTime = DateTime.now();
  DateTime? _simulatedSpeechUntil;

  bool get useFallbackAudio => _useFallbackAudio;

  /// Triggers a simulated syllable envelope burst (for offline conference stage
  /// preview or action cut-ins when not yet connected to WebSocket).
  void triggerSimulatedSpeechBurst({
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    _simulatedSpeechUntil = DateTime.now().add(duration);
  }

  Future<void> init() async {
    if (!kIsWeb) {
      try {
        await _audioPlayer.init();
        _audioPlayer.setPitchShift(_pitchShift);
      } catch (e) {
        debugPrint('VnAudioService SoLoud init fallback: $e');
        _useFallbackAudio = true;
      }
    } else {
      _useFallbackAudio = true;
    }
  }

  /// True while Hikari's voice is actively playing or within tail window.
  bool get isAiSpeaking {
    if (_simulatedSpeechUntil != null &&
        DateTime.now().isBefore(_simulatedSpeechUntil!)) {
      return true;
    }
    final isPlaying = _useFallbackAudio
        ? (_fallbackAudioPlayer?.isPlaying ?? false)
        : _audioPlayer.isPlaying;
    if (isPlaying) return true;
    if (_rmsEnvelopeQueue.isNotEmpty) return true;
    if (_lastAiAudioReceivedTime != null) {
      final diff = DateTime.now()
          .difference(_lastAiAudioReceivedTime!)
          .inMilliseconds;
      if (diff < 950) return true;
    }
    return false;
  }

  /// Appends a base64 24kHz PCM chunk and extracts its RMS energy for lip-sync.
  void appendBase64Chunk(String base64Chunk) {
    _lastAiAudioReceivedTime = DateTime.now();
    try {
      final bytes = base64Decode(base64Chunk);
      final rms = GeminiLiveAudioUtils.calculateRms(bytes);
      final visualLevel = GeminiLiveAudioUtils.toVisualScale(rms, factor: 1.8);
      _latestChunkRms = visualLevel;
      // Push multiple ~40ms envelope frames corresponding to chunk duration.
      final estimatedFrames = math.max(1, bytes.length ~/ 1920);
      for (var i = 0; i < estimatedFrames; i++) {
        if (_rmsEnvelopeQueue.length < 180) {
          _rmsEnvelopeQueue.add(visualLevel);
        }
      }
    } catch (_) {}

    if (_useFallbackAudio) {
      _fallback.appendBase64Chunk(base64Chunk);
    } else {
      _audioPlayer.appendBase64Chunk(base64Chunk);
    }
  }

  /// Samples the current lip-sync mouth openness (`0.0` closed .. `1.0` wide open).
  /// Call this on every 60fps animation frame.
  double sampleLipSyncEnergy(double elapsedSeconds) {
    if (!isAiSpeaking) {
      _smoothedLipSyncLevel *= 0.78;
      if (_smoothedLipSyncLevel < 0.01) _smoothedLipSyncLevel = 0.0;
      return _smoothedLipSyncLevel;
    }

    double target = 0.0;

    // 1. Try hardware/engine live waveform if available
    if (!_useFallbackAudio) {
      final wave = _audioPlayer.getLiveWaveform(count: 8);
      if (wave.isNotEmpty) {
        double sum = 0.0;
        for (final v in wave) {
          sum += v.abs();
        }
        final avg = (sum / wave.length).clamp(0.0, 1.0);
        if (avg > 0.02) {
          target = math.max(target, (avg * 2.2).clamp(0.0, 1.0));
        }
      }
    }

    // 2. Pop from the decoded PCM RMS envelope queue every ~40ms
    final now = DateTime.now();
    if (now.difference(_lastEnvelopePopTime).inMilliseconds >= 38) {
      _lastEnvelopePopTime = now;
      if (_rmsEnvelopeQueue.isNotEmpty) {
        _latestChunkRms = _rmsEnvelopeQueue.removeAt(0);
      } else {
        _latestChunkRms *= 0.82;
      }
    }
    target = math.max(target, _latestChunkRms);

    // 3. Simulated syllable cadence when testing action/lip-sync offline
    if (_simulatedSpeechUntil != null &&
        DateTime.now().isBefore(_simulatedSpeechUntil!)) {
      final simEnergy =
          0.45 +
          0.45 * math.sin(elapsedSeconds * 26.0) * math.cos(elapsedSeconds * 11.0);
      target = math.max(target, simEnergy.clamp(0.0, 1.0));
    }

    // 4. Modulate with natural Japanese syllable cadence (~6.5 Hz vowel articulation)
    if (target > 0.05) {
      final syllableMod =
          0.65 + 0.35 * math.sin(elapsedSeconds * 38.0).abs();
      target = (target * syllableMod).clamp(0.0, 1.0);
    }

    // Smooth attack & release
    final factor = target > _smoothedLipSyncLevel ? 0.42 : 0.25;
    _smoothedLipSyncLevel += (target - _smoothedLipSyncLevel) * factor;
    return _smoothedLipSyncLevel.clamp(0.0, 1.0);
  }

  void clear() {
    _rmsEnvelopeQueue.clear();
    _latestChunkRms = 0.0;
    _smoothedLipSyncLevel = 0.0;
    _lastAiAudioReceivedTime = null;
    if (_useFallbackAudio) {
      _fallbackAudioPlayer?.clear();
    } else {
      _audioPlayer.clear();
    }
  }

  void onTurnComplete() {
    if (_useFallbackAudio &&
        (_fallbackAudioPlayer?.hasBufferedAudio ?? false)) {
      unawaited(_fallback.playBufferedAudio());
    } else if (!_useFallbackAudio) {
      _audioPlayer.onTurnComplete();
    }
  }

  void dispose() {
    _rmsEnvelopeQueue.clear();
    unawaited(_audioPlayer.dispose());
    final fb = _fallbackAudioPlayer;
    if (fb != null) {
      unawaited(fb.dispose());
    }
  }
}
