import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Low-latency real-time PCM audio streaming player using [SoLoud] for native I/O.
class LiveStreamPlayerImpl {
  final int sampleRate;
  final Channels channels;

  AudioSource? _currentSource;
  SoundHandle? _currentHandle;
  bool _isInitialized = false;
  bool _isPlaying = false;
  StreamSubscription<AudioVisualizationData>? _visSubscription;
  Float32List? _latestWave;
  Float32List? _latestFft;
  bool _turnIsEnded = false;

  LiveStreamPlayerImpl({
    this.sampleRate = 24000,
    dynamic channels,
  }) : channels = channels is Channels
            ? channels
            : channels == 2
                ? Channels.stereo
                : Channels.mono;

  bool get isPlaying {
    if (!_isPlaying ||
        _currentHandle == null ||
        !SoLoud.instance.isInitialized) {
      return false;
    }
    try {
      return SoLoud.instance.getIsValidVoiceHandle(_currentHandle!);
    } catch (_) {
      return _isPlaying;
    }
  }

  /// Initializes the SoLoud audio engine.
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
          _latestFft = data.fftData;
        });
      } catch (_) {}
      _isInitialized = true;
    } catch (e) {
      debugPrint('SoLoud init error: $e');
    }
  }

  void _ensureStream() {
    if (!_isInitialized || !SoLoud.instance.isInitialized) return;

    if (_currentSource == null || _turnIsEnded) {
      if (_turnIsEnded && _currentSource != null) {
        try {
          SoLoud.instance.disposeSource(_currentSource!);
        } catch (_) {}
        _currentSource = null;
        _currentHandle = null;
      }

      try {
        _currentSource = SoLoud.instance.setBufferStream(
          sampleRate: sampleRate,
          channels: channels,
          format: BufferType.s16le,
          bufferingType: BufferingType.released,
          bufferingTimeNeeds: 0.35,
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

  void appendBase64Chunk(String base64Chunk) {
    if (base64Chunk.isEmpty) return;
    try {
      final bytes = base64Decode(base64Chunk);
      appendPcmBytes(bytes);
    } catch (e) {
      debugPrint('Error decoding base64 audio chunk: $e');
    }
  }

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

  Future<void> stop() async {
    clear();
  }

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

  /// Retrieves live audio FFT frequency magnitude data for visualization.
  List<double> getLiveFft({int count = 32}) {
    final fft = _latestFft;
    if (fft == null || fft.isEmpty || !_isPlaying) {
      return List<double>.filled(count, 0.0);
    }
    final result = <double>[];
    for (var i = 0; i < count; i++) {
      final norm = i / count;
      // Focus more resolution on low and mid frequencies (0Hz to ~6kHz)
      final index = (math.pow(norm, 1.5) * (fft.length - 1))
          .round()
          .clamp(0, fft.length - 1);
      result.add(fft[index].clamp(0.0, 1.0));
    }
    return result;
  }

  Future<void> dispose() async {
    await _visSubscription?.cancel();
    await stop();
  }
}
