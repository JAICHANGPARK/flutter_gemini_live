# Gemini CLI & Antigravity Guidelines for flutter_gemini_live

This repository contains the `gemini_live` Flutter package: a zero-Firebase, low-latency, bidirectional multimodal streaming SDK connecting Flutter apps directly to Google's Gemini Live API over WebSockets.

---

## Development & Test Commands

- **Run Tests**: `flutter test`
- **Run Static Analysis**: `dart analyze`
- **Install Dependencies**: `flutter pub get`
- **Build / Run Example App**: `cd example && flutter run`

---

## Project Architecture

```
lib/
├── gemini_live.dart              # Main library export file
└── src/
    ├── google_genai.dart         # GoogleGenAI root client
    ├── live_service.dart         # WebSocket LiveService & LiveSession
    ├── music_service.dart        # Realtime Music (Lyria Live) client & models
    ├── auth_tokens_service.dart  # Ephemeral client tokens service
    ├── compat/firebase_ai/       # firebase_ai-compatible Live API (exported via lib/compat/firebase_ai.dart)
    ├── voices_service.dart       # Available voices discovery service
    ├── client/                   # REST ApiClient & headers
    ├── model/                    # Request/response data models & enums
    ├── platform/                 # Web & I/O WebSocket stubs & implementations
    ├── utils/
    │   ├── live_session_controller.dart # Reactive ChangeNotifier UI controller
    │   ├── audio_utils.dart             # RMS, peak, dBFS, visual scaling
    │   ├── token_usage_tracker.dart     # Token accounting tracker
    │   └── wav_header.dart              # Audio header utility
    └── widgets/                  # Pre-built Material 3 & Cupertino UI widgets
        ├── live_chat_view.dart          # High-level pluggable full-screen chat UI
        ├── live_caption_bubble.dart     # Frosted glass subtitle bubble
        ├── live_mic_button.dart         # Concentric ripple mic toggle
        ├── live_status_badge.dart       # Connection status pill
        ├── live_usage_badge.dart        # Token usage monitor
        ├── live_voice_indicator.dart    # Dual-harmonic wave visualizer
        ├── live_waveform.dart           # Real-time audio waveform visualizer
        ├── live_barge_in_banner.dart    # Interruption notification banner
        ├── live_control_bar.dart        # Floating call interaction control bar
        ├── live_vision_overlay.dart     # Computer vision viewfinder HUD overlay
        ├── live_voice_selector.dart     # Voice persona bottom sheet selector
        ├── cupertino_live_mic_button.dart    # iOS native mic button
        ├── cupertino_live_status_badge.dart  # iOS native status badge
        └── cupertino_live_usage_badge.dart   # iOS native token usage badge
```

---

## AI Agent Skill Reference

A dedicated Agent Skill is maintained for this package at:
- Standard / Hermes: [`skills/flutter-gemini-live/SKILL.md`](skills/flutter-gemini-live/SKILL.md) & [`.hermes/skills/`](.hermes/skills/flutter-gemini-live/SKILL.md)
- Pi Agent: [`.pi/skills/`](.pi/skills/flutter-gemini-live/SKILL.md) & [`.agents/skills/`](.agents/skills/flutter-gemini-live/SKILL.md)
- Gemini CLI / Antigravity Native: [`.gemini/skills/flutter-gemini-live/SKILL.md`](.gemini/skills/flutter-gemini-live/SKILL.md)
- Claude Code / Codex / Agents: [`.claude/skills/`](.claude/skills/flutter-gemini-live/SKILL.md), [`.codex/skills/`](.codex/skills/flutter-gemini-live/SKILL.md), [`.agents/skills/`](.agents/skills/flutter-gemini-live/SKILL.md)
- Open Agents Spec: [`AGENTS.md`](AGENTS.md)
- Universal Root: [`SKILL.md`](SKILL.md)

Refer to this skill whenever generating code, implementing UI features, adding tools/grounding, or handling Live API errors.

### Additional Specialized Skills
- **Audio & Voice Chat**: [`skills/gemini-live-audio/SKILL.md`](skills/gemini-live-audio/SKILL.md) (16kHz mic, 24kHz speaker, SoLoud/record, barge-in, VAD, GeminiLiveVoice)
- **Computer Vision**: [`skills/gemini-live-vision/SKILL.md`](skills/gemini-live-vision/SKILL.md) (1-2 FPS camera streaming, GeminiLiveVisionOverlay HUD)
- **Function Calling & Tools**: [`skills/gemini-live-tools/SKILL.md`](skills/gemini-live-tools/SKILL.md) (Tools, Behavior.NON_BLOCKING, partialArgs, Google Maps/Search grounding)
- **Realtime Music (Lyria)**: [`skills/gemini-live-music/SKILL.md`](skills/gemini-live-music/SKILL.md) (Lyria Realtime, 48kHz stereo, weighted prompts, BPM/Scale)
- **Session Resumption & Auth**: [`skills/gemini-live-session-auth/SKILL.md`](skills/gemini-live-session-auth/SKILL.md) (Ephemeral tokens, SessionResumptionConfig, backoff)
- **Live Translation**: [`skills/gemini-live-translate/SKILL.md`](skills/gemini-live-translate/SKILL.md) (gemini-3.5-live-translate-preview, TranslationConfig, face-to-face UI)
- **UI Widgets**: [`skills/gemini-live-widgets/SKILL.md`](skills/gemini-live-widgets/SKILL.md) (parameters, wiring, visualizers)
- **Firebase Migration**: [`skills/gemini-live-firebase-migration/SKILL.md`](skills/gemini-live-firebase-migration/SKILL.md) (1:1 translation between `firebase_ai` and `gemini_live`)
- **Reference Guide**: [`doc/firebase_ai_compat.md`](doc/firebase_ai_compat.md)
