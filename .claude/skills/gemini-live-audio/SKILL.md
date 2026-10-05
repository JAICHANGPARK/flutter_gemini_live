---
name: gemini-live-audio
description: Implement real-time bidirectional voice chat, microphone capture, audio playback, voice persona selection, voice activity detection (VAD), and speech transcription in Flutter using Gemini Live API. Use when configuring audio parameters, handling barge-in interruptions, setting GeminiLiveVoice personas, or wiring mic input (16kHz PCM) and speaker output (24kHz PCM).
---

# Gemini Live Audio Streaming Skill

This skill provides production-ready guidance for implementing real-time, low-latency voice streaming with the Gemini Live API in Flutter.

---

## 🎧 Hardware & Audio Specifications

The Gemini Live API requires strict audio formatting:

| Direction | Format | Sample Rate | Channels | Bit Depth | Target Companion Package |
|---|---|---|---|---|---|
| **Microphone Input** | Linear PCM (`audio/pcm`) | **16,000 Hz** (16 kHz) | 1 (Mono) | 16-bit signed LE | [`record`](https://pub.dev/packages/record) `^5.2.0` |
| **Speaker Output** | Linear PCM (`audio/pcm`) | **24,000 Hz** (24 kHz) | 1 (Mono) | 16-bit signed LE | [`flutter_soloud`](https://pub.dev/packages/flutter_soloud) `^3.4.0` |

---

## ⚙️ Platform Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS / macOS (`ios/Runner/Info.plist` & `macos/Runner/Info.plist`)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access for real-time voice conversations with Gemini Live.</string>
```

---

## 🎙️ Core Implementation: High-Level Voice Pipeline

```dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

class LiveVoiceManager {
  final GeminiLiveSessionController controller;
  final AudioRecorder _recorder = AudioRecorder();
  SoundHandle? _playbackHandle;
  AudioSource? _bufferSource;
  StreamSubscription<Uint8List>? _micSub;

  LiveVoiceManager({required this.controller});

  Future<void> startVoiceSession({
    GeminiLiveVoice voice = GeminiLiveVoice.puck,
    List<String> transcriptionLanguages = const ['en-US', 'ko-KR'],
  }) async {
    // 1. Verify Microphone Permission
    if (!await _recorder.hasPermission()) {
      throw StateError('Microphone permission denied');
    }

    // 2. Initialize SoLoud Audio Output Engine (24 kHz, 16-bit mono PCM)
    await SoLoud.instance.init();
    _bufferSource = SoLoud.instance.setBufferStream(
      sampleRate: 24000,
      channels: Channels.mono,
      format: BufferType.s16le,
      bufferingType: BufferingType.released,
    );
    _playbackHandle = await SoLoud.instance.play(_bufferSource!);

    // 3. Connect Gemini Live Session
    await controller.connect(
      LiveConnectParameters(
        model: LiveModels.gemini38Live,
        config: GenerationConfig(
          responseModalities: [Modality.AUDIO],
          // Strongly typed voice persona
          speechConfig: SpeechConfig.fromLiveVoice(voice),
        ),
        inputAudioTranscription: AudioTranscriptionConfig(
          languageCodes: transcriptionLanguages,
          customVocabulary: ['Flutter', 'Gemini', 'Dart'],
        ),
        outputAudioTranscription: AudioTranscriptionConfig(),
      ),
    );

    // 4. Handle Incoming Model Speech & Barge-in Interruptions
    controller.incomingAudioStream.listen((pcmChunk) {
      if (_bufferSource != null) {
        SoLoud.instance.addAudioDataStream(_bufferSource!, pcmChunk);
      }
    });

    // CRITICAL: Immediately clear audio queue when user interrupts the model
    controller.addListener(() {
      if (controller.isInterrupted && _bufferSource != null) {
        SoLoud.instance.resetBufferStream(_bufferSource!);
      }
    });

    // 5. Start Real-time Mic Capture (16 kHz, 16-bit mono PCM)
    final micStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
      ),
    );

    _micSub = micStream.listen((pcmBytes) {
      controller.sendRealtimeAudio(pcmBytes);
    });
  }

  Future<void> dispose() async {
    await _micSub?.cancel();
    await _recorder.dispose();
    if (_bufferSource != null) {
      SoLoud.instance.resetBufferStream(_bufferSource!);
    }
    await controller.disconnect();
  }
}
```

---

## 🗣️ Voice Persona Configuration (`GeminiLiveVoice`)

Use the strongly-typed `GeminiLiveVoice` enum to choose from Google's official 30 voice personas:

```dart
// Recommended: Type-safe factory with language code
final speechConfig = SpeechConfig.fromLiveVoice(
  GeminiLiveVoice.charon,
  languageCode: 'en-US',
);

// Convenience enum helper
final speechConfig = GeminiLiveVoice.kore.toSpeechConfig();

// Inspecting active voice properties
final active = speechConfig.liveVoice;
if (active != null) {
  print('Name: ${active.voiceName}');
  print('Tone: ${active.tone}');     // e.g. "Deep, calm, and resonant"
  print('Gender: ${active.gender}'); // e.g. "Male / Deep"
}
```

### Popular Voice Personas
- `GeminiLiveVoice.puck`: Upbeat, playful, expressive (Default)
- `GeminiLiveVoice.charon`: Deep, informative, resonant
- `GeminiLiveVoice.kore`: Warm, soothing, empathetic
- `GeminiLiveVoice.fenrir`: Authoritative, excitable, strong
- `GeminiLiveVoice.aoede`: Breezy, gentle, melodic
- `GeminiLiveVoice.leda`: Youthful, articulate, bright
- `GeminiLiveVoice.orus`: Steady, direct, composed
- `GeminiLiveVoice.zephyr`: Crisp, friendly, modern

---

## 🔇 Voice Activity Detection (VAD) & Manual Control

### Automatic VAD (Default)
The Gemini Live model automatically listens and detects the beginning and end of speech turns.

### Manual Push-to-Talk (PTT)
To control turns manually or override VAD:

```dart
// User presses mic button
void onPushToTalkStart() {
  controller.sendStartActivityRealtime();
}

// User releases mic button
void onPushToTalkEnd() {
  controller.sendStopActivityRealtime();
}
```

---

## 🚨 Critical Audio Rules & Anti-Patterns

1. **NEVER accumulate audio on barge-in:**
   When `controller.isInterrupted` becomes `true` (or `serverContent.interrupted == true`), you MUST immediately flush local playback buffers (`SoLoud.instance.resetBufferStream(...)`). Failing to do so causes audio collisions and acoustic feedback.
2. **Never send 44.1kHz or 48kHz audio to the mic stream:**
   The Gemini Live input endpoint expects 16,000 Hz 16-bit PCM. Sending higher sample rates without downsampling will distort the speech and cause poor recognition.
3. **Always enable hardware echo cancellation:**
   Ensure `echoCancel: true` is configured in `RecordConfig` when playing model speech through the device speaker while the microphone is hot.
