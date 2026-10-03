# Firebase AI Logic Compatibility & Migration

`gemini_live` ships a compatibility layer that mirrors the **Live API of
[`package:firebase_ai`](https://pub.dev/packages/firebase_ai) 4.x**: the same
class names, constructors, method names and defaults. It runs on the
`gemini_live` WebSocket engine and needs no Firebase project.

```dart
import 'package:gemini_live/compat/firebase_ai.dart';
```

The core `gemini_live` API (`GoogleGenAI`, `LiveSession`,
`GeminiLiveSessionController`, widgets) is unchanged. The compatibility layer is
a separate entry point that sits on top of it.

- [What is covered](#what-is-covered)
- [Migrating from firebase_ai to gemini_live](#migrating-from-firebase_ai-to-gemini_live)
- [Migrating from gemini_live back to firebase_ai](#migrating-from-gemini_live-back-to-firebase_ai)
- [gemini_live-only extras](#gemini_live-only-extras)
- [Behavior differences](#behavior-differences)
- [Using both packages in one app](#using-both-packages-in-one-app)
- [Verifying compatibility](#verifying-compatibility)

## What is covered

| Area | firebase_ai 4.x API | Compat layer |
| :--- | :--- | :--- |
| Entry point | `FirebaseAI.googleAI()` | ✅ (plus `FirebaseAI.initialize(apiKey:)`) |
| Model | `liveGenerativeModel(model:, liveGenerationConfig:, tools:, systemInstruction:)` | ✅ |
| Connect | `connect({sessionResumption})` | ✅ |
| Config | `LiveGenerationConfig`, `SpeechConfig` (single and `multiSpeaker`), `AudioTranscriptionConfig`, `RealtimeInputConfig`, `ActivityDetectionConfig`, `ContextWindowCompressionConfig`, `SessionResumptionConfig`, `ResponseModalities`, `MediaResolution` | ✅ |
| Content | `Content(role, parts)`, `Content.text/inlineData/multi/model/system/functionResponse(s)` | ✅ |
| Parts | `TextPart`, `InlineDataPart`, `FunctionCall`, `FunctionResponse`, `FileData`, `ExecutableCodePart`, `CodeExecutionResultPart`, `UnknownPart` | ✅ |
| Tools | `Tool.functionDeclarations/googleSearch/codeExecution/urlContext/googleMaps`, `FunctionDeclaration`, `AutoFunctionDeclaration`, `Schema`, `JSONSchema` | ✅ |
| Send | `send`, `sendAudioRealtime`, `sendVideoRealtime`, `sendTextRealtime`, `sendStartActivityRealtime`, `sendStopActivityRealtime`, `sendToolResponse`, `sendMediaStream`*, `sendMediaChunks`* | ✅ (*deprecated, as in firebase_ai) |
| Receive | `receive()` → `LiveServerResponse.message` (`LiveServerContent`, `LiveServerToolCall`, `LiveServerToolCallCancellation`, `GoingAwayNotice`, `SessionResumptionUpdate`) | ✅ |
| Session | `resumeSession({sessionResumption})`, `close()` | ✅ |
| Errors | `FirebaseAIException`, `InvalidApiKey`, `QuotaExceeded`, `ServerException`, `UnsupportedUserLocation`, `ServiceApiNotEnabled`, `FirebaseAISdkException` | ✅ (types only; see [Behavior differences](#behavior-differences)) |
| Not provided | `FirebaseAI.vertexAI()`, `FirebaseAI.agentPlatform()`, `generativeModel`, `imagenModel`, chat, templates | ❌ compile error |

Anything that is not provided fails at **compile time**, never silently at
runtime.

## Migrating from firebase_ai to gemini_live

Two edits. Everything from `FirebaseAI.googleAI()` onward stays the same.

```diff
- import 'package:firebase_core/firebase_core.dart';
- import 'package:firebase_ai/firebase_ai.dart';
+ import 'package:gemini_live/compat/firebase_ai.dart';

  Future<void> main() async {
-   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
+   FirebaseAI.initialize(apiKey: 'YOUR_KEY_OR_EPHEMERAL_TOKEN');

    final model = FirebaseAI.googleAI().liveGenerativeModel(
      model: 'gemini-2.5-flash-native-audio-preview-12-2025',
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [ResponseModalities.audio],
        speechConfig: SpeechConfig(voiceName: 'Puck'),
      ),
    );
    final session = await model.connect();
    ...
  }
```

Checklist:

1. **pubspec:** add `gemini_live`; remove `firebase_ai` (and `firebase_core`,
   `firebase_app_check`, `firebase_auth` if nothing else uses them).
2. **Initialization:** replace `Firebase.initializeApp()` with
   `FirebaseAI.initialize(apiKey: ...)`, or pass
   `FirebaseAI.googleAI(apiKey: ...)`. Remove `app:`, `appCheck:`, `auth:` and
   `useLimitedUseAppCheckTokens:` arguments.
3. **Security:** Firebase App Check no longer protects the key. Do not ship a
   raw API key; mint an ephemeral token on your backend and pass it as the
   key. Tokens starting with `auth_tokens/` select the `v1alpha` API
   automatically. See [Ephemeral Tokens](advanced_configuration.md).
4. **Vertex AI:** code using `FirebaseAI.vertexAI()` must switch to
   `googleAI()` (Gemini Developer API).
5. **Non-Live APIs:** keep `firebase_ai` for `generativeModel` and friends, or
   move them to another SDK. See
   [Using both packages in one app](#using-both-packages-in-one-app).
6. Run your tests and review [Behavior differences](#behavior-differences).

## Migrating from gemini_live back to firebase_ai

Code written against `package:gemini_live/compat/firebase_ai.dart` moves back
with the reverse two edits:

```diff
- import 'package:gemini_live/compat/firebase_ai.dart';
+ import 'package:firebase_core/firebase_core.dart';
+ import 'package:firebase_ai/firebase_ai.dart';

- FirebaseAI.initialize(apiKey: '...');
+ await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Checklist:

1. **Remove gemini_live-only calls.** The compiler lists them after the import
   swap: `FirebaseAI.initialize`, `googleAI(apiKey:/apiVersion:)`, and
   everything in [gemini_live-only extras](#gemini_live-only-extras)
   (`session.tokenTracker`, `session.rawSession`, `response.rawMessage`).
2. **Subscribe to `receive()` before sending.** gemini_live buffers responses
   that arrive before the first listener; firebase_ai drops them.
3. **`presencePenalty` / `frequencyPenalty`** start being sent to the server.
4. **Core API code** (`GoogleGenAI`, `genAI.live.connect`,
   `GeminiLiveSessionController`) is not part of the firebase_ai API and must
   be rewritten. Only code written against the compat layer is portable.
5. **Features firebase_ai cannot replace** are lost. Decide what to do with
   each before switching:

| gemini_live feature | On firebase_ai 4.x Live |
| :--- | :--- |
| Speech translation (`TranslationConfig`, translate model) | Not available |
| Live Music / Lyria RealTime (`genAI.live.music`) | Not available |
| Usage and cost (`usageMetadata`, `tokenTracker`, `GeminiLiveUsageBadge`) | Not exposed |
| Thinking (`thinkingConfig`), affective dialog, proactive audio | Not available |
| Transcription options (`languageCodes`, `customVocabulary`, `mode`) | Transcription on/off only |
| Custom and cloned voices, voices API | Prebuilt `voiceName` only |
| Async tools (`Behavior.NON_BLOCKING`, `scheduling`, `willContinue`), streamed `partialArgs` | Blocking tool calls only |
| Tool options and extra tools (`excludeDomains`, `groundingTypes`, `computerUse`, `mcpServers`, `fileSearch`, ...) | Plain Search / Maps / URL context / code execution |
| Grounding metadata, `turnCompleteReason`, `waitingForInput`, `interactionStatus`, VAD signals | Not exposed |
| `sendAudioStreamEnd`, `historyConfig`, `avatarConfig`, `safetySettings`, `seed`, `labels` | Not available |
| Ephemeral tokens (`genAI.authTokens`) | Use Firebase App Check instead |
| `GeminiLiveSessionController` | Write your own state holder |

   The UI widgets (`GeminiLiveMicButton`, `GeminiLiveVoiceIndicator`,
   `GeminiLiveCaptionBubble`, `GeminiLiveWaveform`, `GeminiLiveStatusBadge`)
   take plain values and keep working next to firebase_ai if `gemini_live`
   stays as a UI dependency. The
   [`gemini-live-firebase-migration`](../skills/gemini-live-firebase-migration/SKILL.md)
   agent skill has the search command and the action for each feature.

## gemini_live-only extras

These are extensions, kept apart from the firebase_ai surface so they are easy
to find (and remove) when moving back.

```dart
// Token usage and cost (firebase_ai does not expose Live usage metadata).
final tracker = session.tokenTracker;
print('${tracker.totalTokens} tokens, ${tracker.formatCost()}');

// Works with the pre-built widget:
GeminiLiveUsageBadge(tracker: session.tokenTracker);

// Full core message behind a response (usage, grounding, voice activity, ...).
final usage = response.rawMessage?.usageMetadata;

// Core session for features outside the firebase_ai API.
session.rawSession.sendAudioStreamEnd();
```

`GeminiLiveUsageBadge` and `GeminiLiveWaveform` (fed with your audio stream)
work with compat sessions; import `package:gemini_live/gemini_live.dart` with a
prefix to use them (see below). Widgets driven by
`GeminiLiveSessionController` need the core API.

## Behavior differences

| Topic | firebase_ai | gemini_live compat |
| :--- | :--- | :--- |
| Early responses | Dropped if nobody listens to `receive()` yet | Buffered (up to 256) and delivered to the first listener, including `LiveServerSetupComplete` |
| `connect()` | Returns once the socket opens; setup errors surface later | Waits for the server's setup reply; setup errors and timeouts throw from `connect()` |
| Server `error` frames | Thrown as `InvalidApiKey`, `QuotaExceeded`, … on the stream | Not surfaced; failures appear as a socket close. The exception types exist so `on QuotaExceeded` still compiles |
| Sends after close | `LiveWebSocketClosedException` | Same message format, including close code and reason |
| `sendMediaStream` / `sendMediaChunks` | Sends deprecated `media_chunks` | Sends `audio` (for `audio/*`) or `video` (for `image/*`, `video/*`) |
| `presencePenalty`, `frequencyPenalty` | Sent | Accepted but not sent yet (debug log on `connect()`) |
| Socket error | Stream ends when the socket closes | Stream ends once the socket is confirmed closed |

## Using both packages in one app

The compat layer and `firebase_ai` export the same names, and neither shares
types with the core `gemini_live` API. Use import prefixes in files that need
more than one of them:

```dart
import 'package:firebase_ai/firebase_ai.dart' as fb;          // generativeModel
import 'package:gemini_live/compat/firebase_ai.dart';         // Live API
import 'package:gemini_live/gemini_live.dart' as gl;          // widgets
```

`Content`, `Part` and `Tool` objects are not interchangeable between packages;
build them with the matching import.

## Verifying compatibility

- [`test/compat/firebase_ai_portable_sample.dart`](../test/compat/firebase_ai_portable_sample.dart)
  uses only the firebase_ai API. `test/firebase_ai_compat_test.dart` runs it
  against a fake Live server.
- [`tool/check_firebase_ai_compat.sh`](../tool/check_firebase_ai_compat.sh)
  swaps its import to `package:firebase_ai` and runs `dart analyze`, proving
  the same source compiles on both packages. Pass a version to check another
  release: `tool/check_firebase_ai_compat.sh 4.1.0`.
