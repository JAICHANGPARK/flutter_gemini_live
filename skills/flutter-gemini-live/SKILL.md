---
name: flutter-gemini-live
description: Build real-time, multimodal streaming applications in Flutter using the Google Gemini Live API without Firebase dependencies. Use when implementing voice/text/video live chat, function calling, audio transcription, live translation, session resumption, or Google Maps grounding in Flutter.
---

# Flutter Gemini Live Agent Skill

This skill guides AI agents in using the `gemini_live` Flutter package to build real-time, low-latency, multimodal applications connected directly to Google's Gemini Live API via WebSockets.

---

## 💡 Key Package Principles

1. **Zero Firebase Dependency**: Connects directly to Google Generative Language WebSocket endpoints without Firebase or Firebase AI Logic SDKs.
2. **Supported Models**: `gemini-3.1-flash-live-preview` (default) and `gemini-2.5-flash-native-audio-preview-12-2025`.
3. **Response Modalities**: `Modality.TEXT`, `Modality.AUDIO`, and `Modality.VIDEO`.

---

## 🛠️ Step-by-Step Implementation Workflow

### Step 1: Package Import & Client Initialization

Always initialize `GoogleGenAI` with an API key. Optional `logger` receives WebSocket traffic logs.

```dart
import 'package:gemini_live/gemini_live.dart';

final genAI = GoogleGenAI(
  apiKey: 'YOUR_GEMINI_API_KEY',
  logger: print, // Optional: logs connection events, sent/received JSON
);
```

### Step 2: Establish a Live Session

Use `genAI.live.connect()` to open a WebSocket connection and register `LiveCallbacks`.

```dart
LiveSession? session;

Future<void> connectToLiveAPI() async {
  try {
    session = await genAI.live.connect(
      LiveConnectParameters(
        model: 'gemini-3.1-flash-live-preview',
        config: GenerationConfig(
          responseModalities: [Modality.TEXT],
        ),
        callbacks: LiveCallbacks(
          onOpen: () => print('WebSocket connection established.'),
          onMessage: (LiveServerMessage message) => handleServerMessage(message),
          onError: (error, stackTrace) => print('Error: $error'),
          onClose: (code, reason) => print('Closed: $code - $reason'),
        ),
      ),
    );
  } on TimeoutException catch (e) {
    print('Setup timeout: $e');
  } on UnsupportedError catch (e) {
    print('Unsupported config: $e');
  } catch (e) {
    print('Failed to connect: $e');
  }
}
```

### Step 3: Handling Server Messages (`LiveServerMessage`)

Process responses inside `onMessage`:

```dart
void handleServerMessage(LiveServerMessage message) {
  // 1. Text chunks (concatenated non-thought output)
  if (message.text != null && message.text!.isNotEmpty) {
    print('Model: ${message.text}');
  }

  // 2. Audio output (Base64 encoded audio/pcm data)
  if (message.data != null) {
    final audioBytes = base64Decode(message.data!);
    // Feed audioBytes to audio player...
  }

  // 3. Tool Calls (Function Calling)
  if (message.toolCall != null) {
    handleToolCalls(message.toolCall!.functionCalls);
  }

  // 4. Session Resumption handle updates
  if (message.sessionResumptionUpdate != null) {
    final handle = message.sessionResumptionUpdate!.newHandle;
    // Store handle locally for reconnection...
  }

  // 5. Session expiration warnings (GoAway)
  if (message.goAway != null) {
    print('Session expiring in ${message.goAway!.timeRemaining}s');
  }

  // 6. Turn Completion & Reason
  if (message.serverContent?.turnComplete ?? false) {
    final reason = message.serverContent?.turnCompleteReason;
    if (reason == TurnCompleteReason.TOO_MANY_TOOL_CALLS) {
      print('Warning: Tool call loop limit reached');
    }
  }
}
```

### Step 4: Sending Client Content & Real-time Inputs

```dart
// Send text prompt
session?.sendText('Hello Gemini!');

// Send audio input bytes (PCM 16-bit 16kHz mono)
session?.sendAudio(pcmAudioBytes);

// Send camera image frame bytes
session?.sendVideo(jpegFrameBytes, mimeType: 'image/jpeg');

// Signal speech end in manual VAD mode
session?.sendActivityEnd();
```

---

## ⚙️ Advanced Feature Patterns

### 1. Function Calling (Tools)

```dart
LiveConnectParameters(
  model: 'gemini-3.1-flash-live-preview',
  tools: [
    Tool(
      functionDeclarations: [
        FunctionDeclaration(
          name: 'get_weather',
          description: 'Get weather for city',
          parameters: Schema(
            type: Type.OBJECT,
            properties: {
              'location': Schema(type: Type.STRING),
            },
            required: ['location'],
          ),
        ),
      ],
    ),
  ],
  callbacks: LiveCallbacks(
    onMessage: (message) {
      if (message.toolCall != null) {
        for (final call in message.toolCall!.functionCalls) {
          if (call.name == 'get_weather') {
            final city = call.args['location'];
            // Send execution response
            session?.sendFunctionResponse(
              id: call.id,
              name: call.name,
              response: {'temperature': '20°C', 'condition': 'Sunny'},
            );
          }
        }
      }
    },
  ),
);
```

### 2. Google Maps Grounding

```dart
tools: [
  Tool(
    googleMaps: GoogleMaps(
      groundingTypes: ['places', 'routing'],
    ),
  ),
]
```

### 3. Session Resumption

```dart
LiveConnectParameters(
  model: 'gemini-3.1-flash-live-preview',
  sessionResumption: SessionResumptionConfig(
    handle: savedSessionHandle,
  ),
)
```

### 4. Audio Transcription with Custom Vocabulary

```dart
inputAudioTranscription: AudioTranscriptionConfig(
  languageAuto: LanguageAuto(),
  customVocabulary: ['Gemini', 'Flutter', 'Dart'],
),
outputAudioTranscription: AudioTranscriptionConfig(),
```

### 5. Real-time Speech-to-Speech Translation

```dart
config: GenerationConfig(
  responseModalities: [Modality.AUDIO],
  translationConfig: TranslationConfig(
    targetLanguageCode: 'ko', // BCP-47 target language
    echoTargetLanguage: false,
  ),
)
```

---

## 🚨 Error Handling Rules for AI Agents

- **`TimeoutException`**: Thrown if setup handshake exceeds 10 seconds. Check API key validity and WebSocket proxy rules.
- **`UnsupportedError`**: Thrown when passing unsupported parameters like `sessionResumption.transparent`, `explicitVadSignal`, or array `languageCodes`.
- **`ArgumentError`**: Thrown if `sendFunctionResponse` lacks required `id` or `name` fields, or invalid MIME types.
- **Close Code `4004`**: Quota limit exceeded (RPM/TPM).
- **Close Code `1006`**: Abnormal disconnect; attempt reconnection with exponential backoff.
