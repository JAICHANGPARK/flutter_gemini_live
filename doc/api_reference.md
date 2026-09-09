# Gemini Live API & Flutter SDK API Reference

This document provides a comprehensive API reference for the `gemini_live` package.

---

## Table of Contents
1. [GoogleGenAI](#1-googlegenai)
2. [LiveService](#2-liveservice)
3. [LiveConnectParameters](#3-liveconnectparameters)
4. [LiveCallbacks](#4-livecallbacks)
5. [LiveSession](#5-livesession)
6. [LiveServerMessage](#6-liveservermessage)
7. [Models & Enums](#7-models--enums)

---

## 1. GoogleGenAI

The entry point for initializing the Gemini Live SDK client.

```dart
final genAI = GoogleGenAI(
  apiKey: 'YOUR_API_KEY',
  apiVersion: 'v1beta', // optional, defaults to 'v1beta'
  logger: print,        // optional, callback for logging network/WebSocket events
);
```

### Properties & Methods

- `apiKey` (`String`): The Google Gemini API key or ephemeral token (`auth_tokens/...`).
- `apiVersion` (`String`): Target API version (`v1beta` or `v1alpha`).
- `live` (`LiveService`): Instance of the streaming Live Service.
- `logger` (`void Function(String)?`): Optional logging callback.
- `close()`: Releases HTTP and network resources held by the client.

---

## 2. LiveService

Handles connection setup, WebSocket URI building, headers, and protocol messages.

```dart
final session = await genAI.live.connect(params);
```

### Properties & Methods

- `connect(LiveConnectParameters params)`: Establishes a WebSocket connection to the Gemini Live API and resolves once `setupComplete` is received.
- `dartVersion()`: Returns current runtime Dart version string.

---

## 3. LiveConnectParameters

Parameters used when connecting to a Gemini Live session via `connect()`.

```dart
LiveConnectParameters(
  required String model,
  required LiveCallbacks callbacks,
  GenerationConfig? config,
  Content? systemInstruction,
  List<Tool>? tools,
  RealtimeInputConfig? realtimeInputConfig,
  SessionResumptionConfig? sessionResumption,
  ContextWindowCompressionConfig? contextWindowCompression,
  AudioTranscriptionConfig? inputAudioTranscription,
  AudioTranscriptionConfig? outputAudioTranscription,
  ProactivityConfig? proactivity,
  AvatarConfig? avatarConfig,
  List<SafetySetting>? safetySettings,
  HistoryConfig? historyConfig,
)
```

---

## 4. LiveCallbacks

Event callbacks for session lifecycle events and incoming server messages.

```dart
LiveCallbacks(
  void Function()? onOpen,
  void Function(LiveServerMessage message)? onMessage,
  void Function(Object error, StackTrace stackTrace)? onError,
  void Function(int? closeCode, String? closeReason)? onClose,
)
```

---

## 5. LiveSession

Represents an active, bidirectional Gemini Live API session over WebSocket.

### Methods

- `sendText(String text)`: Sends a single text message.
- `sendClientContent({List<Content>? turns, bool turnComplete = true})`: Sends multi-turn content history.
- `sendRealtimeInput({...})`: Sends realtime media chunks (audio, video frames, text).
- `sendMediaChunks(List<Blob> mediaChunks)`: Sends raw media chunks.
- `sendAudio(List<int> audioBytes)`: Sends raw PCM audio bytes as a base64 Blob (`audio/pcm`).
- `sendVideo(List<int> videoBytes, {String mimeType = 'image/jpeg'})`: Sends image/video frame bytes.
- `sendAudioStreamEnd()`: Signals the end of the current audio stream.
- `sendRealtimeText(String text)`: Sends realtime text input chunks.
- `sendActivityStart()` / `sendActivityEnd()`: Signals user speech activity start/end in manual VAD mode.
- `sendToolResponse({required List<FunctionResponse> functionResponses})`: Sends function call results back to the model.
- `sendFunctionResponse({required String id, required String name, required Map<String, dynamic> response})`: Sends a single function call result.
- `close()`: Closes the active WebSocket connection.
- `isClosed` (`bool`): Returns `true` if the session WebSocket is closed.

---

## 6. LiveServerMessage

Top-level message object received from the Gemini Live server via `onMessage`.

### Key Properties

- `text` (`String?`): Concatenated non-thought text output from the current turn.
- `data` (`String?`): Base64 encoded inline binary audio/media output.
- `serverContent` (`LiveServerContent?`): Full server content container:
  - `modelTurn`: Model's generated `Content` and `Part` list.
  - `turnComplete`: `bool?` indicating if the model turn is complete.
  - `interrupted`: `bool?` indicating if the model output was interrupted by user input.
  - `turnCompleteReason`: `TurnCompleteReason?` enum (`TOO_MANY_TOOL_CALLS`, `SAFETY`, etc.).
  - `inputTranscription`: `Transcription?` (final input transcription).
  - `interimInputTranscription`: `Transcription?` (low-latency input transcription).
  - `outputTranscription`: `Transcription?` (output audio transcription).
- `setupComplete` (`LiveServerSetupComplete?`): Contains `sessionId` and `voiceConsentSignature`.
- `toolCall` (`LiveServerToolCall?`): Contains requested `functionCalls` list.
- `toolCallCancellation` (`LiveServerToolCallCancellation?`): Canceled function call IDs.
- `sessionResumptionUpdate` (`LiveServerSessionResumptionUpdate?`): Contains `newHandle` for resumption.
- `voiceActivity` (`VoiceActivity?`): Voice activity event with `audioOffset` and `speechActive`.
- `voiceActivityDetectionSignal` (`VoiceActivityDetectionSignal?`): Low-level VAD signal.
- `goAway` (`LiveServerGoAway?`): Disconnect warning with `timeRemaining` helper.
- `usageMetadata` (`UsageMetadata?`): Prompt, response, thoughts, and modality token counts.
- `interactionStatus` (`InteractionStatus?`): The current session activity status (`IN_PROGRESS`, `IDLE`).

---

## 7. Models & Enums

### Key Enums

- **`Modality`**: `TEXT`, `AUDIO`, `VIDEO`
- **`InteractionStatus`**: `INTERACTION_STATUS_UNSPECIFIED`, `IN_PROGRESS`, `IDLE` (`REQUIRES_ACTION` is deprecated)
- **`MediaProcessing`**: `MEDIA_PROCESSING_UNSPECIFIED`, `STATIC`, `AGENTIC`
- **`AudioTranscriptionConfigMode`**: `MODE_UNSPECIFIED`, `VERBATIM`, `SMART`
- **`TurnCompleteReason`**: `TURN_COMPLETE_REASON_UNSPECIFIED`, `TOO_MANY_TOOL_CALLS`, `MALFORMED_FUNCTION_CALL`, `PROHIBITED_INPUT_CONTENT`, `GENERATED_CONTENT_SAFETY`, `MAX_REGENERATION_REACHED`, etc.
- **`ServiceTier`**: `standard`, `flex`, `priority`, `deferred`
- **`StartSensitivity`**: `START_SENSITIVITY_UNSPECIFIED`, `START_SENSITIVITY_HIGH`, `START_SENSITIVITY_LOW`
- **`EndSensitivity`**: `END_SENSITIVITY_UNSPECIFIED`, `END_SENSITIVITY_HIGH`, `END_SENSITIVITY_LOW`

### Key Data Classes

- **`GoogleMaps`**: `groundingTypes` (`places`, `routing`)
- **`Tool`**: `functionDeclarations`, `googleSearch`, `googleSearchRetrieval`, `codeExecution`, `googleMaps`, `computerUse`, `parallelAiSearch`
- **`GenerationConfig`**: `temperature`, `topK`, `topP`, `maxOutputTokens`, `responseModalities`, `speechConfig`, `thinkingConfig`, `translationConfig`, `audioTranscriptionConfig`
- **`AudioTranscriptionConfig`**: `languageAuto`, `languageHints`, `customVocabulary`, `adaptationPhrases` (deprecated), `mode`
- **`Part`**: `text`, `thought`, `inlineData`, `fileData`, `functionCall`, `functionResponse`, `audioTranscription`, `mediaProcessing`
- **`AuthToken`**: `name`, `expireTime`, `newSessionExpireTime`, `uses`
- **`LiveConnectConstraints`**: `model`, `config`
- **`CreateAuthTokenConfig`**: `expireTime`, `newSessionExpireTime`, `uses`, `liveConnectConstraints`, `lockAdditionalFields`

---

## 8. Flutter UI Widgets

The package provides pre-built, dependency-free Flutter Material widgets for common Gemini Live UI workflows:

### `GeminiLiveStatusBadge`
Compact badge showing real-time connection state (`disconnected`, `connecting`, `connected`, `inProgress`) with animated pulse indicators and `InteractionStatus` support.

```dart
GeminiLiveStatusBadge.fromFlags(
  isConnected: isConnected,
  isConnecting: isConnecting,
  interactionStatus: interactionStatus, // optional: IN_PROGRESS / IDLE
)
```

### `GeminiLiveMicButton`
Microphone toggle button with smooth pulsing ripple animations during active recording.

```dart
GeminiLiveMicButton(
  isRecording: isRecording,
  onPressed: toggleRecording,
  tooltip: 'Tap to speak',
)
```

### `GeminiLiveVoiceIndicator`
Animated audio waveform bar visualizer that dances rhythmically when speech or live streaming is active.

```dart
GeminiLiveVoiceIndicator(
  isSpeaking: isSpeaking,
  barCount: 5,
  height: 24,
  color: Colors.blueAccent,
)
```
