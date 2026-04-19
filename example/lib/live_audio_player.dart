import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import 'live_audio_source_io.dart'
    if (dart.library.js_interop) 'live_audio_source_web.dart';
import 'message.dart';

class LiveAudioPlayer {
  LiveAudioPlayer() {
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
  }

  final AudioPlayer _player = AudioPlayer();
  final List<int> _pcmBytes = <int>[];

  bool get hasBufferedAudio => _pcmBytes.isNotEmpty;

  void appendBase64Chunk(String base64Chunk) {
    if (base64Chunk.isEmpty) return;
    _pcmBytes.addAll(base64Decode(base64Chunk));
  }

  void clear() {
    _pcmBytes.clear();
  }

  ChatAudioClip? takeBufferedClip({
    bool autoPlay = false,
    String label = 'Voice response',
  }) {
    if (_pcmBytes.isEmpty) return null;
    final pcmBytes = Uint8List.fromList(_pcmBytes);
    final wavBytes = addWavHeader(pcmBytes, sampleRate: 24000);
    final waveform = _buildWaveform(pcmBytes);
    _pcmBytes.clear();
    return ChatAudioClip.wav(
      wavBytes: wavBytes,
      waveform: waveform,
      mimeType: 'audio/wav',
      autoPlay: autoPlay,
      label: label,
    );
  }

  Future<void> playBufferedAudio() async {
    final clip = takeBufferedClip();
    if (clip == null) return;

    try {
      await _player.stop();
      final source = await createChatAudioSource(clip);
      await _player.play(source);
    } catch (error) {
      debugPrint('Audio playback failed: $error');
    }
  }

  Future<void> stop() async {
    clear();
    await _player.stop();
  }

  Future<void> dispose() async {
    clear();
    await _player.dispose();
  }

  static List<double> _buildWaveform(Uint8List pcmBytes, {int bars = 24}) {
    if (pcmBytes.isEmpty || bars <= 0) {
      return List<double>.filled(bars, 0.2);
    }

    final samples = ByteData.sublistView(pcmBytes);
    final totalSamples = pcmBytes.length ~/ 2;
    if (totalSamples == 0) {
      return List<double>.filled(bars, 0.2);
    }

    final samplesPerBar = (totalSamples / bars).ceil();
    final waveform = <double>[];

    for (var bar = 0; bar < bars; bar++) {
      final startSample = bar * samplesPerBar;
      final endSample = ((bar + 1) * samplesPerBar).clamp(0, totalSamples);
      if (startSample >= endSample) {
        waveform.add(0.12);
        continue;
      }

      var peak = 0.0;
      for (var i = startSample; i < endSample; i++) {
        final amplitude = samples.getInt16(i * 2, Endian.little).abs() / 32768;
        if (amplitude > peak) {
          peak = amplitude;
        }
      }
      waveform.add(peak.clamp(0.08, 1.0));
    }

    return waveform;
  }
}
