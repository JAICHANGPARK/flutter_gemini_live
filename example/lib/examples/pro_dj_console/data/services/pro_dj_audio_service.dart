import 'dart:math' as math;
import 'dart:typed_data';

import 'package:example/soloud_live_audio_player.dart';

/// Plays the generated 48 kHz stereo PCM music stream through SoLoud
/// with real-time 3-band EQ, soft-knee compression, and stereo balance DSP.
class ProDjAudioService {
  late final SoloudLiveAudioPlayer _audioPlayer;

  double _lpLowL = 0.0;
  double _lpLowR = 0.0;
  double _lpMidL = 0.0;
  double _lpMidR = 0.0;

  ProDjAudioService() {
    _audioPlayer = SoloudLiveAudioPlayer(sampleRate: 48000, channels: 2);
  }

  /// Not awaited by the caller (matches the original fire-and-forget init).
  void init() {
    _audioPlayer.init();
  }

  Uint8List appendPcmBytes(
    Uint8List bytes, {
    double masterGain = 1.0,
    double compAmount = 0.35,
    double lowEq = 0.5,
    double midEq = 0.5,
    double highEq = 0.5,
    double pan = 0.5,
  }) {
    if (bytes.length < 4) {
      _audioPlayer.appendPcmBytes(bytes);
      return bytes;
    }

    final frameCount = bytes.length ~/ 4;
    final out = Uint8List(frameCount * 4);
    final inData = ByteData.sublistView(bytes);
    final outData = ByteData.sublistView(out);

    final lowGain = math.pow(10.0, ((lowEq - 0.5) * 24.0) / 20.0).toDouble();
    final midGain = math.pow(10.0, ((midEq - 0.5) * 20.0) / 20.0).toDouble();
    final highGain = math.pow(10.0, ((highEq - 0.5) * 24.0) / 20.0).toDouble();

    final panAngle = pan.clamp(0.0, 1.0) * (math.pi / 2.0);
    final panL = math.cos(panAngle) * 1.4142;
    final panR = math.sin(panAngle) * 1.4142;
    final compDrive = 1.0 + compAmount.clamp(0.0, 1.0) * 1.6;
    final master = masterGain.clamp(0.0, 1.5);

    const aLow = 0.032;
    const aMid = 0.285;

    for (var i = 0; i < frameCount; i++) {
      final byteOffset = i * 4;
      final rawL = inData.getInt16(byteOffset, Endian.little) / 32768.0;
      final rawR = inData.getInt16(byteOffset + 2, Endian.little) / 32768.0;

      _lpLowL += aLow * (rawL - _lpLowL);
      _lpLowR += aLow * (rawR - _lpLowR);
      _lpMidL += aMid * (rawL - _lpMidL);
      _lpMidR += aMid * (rawR - _lpMidR);

      final lowBandL = _lpLowL;
      final lowBandR = _lpLowR;
      final midBandL = _lpMidL - _lpLowL;
      final midBandR = _lpMidR - _lpLowR;
      final highBandL = rawL - _lpMidL;
      final highBandR = rawR - _lpMidR;

      var eqL =
          lowBandL * lowGain + midBandL * midGain + highBandL * highGain;
      var eqR =
          lowBandR * lowGain + midBandR * midGain + highBandR * highGain;

      if (compAmount > 0.02) {
        final dL = eqL * compDrive;
        final dR = eqR * compDrive;
        eqL = dL / (1.0 + 0.55 * dL.abs());
        eqR = dR / (1.0 + 0.55 * dR.abs());
      }

      final outL = (eqL * panL * master * 32767.0).round().clamp(-32768, 32767);
      final outR = (eqR * panR * master * 32767.0).round().clamp(-32768, 32767);

      outData.setInt16(byteOffset, outL, Endian.little);
      outData.setInt16(byteOffset + 2, outR, Endian.little);
    }

    _audioPlayer.appendPcmBytes(out);
    return out;
  }

  void clear() {
    _lpLowL = 0.0;
    _lpLowR = 0.0;
    _lpMidL = 0.0;
    _lpMidR = 0.0;
    _audioPlayer.clear();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
