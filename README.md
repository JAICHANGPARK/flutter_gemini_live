# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[[English]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [[한국어]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md)

---

- A Flutter package for using [the experimental Gemini Live API](https://ai.google.dev/gemini-api/docs/live), enabling real-time, multimodal conversations with Google's Gemini models.
- No Firebase / Firebase AI Logic dependency
- Supports current Gemini Live model families (for example `gemini-live-2.5-flash-preview` and `gemini-2.5-flash-native-audio-preview-12-2025`).
- Supports both `TEXT` and `AUDIO` response modalities (one modality per session).

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e


## ✨ Features

*   **Real-time Communication**: Establishes a WebSocket connection for low-latency, two-way interaction.
*   **Multimodal Input**: Send text, images, and audio in a single conversational turn.
*   **Streaming Responses**: Receive text responses from the model as they are being generated.
*   **Easy-to-use Callbacks**: Simple event-based handlers for `onOpen`, `onMessage`, `onError`, and `onClose`.
*   **Function Calling**: Model can call external functions and receive results.
*   **Session Resumption**: Resume sessions after connection drops.
*   **Voice Activity Detection (VAD)**: Automatic or manual voice activity detection.
*   **Realtime Media Chunks**: Send audio/video chunks in real-time.
*   **Audio Transcription**: Transcribe voice input and output to text.

| Demo 1: Chihuahua vs muffin | Demo 2: Labradoodle vs fried chicken |
| :---: | :---: |
| <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222333.png?raw=true" alt="실시간 대화 데모" width="400"/> | <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222355.png?raw=true" alt="멀티모달 입력 데모" width="400"/> |
| *Chihuahua vs muffin* | *Labradoodle vs fried chicken* |

## 🏁 Getting Started

### Prerequisites

You need a Google Gemini API key to use this package. You can get your key from [Google AI Studio](https://aistudio.google.com/app/apikey).

### Installation

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  gemini_live: ^0.2.1 # Use the latest version
```

or run this command (Recommend):

```bash
flutter pub add gemini_live
```

Install the package from your terminal:

```bash
flutter pub get
```

Now, import the package in your Dart code:

```dart
import 'package:gemini_live/gemini_live.dart';
```

## 🚀 Usage

### Basic Example

Here is a basic example of how to use the `gemini_live` package to start a session and send a message.

**Security Note**: Do not hardcode your API key. It is highly recommended to use a `.env` file with a package like `flutter_dotenv` to keep your credentials secure.

```dart
import 'package:gemini_live/gemini_live.dart';

// 1. Initialize Gemini with your API key
final genAI = GoogleGenAI(apiKey: 'YOUR_API_KEY_HERE');
LiveSession? session;

// 2. Connect to the Live API
Future<void> connect() async {
  try {
    session = await genAI.live.connect(
      LiveConnectParameters(
        model: 'gemini-live-2.5-flash-preview',
        callbacks: LiveCallbacks(
          onOpen: () => print('✅ Connection opened'),
          onMessage: (LiveServerMessage message) {
            // 3. Handle incoming messages from the model
            if (message.text != null) {
              print('Received chunk: ${message.text}');
            }
            if (message.serverContent?.turnComplete ?? false) {
              print('✅ Turn complete!');
            }
          },
          onError: (e, s) => print('🚨 Error: $e'),
          onClose: (code, reason) => print('🚪 Connection closed'),
        ),
      ),
    );
  } catch (e) {
    print('Connection failed: $e');
  }
}

// 4. Send a message to the model
void sendMessage(String text) {
  session?.sendText(text);
}
```

### 🆕 New Features (v0.2.1)

#### Function Calling

The model can call external functions and receive results:

```dart
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-live-2.5-flash-preview',
    tools: [
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            name: 'get_weather',
            description: 'Get weather by city',
            parameters: {
              'type': 'OBJECT',
              'properties': {
                'city': {'type': 'STRING'},
              },
              'required': ['city'],
            },
          ),
        ],
      ),
    ],
    callbacks: LiveCallbacks(
      onMessage: (LiveServerMessage message) {
        // Handle function calls
        if (message.toolCall != null) {
          for (final call in message.toolCall!.functionCalls!) {
            print('Function call: ${call.name}');
            
            // Execute function and send response
            session.sendFunctionResponse(
              id: call.id!,
              name: call.name!,
              response: {'result': 'success'},
            );
          }
        }
      },
    ),
  ),
);
```

#### Realtime Input

Send audio, video, and text in real-time:

```dart
// Send real-time text
session.sendRealtimeText('Realtime text input');

// Send media chunks
session.sendMediaChunks([
  Blob(mimeType: 'audio/pcm', data: base64Audio),
]);

// Combined real-time input
session.sendRealtimeInput(
  audio: Blob(mimeType: 'audio/pcm', data: base64Audio),
  video: Blob(mimeType: 'image/jpeg', data: base64Image),
  text: 'Text description',
);

// Signal audio stream end
session.sendAudioStreamEnd();
```

#### Manual Activity Detection

Disable automatic VAD and control manually:

```dart
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-live-2.5-flash-preview',
    realtimeInputConfig: RealtimeInputConfig(
      automaticActivityDetection: AutomaticActivityDetection(
        disabled: true, // Disable automatic detection
      ),
    ),
  ),
);

// Signal activity start
session.sendActivityStart();

// Send voice data...

// Signal activity end
session.sendActivityEnd();
```

#### Session Resumption

Resume sessions after connection drops:

```dart
// First connection with session resumption
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-live-2.5-flash-preview',
    sessionResumption: SessionResumptionConfig(
      handle: previousSessionHandle, // Previous session handle
      transparent: true,
    ),
  ),
);

// Receive session handle updates
if (message.sessionResumptionUpdate != null) {
  final newHandle = message.sessionResumptionUpdate!.newHandle;
  // Save newHandle for later use
}
```

#### Advanced Configuration

```dart
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-2.5-flash-native-audio-preview-12-2025',
    // Realtime input configuration
    realtimeInputConfig: RealtimeInputConfig(
      automaticActivityDetection: AutomaticActivityDetection(
        disabled: false,
        startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
        endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
        prefixPaddingMs: 300,
        silenceDurationMs: 500,
      ),
      activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
      turnCoverage: TurnCoverage.TURN_INCLUDES_ALL_INPUT,
    ),
    // Audio transcription
    inputAudioTranscription: AudioTranscriptionConfig(),
    outputAudioTranscription: AudioTranscriptionConfig(),
    // Context window compression
    contextWindowCompression: ContextWindowCompressionConfig(
      triggerTokens: '10000',
      slidingWindow: SlidingWindow(targetTokens: '5000'),
    ),
    // Proactivity
    proactivity: ProactivityConfig(proactiveAudio: true),
  ),
);
```

#### Ephemeral Token (Client-to-Server)

Use `apiVersion: 'v1alpha'` and pass the issued ephemeral token (`auth_tokens/...`) as `apiKey`:

```dart
final genAI = GoogleGenAI(
  apiKey: 'auth_tokens/your_ephemeral_token',
  apiVersion: 'v1alpha',
);
```

## 💬 Live Chat Demo

This repository includes a comprehensive example application demonstrating the features of the `gemini_live` package.

### Running the Demo App

1.  **Get an API Key**: Make sure you have a Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey).

2.  **Set Up the Project**:
    *   Clone this repository.
    *   The example app now supports API key input from the UI.
    *   Run the app and open **Settings** (top-right icon) to paste your API key.
    *   Configure platform permissions for microphone and photo library access as needed.
    *   Run `flutter pub get` in the `example` directory.

3.  **Run the App**:
    ```bash
    cd example
    flutter run
    ```

### Demo Pages

The example app includes the following demo pages:

1. **Chat Interface** - Basic chat (text, image, audio)
2. **Live API Features** - Comprehensive demo of all new features
   - VAD, transcription, session resumption, context compression, etc.
3. **Function Calling** - Function calling demo (weather/time)
4. **Realtime Media** - Real-time audio/video input demo

### CLI Script Examples

Additional runnable scripts are available under `examples/`:

- `examples/basic_usage.dart`
- `examples/function_calling.dart`
- `examples/realtime_audio_video.dart`
- `examples/manual_activity_detection.dart`
- `examples/session_resumption.dart`
- `examples/complete_features.dart`
- `examples/ephemeral_token.dart` (uses `GEMINI_EPHEMERAL_TOKEN`, `apiVersion: 'v1alpha'`)

See [examples/README.md](/Users/jaichang/Documents/GitHub/flutter_gemini_live/examples/README.md) for usage details.

### How to Use the App

1.  **Connect**: The app will attempt to connect to the Gemini API automatically. If the connection fails, tap the **"Reconnect"** button.

2.  **Send a Text Message**:
    -   Type your message in the text field at the bottom.
    -   Tap the send (**▶️**) icon.

3.  **Send a Message with an Image**:
    -   Tap the image (**🖼️**) icon to open your gallery.
    -   Select an image. A preview will appear.
    -   (Optional) Type a question about the image.
    -   Tap the send (**▶️**) icon.

4.  **Send a Voice Message**:
    -   Tap the microphone (**🎤**) icon. Recording will start, and the icon will change to a red stop (**⏹️**) icon.
    -   Speak your message.
    -   Tap the stop (**⏹️**) icon again to finish. The audio will be sent automatically.

## 📚 API Reference

### LiveSession Methods

- `sendText(String text)` - Send text message
- `sendClientContent({List<Content>? turns, bool turnComplete})` - Send multi-turn content
- `sendRealtimeInput({...})` - Send real-time input (audio, video, text)
- `sendMediaChunks(List<Blob> mediaChunks)` - Send media chunks
- `sendAudioStreamEnd()` - Signal audio stream end
- `sendRealtimeText(String text)` - Send real-time text
- `sendActivityStart()` / `sendActivityEnd()` - Signal activity start/end
- `sendToolResponse({required List<FunctionResponse> functionResponses})` - Send tool response
- `sendFunctionResponse({required String id, required String name, required Map<String, dynamic> response})` - Send single function response
- `sendVideo(List<int> videoBytes, {String mimeType})` - Send video
- `sendAudio(List<int> audioBytes)` - Send audio
- `close()` - Close connection
- `isClosed` - Check connection status

### LiveServerMessage Properties

- `text` - Text response
- `data` - Base64 encoded inline data
- `serverContent` - Server content (modelTurn, turnComplete, etc.)
- `toolCall` - Tool call request
- `toolCallCancellation` - Tool call cancellation
- `sessionResumptionUpdate` - Session resumption update
- `voiceActivity` - Voice activity status
- `voiceActivityDetectionSignal` - Voice activity detection signal
- `goAway` - Server disconnect warning
- `usageMetadata` - Token usage metadata

## 🤝 Contributing

Contributions of all kinds are welcome, including bug reports, feature requests, and pull requests! Please feel free to open an issue on the issue tracker.

1.  Fork this repository.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

## 📜 License

See the `LICENSE` file for more details.
