import 'dart:math' as math;
import 'dart:typed_data';

/// Utilities for working with raw PCM audio data in Gemini Live sessions.
///
/// Gemini Live communicates using 16-bit linear PCM Little-Endian audio
/// (typically 16kHz for input and 24kHz for output). This utility provides
/// high-performance calculations for amplitude, RMS, and decibel levels
/// suitable for audio waveform visualizations.
class GeminiLiveAudioUtils {
  GeminiLiveAudioUtils._(); // coverage:ignore-line

  /// Calculates the Root Mean Square (RMS) amplitude of a 16-bit Linear PCM
  /// little-endian byte buffer.
  ///
  /// Returns a normalized value between `0.0` (silence) and `1.0` (peak volume).
  static double calculateRms(Uint8List pcmBytes) {
    if (pcmBytes.isEmpty || pcmBytes.length < 2) return 0.0;

    final sampleCount = pcmBytes.length ~/ 2;
    final byteData = ByteData.sublistView(pcmBytes);

    double sumSquares = 0.0;
    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      sumSquares += sample * sample;
    }

    final meanSquare = sumSquares / sampleCount;
    final rms = math.sqrt(meanSquare);

    // 16-bit signed integer max value is 32768.
    return (rms / 32768.0).clamp(0.0, 1.0);
  }

  /// Calculates the peak absolute amplitude of a 16-bit Linear PCM
  /// little-endian byte buffer.
  ///
  /// Returns a normalized value between `0.0` and `1.0`.
  static double calculatePeak(Uint8List pcmBytes) {
    if (pcmBytes.isEmpty || pcmBytes.length < 2) return 0.0;

    final sampleCount = pcmBytes.length ~/ 2;
    final byteData = ByteData.sublistView(pcmBytes);

    int maxSample = 0;
    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little).abs();
      if (sample > maxSample) {
        maxSample = sample;
      }
    }

    return (maxSample / 32768.0).clamp(0.0, 1.0);
  }

  /// Calculates the sound pressure level in decibels (dB FS) of a 16-bit
  /// Linear PCM little-endian byte buffer.
  ///
  /// Returns a value typically between [minDb] (default -96.0 dB) and `0.0 dB`.
  static double calculateDecibels(
    Uint8List pcmBytes, {
    double minDb = -96.0,
  }) {
    final rms = calculateRms(pcmBytes);
    if (rms <= 0.00001) return minDb;

    final db = 20.0 * (math.log(rms) / math.ln10);
    return db.clamp(minDb, 0.0);
  }

  /// Converts a normalized amplitude (0.0 to 1.0) into a logarithmic
  /// visual scale (0.0 to 1.0) for more natural and dynamic visualizer bars.
  static double toVisualScale(
    double normalizedAmplitude, {
    double factor = 2.0,
  }) {
    if (normalizedAmplitude <= 0.0) return 0.0;
    return math.pow(normalizedAmplitude.clamp(0.0, 1.0), 1.0 / factor).toDouble().clamp(0.0, 1.0);
  }

  /// Returns `true` if the 16-bit PCM buffer's decibel level is below
  /// [thresholdDb] (useful as a lightweight client-side silence / energy gate).
  static bool isSilence(
    Uint8List pcmBytes, {
    double thresholdDb = -45.0,
  }) {
    return calculateDecibels(pcmBytes) <= thresholdDb;
  }

  /// Downmixes 16-bit Little-Endian stereo PCM (2 channels) into 16-bit mono PCM (1 channel)
  /// by averaging the left and right channels per frame.
  static Uint8List stereoToMonoPcm16(Uint8List stereoPcmBytes) {
    final frameCount = stereoPcmBytes.length ~/ 4;
    if (frameCount <= 0) return Uint8List(0);

    final src = ByteData.sublistView(stereoPcmBytes);
    final dstBytes = Uint8List(frameCount * 2);
    final dst = ByteData.sublistView(dstBytes);

    for (int i = 0; i < frameCount; i++) {
      final left = src.getInt16(i * 4, Endian.little);
      final right = src.getInt16(i * 4 + 2, Endian.little);
      final mono = ((left + right) ~/ 2).clamp(-32768, 32767);
      dst.setInt16(i * 2, mono, Endian.little);
    }
    return dstBytes;
  }

  /// Upmixes 16-bit Little-Endian mono PCM (1 channel) into 16-bit stereo PCM (2 channels)
  /// by duplicating each mono sample across left and right channels.
  static Uint8List monoToStereoPcm16(Uint8List monoPcmBytes) {
    final sampleCount = monoPcmBytes.length ~/ 2;
    if (sampleCount <= 0) return Uint8List(0);

    final src = ByteData.sublistView(monoPcmBytes);
    final dstBytes = Uint8List(sampleCount * 4);
    final dst = ByteData.sublistView(dstBytes);

    for (int i = 0; i < sampleCount; i++) {
      final sample = src.getInt16(i * 2, Endian.little);
      dst.setInt16(i * 4, sample, Endian.little);
      dst.setInt16(i * 4 + 2, sample, Endian.little);
    }
    return dstBytes;
  }

  /// Resamples 16-bit Little-Endian mono PCM audio from [fromSampleRate] to
  /// [toSampleRate] using linear interpolation.
  ///
  /// Useful when hardware microphones capture at `48000` Hz or `44100` Hz and
  /// need to be converted to Gemini Live's `16000` Hz input format, or when
  /// converting `24000` Hz Gemini speech to `48000` Hz output.
  static Uint8List resamplePcm16Mono(
    Uint8List pcmBytes, {
    required int fromSampleRate,
    required int toSampleRate,
  }) {
    assert(fromSampleRate > 0 && toSampleRate > 0);
    if (pcmBytes.length < 2) return Uint8List(0);
    if (fromSampleRate == toSampleRate) return Uint8List.fromList(pcmBytes);

    final inSamples = pcmBytes.length ~/ 2;
    final outSamples = ((inSamples * toSampleRate) / fromSampleRate).round();
    if (outSamples <= 0) return Uint8List(0);

    final src = ByteData.sublistView(pcmBytes);
    final dstBytes = Uint8List(outSamples * 2);
    final dst = ByteData.sublistView(dstBytes);
    final ratio = fromSampleRate / toSampleRate;

    for (int i = 0; i < outSamples; i++) {
      final srcPos = i * ratio;
      final index0 = srcPos.floor().clamp(0, inSamples - 1);
      final index1 = (index0 + 1).clamp(0, inSamples - 1);
      final frac = srcPos - index0;

      final s0 = src.getInt16(index0 * 2, Endian.little);
      final s1 = src.getInt16(index1 * 2, Endian.little);
      final interpolated = (s0 + (s1 - s0) * frac).round().clamp(-32768, 32767);
      dst.setInt16(i * 2, interpolated, Endian.little);
    }

    return dstBytes;
  }
}
