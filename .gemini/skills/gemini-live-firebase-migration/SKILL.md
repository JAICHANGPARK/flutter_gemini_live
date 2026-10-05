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
6. **Audit gemini_live-only features** with the inventory below. Code on the core API (`package:gemini_live/gemini_live.dart`) must first go through Workflow C; whatever has no compat equivalent appears in this table.

### 🚫 gemini_live-only features firebase_ai cannot replace

`firebase_ai` 4.x Live exposes only: `LiveGenerationConfig` (speech voice/language, transcription on/off, `realtimeInputConfig`, `contextWindowCompression`, sampling params, `mediaResolution`, `responseModalities`), `systemInstruction`, `tools` (function declarations, Google Search, code execution, URL context, Google Maps, all without options), session resumption, and the `send*` / `receive` methods. Everything below is **lost** when moving to firebase_ai.

Search for them first:

```bash
grep -rnE "thinkingConfig|enableAffectiveDialog|proactivity|ProactivityConfig|translationConfig|TranslationConfig|explicitVadSignal|historyConfig|avatarConfig|safetySettings|seed:|labels:|languageCodes|customVocabulary|languageHints|AudioTranscriptionConfigMode|replicatedVoiceConfig|promptedVoiceConfig|VoiceConfig\.fromVoiceId|transparent:|Behavior\.NON_BLOCKING|FunctionResponseScheduling|willContinue|partialArgs|computerUse|mcpServers|fileSearch|excludeDomains|timeRangeFilter|groundingTypes|usageMetadata|tokenTracker|GeminiLiveUsageBadge|groundingMetadata|urlContextMetadata|turnCompleteReason|generationComplete|waitingForInput|interimInputTranscription|interactionStatus|voiceActivity|sendAudioStreamEnd|authTokens|AuthTokensService|live\.music|LiveMusic|voices\.|GeminiVoicesService|GeminiLiveSessionController|rawSession|rawMessage|apiVersion" lib
```

| Feature | gemini_live API | firebase_ai 4.x | Action when migrating |
| :--- | :--- | :--- | :--- |
| **Thinking** | `GenerationConfig.thinkingConfig` | Not in Live (only `generateContent`) | Remove; model default applies. Tell the user reasoning depth may change. |
| **Affective dialog** | `enableAffectiveDialog` | None | Remove. |
| **Proactive audio** | `ProactivityConfig` (`proactivity:`) | None | Remove; the model answers every turn. |
| **Speech translation** | `TranslationConfig`, `gemini-3.5-live-translate-preview` | None | Not migratable. Keep this feature on gemini_live, or prompt a regular Live model to translate (lower quality, no translate model). |
| **Explicit VAD signals** | `explicitVadSignal`, `VoiceActivityDetectionSignal`, `VoiceActivity` messages | None | Remove; derive "user speaking" from your own mic level or use `sendStart/StopActivityRealtime` with manual VAD. |
| **Transcription options** | `AudioTranscriptionConfig(languageCodes:, customVocabulary:, languageHints:, mode:)` | `AudioTranscriptionConfig()` has no options | Drop the options; transcription stays on with defaults. Custom vocabulary is lost. |
| **Custom / cloned voices** | `VoiceConfig.fromVoiceId`, `replicatedVoiceConfig`, `promptedVoiceConfig`, `GeminiVoicesService` | `SpeechConfig(voiceName:)` / `SpeechConfig.fromLiveVoice(GeminiLiveVoice)` prebuilt voices only | Pick the closest prebuilt voice (`GeminiLiveVoice.puck`, etc.). Voice management APIs are lost. |
| **Async (non-blocking) tools** | `FunctionDeclaration(behavior: Behavior.NON_BLOCKING)`, `FunctionResponse(scheduling:, willContinue:)` | None; tool calls block the turn | Make tools fast or return a placeholder result; scheduling semantics are lost. |
| **Streamed function args** | `FunctionCall.partialArgs` | None | Wait for the complete `FunctionCall.args`. |
| **Extra tools / tool options** | `computerUse`, `mcpServers`, `fileSearch`, `enterpriseWebSearch`, Exa / Parallel search, `GoogleSearch(excludeDomains:, timeRangeFilter:)`, `GoogleMaps(groundingTypes:)` | Plain `googleSearch()` / `googleMaps()` / `urlContext()` / `codeExecution()` | Drop options; replace other tools with your own function declarations. |
| **Usage / cost tracking** | `usageMetadata`, `GeminiTokenUsageTracker`, `session.tokenTracker`, `GeminiLiveUsageBadge` | Not exposed for Live | Remove the badge and cost UI, or estimate cost server-side. |
| **Grounding / URL metadata** | `serverContent.groundingMetadata`, `urlContextMetadata` | Not exposed for Live | Remove source citations UI. |
| **Turn details** | `turnCompleteReason`, `generationComplete`, `waitingForInput`, `interimInputTranscription`, `interactionStatus`, `Transcription.languageCode`, `goAway.reason` | Only `turnComplete`, `interrupted`, transcription text/finished, `timeLeft` | Rewrite logic on `turnComplete` / `interrupted`. |
| **Audio stream end** | `sendAudioStreamEnd()` | None | Remove; stop sending audio, or use `sendStopActivityRealtime()` with manual VAD. |
| **Setup extras** | `historyConfig`, `avatarConfig`, `safetySettings`, `seed`, `labels`, `SessionResumptionConfig(transparent:)`, `apiVersion` | None | Remove. |
| **Ephemeral tokens** | `genAI.authTokens` / `AuthTokensService` | Replaced by Firebase App Check | Delete token minting; set up App Check (`firebase_app_check`). |
| **Live Music (Lyria RealTime)** | `genAI.live.music`, `LiveMusicSession` | None | Not migratable. Keep gemini_live for music, or drop the feature. |
| **Session controller** | `GeminiLiveSessionController` | None | Rebuild state (connection, transcripts, interruption) in your own `ChangeNotifier` around `firebase_ai`'s `LiveSession`. |
| **Model IDs** | `LiveModels.*` constants, e.g. `gemini-3.8-live` | Plain strings | Use string IDs and confirm each model is available through Firebase AI Logic before switching. |

**Can stay:** the UI widgets take plain values, so they keep working with firebase_ai if `gemini_live` stays as a UI-only dependency:
`GeminiLiveMicButton(isRecording:)`, `GeminiLiveVoiceIndicator(isSpeaking:)`, `GeminiLiveCaptionBubble(text:, role:)`, `GeminiLiveWaveform(amplitude:/amplitudeStream:/audioStream:)`, `GeminiLiveStatusBadge(state:)` (map your own state to `GeminiLiveSessionState`), and `GeminiLiveAudioUtils` / `addWavHeader()`. Import `package:gemini_live/gemini_live.dart` with a prefix next to `firebase_ai`. Only `GeminiLiveUsageBadge` needs usage data firebase_ai does not provide.

**Report to the user before editing:** list every hit from the search above with its action, and call out the ones that remove product features (translation, Live Music, usage/cost UI, custom voices, async tools). Those need the user's decision, not a silent deletion.

---

## 🅲 Workflow C: core gemini_live API → compat API

Use this when code written with `GoogleGenAI` / `genAI.live.connect` should become portable to `firebase_ai`.

| Core API (`package:gemini_live/gemini_live.dart`) | Compat API (`package:gemini_live/compat/firebase_ai.dart`) |
| :--- | :--- |
| `GoogleGenAI(apiKey: k).live.connect(LiveConnectParameters(model: m, ...))` | `FirebaseAI.googleAI(apiKey: k).liveGenerativeModel(model: m, ...).connect()` |
| `config: GenerationConfig(responseModalities: [Modality.AUDIO], speechConfig: SpeechConfig.fromLiveVoice(GeminiLiveVoice.puck))` | `liveGenerationConfig: LiveGenerationConfig(responseModalities: [ResponseModalities.audio], speechConfig: SpeechConfig.fromLiveVoice(GeminiLiveVoice.puck))` |
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
