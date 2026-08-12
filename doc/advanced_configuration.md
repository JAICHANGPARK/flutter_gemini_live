# ⚙️ Gemini Live API Advanced Configuration Guide

This guide details advanced capabilities of the `gemini_live` package, with complete code examples.

---

## 📑 Table of Contents
1. [Function Calling](#1-function-calling)
2. [Voice Activity Detection (VAD)](#2-voice-activity-detection-vad)
3. [Session Resumption](#3-session-resumption)
4. [Audio Transcription & Custom Vocabulary](#4-audio-transcription--custom-vocabulary)
5. [Real-time Speech Translation](#5-real-time-speech-translation)
6. [Google Maps & Search Grounding](#6-google-maps--search-grounding)
7. [History Pre-loading](#7-history-pre-loading)
8. [Ephemeral Tokens](#8-ephemeral-tokens)
9. [Context Window Compression](#9-context-window-compression)

---

## 1. Function Calling

Define function declarations for tools and handle execution responses.

```dart
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-3.1-flash-live-preview',
    tools: [
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            name: 'get_current_weather',
            description: 'Get the current weather for a location',
            parameters: Schema(
              type: Type.OBJECT,
              properties: {
                'location': Schema(type: Type.STRING, description: 'City name'),
              },
              required: ['location'],
            ),
          ),
        ],
      ),
    ],
    callbacks: LiveCallbacks(
      onMessage: (message) async {
        if (message.toolCall != null) {
          for (final call in message.toolCall!.functionCalls) {
            if (call.name == 'get_current_weather') {
              final location = call.args['location'];
              // Perform tool execution...
              session.sendFunctionResponse(
                id: call.id,
                name: call.name,
                response: {'temperature': '22°C', 'condition': 'Sunny'},
              );
            }
          }
        }
      },
    ),
  ),
);
```

---

## 2. Voice Activity Detection (VAD)

### Automatic VAD Configuration

```dart
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
)
```

### Manual Activity Mode

```dart
realtimeInputConfig: RealtimeInputConfig(
  automaticActivityDetection: AutomaticActivityDetection(disabled: true),
),

// Signal speech start
session.sendActivityStart();
// Send audio chunks...
// Signal speech end
session.sendActivityEnd();
```

---

## 3. Session Resumption

Resume a conversation across network dropouts using saved session handles.

```dart
// First connection with session resumption
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-3.1-flash-live-preview',
    sessionResumption: SessionResumptionConfig(
      handle: previousSessionHandle,
    ),
  ),
);

// Save new handles as updates arrive
if (message.sessionResumptionUpdate != null) {
  final newHandle = message.sessionResumptionUpdate!.newHandle;
  await saveSessionHandleToStorage(newHandle);
}
```

> **Note**: `SessionResumptionConfig.transparent` is not supported in the Gemini Live API.

---

## 4. Audio Transcription & Custom Vocabulary

Transcribe audio input/output and bias ASR towards domain-specific terms.

```dart
inputAudioTranscription: AudioTranscriptionConfig(
  languageAuto: LanguageAuto(),
  customVocabulary: ['Gemini', 'Flutter', 'Dart', 'Antigravity'],
),
outputAudioTranscription: AudioTranscriptionConfig(),
```

---

## 5. Real-time Speech Translation

Enable real-time speech-to-speech translation by setting `translationConfig`.

```dart
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-3.1-flash-live-preview',
    config: GenerationConfig(
      responseModalities: [Modality.AUDIO],
      translationConfig: TranslationConfig(
        targetLanguageCode: 'ko',  // BCP-47 language code
        echoTargetLanguage: false,
      ),
    ),
  ),
);
```

> **Note**: Live Translation requires audio-only input (`Modality.AUDIO`) without tools or system instructions.

---

## 6. Google Maps & Search Grounding

### Google Maps Grounding

```dart
tools: [
  Tool(
    googleMaps: GoogleMaps(
      groundingTypes: ['places', 'routing'],
    ),
  ),
]
```

### Google Search Grounding

```dart
tools: [
  Tool(googleSearch: GoogleSearch()),
]
```

---

## 7. History Pre-loading

Pre-load conversation history prior to the first realtime interaction turn.

```dart
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-3.1-flash-live-preview',
    historyConfig: HistoryConfig(
      initialHistoryInClientContent: true,
    ),
  ),
);

// Send conversation history before first realtime input
session.sendClientContent(
  turns: [
    Content(role: 'user', parts: [Part(text: 'Hello, my name is Alice.')]),
    Content(role: 'model', parts: [Part(text: 'Hello Alice! How can I help you today?')]),
  ],
  turnComplete: true,
);
```

---

## 8. Ephemeral Tokens

Secure client-side authentication using short-lived ephemeral tokens issued by your server.

```dart
final genAI = GoogleGenAI(
  apiKey: 'auth_tokens/your_issued_ephemeral_token',
  apiVersion: 'v1alpha', // Ephemeral tokens require v1alpha
);
```

---

## 9. Context Window Compression

Manage long-running sessions by automatically compressing sliding conversation context.

```dart
contextWindowCompression: ContextWindowCompressionConfig(
  triggerTokens: '10000',
  slidingWindow: SlidingWindow(targetTokens: '5000'),
)
```
