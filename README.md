# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[[English]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [[한국어]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [[日本語]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [[简体中文]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- A Flutter package for [the experimental Gemini Live API](https://ai.google.dev/gemini-api/docs/live), enabling real-time, multimodal conversations with Google's Gemini models.
- **Zero Firebase Dependency**: Direct WebSocket connection without Firebase or Firebase AI Logic.
- Supports latest Gemini Live models (`gemini-3.1-flash-live-preview`, `gemini-2.5-flash-native-audio-preview-12-2025`).
- Supports `TEXT`, `AUDIO`, and `VIDEO` response modalities.

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

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
      model: 'gemini-3.1-flash-live-preview',
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

- **[API Reference](doc/api_reference.md)**: Complete class & method documentation for `GoogleGenAI`, `LiveSession`, `LiveServerMessage`, etc.
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

| Demo 1: Chihuahua vs muffin | Demo 2: Labradoodle vs fried chicken |
| :---: | :---: |
| <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222333.png?raw=true" alt="Live Conversation Demo" width="400"/> | <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222355.png?raw=true" alt="Multimodal Demo" width="400"/> |
| *Chihuahua vs muffin* | *Labradoodle vs fried chicken* |

---

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.
