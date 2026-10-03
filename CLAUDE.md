# Claude Code Guidelines for flutter_gemini_live

This repository contains the `gemini_live` Flutter package: a zero-Firebase, low-latency, bidirectional multimodal streaming SDK connecting Flutter apps directly to Google's Gemini Live API over WebSockets.

---

## 🛠️ Development & Test Commands

- **Run Tests**: `flutter test`
- **Run Static Analysis**: `dart analyze`
- **Install Dependencies**: `flutter pub get`
- **Build / Run Example App**: `cd example && flutter run`

---

## 🧭 Project Architecture

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
    └── widgets/                  # Pre-built Material 3 UI widgets
        ├── live_caption_bubble.dart     # Frosted glass subtitle bubble
        ├── live_mic_button.dart         # Concentric ripple mic toggle
        ├── live_status_badge.dart       # Connection status pill
        ├── live_usage_badge.dart        # Token usage monitor
        ├── live_voice_indicator.dart    # Dual-harmonic wave visualizer
        └── live_waveform.dart           # Real-time audio waveform visualizer
```

---

## 💡 AI Agent Skill Reference

A dedicated Agent Skill is maintained for this package at:
- Standard: [`skills/flutter-gemini-live/SKILL.md`](skills/flutter-gemini-live/SKILL.md)
- Claude Code Native: [`.claude/skills/flutter-gemini-live/SKILL.md`](.claude/skills/flutter-gemini-live/SKILL.md)
- Root: [`SKILL.md`](SKILL.md)

Refer to this skill whenever generating code, implementing UI features, adding tools/grounding, or handling Live API errors.

For the pre-built widgets (parameters, wiring, UI patterns), use [`skills/gemini-live-widgets/SKILL.md`](skills/gemini-live-widgets/SKILL.md).

For migrations between `firebase_ai` and `gemini_live` (either direction), use the migration skill:
- [`skills/gemini-live-firebase-migration/SKILL.md`](skills/gemini-live-firebase-migration/SKILL.md) (mirrored under `.claude/`, `.gemini/`, `.codex/`, `.agents/skills/`)
- Reference guide: [`doc/firebase_ai_compat.md`](doc/firebase_ai_compat.md)
- Two-way compile check: `tool/check_firebase_ai_compat.sh`
