# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[English](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [한국어](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [日本語](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [简体中文](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- A Flutter package for the [Gemini Live API](https://ai.google.dev/gemini-api/docs/live), enabling real-time, multimodal conversations with Google's Gemini models.
- **Zero Firebase Dependency**: Direct WebSocket connection without Firebase or Firebase AI Logic.
- Supports latest Gemini Live models (`gemini-3.8-live`, `gemini-3.8-live-extended-thinking`, `gemini-3.1-flash-live-preview`, `gemini-2.5-flash-native-audio-preview-12-2025`).
- Supports `TEXT`, `AUDIO`, and `VIDEO` response modalities.

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

## 🤖 AI Agents & Coding Assistants Guide

If you are an AI coding assistant (**Claude Code**, **Gemini CLI / Antigravity**, **OpenAI Codex**, **Cursor**, **Windsurf**, or **GitHub Copilot**):
👉 **Read the official package skill specification first:**

| Assistant / Ecosystem | Native Skill Discovery Path | Project Instructions |
|---|---|---|
| **Root Universal** | [`SKILL.md`](SKILL.md) | - |
| **Common Skills Directory** | [`skills/flutter-gemini-live/SKILL.md`](skills/flutter-gemini-live/SKILL.md) | [`skills/README.md`](skills/README.md) |
| **Claude Code** | [`.claude/skills/flutter-gemini-live/SKILL.md`](.claude/skills/flutter-gemini-live/SKILL.md) | [`CLAUDE.md`](CLAUDE.md) |
| **Gemini CLI / Antigravity** | [`.gemini/skills/flutter-gemini-live/SKILL.md`](.gemini/skills/flutter-gemini-live/SKILL.md) | [`GEMINI.md`](GEMINI.md) |
| **OpenAI Codex / Cursor** | [`.codex/skills/flutter-gemini-live/SKILL.md`](.codex/skills/flutter-gemini-live/SKILL.md) | [`CODEX.md`](CODEX.md) |
| **Agent Skills Standard** | [`.agents/skills/flutter-gemini-live/SKILL.md`](.agents/skills/flutter-gemini-live/SKILL.md) | - |

### 📌 Core Agent Rules & Invariants
1. **Zero Firebase**: Never import `firebase_core` or `firebase_vertexai` for live streaming. Connect directly via `GoogleGenAI` WebSocket endpoints.
2. **State Management**: For Flutter UI apps, prefer `GeminiLiveSessionController` (`ChangeNotifier`) to handle connection state, transcripts, audio streams, and interruptions.
3. **Pre-built Material 3 Widgets**: Use built-in widgets (`GeminiLiveWaveform`, `GeminiLiveCaptionBubble`, `GeminiLiveMicButton`, `GeminiLiveStatusBadge`, `GeminiLiveVoiceIndicator`, `GeminiLiveUsageBadge`).
4. **Barge-in Interruption**: Always clear/stop local audio playback buffers immediately when `serverContent.interrupted == true` or `controller.isInterrupted` is true.
5. **Audio Formats**:
   - Mic Input: Linear PCM 16-bit, 16,000 Hz mono.
   - Live Output: Linear PCM 16-bit, 24,000 Hz mono (Music: 48,000 Hz stereo).
6. **Models**: Default to `gemini-3.8-live` (low-latency) or `gemini-3.8-live-extended-thinking` (deep reasoning).

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

## Documentation & Guides

For deep dives and complete references, see the modular guides in the [`doc/`](doc/) directory:

- **[AI Agent Skill Guide](SKILL.md)** ([skills/](skills/README.md)): Agent instructions for Claude Code, Gemini CLI / Antigravity, OpenAI Codex, Cursor, and Copilot.
- **[API Reference](doc/api_reference.md)**: Complete class & method documentation for `GoogleGenAI`, `LiveSession`, `LiveServerMessage`, etc.
- **[Widgets Guide & UI Specification](doc/widgets_guide.md)**: Detailed specification and interactive code examples for `GeminiLiveStatusBadge`, `GeminiLiveMicButton`, and `GeminiLiveVoiceIndicator`.
- **[Advanced Configuration Guide](doc/advanced_configuration.md)**: Guides for Function Calling, VAD, Session Resumption, Audio Transcription, Translation, Grounding, and Ephemeral Tokens.
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
* **Pre-built Flutter Widgets**: Drop-in UI widgets (`GeminiLiveStatusBadge`, `GeminiLiveMicButton`, `GeminiLiveVoiceIndicator`) for seamless app integration.

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
  isRecording: controller.isUserSpeaking,
  isConnected: controller.isConnected,
  onPressed: () => toggleLiveSession(),
)

// 5. Connection Status Badge with Halo Pulse
GeminiLiveStatusBadge(
  state: controller.isConnected ? LiveStatusState.connected : LiveStatusState.disconnected,
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
