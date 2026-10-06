import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Wraps the `record` plugin: device discovery and 16 kHz PCM16 mic streaming.
class MathTutorMicService {
  static const sampleRate = 16000;

  final AudioRecorder _recorder = AudioRecorder();

  Future<List<InputDevice>> listInputDevices() => _recorder.listInputDevices();

  /// Starts streaming PCM16 chunks, or returns `null` when the microphone
  /// permission is denied.
  Future<Stream<Uint8List>?> start({InputDevice? device}) async {
    if (!await _recorder.hasPermission()) {
      debugPrint('Microphone permission denied');
      return null;
    }

    final bool enableVoiceProc =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    debugPrint(
      '🎙️ Starting tutor mic stream (sampleRate: $sampleRate, device: ${device?.label ?? "default"}, voiceProc: $enableVoiceProc)...',
    );

    return _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        device: device,
        autoGain: enableVoiceProc,
        echoCancel: enableVoiceProc,
        noiseSuppress: enableVoiceProc,
        streamBufferSize: 2048,
      ),
    );
  }

  Future<void> stop() => _recorder.stop();

  void dispose() {
    unawaited(_recorder.stop());
    unawaited(_recorder.dispose());
  }
}
