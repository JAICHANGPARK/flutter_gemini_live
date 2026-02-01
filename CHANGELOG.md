## 0.2.0

### New Features (Based on js-genai v1.39.0 Gemini Live API Updates)

#### Live Server Message Types
- Added `LiveServerToolCall` - Handle tool/function call requests from the model
- Added `LiveServerToolCallCancellation` - Handle tool call cancellation
- Added `LiveServerGoAway` - Receive server disconnect warnings
- Added `LiveServerSessionResumptionUpdate` - Handle session resumption updates
- Added `VoiceActivityDetectionSignal` - Voice activity detection start/end signals
- Added `VoiceActivity` - Real-time voice activity status

#### Live Client Setup Configuration
- Added `RealtimeInputConfig` - Configure automatic activity detection, activity handling, and turn coverage
- Added `SessionResumptionConfig` - Enable session resumption with handle and transparent mode
- Added `ContextWindowCompressionConfig` - Configure context window compression with trigger tokens and sliding window
- Added `AudioTranscriptionConfig` - Enable input/output audio transcription
- Added `ProactivityConfig` - Configure proactive audio features
- Added `explicitVadSignal` option - Enable explicit VAD signaling

#### Live Client Realtime Input Enhancements
- Added `mediaChunks` support - Send multiple media chunks at once
- Added `audioStreamEnd` - Signal end of audio stream
- Added `text` - Send real-time text input
- Added `ActivityStart` / `ActivityEnd` - Manual activity detection signals

#### Function Calling Support
- Added `LiveClientToolResponse` - Send tool/function responses to the model
- Added `FunctionCall` - Model function call representation with id, name, and args
- Added `FunctionResponse` - Function response with id, name, and response data

#### New Session Methods
- Added `sendClientContent()` - Send multi-turn client content
- Added `sendRealtimeInput()` - Send combined real-time input (audio, video, text, activity signals)
- Added `sendMediaChunks()` - Send media chunks array
- Added `sendAudioStreamEnd()` - Signal audio stream end
- Added `sendRealtimeText()` - Send real-time text
- Added `sendActivityStart()` / `sendActivityEnd()` - Manual activity detection
- Added `sendToolResponse()` - Send tool responses
- Added `sendFunctionResponse()` - Send single function response
- Added `close()` - Close WebSocket connection
- Added `isClosed` getter - Check connection status

#### New Enums
- Added `ActivityHandling` - Activity handling strategies (START_OF_ACTIVITY_INTERRUPTS, etc.)
- Added `TurnCoverage` - Turn coverage options (TURN_INCLUDES_ALL_INPUT, etc.)
- Added `StartSensitivity` - Speech start sensitivity levels
- Added `EndSensitivity` - Speech end sensitivity levels

#### Example App Updates
- Added `live_api_demo.dart` - Comprehensive demo of all new features
- Added `function_calling_demo.dart` - Function calling demo with weather/time functions
- Added `realtime_media_demo.dart` - Real-time media input with manual/auto VAD
- Updated `main.dart` - New home page with navigation to all demos

### Improvements
- Added `data` getter to `LiveServerMessage` for accessing base64 encoded inline data
- Updated User-Agent to `google-genai-sdk/1.39.0`
- Added `TimeoutException` for connection timeout handling
- Improved documentation and examples

## 0.1.1

- Update dependencies and generated model serialization
- Update web_socket_service_web.dart
- Update web_socket_service_stub.dart

## 0.1.0

- Update Readme
- Documentation

## 0.0.5

- Update Readme

## 0.0.4

- Update Readme

## 0.0.3

- Add Example
- Improve Web Support
- Remove Platform.version (dartVersion)

## 0.0.2

- Update README.md

## 0.0.1

- Initial version of the package.
- Added Gemini Live Code
