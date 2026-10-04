# AGENTS.md — Coding Agent Guidelines for flutter_gemini_live

This repository contains the `gemini_live` Flutter package: a zero-Firebase, low-latency, bidirectional multimodal streaming SDK connecting Flutter apps directly to Google's Gemini Live API over WebSockets.

---

## Setup & Development Commands

- **Install Dependencies**: `flutter pub get`
- **Run Static Analysis**: `dart analyze`
- **Run Unit & Widget Tests**: `flutter test`
- **Run Specific Test**: `flutter test test/<test_file>_test.dart`
- **Run Example App**: `cd example && flutter run`

---

## Code Style & Conventions

- **Dart & Flutter Standards**: Follow [Effective Dart](https://dart.dev/effective-dart) and official Flutter architecture conventions.
- **Linter**: Follow `analysis_options.yaml` (strict pedantic rules).
- **Public API Documentation**: Provide clean doc comments (`///`) for all exported classes, methods, and parameters.
- **Zero Firebase Dependency**: Core package (`lib/gemini_live.dart`) must **never** import `firebase_core`, `firebase_ai`, or `firebase_vertexai`. Live WebSocket connectivity is established directly with Google's Gemini Live endpoints.
- **Interruption Handling**: Always immediately flush or stop local audio buffers when `serverContent.interrupted == true` or `controller.isInterrupted == true`.
- **Audio Specifications**:
  - Microphone capture: 16-bit linear PCM, 16,000 Hz, mono.
  - Live AI speech output: 16-bit linear PCM, 24,000 Hz, mono.
  - Live Music (Lyria) output: 16-bit linear PCM, 48,000 Hz, stereo.

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

## AI Agent Skills Reference

A dedicated Agent Skill specification conforming to the open [agents.md](https://agents.md/) standard is maintained in:
- Universal Root: [`SKILL.md`](SKILL.md)
- Standard Skills Directory: [`skills/flutter-gemini-live/SKILL.md`](skills/flutter-gemini-live/SKILL.md)
- Hermes Agent: [`.hermes/skills/flutter-gemini-live/SKILL.md`](.hermes/skills/flutter-gemini-live/SKILL.md)
- Pi Agent: [`.pi/skills/flutter-gemini-live/SKILL.md`](.pi/skills/flutter-gemini-live/SKILL.md)
- Gemini CLI / Antigravity: [`.gemini/skills/flutter-gemini-live/SKILL.md`](.gemini/skills/flutter-gemini-live/SKILL.md)
- Claude Code: [`.claude/skills/flutter-gemini-live/SKILL.md`](.claude/skills/flutter-gemini-live/SKILL.md)
- OpenAI Codex / Cursor: [`.codex/skills/flutter-gemini-live/SKILL.md`](.codex/skills/flutter-gemini-live/SKILL.md)
- Agent Skills Standard: [`.agents/skills/flutter-gemini-live/SKILL.md`](.agents/skills/flutter-gemini-live/SKILL.md)

### Additional Specialized Skills
- **UI Widgets**: [`skills/gemini-live-widgets/SKILL.md`](skills/gemini-live-widgets/SKILL.md) (parameters, wiring, visualizers)
- **Firebase Migration**: [`skills/gemini-live-firebase-migration/SKILL.md`](skills/gemini-live-firebase-migration/SKILL.md) (1:1 translation between `firebase_ai` and `gemini_live`)
- **Reference Guide**: [`doc/firebase_ai_compat.md`](doc/firebase_ai_compat.md)
- **Two-way Compile Check**: `tool/check_firebase_ai_compat.sh`
