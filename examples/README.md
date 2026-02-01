# Gemini Live API Examples

This directory contains comprehensive examples demonstrating the various features of the Gemini Live API Dart/Flutter SDK.

## Examples Overview

### 1. basic_usage.dart
A basic example showing how to:
- Connect to the Live API
- Send text messages
- Handle various response types
- Close the connection

**Run:**
```bash
dart examples/basic_usage.dart
```

### 2. function_calling.dart
Demonstrates function calling (tool calling) capabilities:
- Setting up tools for the model
- Handling `toolCall` messages from the server
- Executing functions
- Sending `toolResponse` back to the model
- Handling `toolCallCancellation` messages

**Run:**
```bash
dart examples/function_calling.dart
```

### 3. realtime_audio_video.dart
Shows how to send realtime media input:
- Sending audio chunks
- Sending video frames
- Configuring automatic activity detection
- Handling audio transcriptions (input and output)
- Using `audioStreamEnd` signal
- Working with voice activity detection (VAD) signals

**Run:**
```bash
dart examples/realtime_audio_video.dart
```

### 4. session_resumption.dart
Demonstrates session management features:
- Configuring session resumption
- Handling `sessionResumptionUpdate` messages
- Saving and restoring session handles
- Context window compression configuration
- Handling `goAway` messages (server disconnect warnings)

**Run:**
```bash
# First run to create a session
dart examples/session_resumption.dart

# Set the session handle and run again to resume
export GEMINI_SESSION_HANDLE="your-session-handle"
dart examples/session_resumption.dart
```

### 5. manual_activity_detection.dart
Shows manual activity detection when automatic VAD is disabled:
- Disabling automatic activity detection
- Using `sendActivityStart()` to signal speech start
- Using `sendActivityEnd()` to signal speech end
- Manually controlling turn handling

**Run:**
```bash
dart examples/manual_activity_detection.dart
```

### 6. complete_features.dart
A comprehensive example demonstrating all features:
- Basic text input/output
- Function calling
- Multi-turn client content
- Realtime audio input
- Realtime video input
- Realtime text input
- Media chunks
- Combined realtime input
- Audio transcription
- Session resumption
- Context window compression
- Voice activity detection
- Token usage tracking

**Run:**
```bash
dart examples/complete_features.dart
```

## Prerequisites

1. **API Key**: All examples require a Gemini API key. Replace `'YOUR_API_KEY'` with your actual API key in each example, or set it as an environment variable:
   ```bash
   export GEMINI_API_KEY="your-api-key"
   ```

2. **Dependencies**: Make sure you have the dependencies installed:
   ```bash
   dart pub get
   ```

## Common Features Demonstrated

### LiveClientMessage Types

#### 1. Setup Message
```dart
LiveClientMessage(
  setup: LiveClientSetup(
    model: 'models/gemini-live-2.5-flash-preview',
    generationConfig: GenerationConfig(...),
    systemInstruction: Content(...),
    tools: [...],
    // ... other config options
  ),
)
```

#### 2. Client Content Message
```dart
LiveClientMessage(
  clientContent: LiveClientContent(
    turns: [Content(...)],
    turnComplete: true,
  ),
)
```

#### 3. Realtime Input Message
```dart
LiveClientMessage(
  realtimeInput: LiveClientRealtimeInput(
    audio: Blob(...),
    video: Blob(...),
    mediaChunks: [...],
    text: 'realtime text',
    audioStreamEnd: true,
    activityStart: ActivityStart(),
    activityEnd: ActivityEnd(),
  ),
)
```

#### 4. Tool Response Message
```dart
LiveClientMessage(
  toolResponse: LiveClientToolResponse(
    functionResponses: [
      FunctionResponse(
        id: 'call-id',
        name: 'function_name',
        response: {...},
      ),
    ],
  ),
)
```

### LiveServerMessage Handling

Handle various server message types:

```dart
onMessage: (message) {
  // Text response
  if (message.text != null) {
    print(message.text);
  }
  
  // Audio data
  if (message.data != null) {
    // Handle audio
  }
  
  // Tool calls
  if (message.toolCall != null) {
    // Handle function calls
  }
  
  // Tool call cancellation
  if (message.toolCallCancellation != null) {
    // Handle cancellation
  }
  
  // Session resumption update
  if (message.sessionResumptionUpdate != null) {
    // Save session handle
  }
  
  // Server disconnect warning
  if (message.goAway != null) {
    // Prepare for disconnect
  }
  
  // Voice activity
  if (message.voiceActivity != null) {
    // Handle VAD
  }
  
  // Token usage
  if (message.usageMetadata != null) {
    // Track usage
  }
}
```

### Configuration Options

#### Generation Config
```dart
config: GenerationConfig(
  temperature: 0.7,
  maxOutputTokens: 1024,
  responseModalities: [Modality.AUDIO, Modality.TEXT],
)
```

#### Realtime Input Config
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

#### Session Resumption
```dart
sessionResumption: SessionResumptionConfig(
  handle: 'previous-session-handle', // null for new session
  transparent: true,
)
```

#### Context Window Compression
```dart
contextWindowCompression: ContextWindowCompressionConfig(
  triggerTokens: '10000',
  slidingWindow: SlidingWindow(targetTokens: '5000'),
)
```

#### Audio Transcription
```dart
inputAudioTranscription: AudioTranscriptionConfig(),
outputAudioTranscription: AudioTranscriptionConfig(),
```

#### Proactivity Config
```dart
proactivity: ProactivityConfig(proactiveAudio: true),
```

## Tips

1. **Always close the session**: Use `session.close()` when done to properly close the WebSocket connection.

2. **Handle errors**: Implement `onError` callback to handle connection errors.

3. **Save session handles**: When using session resumption, save the handle to resume later.

4. **Check connection status**: Use `session.isClosed` to check if the connection is still open.

5. **Use appropriate modalities**: Set `responseModalities` based on your use case (text only, audio only, or both).

6. **Configure VAD properly**: Adjust `AutomaticActivityDetection` settings based on your audio input characteristics.

## More Information

For more details, see:
- [Main README](../README.md)
- [API Documentation](https://ai.google.dev/api)
- [Dart Package Documentation](https://pub.dev/packages/gemini_live)
