---
name: gemini-live-music
description: Implement real-time steerable music generation using Google's Lyria Live (Realtime Music) model in Flutter. Use when connecting to models/lyria-realtime-exp via genAI.live.music, adjusting weighted prompts (Prompt DJ), setting musical attributes (BPM, musical scale, temperature), controlling playback (play, pause, stop, resetContext), or playing 48kHz stereo PCM audio.
---

# Gemini Live Music (Lyria Realtime) Skill

This skill provides instructions for generating continuous, steerable real-time music using Google's **Lyria Realtime** model (`models/lyria-realtime-exp`) via the `gemini_live` package.

---

## 🎵 Audio Specifications

| Parameter | Specification | Notes |
|---|---|---|
| **Model ID** | `models/lyria-realtime-exp` | Realtime interactive music generation. |
| **Output Format** | Linear PCM (`audio/pcm`) | 16-bit signed Little-Endian. |
| **Sample Rate** | **48,000 Hz** (48 kHz) | High fidelity music stream. |
| **Channels** | **2 (Stereo)** | Left & right audio channels. |
| **Player Setup** | `Channels.stereo`, `sampleRate: 48000` | Configure in `flutter_soloud` or Web Audio API. |

---

## 🎹 Connecting to the Live Music Service

Access the service via `genAI.live.music.connect()`:

```dart
import 'dart:typed_data';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:gemini_live/gemini_live.dart';

class LiveMusicManager {
  final GoogleGenAI genAI;
  LiveMusicSession? _session;
  AudioSource? _bufferSource;

  LiveMusicManager({required this.genAI});

  Future<void> startMusicStream() async {
    // 1. Initialize Stereo 48kHz Audio Output (via flutter_soloud)
    await SoLoud.instance.init();
    _bufferSource = SoLoud.instance.setBufferStream(
      sampleRate: 48000,
      channels: Channels.stereo, // Stereo playback
      format: BufferType.s16le,
      bufferingType: BufferingType.released,
    );
    await SoLoud.instance.play(_bufferSource!);

    // 2. Connect to Lyria Realtime
    _session = await genAI.live.music.connect(
      LiveMusicConnectParameters(
        model: 'models/lyria-realtime-exp',
        callbacks: LiveMusicCallbacks(
          onOpen: () => print('Music WebSocket connected'),
          onMessage: (LiveMusicServerMessage message) {
            // Incoming 48kHz stereo PCM chunks
            if (message.audioChunk != null) {
              final pcmBytes = message.audioChunk!.bytes;
              SoLoud.instance.addAudioDataStream(_bufferSource!, pcmBytes);
            }
          },
          onError: (e, st) => print('Live Music Error: $e'),
          onClose: (code, reason) => print('Closed: $code ($reason)'),
        ),
      ),
    );

    // 3. Start generating initial music
    await _session!.setWeightedPrompts([
      WeightedPrompt(text: 'ambient chill lofi beats', weight: 1.0),
      WeightedPrompt(text: 'gentle rain in the background', weight: 0.5),
    ]);

    await _session!.setMusicGenerationConfig(
      LiveMusicGenerationConfig(
        bpm: 85,
        scale: Scale.C_MAJOR_A_MINOR,
        temperature: 0.7,
      ),
    );

    // 4. Begin playback
    _session!.play();
  }

  /// Update prompt weights dynamically in real-time (Prompt DJ)
  Future<void> updatePromptDJ(double crossfade) async {
    if (_session == null) return;
    // Crossfade between 0.0 (Chill) and 1.0 (Energetic)
    await _session!.setWeightedPrompts([
      WeightedPrompt(text: 'chill lofi beats', weight: 1.0 - crossfade),
      WeightedPrompt(text: 'energetic synthwave bassline', weight: crossfade),
    ]);
  }

  /// Control playback state
  void pause() => _session?.pause();
  void resume() => _session?.play();
  void stop() => _session?.stop();

  /// Reset generation context for dramatic genre shifts
  void resetGenre(String newGenre) {
    _session?.resetContext();
    _session?.setWeightedPrompts([
      WeightedPrompt(text: newGenre, weight: 1.0),
    ]);
  }

  Future<void> dispose() async {
    _session?.stop();
    await _session?.close();
  }
}
```

---

## 🎚️ Musical Attribute Controls

### BPM (Tempo)
Tempo can be adjusted between 60 and 180 BPM:
```dart
session.setMusicGenerationConfig(
  LiveMusicGenerationConfig(bpm: 128),
);
```

### Musical Scales (`Scale` Enum)
Supported scales include:
- `Scale.C_MAJOR_A_MINOR`
- `Scale.D_MAJOR_B_MINOR`
- `Scale.G_MAJOR_E_MINOR`
- `Scale.F_MAJOR_D_MINOR`
- `Scale.A_MAJOR_F_SHARP_MINOR`
- `Scale.SCALE_UNSPECIFIED` (allows AI free choice)

### Generation Temperature
Values from `0.2` (predictable, stable rhythm) to `1.0` (creative, experimental).

---

## 🚨 Critical Music Rules & Anti-Patterns

1. **Ensure Stereo Configuration:**
   Lyria outputs stereo audio (2 channels). Playing it on a mono buffer will play at half speed or double pitch. Always configure output audio players with `Channels.stereo` and `48,000 Hz`.
2. **Use `resetContext()` when switching genres radically:**
   Lyria maintains musical context continuity. If you transition abruptly from "classical piano" to "heavy drum and bass", call `resetContext()` to avoid jarring musical dissonance.
3. **Do not confuse Lyria Realtime with TTS models:**
   Lyria is an instrumental and background music model. It does not output speech or transcribe text.
