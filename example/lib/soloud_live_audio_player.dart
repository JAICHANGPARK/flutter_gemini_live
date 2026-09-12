import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Low-latency real-time PCM audio streaming player using [SoLoud].
///
/// Handles Gemini Live's 24kHz 16-bit linear PCM audio stream chunks directly,
/// enabling real-time playback with minimal latency and instant interruption flush.
class SoloudLiveAudioPlayer {
  SoloudLiveAudioPlayer();

  AudioSource? _currentSource;
  SoundHandle? _currentHandle;
  bool _isInitialized = false;
  bool _isPlaying = false;
  StreamSubscription<AudioVisualizationData>? _visSubscription;
  Float32List? _latestWave;

  bool get isPlaying => _isPlaying;

  /// Initializes the SoLoud audio engine if not already initialized.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init();
      }
      try {
        SoLoud.instance.setVisualizationEnabled(true);
        _visSubscription =
            SoLoud.instance.audioVisualizationEvents.listen((data) {
          _latestWave = data.waveData;
        });
      } catch (_) {
        // Visualization is optional
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('SoLoud init error: $e');
    }
  }

  bool _turnIsEnded = false;

  void _ensureStream() {
    if (!_isInitialized || !SoLoud.instance.isInitialized) return;

    if (_currentSource == null || _turnIsEnded) {
      // Dispose finished previous turn stream if any
      if (_turnIsEnded && _currentSource != null) {
        try {
          SoLoud.instance.disposeSource(_currentSource!);
        } catch (_) {}
        _currentSource = null;
        _currentHandle = null;
      }

      try {
        _currentSource = SoLoud.instance.setBufferStream(
          sampleRate: 24000,
          channels: Channels.mono,
          format: BufferType.s16le,
          bufferingType: BufferingType.released,
          bufferingTimeNeeds: 0.05, // 50ms initial buffer for low latency
          maxBufferSizeDuration: const Duration(seconds: 30),
          onBuffering: (isBuffering, handle, time) {
            _isPlaying = !isBuffering;
          },
        );

        _currentHandle = SoLoud.instance.play(_currentSource!);
        _isPlaying = true;
        _turnIsEnded = false;
      } catch (e) {
        debugPrint('Failed to initialize buffer stream: $e');
      }
    }
  }

  /// Appends a base64-encoded PCM chunk received from Gemini Live.
  void appendBase64Chunk(String base64Chunk) {
    if (base64Chunk.isEmpty) return;
    try {
      final bytes = base64Decode(base64Chunk);
      appendPcmBytes(bytes);
    } catch (e) {
      debugPrint('Error decoding base64 audio chunk: $e');
    }
  }

  /// Appends raw PCM byte data to the active stream buffer.
  void appendPcmBytes(Uint8List pcmBytes) {
    if (pcmBytes.isEmpty) return;
    _ensureStream();

    final source = _currentSource;
    if (source != null && SoLoud.instance.isInitialized) {
      try {
        SoLoud.instance.addAudioDataStream(source, pcmBytes);
      } catch (e) {
        debugPrint('SoLoud addAudioDataStream error: $e');
      }
    }
  }

  /// Marks that the current AI turn has finished transmitting audio data.
  void onTurnComplete() {
    final source = _currentSource;
    if (source != null && SoLoud.instance.isInitialized) {
      try {
        SoLoud.instance.setDataIsEnded(source);
      } catch (e) {
        debugPrint('SoLoud setDataIsEnded error: $e');
      }
    }
    _turnIsEnded = true;
  }

  /// Immediately interrupts and flushes audio playback (e.g. user barge-in).
  void clear() {
    if (!SoLoud.instance.isInitialized) return;

    if (_currentHandle != null) {
      try {
        SoLoud.instance.stop(_currentHandle!);
      } catch (_) {}
      _currentHandle = null;
    }

    if (_currentSource != null) {
      try {
        SoLoud.instance.disposeSource(_currentSource!);
      } catch (_) {}
      _currentSource = null;
    }

    _isPlaying = false;
    _turnIsEnded = false;
  }

  /// Stops current playback.
  Future<void> stop() async {
    clear();
  }

  /// Retrieves live audio waveform / amplitude data for visualization.
  List<double> getLiveWaveform({int count = 14}) {
    final wave = _latestWave;
    if (wave == null || wave.isEmpty || !_isPlaying) {
      return List<double>.filled(count, 0.1);
    }
    final step = (wave.length / count).floor();
    final result = <double>[];
    for (var i = 0; i < count; i++) {
      final idx = (i * step).clamp(0, wave.length - 1);
      result.add(wave[idx].abs().clamp(0.05, 1.0));
    }
    return result;
  }

  /// Disposes the player.
  Future<void> dispose() async {
    await _visSubscription?.cancel();
    await stop();
  }
}
