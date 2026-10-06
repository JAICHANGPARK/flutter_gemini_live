import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Wraps the `record` plugin: device discovery and 16 kHz PCM16 mic streaming.
class VisionCallMicService {
  static const sampleRate = 16000;

  final AudioRecorder _recorder = AudioRecorder();

  Future<List<InputDevice>> listInputDevices() => _recorder.listInputDevices();

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Whether platform voice processing (AGC / AEC / NS) is enabled.
  bool get voiceProcessingEnabled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<Stream<Uint8List>> startStream({
    InputDevice? device,
    required bool enableVoiceProc,
  }) {
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

  Future<void> resume() => _recorder.resume();

  void dispose() {
    unawaited(_recorder.stop());
    unawaited(_recorder.dispose());
  }
}
