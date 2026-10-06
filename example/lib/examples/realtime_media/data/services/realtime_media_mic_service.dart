import 'dart:typed_data';

import 'package:record/record.dart';

/// Wraps the `record` plugin: 16 kHz PCM16 mic streaming.
class RealtimeMediaMicService {
  static const _audioSampleRate = 16000;

  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<bool> hasPermission() => _audioRecorder.hasPermission();

  Future<Stream<Uint8List>> startStream() {
    return _audioRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _audioSampleRate,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
        streamBufferSize: 2048,
      ),
    );
  }

  Future<void> stop() => _audioRecorder.stop();

  Future<void> dispose() => _audioRecorder.dispose();
}
