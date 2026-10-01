import 'dart:math' as math;
import 'dart:typed_data';

/// Utilities for working with raw PCM audio data in Gemini Live sessions.
///
/// Gemini Live communicates using 16-bit linear PCM Little-Endian audio
/// (typically 16kHz for input and 24kHz for output). This utility provides
/// high-performance calculations for amplitude, RMS, and decibel levels
/// suitable for audio waveform visualizations.
class GeminiLiveAudioUtils {
  GeminiLiveAudioUtils._();

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
}
