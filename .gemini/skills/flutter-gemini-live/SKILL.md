---
name: flutter-gemini-live
description: Build real-time, multimodal streaming applications in Flutter using the Google Gemini Live API without Firebase dependencies. Use when implementing voice/text/video live chat, function calling, audio transcription, live translation, session resumption, Google Maps grounding, Live Music generation (Lyria Realtime), ephemeral client auth tokens, or pre-built Flutter UI widgets. Also use whenever a Dart/Flutter project depends on the `gemini_live` package or asks for Gemini Live without `firebase_ai`.
---

# Flutter Gemini Live Agent Skill

This skill guides AI coding assistants (**Claude Code**, **Gemini CLI / Antigravity**, **OpenAI Codex**, **Cursor**, **Windsurf**, and **GitHub Copilot**) in using the `gemini_live` Flutter package to build production-grade, low-latency, multimodal applications connected directly to Google's Gemini Live API via WebSockets.

---

## 📦 Setup

```bash
flutter pub add gemini_live
# Typical companions for voice apps (mic capture + low-latency PCM playback):
flutter pub add record flutter_soloud
```

Platform permissions required for microphone input:
- **Android** `AndroidManifest.xml`: `<uses-permission android:name="android.permission.RECORD_AUDIO" />` and `android.permission.INTERNET`.
- **iOS** `Info.plist`: `NSMicrophoneUsageDescription` (and `NSCameraUsageDescription` for video).
- **macOS** entitlements: `com.apple.security.device.audio-input` and `com.apple.security.network.client`.

---

## ⛔ Do NOT

- Do **not** add `firebase_ai`, `firebase_core`, or `google_generative_ai` for Live features. `gemini_live` replaces them.
- Do **not** invent model IDs. Use only the IDs listed below.
- Do **not** use `gemini-omni-*` (video generation), `*-tts` (text-to-speech), or `lyria-3*` models with `genAI.live.connect` / `genAI.live.music.connect`. They are Interactions API models, not Live models. The matching `LiveModels` / `LiveMusicModels` constants are deprecated.
- Do **not** ship a raw API key in a production client. Mint an ephemeral token on a backend (see *Ephemeral Client Auth Tokens*).
- Do **not** assume `GeminiLiveSessionController` captures the microphone or plays audio. It only streams data; you wire up `record` (input) and a PCM player (output) yourself.
- Do **not** send audio in any format other than 16-bit PCM, 16 kHz, mono.

---

## 💡 Key Package Principles

1. **Zero Firebase Dependency**: Direct WebSocket streaming connection to Google Generative Language endpoints (`wss://generativelanguage.googleapis.com/ws/...`) without Firebase or Cloud Functions.
2. **Supported Models**:
   - `gemini-3.8-live` (**Default Stable**): Low-latency voice/multimodal dialogue, default async non-blocking tools.
   - `gemini-3.8-live-extended-thinking` (**Stable Reasoning**): High-reasoning voice/multimodal interactions with background thinking thoughts.
   - `models/lyria-realtime-exp`: Bidirectional Realtime Music generation via `genAI.live.music`.
   - `gemini-3.5-live-translate-preview` (`LiveModels.gemini35LiveTranslatePreview`): Speech-to-speech translation (use with `TranslationConfig`).
   - `gemini-3.1-flash-live-preview` & `gemini-2.5-flash-native-audio-preview-12-2025`: Preview models.
3. **Response Modalities**: `Modality.TEXT`, `Modality.AUDIO`, and `Modality.VIDEO`.
4. **Audio Standards**:
   - Input: 16-bit linear PCM, 16,000 Hz, mono.
   - Output: 16-bit linear PCM, 24,000 Hz, mono (Music: 48,000 Hz stereo).

---

## 🚀 Quickstart 1: High-Level UI with `GeminiLiveSessionController` (Recommended)

For Flutter UI applications, use `GeminiLiveSessionController`. It extends `ChangeNotifier` to manage connection lifecycles, transcription timelines, barge-in state, audio streams for visualizers, and token accounting.

> The controller does **not** record the microphone or play audio. Feed mic PCM into `sendRealtimeAudio()` and play `incomingAudioStream` yourself, as shown below.

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

class LiveChatWidget extends StatefulWidget {
  const LiveChatWidget({super.key});

  @override
  State<LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<LiveChatWidget> {
  late final GoogleGenAI _genAI;
  late final GeminiLiveSessionController _controller;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<Uint8List>? _speakerSub;
  AudioSource? _playbackSource;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY');
    _controller = GeminiLiveSessionController(liveService: _genAI.live);
    _controller.addListener(_onControllerChanged);
  }

  // Barge-in: stop local playback as soon as the user interrupts the model.
  void _onControllerChanged() {
    if (_controller.isInterrupted) _resetPlayback();
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) return;
    setState(() => _connecting = true);
    try {
      await _controller.connect(
        LiveConnectParameters(
          model: 'gemini-3.8-live',
          config: GenerationConfig(
            responseModalities: [Modality.AUDIO],
            speechConfig: SpeechConfig(
              voiceConfig: VoiceConfig(
                prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: 'Puck'),
              ),
            ),
          ),
          inputAudioTranscription: AudioTranscriptionConfig(
            languageCodes: ['en-US', 'ko-KR'],
          ),
          outputAudioTranscription: AudioTranscriptionConfig(),
          callbacks: LiveCallbacks(
            onError: (e, st) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _connecting = false);
    }

    // Output: 24 kHz 16-bit mono PCM -> SoLoud buffer stream.
    await SoLoud.instance.init();
    _speakerSub = _controller.incomingAudioStream.listen((pcm) {
      _playbackSource ??= SoLoud.instance.setBufferStream(
        sampleRate: 24000,
        channels: Channels.mono,
        format: BufferType.s16le,
        bufferingType: BufferingType.released,
      );
      final source = _playbackSource!;
      if (SoLoud.instance.getActiveVoiceCount() == 0) {
        SoLoud.instance.play(source);
      }
      SoLoud.instance.addAudioDataStream(source, pcm);
    });

    // Input: 16 kHz 16-bit mono PCM from the microphone.
    final micStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _micSub = micStream.listen(_controller.sendRealtimeAudio);
  }

  void _resetPlayback() {
    final source = _playbackSource;
    if (source != null) SoLoud.instance.disposeSource(source);
    _playbackSource = null;
  }

  Future<void> _stop() async {
    await _micSub?.cancel();
    await _speakerSub?.cancel();
    await _recorder.stop();
    _resetPlayback();
    _controller.stopUserSpeaking();
    await _controller.disconnect();
  }

  @override
  void dispose() {
    _stop();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _recorder.dispose();
    _genAI.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gemini Live Assistant'),
            actions: [
              GeminiLiveUsageBadge(tracker: _controller.tokenTracker),
              const SizedBox(width: 8),
              GeminiLiveStatusBadge.fromFlags(
                isConnected: _controller.isConnected,
                isConnecting: _connecting,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              GeminiLiveWaveform(
                audioStream: _controller.incomingAudioStream,
                barCount: 28,
                height: 64,
                color: Theme.of(context).colorScheme.primary,
                enableIdleBreathing: true,
              ),
              const Spacer(),
              if (_controller.latestTranscript != null)
                GeminiLiveCaptionBubble(
                  text: _controller.latestTranscript!,
                  speaker: _controller.latestTranscriptRole == 'user' ? 'You' : 'Gemini',
                  isStreaming: _controller.isModelSpeaking,
                ),
              const Spacer(),
              Center(
                child: GeminiLiveMicButton(
                  isRecording: _controller.isConnected,
                  onPressed: _controller.isConnected ? _stop : _start,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 🛠️ Quickstart 2: Low-Level Session (`genAI.live.connect()`)

Use direct `LiveSession` when implementing background services, custom pipelines, or headless CLI/embedded tools.

### Step 1: Initialize Client & Connect

```dart
import 'package:gemini_live/gemini_live.dart';

final genAI = GoogleGenAI(
  apiKey: 'YOUR_GEMINI_API_KEY',
  logger: print, // Optional: logs incoming/outgoing WebSocket JSON
);

LiveSession? session;

Future<void> connectLive() async {
  session = await genAI.live.connect(
    LiveConnectParameters(
      model: 'gemini-3.8-live',
      config: GenerationConfig(
        responseModalities: [Modality.AUDIO],
      ),
      callbacks: LiveCallbacks(
        onOpen: () => print('WebSocket opened'),
        onMessage: (LiveServerMessage message) => handleServerMessage(message),
        onError: (e, st) => print('Live error: $e'),
        onClose: (code, reason) => print('Closed: $code - $reason'),
      ),
    ),
  );
}
```

### Step 2: Handle Incoming `LiveServerMessage`

```dart
void handleServerMessage(LiveServerMessage message) {
  // 1. Text chunks (non-thought streaming output)
  if (message.text != null && message.text!.isNotEmpty) {
    print('Model text: ${message.text}');
  }

  // 2. Audio chunks (Base64 PCM 24kHz 16-bit mono)
  if (message.data != null) {
    final pcmBytes = base64Decode(message.data!);
    audioOutputBuffer.add(pcmBytes);
  }

  // 3. User barge-in interruption (Clear audio playback buffer immediately!)
  if (message.serverContent?.interrupted ?? false) {
    audioOutputBuffer.clear();
    print('Model was interrupted by user speech');
  }

  // 4. Function / Tool Calls
  if (message.toolCall != null) {
    handleToolCalls(message.toolCall!.functionCalls);
  }

  // 5. Session Resumption Token Update
  if (message.sessionResumptionUpdate != null) {
    final handle = message.sessionResumptionUpdate!.newHandle;
    saveSessionHandleLocally(handle);
  }

  // 6. Session Expiration Warning
  if (message.goAway != null) {
    print('Warning: Session expiring in ${message.goAway!.timeRemaining}s');
  }
}
```

### Step 3: Stream Client Real-Time Inputs

```dart
// Send text turn
session?.sendText('Summarize today\'s tech headlines.');

// Send microphone audio bytes (PCM 16-bit 16kHz mono)
session?.sendAudio(pcmAudio16kHzBytes);

// Send camera frame bytes
session?.sendVideo(jpegFrameBytes, mimeType: 'image/jpeg');

// Signal speech end when in manual VAD mode
session?.sendActivityEnd();
```

---

## ⚙️ Advanced Feature Patterns

### 1. Function Calling & Tools

With `GeminiLiveSessionController`, reply with `controller.sendToolResponses([...])` instead.

```dart
LiveConnectParameters(
  model: 'gemini-3.8-live',
  tools: [
    Tool(
      functionDeclarations: [
        FunctionDeclaration(
          name: 'get_device_battery',
          description: 'Get the current battery percentage and charging state',
          // `parameters` is a plain JSON Schema map (OpenAPI subset).
          parameters: {
            'type': 'OBJECT',
            'properties': {
              'deviceId': {'type': 'STRING'},
            },
            'required': ['deviceId'],
          },
        ),
      ],
    ),
  ],
  callbacks: LiveCallbacks(
    onMessage: (message) {
      if (message.toolCall != null) {
        for (final call in message.toolCall!.functionCalls ?? const <FunctionCall>[]) {
          if (call.name == 'get_device_battery') {
            session?.sendFunctionResponse(
              id: call.id!, // Echo the call id back; it is required.
              name: call.name!,
              response: {'percentage': 85, 'isCharging': true},
            );
          }
        }
      }
    },
  ),
);
```

### 2. Live Music Generation (`models/lyria-realtime-exp`)

Generate continuous, steerable real-time music via `genAI.live.music`:

```dart
final musicSession = await genAI.live.music.connect(
  LiveMusicConnectParameters(
    model: 'models/lyria-realtime-exp',
    callbacks: LiveMusicCallbacks(
      onMessage: (LiveMusicServerMessage message) {
        if (message.audioChunk != null) {
          final audioBytes = message.audioChunk!.bytes; // 48kHz stereo PCM
          playMusicPcm(audioBytes);
        }
      },
    ),
  ),
);

// Dynamic prompt steering with weights
musicSession.setWeightedPrompts([
  WeightedPrompt(text: 'ambient lofi hip hop', weight: 1.0),
  WeightedPrompt(text: 'gentle rain sounds', weight: 0.4),
]);

// Configure musical attributes
musicSession.setMusicGenerationConfig(
  LiveMusicGenerationConfig(
    bpm: 90,
    scale: Scale.C_MAJOR_A_MINOR,
    temperature: 0.8,
  ),
);

// Playback control
musicSession.play();
// musicSession.pause();
// musicSession.stop();
```

### 3. Ephemeral Client Auth Tokens (`genAI.authTokens`)

Protect master API keys by minting short-lived, locked tokens for mobile clients:

```dart
// Server or backend mints token:
final token = await genAI.authTokens.create(
  CreateAuthTokenConfig(
    expireTime: DateTime.now().add(const Duration(minutes: 30)).toUtc().toIso8601String(),
    uses: 1,
    liveConnectConstraints: LiveConnectConstraints(
      model: 'models/gemini-3.8-live',
      config: GenerationConfig(responseModalities: [Modality.AUDIO]),
    ),
    lockAdditionalFields: ['speechConfig'],
  ),
);

// Client connects safely using ephemeral token (v1alpha):
final clientGenAI = GoogleGenAI(
  apiKey: token.name!, // Format: auth_tokens/...
  apiVersion: 'v1alpha',
);
final clientSession = await clientGenAI.live.connect(...);
```

### 4. Real-time Speech-to-Speech Translation

Use the dedicated translate model and put `translationConfig` inside `GenerationConfig`:

```dart
LiveConnectParameters(
  model: 'gemini-3.5-live-translate-preview',
  config: GenerationConfig(
    responseModalities: [Modality.AUDIO],
    translationConfig: TranslationConfig(
      targetLanguageCode: 'es', // BCP-47 target language
      echoTargetLanguage: false,
    ),
  ),
  inputAudioTranscription: AudioTranscriptionConfig(),
  outputAudioTranscription: AudioTranscriptionConfig(),
  callbacks: LiveCallbacks(...),
)
```

### 5. Audio Transcription with `languageCodes` & `customVocabulary`

```dart
LiveConnectParameters(
  model: 'gemini-3.8-live',
  inputAudioTranscription: AudioTranscriptionConfig(
    languageCodes: ['en-US', 'ja-JP', 'ko-KR'],
    customVocabulary: ['Flutter', 'Gemini', 'Dart', 'BLoC'],
  ),
  outputAudioTranscription: AudioTranscriptionConfig(),
  callbacks: LiveCallbacks(...),
)
```

### 6. Google Maps Grounding

```dart
LiveConnectParameters(
  model: 'gemini-3.8-live',
  tools: [
    Tool(
      googleMaps: GoogleMaps(
        groundingTypes: ['places', 'routing'],
      ),
    ),
  ],
  callbacks: LiveCallbacks(...),
)
```

### 7. Session Resumption

```dart
// Resume previous session using persisted handle
LiveConnectParameters(
  model: 'gemini-3.8-live',
  sessionResumption: SessionResumptionConfig(
    handle: savedSessionHandle,
  ),
  callbacks: LiveCallbacks(...),
)
```

---

## 🎨 Pre-Built Flutter Widgets & Helpers

| Component | Class | Description |
|---|---|---|
| **Audio Visualizer** | `GeminiLiveWaveform` | Animated audio visualizer bars/sine with capsule pills, organic idle breathing, and raw PCM / amplitude stream support. |
| **Subtitle Bubble** | `GeminiLiveCaptionBubble` | Frosted glass (`BackdropFilter` blur), speaker tags (`user`/`model`), subtle tone chips, and pulsing streaming dot. |
| **Microphone Button** | `GeminiLiveMicButton` | Material 3 mic toggle with ripple rings. Params: `isRecording` (required), `onPressed`, `onLongPressStart`/`onLongPressEnd` (push-to-talk). It does not record audio itself. |
| **Status Badge** | `GeminiLiveStatusBadge` | Status pill for `GeminiLiveSessionState` (`disconnected`, `connecting`, `connected`, `inProgress`). Use `GeminiLiveStatusBadge.fromFlags(isConnected:, isConnecting:)` to build it from booleans. |
| **Voice Activity** | `GeminiLiveVoiceIndicator` | Dual-harmonic wave visualizer reflecting voice activity. |
| **Token Monitor** | `GeminiLiveUsageBadge` | Real-time token usage badge and breakdown modal dialog via `GeminiTokenUsageTracker`. |
| **Audio Analysis** | `GeminiLiveAudioUtils` | Utilities to calculate RMS amplitude, peak amplitude, dBFS decibels, and logarithmic visual scaling from 16-bit PCM buffers. |

---

## 🚨 Error Handling Rules for AI Agents

- **`TimeoutException`** (the package's own class, not `dart:async`): Setup handshake exceeded `setupTimeout` (default 10 s). Check API key validity, model ID, network proxies, and firewall rules.
- **`UnsupportedError`**: Thrown at connect time for parameters the Gemini API (non-Vertex) rejects: `sessionResumption.transparent`, `explicitVadSignal`, `SafetySetting.method`, `Tool.exaAiSearch`, `Tool.parallelAiSearch`. Remove them.
- **`ArgumentError`**: Thrown if a function response lacks `id`, `name`, or `response`, or a realtime blob has an unsupported MIME type.
- **`onClose(code, reason)`**: Always surface `reason` to the user/log. Quota, invalid key, and invalid model errors arrive as a close reason string.
- **Close Code `1006`**: Abnormal WebSocket termination. Reconnect with exponential backoff, passing the last `sessionResumptionUpdate.newHandle` to resume.
- **`goAway`**: The server will close soon. Reconnect proactively with the saved resumption handle.
- **Barge-in Interruption**: Always clear/stop local audio playback buffers immediately when `message.serverContent?.interrupted == true` or `controller.isInterrupted` changes to prevent acoustic feedback.
