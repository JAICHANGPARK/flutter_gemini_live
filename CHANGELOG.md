## 2026.10.5

### Added
- `LiveModels.gemini35LiveTranslatePreview` (`gemini-3.5-live-translate-preview`) for speech-to-speech translation.
- `SpeechAnnotation` model and serialization for voice synthesis metadata (js-genai 2.27.0 sync).
- `GoogleGenAI.music` getter that exposes the Realtime Music service directly.
- **Type-Safe Voice Personas (`GeminiLiveVoice`)**:
  - Added enhanced enum `GeminiLiveVoice` covering Google's 30 official prebuilt voices (`puck`, `charon`, `kore`, `fenrir`, `aoede`, `leda`, `orus`, `zephyr`, etc.) with compile-time safety, tone styles, and pitch/gender metadata.
  - Added `SpeechConfig.fromLiveVoice(GeminiLiveVoice voice, {String? languageCode})` and extended `SpeechConfig.fromVoice(Object voice)` to accept both enums and custom strings.
  - Added `liveVoice` getter across `SpeechConfig`, `VoiceConfig`, and `PrebuiltVoiceConfig` for typed inspection and JSON round-trip deserialization.
  - Integrated `GeminiLiveVoice` with `GeminiLiveVoiceSelectorSheet` (`.showLiveVoice`, `onLiveVoiceSelected`, `.allLiveVoices` 30-voice catalog) and `GeminiVoiceOption.fromLiveVoice`.
  - Synchronized `GeminiLiveVoice` and `SpeechConfig.fromLiveVoice` in `package:gemini_live/compat/firebase_ai.dart`.
- Live/music service SDK version header bumped to js-genai `2.27.0`.

### Deprecated
- Model constants that were misfiled as Live models during the js-genai 2.27.0 sync. Upstream added them to the **Interactions** `Model` enum, not the Live API. They will be removed in a future release.
  - `LiveModels.geminiOmni11Flash`, `LiveModels.geminiOmniFlashPreview` (Gemini Omni is a video generation model).
  - `LiveModels.gemini38FlashTts`, `LiveModels.gemini38FlashLiteTts`, `LiveModels.gemini31FlashTtsPreview` (TTS models).
  - `LiveMusicModels.lyria35`, `LiveMusicModels.lyria3ClipPreview`, `LiveMusicModels.lyria3ProPreview` (not Realtime Music models; use `LiveMusicModels.lyriaRealtimeExp`).

### Example App
- Live Music Studio demo for Lyria RealTime, with Prompt DJ crossfader, tag bank, and auto-reset context.
- Pioneer-style Pro DJ Console and AI Studio Prompt DJ 4x4 rotary MIDI Box demos.
- Web Audio API real-time PCM streamer for Flutter Web playback.
- Removed non-realtime Lyria 3.x models from the Live Music Studio model picker.

### Documentation
- README (EN/KR/JP/ZH): AI Agents guide, Supported Models tables, Voice Quick Start (mic + playback + platform permissions), API key security note, and fixed widget snippets that did not compile.
- Agent Skills synchronized across Claude Code, Gemini CLI / Antigravity, Codex, and the open Agent Skills paths. Fixed snippets that did not compile, added mic/playback wiring, setup, and "Do NOT" guardrails.
- `doc/advanced_configuration.md`: fixed the function calling example.

## 2026.10.4

### Added (Upstream Parity with js-genai & python-genai)
- **Live Music API (`ai.live.music` / `LiveMusicService`)**:
  - Full bidirectional WebSocket streaming client for Gemini Realtime Music generation (`models/lyria-realtime-exp`) via `BidiGenerateMusic`.
  - Accessible via `genAI.live.music` or `liveService.music`.
  - Added session controls: `setWeightedPrompts()`, `setMusicGenerationConfig()`, `play()`, `pause()`, `stop()`, `resetContext()`.
  - Added full models and enums: `Scale`, `MusicGenerationMode`, `LiveMusicPlaybackControl`, `WeightedPrompt`, `LiveMusicGenerationConfig`, `LiveMusicClientMessage`, `LiveMusicServerMessage`, `AudioChunk` (with `bytes` helper getter), `LiveMusicFilteredPrompt`.
- **Ephemeral Authentication Tokens Service (`genAI.authTokens` / `AuthTokensService`)**:
  - Implemented `AuthTokensService` for issuing secure, short-lived client-side session tokens (`POST /v1alpha/authTokens`).
  - Supports `liveConnectConstraints` (locking model and `GenerationConfig`) and automated `fieldMask` generation with `lockAdditionalFields`.
  - Handles dual camelCase/snake_case JSON mapping for `AuthToken` responses.
- **Top-level `translationConfig` on `LiveConnectParameters`**:
  - Directly pass `TranslationConfig` on `LiveConnectParameters` for seamless realtime bidirectional translation without nesting in `GenerationConfig`.
- **Audio Transcription `languageCodes` Support**:
  - Removed outdated restriction prohibiting `languageCodes` in `AudioTranscriptionConfig`, aligning with upstream Gemini API support for transcription languages.

## 2026.10.3

### Changed & Improved (Design & Aesthetics)
- **Native Non-AI UI Overhaul across all Pre-built Widgets**:
  - **`GeminiLiveCaptionBubble`**:
    - Replaced garish neon-colored badges with sleek, native frosted glass (`enableBlur: true` with `BackdropFilter` and `ImageFilter.blur`).
    - Added subtle neutral speaker chips (`showSpeakerTag: true/false`), elegant subtitle typography, and smooth breathing indicator dot (`_PulsingDot` 900ms ease-in-out).
  - **`GeminiLiveWaveform`**:
    - Replaced mechanical rectangular bars with organic capsule pills (`borderRadius` defaulting to `barWidth / 2`).
    - Added `enableIdleBreathing: true` with organic sinusoidal micro-motion when idle, mimicking professional native audio recording equipment.
  - **`GeminiLiveStatusBadge`**:
    - Swapped out raw color-outline boxes for refined neutral surface containers with 0.5px borders.
    - Upgraded pulse dot to a modern halo ripple ring effect (`_PulseDot`) and softened semantic palette.
  - **`GeminiLiveMicButton`**:
    - Replaced generic BoxShadow blur glow with crisp, expanding concentric acoustic ripple rings and neutral dark/light tactile surface layers.
  - **`GeminiLiveVoiceIndicator`**:
    - Upgraded from simple single sine to organic dual-harmonic motion with bell-curve center envelopes and pill capsules.
  - **`GeminiLiveUsageBadge` & `GeminiLiveUsageDetailsDialog`**:
    - Removed arcade-like neon cyan/amber accents in favor of clean, professional SaaS observability dark/light surface aesthetics.

## 2026.10.2

### Added
- **GeminiLiveSessionController (`LiveSessionController`)**:
  - All-in-one Flutter `ChangeNotifier` state manager for handling Live API WebSocket connections, lifecycle (`disconnected`, `connecting`, `connected`, `error`), message streams, and errors.
  - Integrated real-time transcript timeline tracking (`LiveTranscriptItem`) for user input, interim speech, and model output with speaker attribution and style metadata.
  - Seamless barge-in interruption handling via `onInterrupted` callback.
  - Built-in token usage tracking integration (`TokenUsageTracker`) and audio stream helpers (`feedAudioPcm`, `sendText`).
- **GeminiLiveWaveform Widget**:
  - Real-time animated audio visualizer supporting continuous amplitude stream/normalized levels or raw 16-bit PCM byte streams.
  - Configurable bar count, wave style (`bars` vs `sine`), animated idle breathing, and gradient styling.
- **GeminiLiveCaptionBubble Widget**:
  - Live subtitle/caption bubble widget for streaming speech-to-text transcripts with animated streaming dot indicator.
  - Displays speaker badge, emotional/style tone indicators, and auto-dismiss after inactivity.
- **GeminiLiveAudioUtils**:
  - Production-grade PCM audio analysis helper: RMS amplitude, peak amplitude, decibels (dBFS), and logarithmic visual scaling for audio meters.

## 2026.10.1

### Added
- **LiveClientSetup & GenerationConfig Metadata Labels**:
  - Added `labels` (`Map<String, String>?`) to `LiveConnectParameters`, `LiveClientSetup`, and `GenerationConfig`.
  - Enables user-defined metadata labels for tracking, attribution, and aggregator safety identifiers (e.g. `safety_identifier`) adhering to unified Cloud label formatting.
- **Speech Synthesis Metadata (`SpeechMetadata`)**:
  - Added `SpeechMetadata` data model with `speaker` and `style` fields.
  - Added `Part.speechMetadata` (`speech_metadata`) to control per-part multi-speaker allocation and vocal styles (e.g. "whispering", "excited, fast-paced") during speech synthesis and Live conversations.
- **Gemini 3.8 Flash TTS Canonical Model Identifiers**:
  - Added canonical TTS model constants to `LiveModels`:
    - `LiveModels.gemini38FlashTts` (`'gemini-3.8-flash-tts'`): High-fidelity Gemini 3.8 Flash text-to-speech model.
    - `LiveModels.gemini38FlashLiteTts` (`'gemini-3.8-flash-lite-tts'`): Ultra-low-latency lightweight Gemini 3.8 Flash text-to-speech model.
- **Voice Resource Sample Audio**:
  - Added `sampleAudio` (`VoiceAudioData?`) to `VoiceResource` and `CreateVoiceRequest` (`sample_audio`), providing audio payload reference for newly designed and replicated voice assets.
- **Upstream Sync with `js-genai` 2.25.0 & `python-genai` 2.26.0**:
  - Bumped internal SDK client user-agent to `google-genai-sdk/2.25.0`.
  - Regenerated serialization code and updated unit test suites.

## 2026.9.20

### Added
- **Gemini Voices API Integration & Support**:
  - Added `GeminiVoicesService` (accessible via `genAI.voices` or standalone) for managing custom and prebuilt system voice catalog resources (`listVoices`, `createVoice`, `getVoice`, `deleteVoice`).
  - Added `VoiceResource` model supporting custom Google-managed voices, client-managed replication keys, and prebuilt catalog voices.
  - Added `CreateVoiceRequest` supporting natural-language prompted voices (`CreateVoiceRequest.prompted`) and audio-cloned replicated voices (`CreateVoiceRequest.replicated`).
  - Added `VoiceType` (`replicated`, `prompted`, `prebuilt`), `VoicePitch` (`low`, `medium`, `high`), `PromptedVoice`, `ReplicatedVoice`, `VoiceAudioData`, `ListVoicesResponse`, and `DeleteVoiceResponse` data models.
- **VoiceConfig & SpeechConfig Enhancements**:
  - Added `VoiceConfig.voice` string property to directly pass custom voice IDs (`voice_...`), replication keys (`voicekey_...`), or prebuilt voice names directly into speech synthesis.
  - Added `VoiceConfig.promptedVoiceConfig` support for natural-language designed voices.
  - Added ergonomic constructors: `VoiceConfig.fromVoiceName(String name)` and `VoiceConfig.fromVoiceId(String id)`.
  - Added `SpeechConfig.voice` property and `SpeechConfig.fromVoice(String voiceNameOrId, {String? languageCode})` convenience factory.
- **Upstream Sync & Documentation**:
  - Synced with upstream `js-genai` and `python-genai` discovery doc and Voices API resource updates.
  - Updated `AudioTranscriptionConfig.languageCodes` documentation reflecting current upstream preference over deprecated `languageHints`/`languageAuto`.

## 2026.9.19

### Added
- **Real-time Token Usage & Cost Tracking**:
  - Added `GeminiTokenUsageTracker`: Automatically tracks real-time prompt, candidate, thoughts, audio, video, image, and document token consumption per turn and session with model-specific cost estimation.
  - Added `GeminiLiveUsageBadge`: Sleek Material widget showing live token count and estimated cost, with interactive tap dialog (`GeminiLiveUsageDetailsDialog`) showing full multi-modal breakdowns.
- **Upstream Sync with `js-genai` 2.23.0 & `python-genai` 2.24.0**:
  - Added `TrafficType.ON_DEMAND_OFFPEAK` (`'ON_DEMAND_OFFPEAK'`) enum value.
  - Synced Live SDK request headers and user-agent string to `google-genai-sdk/2.23.0`.
  - Regenerated code generation artifacts (`models.g.dart`).
- **Example App Enhancements**:
  - Integrated `GeminiLiveUsageBadge` across live demo pages.
  - Added Live Media Subtitle & Live Smart Notetaker workflows.
- Removed legacy `experimental` designation across package metadata and documentation to reflect the official Stable release of the Gemini Live API.

## 2026.9.16

### Added
- **Gemini 3.8 Live & Extended Thinking Support**:
  - Added `LiveModels` class providing canonical model identifiers:
    - `LiveModels.gemini38Live` (`'gemini-3.8-live'`): Default stable Live API model for low-latency voice and multimodal dialogue without reasoning-induced delays.
    - `LiveModels.gemini38LiveExtendedThinking` (`'gemini-3.8-live-extended-thinking'`): High-reasoning Live model for voice interactions requiring deep background reasoning.
    - `LiveModels.gemini31FlashLivePreview` (`'gemini-3.1-flash-live-preview'`): Previous preview model.
    - `LiveModels.gemini25FlashNativeAudioPreview` (`'gemini-2.5-flash-native-audio-preview-12-2025'`).
- **Example App Updates**:
  - Set default model to `gemini-3.8-live` in `ApiKeyStore` and `LiveAPIDefaults`.
  - Added `gemini-3.8-live` and `gemini-3.8-live-extended-thinking` to model selection lists across all demo pages.
  - Updated connection logging to display active Gemini 3.8 Live model code.
- **Documentation & Guides**:
  - Updated `README.md`, `README_KR.md`, `README_JP.md`, and `README_ZH.md` with official Gemini 3.8 Live models.
  - Added Supported Live Models table to `doc/api_reference.md`.
  - Added Section 10: *Gemini 3.8 Live Migration & Best Practices* in `doc/advanced_configuration.md` covering model selection, omitting `thinking_level` on `gemini-3.8-live`, default non-blocking function execution, and completion tracking via `LiveServerContent.isInteractionComplete`.
  - Updated AI Agent Skill definition (`SKILL.md`) to guide assistant models with Gemini 3.8 Live patterns.

## 2026.9.11

### Added
- Added `LiveServerContent.isInteractionComplete` getter aligned with upstream `python-genai` 2.23.0 interaction lifecycle logic:
  - If `interactionStatus` is specified, evaluates whether the status has settled to `InteractionStatus.IDLE`.
  - Otherwise, cleanly falls back to `turnComplete == true`.
  - Makes handling multi-turn conversational chunking, tool call completion, and live agent turn boundaries significantly more ergonomic for Flutter developers.

### Changed
- Synced Gemini Live SDK request headers and user-agent string to `google-genai-sdk/2.22.0` (aligned with upstream `js-genai` 2.22.0).
- Bumped package version to `2026.9.11`.

### Tested
- Added unit tests for `LiveServerContent.isInteractionComplete` across all permutations (`turnComplete`, `interactionStatus` transitions).

## 2026.9.9

### Added
- Synced DTOs and features with `js-genai` versions 2.17.0 through 2.21.0 and `python-genai` 2.17.0 through 2.22.0 (changes through September 2026):
  - `InteractionStatus` enum (`UNSPECIFIED`, `IN_PROGRESS`, `@Deprecated('Use IDLE instead.') REQUIRES_ACTION`, `IDLE`) representing the live session activity status.
  - `LiveServerContent.interactionStatus` property sent by the server alongside `turnComplete`.
  - `MediaProcessing` enum (`MEDIA_PROCESSING_UNSPECIFIED`, `STATIC`, `AGENTIC`) and `Part.mediaProcessing` field indicating how input media is processed.
  - `AudioTranscriptionConfigMode` enum (`MODE_UNSPECIFIED`, `VERBATIM`, `SMART`) and `AudioTranscriptionConfig.mode` field for configuring smart disfluency removal and formatting.
  - `ToolParallelAiSearch` model class and `Tool.parallelAiSearch` field (supported in enterprise agent platform grounding).
  - `ToolType.MEDIA_PROCESSING` enum value.
  - `ServiceTier.DEFERRED` (`'deferred'`) enum value in `ServiceTier`.
  - `AuthToken`, `LiveConnectConstraints`, and `CreateAuthTokenConfig` DTO classes for ephemeral token constraints and configuration (`expireTime`, `newSessionExpireTime`, `uses`).
- **Reusable Flutter Material Widgets**:
  - `GeminiLiveStatusBadge` & `GeminiLiveStatusBadge.fromFlags()`: Real-time visual badge tracking connection state and `InteractionStatus` with animated pulsing indicators.
  - `GeminiLiveMicButton`: Interactive microphone button with animated ripple effects during voice recording.
  - `GeminiLiveVoiceIndicator`: Lightweight waveform audio bar visualizer animating rhythmically when speech or streaming is active.
- **Example App Updates**:
  - Integrated `GeminiLiveStatusBadge`, `GeminiLiveMicButton`, and `GeminiLiveVoiceIndicator` into `LiveAPIDemoPage`, `ChatPage`, and `RealtimeMediaDemoPage`.
  - Added live `InteractionStatus` monitoring (`IN_PROGRESS` / `IDLE`) and `AudioTranscriptionConfigMode.SMART` toggle to `LiveAPIDemoPage`.
- **Documentation & Specifications**:
  - Added dedicated `doc/widgets_guide.md` specifying widget states, visual indicators, constructor APIs, and a complete end-to-end screen example.
  - Updated `doc/api_reference.md`, `README.md`, and `README_KR.md` with official widget documentation links.

### Changed
- Upgraded package and example dependencies to their latest compatible versions (`camera: ^0.12.1`, `build_runner: ^2.16.1`, `flutter_lints: ^6.0.0`, etc.).
- Synced Live SDK request headers and user-agent to `google-genai-sdk/2.21.0` (synced with upstream `js-genai` 2.21.0).
- `LiveService.buildSetupMessage` now explicitly validates and rejects `Tool.parallelAiSearch` in Gemini Developer API mode with clear descriptive error messages.
- Bumped package version to `2026.9.9`.

### Fixed & Tested
- Expanded widget test suite (`test/widgets_test.dart`) to achieve 95%+ line coverage across all newly introduced Flutter widgets.
- Verified 0 warnings and 0 errors across `dart doc --dry-run` and `flutter analyze --fatal-infos --fatal-warnings`.

### Added
- Synced DTOs and features with `js-genai` versions 2.14.0, 2.15.0, and 2.16.0 (changes after July 24, 2026):
  - `GenerationConfig.audioTranscriptionConfig` (`audio_transcription_config`) and `Part.audioTranscription` (`audio_transcription`).
  - `GoogleMaps` model class and `Tool.googleMaps` grounding options (`groundingTypes`, e.g., `places`, `routing`).
  - `TurnCompleteReason.TOO_MANY_TOOL_CALLS` enum value for tool iteration safety terminations.

### Changed
- Synced Live SDK request headers to `google-genai-sdk/2.16.0` (synced with `js-genai` 2.16.0).
- Bumped package version to `2026.8.12`.

## 2026.7.24

### Changed
- Synced Live SDK request headers to `google-genai-sdk/2.13.0` (synced with `js-genai` 2.13.0).
- Bumped package version to `2026.7.24`.

## 2026.7.19

### Added
- Synced Live-facing DTOs with `js-genai` 2.12.0:
  - `HistoryConfig` — new type with `initialHistoryInClientContent` flag; also added `LiveClientSetup.historyConfig` and `LiveConnectParameters.historyConfig`.
  - `AudioTranscriptionConfig.customVocabulary` — preferred replacement for `adaptationPhrases` (which is now `@Deprecated`).

### Changed
- Updated Live SDK request headers to `google-genai-sdk/2.12.0`.
- Updated all example and documentation model references from the deprecated `gemini-live-2.5-flash-preview` (shut down) to `gemini-3.1-flash-live-preview` (latest, March 2026).
  - Note: `js-genai` ref still uses the old model string in its test/sample files; this change is based on the official Gemini API models documentation.
- Updated README and README_KR supported model descriptions to reflect the current lineup.
- Bumped package version to `2026.7.19`.

## 2026.7.11

### Added
- Synced Live-facing DTOs with `js-genai` 2.11.0:
  - `VoiceConsentSignature`, plus `ReplicatedVoiceConfig.consentAudio` and `ReplicatedVoiceConfig.voiceConsentSignature`.
  - `AudioTranscriptionConfig.languageAuto`, `AudioTranscriptionConfig.languageHints`, and `AudioTranscriptionConfig.adaptationPhrases`, with the new `LanguageAuto` and `LanguageHints` types (`languageCodes` is now deprecated upstream).
  - `ComputerUse.disabledSafetyPolicies` and the `SafetyPolicy` enum.
  - `Tool.exaAiSearch` and the `ToolExaAiSearch` type (rejected for the Gemini API during setup).
  - Server fields: `LiveServerSetupComplete.voiceConsentSignature`, `Transcription.languageCode`, `LiveServerContent.interimInputTranscription`, `VoiceActivity.audioOffset`, and `UsageMetadata.serviceTier` with the new lowercase-valued `ServiceTier` enum.
  - `LiveSession.setupComplete`, populated once the initial `setupComplete` message arrives.

### Changed
- Renamed `StreamTranslationConfig` to `TranslationConfig` and `GenerationConfig.streamTranslationConfig` to `GenerationConfig.translationConfig` (wire key `translation_config`). A deprecated `StreamTranslationConfig` typedef and `GenerationConfig.streamTranslationConfig` getter remain for backward compatibility.
- `connect()` now resolves on the `setupComplete` message instead of the first frame: messages received before setup completes (including `setupComplete` itself) are queued and flushed to `onMessage` in arrival order once the session resolves.
- Updated Live SDK request headers to `google-genai-sdk/2.11.0`.
- Updated package metadata and README installation snippets to `2026.7.11`.
- Updated the example lockfile to reference the current local package version.

## 2026.6.6

### Changed
- Updated package metadata and README installation snippets to `2026.6.6`.
- Updated the example lockfile to reference the current local package version.

## 2026.5.24

### Added
- Synced Live-facing DTOs with `js-genai` 2.6.0:
  - `GenerationConfig.streamTranslationConfig`
  - `ThinkingConfig.thinkingLevel`
  - multi-speaker and replicated voice speech config types
  - `FunctionCall.partialArgs` / `FunctionCall.willContinue`
  - `FunctionResponseBlob.displayName` and `FunctionResponseFileData.displayName`
  - typed `ComputerUse` config including `enablePromptInjectionDetection`

### Changed
- Updated Live SDK request headers to `google-genai-sdk/2.6.0`.
- Updated package metadata and README installation snippets to `2026.5.24`.

## 2026.4.19

### Added
- Added configurable logging for Live API sessions through `LiveService(logger: ...)`.
- Example app now plays Gemini Live audio responses in-app by buffering PCM chunks, wrapping them as WAV, and playing them when a response turn completes.
- Added timestamped chat demo debug logging for connection state, user sends, recorder events, and voice playback transitions.

### Changed
- Live WebSocket traffic logging is now disabled by default.
- Passing `print` as the logger restores the previous verbose logging behavior.
- Updated publish metadata and README installation snippets to the current date-based version.
- Split example app Live model defaults by demo:
  - `Realtime Media` now targets `gemini-3.1-flash-live-preview`.
  - chat, function-calling, and feature demos stay on the 2.5 compatibility path until the SDK exposes the additional 3.1 history/session controls.
- Restored chat demo `Text Mode` / `Voice Mode` switching while keeping audio-response sessions compatible with current Live API behavior.
- Refined chat voice playback control so autoplay is consumed once per response and old audio bubbles do not restart when the list rebuilds.
- Reduced noisy chat logging by suppressing empty text chunk logs and summarizing audio chunk progress per response.

### Fixed
- Fixed the example app disconnection issue reported in GitHub issue `#8` by removing non-audio request flows from Live setup in the app demos.
- Fixed example audio playback cleanup so buffered audio is cleared on interruption, connection close, and error paths.
- Fixed example playback triggering to handle turns that finish with `generationComplete` as well as `turnComplete`.
- Fixed chat voice playback so new user input or a newer response stops the currently playing voice response instead of overlapping playback.
- Fixed macOS image picking in the example app by adding the required `user-selected read-only` sandbox entitlement.
- Fixed chat screen teardown races so closing or leaving the page no longer triggers `setState()` on a defunct widget after the session closes.

## 2026.4.17

### Added
- Synced additional Gemini Live setup fields from the current `js-genai` reference:
  - `LiveClientSetup.avatarConfig`
  - `LiveClientSetup.safetySettings`
  - `SafetySetting`, `AvatarConfig`, `CustomizedAvatar`
- Expanded Live enum coverage for newer server responses:
  - `Modality.VIDEO`
  - `TurnCoverage.TURN_INCLUDES_AUDIO_ACTIVITY_AND_ALL_VIDEO`
  - additional `TurnCompleteReason` values
  - additional `TrafficType` values
  - latest safety enums for Gemini blocking config

### Changed
- Updated Live SDK request headers to `google-genai-sdk/1.50.1`.
- Updated README and README_KR to match the current API surface and date-based package versioning.

## 2026.3.21

### Added
- Added the latest Gemini Live part-schema fields from the current `js-genai` reference:
  - `Part.mediaResolution`, `Part.fileData`, `Part.videoMetadata`
  - `Part.thoughtSignature`, `Part.toolCall`, `Part.toolResponse`, `Part.partMetadata`
  - `PartMediaResolution`, `PartMediaResolutionLevel`, `ToolCall`, `ToolResponse`, `ToolType`
- Added `AudioTranscriptionConfig.languageCodes` and code execution IDs on `ExecutableCode` / `CodeExecutionResult`.

### Changed
- Tightened Gemini Live setup validation to reject unsupported `input/outputAudioTranscription.languageCodes` before sending setup.
- Added client-side MIME validation for realtime audio/video payloads so malformed blobs fail fast.

### Fixed
- Fixed `LiveServerMessage.data` so multiple inline binary chunks are concatenated as bytes before base64 encoding.
- Fixed session resumption parsing parity by treating `lastConsumedClientMessageIndex` as a string.

## 0.2.2

### Added
- Example app now supports in-app Gemini API key configuration via Settings UI.
  - Users can save/update/clear API keys directly from the app screen.
  - API key is persisted locally with `shared_preferences`.
- Added `examples/ephemeral_token.dart`:
  - demonstrates Live API connection using ephemeral tokens (`auth_tokens/...`)
  - uses `GoogleGenAI(apiVersion: 'v1alpha')`
- Added platform-specific runtime info adapters so Dart version reporting works consistently across IO and web builds.
- Added comprehensive automated coverage for Live service flows, transport connectors, and model serialization.

### Changed
- Improved Gemini Live setup handling:
  - added `LiveService.buildSetupMessage(...)` to centralize setup message construction
  - added `LiveService.validateFunctionResponses(...)` to validate tool responses before sending
  - default setup now falls back to `responseModalities: [Modality.AUDIO]` when omitted
  - unsupported Gemini API options now fail fast during setup construction
- Expanded Function Calling demo in the example app:
  - added richer tool declarations:
    - `get_exchange_rate`
    - `convert_currency`
    - `search_places`
    - `create_reminder` (non-blocking)
  - improved simulated tool responses with structured payloads
  - added quick prompt chips for multi-tool scenarios
- Updated example/docs descriptions to reflect richer function calling capabilities.
- Documented the public model API more clearly in the package docs.

### Fixed
- Enforced Gemini Live function response IDs so tool replies match `ToolCall.functionCalls` contract.
- Removed Gemini example usage that relied on unsupported setup parameters.

## 0.2.1

### Added
- Expanded Live tool schema support:
  - `Tool.functionDeclarations`
  - `Tool.googleSearch`
  - `Tool.googleSearchRetrieval`
- Added richer function response fields:
  - `FunctionResponse.scheduling`
  - `FunctionResponse.willContinue`
  - `FunctionResponse.parts`
- Added Live generation config parity fields:
  - `GenerationConfig.mediaResolution`
  - `GenerationConfig.speechConfig` (voice config)
  - `GenerationConfig.thinkingConfig`
  - `GenerationConfig.enableAffectiveDialog`
  - `GenerationConfig.seed`
- Added additional Live server metadata parsing:
  - `LiveServerContent.interrupted`
  - `LiveServerContent.waitingForInput`
  - `LiveServerContent.turnCompleteReason`
  - `LiveServerSetupComplete.sessionId`
  - detailed `UsageMetadata` modality/token breakdown fields

### Changed
- Updated WebSocket connection behavior for Gemini Live ephemeral tokens:
  - auto-switches to `BidiGenerateContentConstrained`
  - uses `access_token` query parameter when API key starts with `auth_tokens/`
- Added `apiVersion` option to `GoogleGenAI(...)` so Live API version can be configured from the top-level client.
- Updated Live User-Agent version to `google-genai-sdk/1.42.0`.
- Updated enums and compatibility mapping for current Live API:
  - `ActivityHandling.NO_INTERRUPTION` (with backward-compatible alias)
  - VAD/voice activity typed signals
  - traffic/modality token metadata enums

### Fixed
- Fixed tool serialization so configured tools are actually sent in `setup`.
- Fixed session resumption parsing type for `resumable` (`bool`).
- Fixed GoAway parsing to align with `timeLeft` and added helper conversion to seconds (`timeRemaining`).
- Improved `LiveServerMessage.text` getter to ignore thought-only parts.

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
