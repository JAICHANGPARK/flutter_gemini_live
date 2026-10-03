# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[English](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [한국어](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [日本語](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [简体中文](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- A Flutter package for the [Gemini Live API](https://ai.google.dev/gemini-api/docs/live), enabling real-time, multimodal conversations with Google's Gemini models.
- **Zero Firebase Dependency**: Direct WebSocket connection without Firebase or Firebase AI Logic.
- **Firebase AI Logic compatible**: Optional drop-in layer that mirrors the `firebase_ai` Live API, so code moves between the two packages by swapping imports. See [Firebase AI Logic Compatibility](#firebase-ai-logic-compatibility).
- Supports the latest Gemini Live, translation, and Lyria music models. See [Supported Models](#supported-models).
- Supports `TEXT`, `AUDIO`, and `VIDEO` response modalities.

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

## 🤖 AI Agents & Coding Assistants Guide

If you are an AI coding assistant (**Claude Code**, **Gemini CLI / Antigravity**, **OpenAI Codex**, **Cursor**, **Windsurf**, or **GitHub Copilot**):
👉 **Read the official package skill specification first:**

| Assistant / Ecosystem | Native Skill Discovery Path | Project Instructions |
|---|---|---|
| **Root Universal** | [`SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/SKILL.md) | - |
| **Common Skills Directory** | [`skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/flutter-gemini-live/SKILL.md) | [`skills/README.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/README.md) |
| **Claude Code** | [`.claude/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.claude/skills/flutter-gemini-live/SKILL.md) | [`CLAUDE.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/CLAUDE.md) |
| **Gemini CLI / Antigravity** | [`.gemini/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.gemini/skills/flutter-gemini-live/SKILL.md) | [`GEMINI.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/GEMINI.md) |
| **OpenAI Codex / Cursor** | [`.codex/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.codex/skills/flutter-gemini-live/SKILL.md) | [`CODEX.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/CODEX.md) |
| **Agent Skills Standard** | [`.agents/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.agents/skills/flutter-gemini-live/SKILL.md) | - |

**🔄 Firebase AI Logic migration skill** — for moving Live code between `firebase_ai` and `gemini_live` in either direction (see [Migration](#migration)):

| Assistant / Ecosystem | Migration Skill Path |
|---|---|
| **Common Skills Directory** | [`skills/gemini-live-firebase-migration/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/gemini-live-firebase-migration/SKILL.md) |
| **Claude Code** | [`.claude/skills/gemini-live-firebase-migration/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.claude/skills/gemini-live-firebase-migration/SKILL.md) |
| **Gemini CLI / Antigravity** | [`.gemini/skills/gemini-live-firebase-migration/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.gemini/skills/gemini-live-firebase-migration/SKILL.md) |
| **OpenAI Codex / Cursor** | [`.codex/skills/gemini-live-firebase-migration/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.codex/skills/gemini-live-firebase-migration/SKILL.md) |
| **Agent Skills** | [`.agents/skills/gemini-live-firebase-migration/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.agents/skills/gemini-live-firebase-migration/SKILL.md) |

**🎨 Widgets skill** — parameters, wiring and UI patterns for the pre-built widgets (see [Pre-built UI Widgets](#pre-built-ui-widgets)):

| Assistant / Ecosystem | Widgets Skill Path |
|---|---|
| **Common Skills Directory** | [`skills/gemini-live-widgets/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/gemini-live-widgets/SKILL.md) |
| **Claude Code** | [`.claude/skills/gemini-live-widgets/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.claude/skills/gemini-live-widgets/SKILL.md) |
| **Gemini CLI / Antigravity** | [`.gemini/skills/gemini-live-widgets/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.gemini/skills/gemini-live-widgets/SKILL.md) |
| **OpenAI Codex / Cursor** | [`.codex/skills/gemini-live-widgets/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.codex/skills/gemini-live-widgets/SKILL.md) |
| **Agent Skills** | [`.agents/skills/gemini-live-widgets/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.agents/skills/gemini-live-widgets/SKILL.md) |

**🔗 Fetch the skill directly** — hidden folders (`.claude/`, `.gemini/`, …) are not shipped in the pub.dev package, so use these links:
- **Raw Markdown (for agents)**: https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main/skills/flutter-gemini-live/SKILL.md
- **Widgets skill** (`gemini-live-widgets`): https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main/skills/gemini-live-widgets/SKILL.md
- **Firebase migration skill** (`gemini-live-firebase-migration`): https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main/skills/gemini-live-firebase-migration/SKILL.md
- **Local copy after `flutter pub get`**: `<PUB_CACHE>/hosted/pub.dev/gemini_live-<version>/skills/flutter-gemini-live/SKILL.md`

```bash
# Install as a global skill (keep only the agents you use)
for d in ~/.claude ~/.gemini ~/.codex ~/.agents; do
  for s in flutter-gemini-live gemini-live-widgets gemini-live-firebase-migration; do
    mkdir -p "$d/skills/$s"
    curl -fsSL "https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main/skills/$s/SKILL.md" \
      -o "$d/skills/$s/SKILL.md"
  done
done
```

### 📌 Core Agent Rules & Invariants
1. **Zero Firebase**: Never import `firebase_core` or `firebase_vertexai` for live streaming. Connect directly via `GoogleGenAI` WebSocket endpoints.
2. **State Management**: For Flutter UI apps, prefer `GeminiLiveSessionController` (`ChangeNotifier`) to handle connection state, transcripts, audio streams, and interruptions.
3. **Pre-built Material 3 Widgets**: Use built-in widgets (`GeminiLiveWaveform`, `GeminiLiveCaptionBubble`, `GeminiLiveMicButton`, `GeminiLiveStatusBadge`, `GeminiLiveVoiceIndicator`, `GeminiLiveUsageBadge`).
4. **Barge-in Interruption**: Always clear/stop local audio playback buffers immediately when `serverContent.interrupted == true` or `controller.isInterrupted` is true.
5. **Audio Formats**:
   - Mic Input: Linear PCM 16-bit, 16,000 Hz mono.
   - Live Output: Linear PCM 16-bit, 24,000 Hz mono (Music: 48,000 Hz stereo).
6. **Models**: Default to `gemini-3.8-live` (low-latency) or `gemini-3.8-live-extended-thinking` (deep reasoning).
7. **Audio I/O is yours**: `GeminiLiveSessionController` does not record or play audio. Stream mic PCM into `sendRealtimeAudio()` and play `incomingAudioStream` (e.g. `record` + `flutter_soloud`).

## Supported Models

Use the model ID string, or the matching constant from `LiveModels` / `LiveMusicModels`.

### Live API (`genAI.live.connect`)

| Model ID | Constant | Use for | Status |
|---|---|---|---|
| `gemini-3.8-live` | `LiveModels.gemini38Live` | **Default.** Low-latency voice & multimodal dialogue | Stable |
| `gemini-3.8-live-extended-thinking` | `LiveModels.gemini38LiveExtendedThinking` | Voice with deeper reasoning (`thinkingConfig`) | Stable |
| `gemini-3.5-live-translate-preview` | `LiveModels.gemini35LiveTranslatePreview` | Speech-to-speech translation (`TranslationConfig`) | Preview |
| `gemini-3.1-flash-live-preview` | `LiveModels.gemini31FlashLivePreview` | Previous generation | Preview |
| `gemini-2.5-flash-native-audio-preview-12-2025` | `LiveModels.gemini25FlashNativeAudioPreview` | Native audio output | Preview |

### Live Music (`genAI.live.music.connect`)

| Model ID | Constant | Use for | Status |
|---|---|---|---|
| `models/lyria-realtime-exp` | `LiveMusicModels.lyriaRealtimeExp` | **Default.** Real-time music generation | Experimental |

> - Pass `thinkingConfig` only to `gemini-3.8-live-extended-thinking`. `gemini-3.8-live` rejects it.
> - `gemini-3.8-live` runs tool calls as non-blocking by default (`Behavior.NON_BLOCKING`).
> - Live output audio is 16-bit PCM 24 kHz mono. Lyria output is 16-bit PCM 48 kHz stereo.
> - Model availability changes over time. Check the [Gemini API models page](https://ai.google.dev/gemini-api/docs/models) for the latest status.

## Installation

Add the package to your Flutter project:

```bash
flutter pub add gemini_live
```

Import the package in Dart:

```dart
import 'package:gemini_live/gemini_live.dart';
```

## Quick Start

Get up and running in under 20 lines of code:

```dart
import 'package:gemini_live/gemini_live.dart';

void main() async {
  // 1. Initialize Gemini Live client
  final genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY', logger: print);

  // 2. Connect to the Live API
  final session = await genAI.live.connect(
    LiveConnectParameters(
      model: 'gemini-3.8-live',
      config: GenerationConfig(responseModalities: [Modality.TEXT]),
      callbacks: LiveCallbacks(
        onOpen: () => print('Live Session Connected!'),
        onMessage: (message) {
          if (message.text != null) {
            print('Gemini: ${message.text}');
          }
        },
        onError: (error, st) => print('Error: $error'),
        onClose: (code, reason) => print('Closed: $code - $reason'),
      ),
    ),
  );

  // 3. Send a message
  session.sendText('Hello Gemini, tell me a quick joke!');
}
```

## Voice Quick Start

Most Live apps are voice apps. `GeminiLiveSessionController` streams audio, but it does **not** record the microphone or play sound. Connect it to [`record`](https://pub.dev/packages/record) (input) and [`flutter_soloud`](https://pub.dev/packages/flutter_soloud) (output):

```bash
flutter pub add gemini_live record flutter_soloud
```

Add the microphone permission for each platform:

| Platform | Setting |
|---|---|
| Android | `AndroidManifest.xml`: `android.permission.RECORD_AUDIO`, `android.permission.INTERNET` |
| iOS | `Info.plist`: `NSMicrophoneUsageDescription` |
| macOS | Entitlements: `com.apple.security.device.audio-input`, `com.apple.security.network.client` |

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

final genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY');
final controller = GeminiLiveSessionController(liveService: genAI.live);
final recorder = AudioRecorder();

Future<void> startVoiceChat() async {
  if (!await recorder.hasPermission()) return;

  await controller.connect(
    LiveConnectParameters(
      model: 'gemini-3.8-live',
      config: GenerationConfig(responseModalities: [Modality.AUDIO]),
      outputAudioTranscription: AudioTranscriptionConfig(),
      callbacks: LiveCallbacks(onError: (e, st) => debugPrint('Live error: $e')),
    ),
  );

  // Speaker: model audio is 16-bit PCM, 24 kHz, mono.
  await SoLoud.instance.init();
  final speaker = SoLoud.instance.setBufferStream(
    sampleRate: 24000,
    channels: Channels.mono,
    format: BufferType.s16le,
    bufferingType: BufferingType.released,
  );
  SoLoud.instance.play(speaker);
  controller.incomingAudioStream.listen(
    (pcm) => SoLoud.instance.addAudioDataStream(speaker, pcm),
  );

  // Barge-in: drop queued model audio when the user interrupts.
  controller.addListener(() {
    if (controller.isInterrupted) SoLoud.instance.resetBufferStream(speaker);
  });

  // Mic: send 16-bit PCM, 16 kHz, mono.
  final mic = await recorder.startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
    ),
  );
  mic.listen(controller.sendRealtimeAudio);
}
```

For a complete screen with captions, waveform, and barge-in handling, see the [Agent Skill quickstart](skills/flutter-gemini-live/SKILL.md) and the [example app](example/lib/).

> **🔐 API key security:** Do not ship a raw Gemini API key in a production app. Mint short-lived **ephemeral tokens** on your backend with `genAI.authTokens.create(...)` and connect the client with that token. See [Ephemeral Tokens](doc/advanced_configuration.md) and [`examples/ephemeral_token.dart`](examples/ephemeral_token.dart).

## Firebase AI Logic Compatibility

`package:gemini_live/compat/firebase_ai.dart` mirrors the **Live API of [`firebase_ai`](https://pub.dev/packages/firebase_ai) 4.x**: same class names, constructors, methods and defaults (`FirebaseAI.googleAI()`, `liveGenerativeModel`, `LiveGenerationConfig`, `LiveSession.send*`, `receive()`, tool calls, session resumption). It runs on the gemini_live engine with no Firebase project. The core `gemini_live` API is unchanged; this is a separate entry point.

```dart
import 'package:gemini_live/compat/firebase_ai.dart';

FirebaseAI.initialize(apiKey: 'YOUR_KEY_OR_EPHEMERAL_TOKEN');

final model = FirebaseAI.googleAI().liveGenerativeModel(
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  liveGenerationConfig: LiveGenerationConfig(
    responseModalities: [ResponseModalities.audio],
    speechConfig: SpeechConfig(voiceName: 'Puck'),
    outputAudioTranscription: AudioTranscriptionConfig(),
  ),
);
final session = await model.connect();

session.receive().listen((response) async {
  final message = response.message;
  if (message is LiveServerContent) {
    for (final part in message.modelTurn?.parts ?? const <Part>[]) {
      if (part is InlineDataPart) playPcm(part.bytes);
    }
  } else if (message is LiveServerToolCall) {
    for (final call in message.functionCalls ?? const <FunctionCall>[]) {
      await session.sendToolResponse([
        FunctionResponse(call.name, await runTool(call), id: call.id),
      ]);
    }
  }
});

await session.sendAudioRealtime(InlineDataPart('audio/pcm;rate=16000', chunk));

// gemini_live-only extra (firebase_ai has no Live usage metadata):
print(session.tokenTracker.formatCost());
```

Only the Live API is covered. `vertexAI()`, `generativeModel` and other non-Live APIs are not provided and fail at compile time.

## Migration

**firebase_ai → gemini_live** (two edits; everything after `FirebaseAI.googleAI()` stays the same):

```diff
- import 'package:firebase_core/firebase_core.dart';
- import 'package:firebase_ai/firebase_ai.dart';
+ import 'package:gemini_live/compat/firebase_ai.dart';

- await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
+ FirebaseAI.initialize(apiKey: 'YOUR_KEY_OR_EPHEMERAL_TOKEN');
```

- Firebase App Check no longer protects the key. Use [ephemeral tokens](doc/advanced_configuration.md) in production; `auth_tokens/...` tokens select `v1alpha` automatically.
- `FirebaseAI.vertexAI()` must become `googleAI()`.

**gemini_live → firebase_ai** (reverse the two edits):

- Remove the gemini_live-only extras the compiler flags: `FirebaseAI.initialize`, `googleAI(apiKey:)`, `session.tokenTracker`, `session.rawSession`, `response.rawMessage`.
- Subscribe to `receive()` before sending. gemini_live buffers early responses; firebase_ai drops them.
- Only code written against the compat layer is portable. Code using the core API (`GoogleGenAI`, `GeminiLiveSessionController`) must be rewritten.

The [Firebase AI compatibility guide](doc/firebase_ai_compat.md) has the full API table, behavior differences, and how to use both packages in one app. Two-way compatibility is checked by [`tool/check_firebase_ai_compat.sh`](tool/check_firebase_ai_compat.sh), which compiles the same sample against both packages.

## Documentation & Guides

For deep dives and complete references, see the modular guides in the [`doc/`](doc/) directory:

- **[AI Agent Skill Guide](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/SKILL.md)** ([skills/](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/README.md)): Agent instructions for Claude Code, Gemini CLI / Antigravity, OpenAI Codex, Cursor, and Copilot.
- **[API Reference](doc/api_reference.md)**: Complete class & method documentation for `GoogleGenAI`, `LiveSession`, `LiveServerMessage`, etc.
- **[Widgets Guide & UI Specification](doc/widgets_guide.md)**: Detailed specification and interactive code examples for `GeminiLiveSessionController` and every pre-built widget.
- **[Advanced Configuration Guide](doc/advanced_configuration.md)**: Guides for Function Calling, VAD, Session Resumption, Audio Transcription, Translation, Grounding, and Ephemeral Tokens.
- **[Firebase AI Compatibility & Migration](doc/firebase_ai_compat.md)**: firebase_ai-compatible Live API, two-way migration checklists, and behavior differences.
- **[Error Codes & Specifications](doc/error_codes_specification.md)**: Complete error codes, close codes, `TurnCompleteReason` enums, and troubleshooting strategies.
- **[Runnable Examples](examples/README.md)**: Dedicated CLI scripts for basic usage, function calling, audio/video streaming, and Google Maps grounding.

## Key Features Overview

* **Real-time Communication**: Low-latency WebSocket interaction.
* **Multimodal Input & Streaming Output**: Text, audio, and camera frame input with live streaming responses.
* **Function Calling**: Synchronous and asynchronous function execution.
* **Session Resumption**: Resume dropped connections via session handles.
* **Google Maps & Search Grounding**: Location and routing-aware responses.
* **Voice Activity Detection**: Automatic and manual VAD.
* **Live Speech Translation**: Real-time speech-to-speech translation (`TranslationConfig`).
* **Pre-built Flutter Widgets & Controller**: `GeminiLiveSessionController`, `GeminiLiveWaveform`, `GeminiLiveCaptionBubble`, `GeminiLiveMicButton`, `GeminiLiveStatusBadge`, `GeminiLiveUsageBadge`, `GeminiLiveVoiceIndicator`.
* **Live Music (Lyria Realtime)**: Steerable real-time music generation via `genAI.live.music`.
* **Ephemeral Auth Tokens**: Short-lived client tokens via `genAI.authTokens` to keep API keys off devices.
* **Token Usage Tracking**: Per-session token accounting with `GeminiTokenUsageTracker`.

| Demo 1: Chihuahua vs muffin | Demo 2: Labradoodle vs fried chicken |
| :---: | :---: |
| <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222333.png?raw=true" alt="Live Conversation Demo" width="400"/> | <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222355.png?raw=true" alt="Multimodal Demo" width="400"/> |
| *Chihuahua vs muffin* | *Labradoodle vs fried chicken* |

---

## Pre-built UI Widgets

The package ships with ready-to-use Flutter Material widgets to accelerate building Live conversational interfaces:

```dart
// 1. Reactive Live Session Controller (ChangeNotifier)
final controller = GeminiLiveSessionController(liveService: genAI.live);
await controller.connect(
  LiveConnectParameters(
    model: 'gemini-3.8-live',
    config: GenerationConfig(responseModalities: [Modality.AUDIO]),
    callbacks: LiveCallbacks(),
  ),
);

// 2. Real-time Audio Waveform Visualizer (Capsule bars & idle breathing)
GeminiLiveWaveform(
  audioStream: controller.incomingAudioStream, // or amplitudeStream
  barCount: 28,
  height: 64,
  color: Theme.of(context).colorScheme.primary,
  enableIdleBreathing: true,
)

// 3. Frosted-Glass Live Caption Bubble (BackdropFilter blur & speaker chips)
GeminiLiveCaptionBubble(
  text: controller.latestTranscript ?? '',
  speaker: controller.latestTranscriptRole == 'user' ? 'You' : 'Gemini',
  isStreaming: controller.isModelSpeaking,
  enableBlur: true,
)

// 4. Concentric Ripple Microphone Button
GeminiLiveMicButton(
  isRecording: controller.isConnected,
  onPressed: () => toggleLiveSession(),
)

// 5. Connection Status Badge with Halo Pulse
GeminiLiveStatusBadge.fromFlags(
  isConnected: controller.isConnected,
  isConnecting: isConnecting,
)

// 6. Real-time Token Usage & Observability Badge
GeminiLiveUsageBadge(
  tracker: controller.tokenTracker,
)

// 7. Dual-Harmonic Voice Indicator
GeminiLiveVoiceIndicator(
  isSpeaking: controller.isModelSpeaking,
  barCount: 5,
)
```

---

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.
