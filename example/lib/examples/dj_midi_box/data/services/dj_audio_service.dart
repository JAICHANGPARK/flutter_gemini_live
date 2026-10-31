import 'dart:math' as math;
import 'dart:typed_data';

import 'package:example/soloud_live_audio_player.dart';

/// Plays the Lyria RealTime 48kHz stereo PCM stream with a real-time
/// 3-Band EQ / Compressor / Stereo Pan / Master Fader DSP stage and exposes
/// live post-DSP FFT & waveform data for the visualizer.
class DjAudioService {
  late final SoloudLiveAudioPlayer _audioPlayer;

  // 1-pole filter state for L and R channels (48kHz stereo)
  double _lpLowL = 0.0;
  double _lpLowR = 0.0;
  double _lpHighL = 0.0;
  double _lpHighR = 0.0;

  DjAudioService() {
    _audioPlayer = SoloudLiveAudioPlayer(sampleRate: 48000, channels: 2);
  }

  /// The wrapped player (the visualizer polls FFT / waveform from it).
  SoloudLiveAudioPlayer get player => _audioPlayer;

  Future<void> init() => _audioPlayer.init();

  /// Applies real-time 48kHz stereo 16-bit PCM hardware mixer DSP (GAIN, COMP,
  /// 3-Band EQ LOW/MID/HIGH, Stereo PAN, PHANTOM +48V exciter, and Master Fader)
  /// and queues the processed audio for playback.
  ///
  /// Returns the processed PCM bytes so VU/RMS meters reflect post-fader level.
  Uint8List appendPcmBytes(
    Uint8List bytes, {
    double masterGain = 1.0,
    double preGain = 0.5,
    double compAmount = 0.35,
    double lowEq = 0.5,
    double midEq = 0.5,
    double highEq = 0.5,
    double pan = 0.5,
    bool phantom48v = true,
  }) {
    if (bytes.length < 4) {
      _audioPlayer.appendPcmBytes(bytes);
      return bytes;
    }

    final frameCount = bytes.length ~/ 4;
    final outBytes = Uint8List(bytes.length);
    final inData = ByteData.sublistView(bytes);
    final outData = ByteData.sublistView(outBytes);

    // Convert normalized 0..1 knob positions to linear filter gains
    final drive = 0.65 + preGain * 0.95;
    final lowGain = math.pow(10.0, ((lowEq - 0.5) * 24.0) / 20.0).toDouble();
    final midGain = math.pow(10.0, ((midEq - 0.5) * 18.0) / 20.0).toDouble();
    final highBoostDb = (highEq - 0.5) * 24.0 + (phantom48v ? 1.5 : 0.0);
    final highGain = math.pow(10.0, highBoostDb / 20.0).toDouble();

    // Equal-power stereo pan law (0.0 = Left, 0.5 = Center, 1.0 = Right)
    final panClamped = pan.clamp(0.0, 1.0);
    final panL = math.cos(panClamped * math.pi * 0.5) * math.sqrt2;
    final panR = math.sin(panClamped * math.pi * 0.5) * math.sqrt2;

    // 1-pole crossover coefficients at 48kHz (~160Hz low, ~4.5kHz high)
    const alphaLow = 0.021;
    const alphaHigh = 0.44;

    for (var i = 0; i < frameCount; i++) {
      final offset = i * 4;
      final rawL = inData.getInt16(offset, Endian.little) / 32768.0;
      final rawR = inData.getInt16(offset + 2, Endian.little) / 32768.0;

      // 1. Preamp GAIN
      final inL = rawL * drive;
      final inR = rawR * drive;

      // 2. 3-Band Crossover (Low / Mid / High)
      _lpLowL += alphaLow * (inL - _lpLowL);
      _lpLowR += alphaLow * (inR - _lpLowR);
      _lpHighL += alphaHigh * (inL - _lpHighL);
      _lpHighR += alphaHigh * (inR - _lpHighR);

      final bandLowL = _lpLowL;
      final bandLowR = _lpLowR;
      final bandHighL = inL - _lpHighL;
      final bandHighR = inR - _lpHighR;
      final bandMidL = _lpHighL - _lpLowL;
      final bandMidR = _lpHighR - _lpLowR;

      var eqL =
          bandLowL * lowGain + bandMidL * midGain + bandHighL * highGain;
      var eqR =
          bandLowR * lowGain + bandMidR * midGain + bandHighR * highGain;

      // 3. 1-Knob Soft-Knee Optical Compressor (COMP)
      if (compAmount > 0.05) {
        final k = 1.0 + compAmount * 2.2;
        eqL = (eqL * k) / (1.0 + (eqL * k).abs() * compAmount * 0.85);
        eqR = (eqR * k) / (1.0 + (eqR * k).abs() * compAmount * 0.85);
      }

      // 4. Stereo Pan & Master Fader Attenuation
      final outL = (eqL * panL * masterGain).clamp(-1.0, 1.0);
      final outR = (eqR * panR * masterGain).clamp(-1.0, 1.0);

      outData.setInt16(
        offset,
        (outL * 32767.0).round().clamp(-32768, 32767),
        Endian.little,
      );
      outData.setInt16(
        offset + 2,
        (outR * 32767.0).round().clamp(-32768, 32767),
        Endian.little,
      );
    }

    _audioPlayer.appendPcmBytes(outBytes);
    return outBytes;
  }

  void clear() {
    _lpLowL = 0.0;
    _lpLowR = 0.0;
    _lpHighL = 0.0;
    _lpHighR = 0.0;
    _audioPlayer.clear();
  }

  Future<void> dispose() => _audioPlayer.dispose();
}
