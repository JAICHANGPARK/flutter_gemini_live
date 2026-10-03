import 'dart:typed_data';

import 'live_stream_player_io.dart'
    if (dart.library.js_interop) 'live_stream_player_web.dart';

/// Low-latency real-time PCM audio streaming player.
///
/// Automatically selects the best underlying audio driver:
/// - **Flutter Web**: Browser's native Web Audio API ([AudioContext]) for
///   reliable, zero-dependency 24kHz/48kHz linear PCM stereo/mono streaming.
/// - **Native Mobile & Desktop**: [SoLoud] high-performance C++ audio engine.
class SoloudLiveAudioPlayer {
  final LiveStreamPlayerImpl _impl;

  SoloudLiveAudioPlayer({
    int sampleRate = 24000,
    dynamic channels,
  }) : _impl = LiveStreamPlayerImpl(
          sampleRate: sampleRate,
          channels: channels,
        );

  /// Whether audio is actively playing through the speaker.
  bool get isPlaying => _impl.isPlaying;

  /// Initializes the audio engine.
  Future<void> init() => _impl.init();

  /// Appends a base64-encoded PCM chunk received from Gemini Live or Lyria.
  void appendBase64Chunk(String base64Chunk) =>
      _impl.appendBase64Chunk(base64Chunk);

  /// Appends raw PCM byte data to the active stream buffer.
  void appendPcmBytes(Uint8List pcmBytes) => _impl.appendPcmBytes(pcmBytes);

  /// Marks that the current AI turn has finished transmitting audio data.
  void onTurnComplete() => _impl.onTurnComplete();

  /// Immediately interrupts and flushes audio playback.
  void clear() => _impl.clear();

  /// Stops current playback.
  Future<void> stop() => _impl.stop();

  /// Retrieves live audio waveform / amplitude data for visualization.
  List<double> getLiveWaveform({int count = 14}) =>
      _impl.getLiveWaveform(count: count);

  /// Disposes the player.
  Future<void> dispose() => _impl.dispose();
}
