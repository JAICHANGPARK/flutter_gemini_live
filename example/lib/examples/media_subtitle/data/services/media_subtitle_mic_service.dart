import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Wraps the `record` plugin: device discovery and 16 kHz PCM16 streaming.
class MediaSubtitleMicService {
  static const int sampleRate = 16000;

  final AudioRecorder _recorder = AudioRecorder();

  Future<List<InputDevice>> listInputDevices() => _recorder.listInputDevices();

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<Stream<Uint8List>> startStream({InputDevice? device}) {
    final bool enableVoiceProc =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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

  Future<void> dispose() => _recorder.dispose();
}
