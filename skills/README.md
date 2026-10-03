# AI Agent Skills for Flutter Gemini Live

This directory provides standardized **AI Agent Skills** for the `gemini_live` package, adhering to the open Agent Skills specification and compatible across all major AI coding environments: **Claude Code**, **Gemini CLI / Antigravity**, and **OpenAI Codex** (as well as **Cursor**, **Windsurf**, and **GitHub Copilot**).

---

## 📂 Skill Locations

To guarantee zero-friction discovery regardless of which AI assistant you or your team use, the skill is synchronized across all standard agent paths in this repository:

| AI Assistant / System | Discovery Path |
|---|---|
| **Root Universal** | [`SKILL.md`](../SKILL.md) |
| **Standard Skills Directory** | [`skills/flutter-gemini-live/SKILL.md`](flutter-gemini-live/SKILL.md) |
| **Claude Code** | [`.claude/skills/flutter-gemini-live/SKILL.md`](../.claude/skills/flutter-gemini-live/SKILL.md) |
| **Gemini CLI / Antigravity** | [`.gemini/skills/flutter-gemini-live/SKILL.md`](../.gemini/skills/flutter-gemini-live/SKILL.md) |
| **OpenAI Codex / ChatGPT** | [`.codex/skills/flutter-gemini-live/SKILL.md`](../.codex/skills/flutter-gemini-live/SKILL.md) |
| **Agent Skills Specification** | [`.agents/skills/flutter-gemini-live/SKILL.md`](../.agents/skills/flutter-gemini-live/SKILL.md) |

---

## 🛠️ Usage Instructions by AI Assistant

### 1. 🟣 Claude Code Users (`claude`)

#### In this repository:
Claude Code automatically discovers project skills in `.claude/skills/` and `skills/`. Simply ask Claude:
```bash
claude "Implement a live voice chat screen with frosted glass captions and audio visualizer using gemini_live"
```

#### Global installation (use in any Flutter project):
Copy the skill folder to your user-level Claude skills directory:
```bash
mkdir -p ~/.claude/skills
cp -r skills/flutter-gemini-live ~/.claude/skills/
```

---

### 2. 🔵 Gemini CLI & Antigravity Users (`gemini` / `agy`)

#### In this repository:
Antigravity and the Gemini CLI automatically load `SKILL.md` and `.gemini/skills/flutter-gemini-live/SKILL.md`. You can invoke it directly:
```bash
agy "Build a real-time Gemini 3.8 Live audio streaming session with barge-in interruption handling"
```

#### Global installation (use in any Flutter project):
Copy the skill to your global Antigravity/Gemini configuration directory:
```bash
mkdir -p ~/.gemini/skills
cp -r skills/flutter-gemini-live ~/.gemini/skills/
```

---

### 3. 🟢 OpenAI Codex, ChatGPT & Cursor Users (`codex` / `cursor`)

#### In this repository:
Codex, Cursor, and Copilot read `.codex/skills/`, `.agents/skills/`, and `CODEX.md` automatically:
- **Cursor / Windsurf**: Open the project; the `@flutter-gemini-live` skill rules and `CODEX.md` are indexed immediately.
- **OpenAI Codex CLI**:
```bash
codex "Add Live Music generation using models/lyria-realtime-exp and weighted prompts"
```

#### Global installation (use in any Flutter project):
Copy the skill to your global agents directory:
```bash
mkdir -p ~/.codex/skills ~/.agents/skills
cp -r skills/flutter-gemini-live ~/.codex/skills/
cp -r skills/flutter-gemini-live ~/.agents/skills/
```

---

## 📋 What the Skill Teaches Agents

- **Supported Models**: `gemini-3.8-live` (default low-latency), `gemini-3.8-live-extended-thinking` (deep reasoning), and `models/lyria-realtime-exp` (live music).
- **High-Level UI Controller**: `GeminiLiveSessionController` for reactive state, barge-in detection, and transcript history.
- **Pre-Built Material 3 Widgets**: `GeminiLiveWaveform`, `GeminiLiveCaptionBubble`, `GeminiLiveMicButton`, `GeminiLiveStatusBadge`, `GeminiLiveVoiceIndicator`, and `GeminiLiveUsageBadge`.
- **Audio Utilities**: `GeminiLiveAudioUtils` (RMS, dBFS decibels, visual scaling).
- **Live Music Streaming**: `genAI.live.music.connect(...)`, steerable weighted prompts, BPM, and key scale control.
- **Ephemeral Authentication Tokens**: Minting client tokens (`AuthTokensService`) with strict parameter locks and `v1alpha` connectivity.
- **Advanced Features**: Realtime bidirectional translation (`translationConfig`), transcription with multi-language `languageCodes` and `customVocabulary`, Google Maps grounding, and session resumption.
