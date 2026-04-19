import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

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

  Future<void> playBufferedAudio() async {
    if (_pcmBytes.isEmpty) return;

    final wavBytes = addWavHeader(
      Uint8List.fromList(_pcmBytes),
      sampleRate: 24000,
    );
    _pcmBytes.clear();

    try {
      await _player.stop();
      await _player.play(BytesSource(wavBytes));
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
}
