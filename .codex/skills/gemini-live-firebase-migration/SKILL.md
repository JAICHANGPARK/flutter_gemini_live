---
name: gemini-live-firebase-migration
description: Migrate Flutter/Dart Gemini Live code between `firebase_ai` (Firebase AI Logic) and the `gemini_live` package, in either direction. Use when a project imports `package:firebase_ai` and uses `liveGenerativeModel`, `LiveSession`, `sendAudioRealtime`, `sendMediaStream` or `receive()` and wants to drop Firebase; when code using `package:gemini_live/compat/firebase_ai.dart` must move back to `firebase_ai`; or when code using the core `gemini_live` API (`GoogleGenAI`, `genAI.live.connect`, `LiveCallbacks`) should be rewritten into the portable firebase_ai-compatible API.
---

# Gemini Live ⇄ Firebase AI Logic Migration Skill

`gemini_live` has a compatibility layer, `package:gemini_live/compat/firebase_ai.dart`, that mirrors the **Live API of `firebase_ai` 4.x**: same class names, constructors, methods and defaults. Code written against it compiles on both packages after an import swap.

Full reference: [`doc/firebase_ai_compat.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/doc/firebase_ai_compat.md).

---

## 🧭 Step 0: Identify the direction

Search the project first:

```bash
grep -rn "package:firebase_ai\|package:gemini_live" lib test
grep -rn "Firebase.initializeApp\|FirebaseAI\.\(googleAI\|vertexAI\|agentPlatform\)" lib
grep -rn "genAI.live.connect\|LiveConnectParameters\|GeminiLiveSessionController" lib
```

| What you find | Workflow |
| :--- | :--- |
| `package:firebase_ai` + `liveGenerativeModel` | **A**: firebase_ai → gemini_live |
| `package:gemini_live/compat/firebase_ai.dart` | **B**: gemini_live → firebase_ai |
| `package:gemini_live/gemini_live.dart` + `genAI.live.connect` | **C**: core API → compat API (then B if needed) |

---

## ⛔ Do NOT

- Do **not** edit `lib/src/` of the `gemini_live` package. Migration happens in the app.
- Do **not** call `startMediaStream`. It does not exist in `firebase_ai` 4.x or the compat layer. Use `sendAudioRealtime` / `sendVideoRealtime` (or deprecated `sendMediaStream`).
- Do **not** mix types between packages. `Content`, `Part`, `Tool`, `LiveSession` from `firebase_ai`, the compat layer and the core API are three unrelated sets of classes. Build each with the import it is passed to.
- Do **not** import `package:gemini_live/gemini_live.dart` without a prefix in a file that also imports the compat layer. Names collide (`Content`, `Part`, `Tool`, `LiveSession`, `SpeechConfig`, ...).
- Do **not** ship a raw API key after removing Firebase App Check. Use ephemeral tokens.
- Do **not** claim a migration works without running `dart analyze` (and tests).

---

## 🅰️ Workflow A: firebase_ai → gemini_live

Only the Live API moves. Everything after `FirebaseAI.googleAI()` stays as is.

1. **pubspec**
   ```bash
   flutter pub add gemini_live
   ```
   Remove `firebase_ai`, `firebase_core`, `firebase_app_check`, `firebase_auth` only if nothing else in the app uses them (step 6).

2. **Imports** (Live files only)
   ```diff
   - import 'package:firebase_core/firebase_core.dart';
   - import 'package:firebase_ai/firebase_ai.dart';
   + import 'package:gemini_live/compat/firebase_ai.dart';
   ```

3. **Initialization**
   ```diff
   - await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   + FirebaseAI.initialize(apiKey: keyOrEphemeralToken);
   ```
   Or pass it per call: `FirebaseAI.googleAI(apiKey: ...)`.
   Remove `app:`, `appCheck:`, `auth:`, `useLimitedUseAppCheckTokens:` arguments from `googleAI(...)`.

4. **Security.** App Check no longer protects the key. In production, fetch an ephemeral token from a backend (`genAI.authTokens.create(...)` on the server side) and pass it as `apiKey`. Tokens starting with `auth_tokens/` select `v1alpha` automatically.

5. **Vertex AI.** Replace `FirebaseAI.vertexAI(...)` / `FirebaseAI.agentPlatform(...)` with `FirebaseAI.googleAI()`. The model ID stays the same if it exists on the Gemini Developer API.

6. **Non-Live APIs.** `generativeModel`, `imagenModel`, chat and templates are not in the compat layer. Either keep `firebase_ai` for them, with a prefix in shared files:
   ```dart
   import 'package:firebase_ai/firebase_ai.dart' as fb;   // generativeModel
   import 'package:gemini_live/compat/firebase_ai.dart';  // Live API
   ```
   or move them to another SDK. Keep `Firebase.initializeApp()` if `fb.` code remains.

7. **Review behavior differences** (table below), then run `dart analyze` and the app's tests.

Optional gemini_live extras after migrating:

```dart
print(session.tokenTracker.formatCost());          // Live token usage and cost
final usage = response.rawMessage?.usageMetadata;  // full core message
session.rawSession.sendAudioStreamEnd();           // core-only features
```

---

## 🅱️ Workflow B: gemini_live (compat) → firebase_ai

1. `flutter pub add firebase_ai firebase_core` and configure Firebase (`flutterfire configure`).
2. Swap the import back and restore `await Firebase.initializeApp(...)`.
3. Run `dart analyze`. The compiler lists every gemini_live-only call. Remove or replace each:

   | gemini_live-only | Replacement on firebase_ai |
   | :--- | :--- |
   | `FirebaseAI.initialize(apiKey:)` | `Firebase.initializeApp()` |
   | `FirebaseAI.googleAI(apiKey:, apiVersion:)` | `FirebaseAI.googleAI()` |
   | `session.tokenTracker` | None for Live; remove `GeminiLiveUsageBadge` |
   | `session.rawSession` | None; drop core-only features |
   | `response.rawMessage` | None |

4. **Subscribe to `receive()` before sending anything.** gemini_live buffers responses that arrive before the first listener; firebase_ai drops them. Code that calls `receive()` late will silently lose messages on firebase_ai.
5. `presencePenalty` / `frequencyPenalty` will now reach the server (gemini_live ignores them). Re-check output quality if they are set.

---

## 🅲 Workflow C: core gemini_live API → compat API

Use this when code written with `GoogleGenAI` / `genAI.live.connect` should become portable to `firebase_ai`.

| Core API (`package:gemini_live/gemini_live.dart`) | Compat API (`package:gemini_live/compat/firebase_ai.dart`) |
| :--- | :--- |
| `GoogleGenAI(apiKey: k).live.connect(LiveConnectParameters(model: m, ...))` | `FirebaseAI.googleAI(apiKey: k).liveGenerativeModel(model: m, ...).connect()` |
| `config: GenerationConfig(responseModalities: [Modality.AUDIO], speechConfig: SpeechConfig.fromVoice('Puck'))` | `liveGenerationConfig: LiveGenerationConfig(responseModalities: [ResponseModalities.audio], speechConfig: SpeechConfig(voiceName: 'Puck'))` |
| `inputAudioTranscription: AudioTranscriptionConfig()` (parameter) | `LiveGenerationConfig(inputAudioTranscription: AudioTranscriptionConfig())` |
| `realtimeInputConfig`, `contextWindowCompression` (parameters) | Same names inside `LiveGenerationConfig` |
| `sessionResumption: SessionResumptionConfig(handle: h)` | `connect(sessionResumption: SessionResumptionConfig.resume(h))` |
| `systemInstruction: Content(role: 'system', parts: [Part(text: s)])` | `systemInstruction: Content.system(s)` |
| `Tool(functionDeclarations: [FunctionDeclaration(name:, description:, parameters: {...json})])` | `Tool.functionDeclarations([FunctionDeclaration(name, description, parameters: {'x': Schema.string()})])` |
| `LiveCallbacks(onMessage: handle)` | `session.receive().listen(...)` / `await for` |
| `message.serverContent` | `response.message is LiveServerContent` |
| `message.toolCall!.functionCalls` | `response.message is LiveServerToolCall` → `.functionCalls` |
| `message.toolCallCancellation!.ids` | `LiveServerToolCallCancellation.functionIds` |
| `message.goAway` | `GoingAwayNotice.timeLeft` |
| `message.sessionResumptionUpdate` | `SessionResumptionUpdate.newHandle` |
| `message.usageMetadata` | `response.rawMessage?.usageMetadata` (gemini_live only) |
| `message.text` / `message.data` (base64) | Iterate `modelTurn.parts`: `TextPart.text`, `InlineDataPart.bytes` (raw bytes) |
| `session.sendAudio(bytes)` | `session.sendAudioRealtime(InlineDataPart('audio/pcm;rate=16000', bytes))` |
| `session.sendVideo(bytes, mimeType: 'image/jpeg')` | `session.sendVideoRealtime(InlineDataPart('image/jpeg', bytes))` |
| `session.sendRealtimeText(t)` | `session.sendTextRealtime(t)` |
| `session.sendText(t)` | `session.send(input: Content.text(t), turnComplete: true)` |
| `session.sendClientContent(turns: [...], turnComplete: x)` | `session.send(input: content, turnComplete: x)` (default is **false**) |
| `session.sendActivityStart()` / `sendActivityEnd()` | `sendStartActivityRealtime()` / `sendStopActivityRealtime()` |
| `session.sendToolResponse(functionResponses: [FunctionResponse(id:, name:, response:)])` | `session.sendToolResponse([FunctionResponse(name, response, id: id)])` |
| `session.close()` | `session.close()` |

Message handling rewritten with the compat API:

```dart
await for (final response in session.receive()) {
  final message = response.message;
  switch (message) {
    case LiveServerContent():
      if (message.interrupted == true) player.clear(); // barge-in
      for (final part in message.modelTurn?.parts ?? const <Part>[]) {
        if (part is InlineDataPart) player.add(part.bytes);
        if (part is TextPart) print(part.text);
      }
    case LiveServerToolCall():
      for (final call in message.functionCalls ?? const <FunctionCall>[]) {
        final result = await runTool(call.name, call.args);
        await session.sendToolResponse([FunctionResponse(call.name, result, id: call.id)]);
      }
    case SessionResumptionUpdate():
      saveHandle(message.newHandle);
    default:
      break;
  }
}
```

**Stays on the core API** (no firebase_ai equivalent, so not portable): `GeminiLiveSessionController` and controller-driven widgets, `translationConfig`, `thinkingConfig`, `proactivity`, `enableAffectiveDialog`, `explicitVadSignal`, `historyConfig`, avatar config, Live Music (`genAI.live.music`), voices and auth-token services. Keep those files on the core API, or reach the core session through `session.rawSession` and accept that the code becomes gemini_live-only.

---

## ⚖️ Behavior differences to check

| Topic | firebase_ai | gemini_live compat |
| :--- | :--- | :--- |
| Responses before the first `receive()` listener | Dropped | Buffered (up to 256), including `LiveServerSetupComplete` |
| `connect()` | Returns when the socket opens | Waits for the setup reply; setup errors and timeouts throw here |
| Server `error` frames | Thrown as `InvalidApiKey`, `QuotaExceeded`, ... | Show up as a socket close; exception types exist for compilation |
| `sendMediaStream` / `sendMediaChunks` | Deprecated `media_chunks` field | `audio` / `video` fields by MIME type |
| `presencePenalty`, `frequencyPenalty` | Sent | Ignored (debug log) |
| Live usage metadata | Not exposed | `session.tokenTracker`, `response.rawMessage` |

When code handles `response.message` with a `switch`, keep a `default:` branch. `LiveServerSetupComplete` is not exported by `firebase_ai`, so an exhaustive switch cannot name it.

---

## ✅ Verification

1. `dart analyze` reports no errors.
2. Run the app's tests and one live session (voice in, audio out, one tool call if used).
3. To prove a file stays portable, compile it against both packages: copy it to a scratch package that depends on `firebase_ai`, replace `package:gemini_live/compat/firebase_ai.dart` with `package:firebase_ai/firebase_ai.dart`, and run `dart analyze`. The gemini_live repo does this in [`tool/check_firebase_ai_compat.sh`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/tool/check_firebase_ai_compat.sh) for [`test/compat/firebase_ai_portable_sample.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/test/compat/firebase_ai_portable_sample.dart).
4. Report to the user: which workflow ran, files changed, gemini_live-only or firebase_ai-only code that remains, and the behavior differences that apply to their code.
