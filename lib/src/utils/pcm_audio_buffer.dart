import 'dart:async';
import 'dart:typed_data';

import 'wav_header.dart';

/// A stream transformer and buffer utility that slices or accumulates irregular
/// raw PCM byte streams into uniform, sample-aligned chunks.
///
/// Gemini Live's WebSocket audio input works best when 16-bit linear PCM (16,000 Hz,
/// mono) is transmitted in consistent frame intervals (typically 20ms to 100ms,
/// or 640 to 3,200 bytes) with strict 2-byte (16-bit) sample alignment.
class GeminiLivePcmChunker extends StreamTransformerBase<Uint8List, Uint8List> {
  /// Target size in bytes for each emitted PCM chunk.
  ///
  /// Must be a positive multiple of [bytesPerSample] (default 2 bytes for 16-bit PCM).
  /// Defaults to `3200` bytes (100ms of 16kHz 16-bit mono audio).
  final int chunkSizeInBytes;

  /// Number of bytes per audio sample frame (`numChannels * (bitsPerSample ~/ 8)`).
  /// Defaults to `2` (16-bit mono).
  final int bytesPerSample;

  /// Whether to flush any remaining trailing bytes (aligned to [bytesPerSample])
  /// when the source stream closes. Defaults to `true`.
  final bool flushRemainingOnClose;

  /// Creates a PCM stream chunker with a fixed [chunkSizeInBytes].
  const GeminiLivePcmChunker({
    this.chunkSizeInBytes = 3200,
    this.bytesPerSample = 2,
    this.flushRemainingOnClose = true,
  }) : assert(chunkSizeInBytes > 0, 'chunkSizeInBytes must be positive.'),
       assert(bytesPerSample > 0, 'bytesPerSample must be positive.'),
       assert(
         chunkSizeInBytes % bytesPerSample == 0,
         'chunkSizeInBytes must be a multiple of bytesPerSample.',
       );

  /// Creates a [GeminiLivePcmChunker] sized for a specific frame [duration].
  ///
  /// Defaults to 16,000 Hz, mono (`numChannels = 1`), 16-bit (`bitsPerSample = 16`).
  factory GeminiLivePcmChunker.fromDuration({
    Duration duration = const Duration(milliseconds: 100),
    int sampleRate = 16000,
    int numChannels = 1,
    int bitsPerSample = 16,
    bool flushRemainingOnClose = true,
  }) {
    final bytesPerSample = numChannels * (bitsPerSample ~/ 8);
    final rawSamples = (sampleRate * duration.inMicroseconds) ~/ 1000000;
    final alignedBytes = (rawSamples > 0 ? rawSamples : 1) * bytesPerSample;
    return GeminiLivePcmChunker(
      chunkSizeInBytes: alignedBytes,
      bytesPerSample: bytesPerSample,
      flushRemainingOnClose: flushRemainingOnClose,
    );
  }

  @override
  Stream<Uint8List> bind(Stream<Uint8List> stream) {
    late StreamController<Uint8List> controller;
    StreamSubscription<Uint8List>? subscription;
    final pending = <int>[];

    void emitChunks() {
      while (pending.length >= chunkSizeInBytes) {
        final chunk = Uint8List.fromList(pending.sublist(0, chunkSizeInBytes));
        pending.removeRange(0, chunkSizeInBytes);
        controller.add(chunk);
      }
    }

    controller = StreamController<Uint8List>(
      onListen: () {
        subscription = stream.listen(
          (data) {
            if (data.isEmpty) return;
            pending.addAll(data);
            emitChunks();
          },
          onError: controller.addError,
          onDone: () {
            if (flushRemainingOnClose && pending.isNotEmpty) {
              final alignedLength =
                  (pending.length ~/ bytesPerSample) * bytesPerSample;
              if (alignedLength > 0) {
                controller.add(
                  Uint8List.fromList(pending.sublist(0, alignedLength)),
                );
              }
            }
            pending.clear();
            controller.close();
          },
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        pending.clear();
        return subscription?.cancel();
      },
    );

    return controller.stream;
  }
}

/// An in-memory accumulator for raw 16-bit linear PCM audio chunks that supports
/// instant barge-in flushing, duration calculation, and WAV file export.
///
/// Defaults match Gemini Live's AI speech output specification:
/// 24,000 Hz, 16-bit linear PCM, mono (`numChannels = 1`).
class GeminiLiveAudioBuffer {
  /// Audio sample rate in Hz (e.g., `24000` for Gemini speech, `16000` for mic, `48000` for Lyria).
  final int sampleRate;

  /// Number of audio channels (`1` for mono, `2` for stereo).
  final int numChannels;

  /// Bits per sample (typically `16`).
  final int bitsPerSample;

  final BytesBuilder _builder = BytesBuilder(copy: false);

  /// Creates a PCM audio buffer with the given audio format parameters.
  GeminiLiveAudioBuffer({
    this.sampleRate = 24000,
    this.numChannels = 1,
    this.bitsPerSample = 16,
  }) : assert(sampleRate > 0, 'sampleRate must be positive.'),
       assert(numChannels > 0, 'numChannels must be positive.'),
       assert(bitsPerSample > 0, 'bitsPerSample must be positive.');

  /// Appends a raw PCM chunk to the buffer.
  void add(Uint8List pcmChunk) {
    if (pcmChunk.isEmpty) return;
    _builder.add(pcmChunk);
  }

  /// Immediately clears all buffered audio bytes (e.g. upon barge-in interruption).
  void clear() {
    _builder.clear();
  }

  /// Whether the buffer currently holds no audio data.
  bool get isEmpty => _builder.isEmpty;

  /// Whether the buffer currently holds audio data.
  bool get isNotEmpty => _builder.isNotEmpty;

  /// Total number of raw PCM bytes currently stored.
  int get lengthInBytes => _builder.length;

  /// Total playback duration of the buffered PCM audio.
  Duration get duration {
    final bytesPerSecond = (sampleRate * numChannels * bitsPerSample) ~/ 8;
    if (bytesPerSecond <= 0 || _builder.isEmpty) return Duration.zero;
    final microseconds = (_builder.length * 1000000) ~/ bytesPerSecond;
    return Duration(microseconds: microseconds);
  }

  /// Returns a consolidated copy of the raw PCM bytes without a header.
  Uint8List toPcmBytes() => _builder.toBytes();

  /// Exports the buffered PCM audio with a standard 44-byte RIFF WAV header.
  Uint8List toWavBytes() {
    return addWavHeader(
      _builder.toBytes(),
      sampleRate: sampleRate,
      numChannels: numChannels,
      bitsPerSample: bitsPerSample,
    );
  }
}
