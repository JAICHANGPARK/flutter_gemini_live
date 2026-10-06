import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Wraps the `record` plugin: device discovery and 16 kHz PCM16 mic streaming.
class TranslationMicService {
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
        // 통화용 오디오 소스 + 통화 모드: OS AEC가 스피커 출력을 기준 신호로 삼아
        // 마이크로 재유입되는 번역 음성을 제거합니다.
        androidConfig: const AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceCommunication,
          audioManagerMode: AudioManagerMode.modeInCommunication,
          speakerphone: true,
        ),
      ),
    );
  }

  Future<void> stop() => _recorder.stop();

  void dispose() {
    unawaited(_recorder.dispose());
  }
}
