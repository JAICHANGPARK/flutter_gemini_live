import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// High-performance Web Audio API PCM streaming player for Flutter Web.
///
/// Converts Gemini Live and Lyria 16-bit linear PCM audio chunks (mono or stereo,
/// 24kHz or 48kHz) into Web Audio [AudioBuffer] nodes and schedules them
/// gaplessly with sub-millisecond precision.
class LiveStreamPlayerImpl {
  final int sampleRate;
  final int channels;

  web.AudioContext? _audioContext;
  double _nextPlayTime = 0.0;
  bool _isPlaying = false;
  final List<web.AudioBufferSourceNode> _activeSources = [];
  Float32List? _latestWave;

  LiveStreamPlayerImpl({
    this.sampleRate = 24000,
    dynamic channels,
  }) : channels = channels is int ? channels : 1;

  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    try {
      final options = web.AudioContextOptions(
        sampleRate: sampleRate,
      );
      _audioContext = web.AudioContext(options);
    } catch (_) {
      try {
        _audioContext = web.AudioContext();
      } catch (e) {
        debugPrint('Web AudioContext init error: $e');
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
    final ctx = _audioContext;
    if (ctx == null || pcmBytes.length < 2) return;

    // Browser autoplay policy: resume suspended audio context on user action/input
    if (ctx.state == 'suspended') {
      ctx.resume();
    }

    final isStereo = channels == 2;
    final numFrames = isStereo ? pcmBytes.length ~/ 4 : pcmBytes.length ~/ 2;
    if (numFrames <= 0) return;

    final leftData = Float32List(numFrames);
    final rightData = isStereo ? Float32List(numFrames) : null;
    final byteData = ByteData.sublistView(pcmBytes);

    if (isStereo) {
      for (var i = 0; i < numFrames; i++) {
        leftData[i] = byteData.getInt16(i * 4, Endian.little) / 32768.0;
        rightData![i] = byteData.getInt16(i * 4 + 2, Endian.little) / 32768.0;
      }
    } else {
      for (var i = 0; i < numFrames; i++) {
        leftData[i] = byteData.getInt16(i * 2, Endian.little) / 32768.0;
      }
    }

    _latestWave = leftData;

    try {
      final audioBuffer = ctx.createBuffer(
        isStereo ? 2 : 1,
        numFrames,
        sampleRate,
      );

      audioBuffer.copyToChannel(leftData.toJS, 0);
      if (isStereo && rightData != null) {
        audioBuffer.copyToChannel(rightData.toJS, 1);
      }

      final source = ctx.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(ctx.destination);

      final currentTime = ctx.currentTime;
      if (_nextPlayTime < currentTime) {
        // Apply 35ms jitter-buffer when queue runs dry
        _nextPlayTime = currentTime + 0.035;
      }

      source.start(_nextPlayTime);
      _nextPlayTime += audioBuffer.duration;
      _isPlaying = true;
      _activeSources.add(source);

      source.addEventListener(
        'ended',
        ((web.Event _) {
          _activeSources.remove(source);
          if (_activeSources.isEmpty && ctx.currentTime >= _nextPlayTime) {
            _isPlaying = false;
          }
        }).toJS,
      );
    } catch (e) {
      debugPrint('Web Audio playback error: $e');
    }
  }

  void onTurnComplete() {
    // Scheduled audio buffers play to completion in Web Audio graph
  }

  void clear() {
    for (final s in _activeSources) {
      try {
        s.stop();
      } catch (_) {}
    }
    _activeSources.clear();
    _nextPlayTime = 0.0;
    _isPlaying = false;
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

  Future<void> dispose() async {
    clear();
    try {
      await _audioContext?.close().toDart;
    } catch (_) {}
    _audioContext = null;
  }
}
