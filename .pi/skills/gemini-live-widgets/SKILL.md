---
name: gemini-live-widgets
description: Build Gemini Live voice and chat UIs in Flutter with the pre-built `gemini_live` widgets (GeminiLiveStatusBadge, GeminiLiveMicButton, GeminiLiveVoiceIndicator, GeminiLiveCaptionBubble, GeminiLiveWaveform, GeminiLiveUsageBadge) and GeminiLiveAudioUtils. Use when adding or styling these widgets, wiring them to GeminiLiveSessionController, a low-level LiveSession, the firebase_ai-compatible layer, or plain firebase_ai, or when building captions, waveforms, mic buttons, status pills, push-to-talk, or barge-in UI.
---

# Gemini Live Widgets Skill

The `gemini_live` package ships six Material 3 widgets for live voice/chat screens, plus PCM audio helpers. This skill gives their exact parameters, how to feed them from each session API, and the patterns and pitfalls that matter in real apps.

Exports come from `package:gemini_live/gemini_live.dart`. Full screen example: the *Quickstart 1* section of the `flutter-gemini-live` skill. Human-readable reference: [`doc/widgets_guide.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/doc/widgets_guide.md).

---

## 💡 Core principle

The widgets are **pure presentation**. They take plain values (`bool`, `String`, `double`, `Stream`) and never talk to the network, the microphone or the speaker. Your code owns the session, mic capture and audio playback; the widgets only show state. That is why they work with any session source (see *Wiring recipes*).

The one exception is `GeminiLiveUsageBadge`, which needs a `GeminiTokenUsageTracker` fed with gemini_live server messages.

---

## ⛔ Do NOT

- Do **not** expect `GeminiLiveMicButton` to record. It only calls your callbacks. Start/stop the recorder (e.g. `record`) yourself.
- Do **not** create a new stream inside `build()` for `GeminiLiveWaveform` (e.g. `audioStream: mic.map(...)`). A new stream instance on every rebuild makes the widget cancel and resubscribe each frame. Create the stream once (in `initState` or a field) and pass the same instance.
- Do **not** pass a single-subscription stream that something else already listens to. The `record` mic stream is single-subscription; convert once with `asBroadcastStream()` or feed the waveform an amplitude stream you control. `GeminiLiveSessionController.incomingAudioStream` / `outgoingAudioStream` are already broadcast.
- Do **not** pass `GeminiLiveSessionController.state` to `GeminiLiveStatusBadge(state:)`. The controller uses `LiveSessionState`; the badge uses `GeminiLiveSessionState`. Map it (below) or use `GeminiLiveStatusBadge.fromFlags(...)`.
- Do **not** forget `role:` on `GeminiLiveCaptionBubble`. It defaults to `'model'`, so user transcripts are shown as model speech unless you pass `role: 'user'`.
- Do **not** keep `enableBlur: true` on many bubbles at once (long transcript lists, low-end devices, Flutter Web). `BackdropFilter` is expensive; set `enableBlur: false` there.
- Do **not** feed widgets anything other than 16-bit little-endian PCM bytes where they expect audio (`audioStream`, `GeminiLiveAudioUtils`).

---

## 📚 Widget reference

### `GeminiLiveStatusBadge` — connection status pill

| Parameter | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `state` | `GeminiLiveSessionState` | required | `disconnected`, `connecting`, `connected`, `inProgress` |
| `interactionStatus` | `InteractionStatus?` | `null` | `IN_PROGRESS` overrides the color/label to "Thinking / Speaking" |
| `showLabel` | `bool` | `true` | Dot only when `false` |
| `customLabel` | `String?` | `null` | Replaces the default label (use for localization) |
| `backgroundColor`, `textColor` | `Color?` | light/dark preset | |
| `borderRadius` | `double` | `20.0` | |
| `padding` | `EdgeInsetsGeometry` | `h10, v4.5` | |

Default labels and colors: `disconnected` "Disconnected" (slate), `connecting` "Connecting..." (amber), `connected` "Ready (Idle)" (green), `inProgress` "Thinking / Speaking" (blue).

`GeminiLiveStatusBadge.fromFlags(isConnected:, isConnecting: false, interactionStatus:, ...)` derives the state from booleans.

Mapping from the controller:

```dart
GeminiLiveSessionState badgeState(GeminiLiveSessionController c) =>
    switch (c.state) {
      LiveSessionState.connecting => GeminiLiveSessionState.connecting,
      LiveSessionState.connected => c.isModelSpeaking
          ? GeminiLiveSessionState.inProgress
          : GeminiLiveSessionState.connected,
      LiveSessionState.disconnected ||
      LiveSessionState.disconnecting ||
      LiveSessionState.error =>
        GeminiLiveSessionState.disconnected,
    };
```

### `GeminiLiveMicButton` — mic toggle with ripple rings

| Parameter | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `isRecording` | `bool` | required | Drives the active look and ripples |
| `onPressed` | `VoidCallback?` | `null` | Tap |
| `onLongPressStart`, `onLongPressEnd` | `VoidCallback?` | `null` | Push-to-talk |
| `size` | `double` | `56.0` | |
| `iconSize` | `double` | `28.0` | |
| `activeColor`, `inactiveColor` | `Color?` | red / neutral surface (light/dark preset) | |
| `tooltip` | `String?` | `null` | Set it for accessibility |

### `GeminiLiveVoiceIndicator` — animated speaking bars

| Parameter | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `isSpeaking` | `bool` | required | Animates while `true` |
| `barCount` | `int` | `4` | |
| `height` | `double` | `24.0` | |
| `color` | `Color?` | `onSurface` (light) / white (dark) | |

Use one for the model (`isModelSpeaking`) and optionally one for the user (`isUserSpeaking`).

### `GeminiLiveCaptionBubble` — frosted glass subtitle

| Parameter | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `text` | `String` | required | Empty/whitespace text fades the bubble out |
| `role` | `String` | `'model'` | `'user'` or `'model'`; styles the bubble |
| `speaker` | `String?` | `null` | Name shown in the tag, e.g. `'You'`, `'Gemini'` |
| `style` | `String?` | `null` | Vocal style chip, e.g. `'whispering'` |
| `isStreaming` | `bool` | `false` | Shows a pulsing dot; pauses auto-dismiss |
| `showSpeakerTag` | `bool` | `true` | |
| `enableBlur` | `bool` | `true` | `BackdropFilter`; turn off in lists / Web |
| `autoDismissDuration` | `Duration?` | `6 s` | `null` keeps it visible |
| `maxWidth` | `double` | `480.0` | |
| `backgroundColor`, `textColor` | `Color?` | iOS-style surface (light/dark preset) | |
| `borderRadius` | `double` | `16.0` | |
| `padding` | `EdgeInsetsGeometry` | `h16, v12` | |
| `onDismissed` | `VoidCallback?` | `null` | Called after the auto-dismiss fade-out |

Behavior: the bubble fades in when `text` changes to non-empty, and the dismiss timer restarts on every text change. While `isStreaming` is `true` the timer is paused, so set it to `false` when the turn ends.

### `GeminiLiveWaveform` — audio level bars

| Parameter | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `amplitude` | `double?` | `null` | Normalized `0.0`–`1.0`; for values you compute yourself |
| `amplitudeStream` | `Stream<double>?` | `null` | Normalized amplitudes |
| `audioStream` | `Stream<Uint8List>?` | `null` | Raw 16-bit PCM LE chunks; RMS is computed per chunk |
| `barCount` | `int` | `7` | |
| `width` | `double` | `120.0` | |
| `height` | `double` | `36.0` | |
| `barWidth` | `double` | `4.0` | |
| `spacing` | `double` | `3.0` | |
| `minBarHeight` | `double` | `4.0` | Height when silent |
| `color` | `Color?` | theme primary | |
| `gradient` | `Gradient?` | `null` | Vertical gradient per bar |
| `borderRadius` | `double?` | `barWidth / 2` | Pill bars by default |
| `enableIdleBreathing` | `bool` | `true` | Subtle motion when silent |

Input rules: if both streams are given, `amplitudeStream` wins and `audioStream` is ignored. Levels go through `GeminiLiveAudioUtils.toVisualScale` and decay smoothly when input stops. Make `width` fit `barCount * (barWidth + spacing)`.

### `GeminiLiveUsageBadge` — token and cost badge

| Parameter | Type | Default | Notes |
| :--- | :--- | :--- | :--- |
| `tracker` | `GeminiTokenUsageTracker` | required | A `ChangeNotifier`; the badge rebuilds itself |
| `compact` | `bool` | `false` | Hides cost details |
| `showIcon` | `bool` | `true` | |
| `onTap` | `VoidCallback?` | `null` | Default opens `GeminiLiveUsageDetailsDialog` |
| `backgroundColor`, `foregroundColor` | `Color?` | light/dark preset | |
| `padding` | `EdgeInsetsGeometry` | `h10, v5` | |

`GeminiLiveUsageDetailsDialog(tracker:)` can also be shown directly with `showDialog`.

### 🍎 iOS / Cupertino Widgets (for iOS apps & HIG compliance)

For apps built with `CupertinoApp` or seeking Apple Human Interface Guidelines styling, the package ships dedicated Cupertino counterparts:

| Widget | Counterpart for | Highlights |
| :--- | :--- | :--- |
| **`CupertinoGeminiLiveStatusBadge`** | `GeminiLiveStatusBadge` | iOS translucent capsule background, `CupertinoColors` resolution, dynamic dark/light surface. Factory: `.fromFlags(...)`. |
| **`CupertinoGeminiLiveMicButton`** | `GeminiLiveMicButton` | iOS spring scale-down press animation (`AnimatedScale`), `HapticFeedback` light/medium impact, translucent red ripple aura. |
| **`CupertinoGeminiLiveUsageBadge`** | `GeminiLiveUsageBadge` | iOS-styled token status pill opening `CupertinoAlertDialog` with compact modal metrics breakdown. |

*Note: `GeminiLiveCaptionBubble`, `GeminiLiveWaveform`, and `GeminiLiveVoiceIndicator` are designed to work seamlessly in both `MaterialApp` and `CupertinoApp` by automatically adapting their brightness and primary tint.*

### 🚀 Advanced Multimodal & Call Interaction Widgets

| Widget | Class | Highlights |
| :--- | :--- | :--- |
| **Barge-In Banner** | `GeminiLiveBargeInBanner` | Slides & fades in when user interrupts the model (`isInterrupted: controller.isInterrupted`). Reassures the user that AI is listening. |
| **Call Control Bar** | `GeminiLiveControlBar` | All-in-one floating call pill with Mic Mute, Video Toggle, Camera Flip, and Hang Up End Call buttons. |
| **Voice Selector** | `GeminiLiveVoiceSelectorSheet` | Pre-built modal bottom sheet (`.show(context, currentVoice:)`) for switching official voices (Puck, Charon, Kore, Fenrir, Aoede, etc.) with tone tags. |
| **Vision Overlay** | `GeminiLiveVisionOverlay` | Wraps any camera preview with Project Astra style radar scanlines, corner HUD target reticles, and in-flight analysis indicator. |

### `GeminiLiveAudioUtils` and `addWavHeader`

All take 16-bit PCM LE bytes:

| API | Returns |
| :--- | :--- |
| `GeminiLiveAudioUtils.calculateRms(bytes)` | RMS amplitude `0.0`–`1.0` |
| `GeminiLiveAudioUtils.calculatePeak(bytes)` | Peak amplitude `0.0`–`1.0` |
| `GeminiLiveAudioUtils.calculateDecibels(bytes, minDb: -96.0)` | dBFS, `minDb`–`0.0` |
| `GeminiLiveAudioUtils.toVisualScale(amplitude, factor: 2.0)` | Log-scaled `0.0`–`1.0` for meters |
| `addWavHeader(pcm, sampleRate: 24000)` | WAV file bytes (for saving or players that need WAV) |

---

## 🔌 Wiring recipes

### 1. `GeminiLiveSessionController` (recommended for UI apps)

Wrap the widgets in `ListenableBuilder(listenable: controller, ...)`.

| Widget | Source on the controller |
| :--- | :--- |
| `GeminiLiveStatusBadge` | `badgeState(controller)` (mapping above) |
| `GeminiLiveMicButton.isRecording` | Your own recording flag (or `controller.isConnected` for a connect toggle) |
| `GeminiLiveVoiceIndicator.isSpeaking` | `controller.isModelSpeaking` / `controller.isUserSpeaking` |
| `GeminiLiveCaptionBubble` | `text: controller.latestTranscript`, `role: controller.latestTranscriptRole`, `isStreaming: controller.isModelSpeaking` |
| Transcript list | `controller.transcripts` (`LiveTranscriptItem`: `role`, `text`, `speaker`, `style`, `isStreaming`) |
| `GeminiLiveWaveform.audioStream` | `controller.incomingAudioStream` (model) / `controller.outgoingAudioStream` (mic) |
| `GeminiLiveUsageBadge.tracker` | `controller.tokenTracker` |

```dart
ListenableBuilder(
  listenable: controller,
  builder: (context, _) => Column(
    children: [
      GeminiLiveStatusBadge(state: badgeState(controller)),
      GeminiLiveWaveform(audioStream: controller.incomingAudioStream, barCount: 24, width: 200, height: 48),
      if (controller.latestTranscript case final text?)
        GeminiLiveCaptionBubble(
          text: text,
          role: controller.latestTranscriptRole ?? 'model',
          speaker: controller.latestTranscriptRole == 'user' ? 'You' : 'Gemini',
          isStreaming: controller.isModelSpeaking,
        ),
      GeminiLiveVoiceIndicator(isSpeaking: controller.isModelSpeaking),
      GeminiLiveUsageBadge(tracker: controller.tokenTracker, compact: true),
    ],
  ),
);
```

Transcript history (many bubbles, so no blur and no auto-dismiss):

```dart
ListView(
  children: [
    for (final item in controller.transcripts)
      Align(
        alignment: item.role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
        child: GeminiLiveCaptionBubble(
          text: item.text,
          role: item.role,
          speaker: item.speaker,
          style: item.style,
          isStreaming: item.isStreaming,
          enableBlur: false,
          autoDismissDuration: null,
        ),
      ),
  ],
);
```

### 2. Low-level `LiveSession` (`genAI.live.connect`)

Keep the UI state in your own `ChangeNotifier` (or `setState`) and update it from `LiveCallbacks.onMessage`:

```dart
final tracker = GeminiTokenUsageTracker(model: 'gemini-3.8-live');
final modelAudio = StreamController<Uint8List>.broadcast(); // waveform + player
var caption = '';
var modelSpeaking = false;
InteractionStatus? interaction;

void onMessage(LiveServerMessage message) {
  tracker.recordMessage(message);                     // GeminiLiveUsageBadge
  final content = message.serverContent;
  if (content == null) return;
  interaction = content.interactionStatus ?? interaction; // GeminiLiveStatusBadge
  if (content.outputTranscription?.text case final t?) caption += t;
  if (message.data case final b64?) {
    modelSpeaking = true;
    modelAudio.add(base64Decode(b64));
  }
  if (content.interrupted == true || content.turnComplete == true) {
    modelSpeaking = false;
  }
}
```

Then: `GeminiLiveStatusBadge.fromFlags(isConnected: ..., interactionStatus: interaction)`, `GeminiLiveWaveform(audioStream: modelAudio.stream)`, `GeminiLiveCaptionBubble(text: caption, isStreaming: modelSpeaking)`, `GeminiLiveUsageBadge(tracker: tracker)`.

### 3. firebase_ai-compatible layer (`package:gemini_live/compat/firebase_ai.dart`)

Import the widgets with a prefix, since the compat layer and the core library share names (`Content`, `LiveSession`, ...):

```dart
import 'package:gemini_live/compat/firebase_ai.dart';
import 'package:gemini_live/gemini_live.dart' as gl;

// Usage tracking works through the gemini_live-only extension:
gl.GeminiLiveUsageBadge(tracker: session.tokenTracker);

// Feed the rest from response.message:
// LiveServerContent.outputTranscription?.text -> gl.GeminiLiveCaptionBubble
// InlineDataPart.bytes -> your broadcast StreamController -> gl.GeminiLiveWaveform(audioStream:)
// interrupted / turnComplete -> gl.GeminiLiveVoiceIndicator(isSpeaking:)
```

### 4. Plain `firebase_ai`

Keep `gemini_live` as a UI-only dependency and import it with a prefix (`as gl`). Status, mic, voice indicator, caption, waveform and audio utils all work from your own state, built like recipe 2 from `LiveServerContent`. `GeminiLiveUsageBadge` cannot be used because firebase_ai does not expose Live usage metadata.

---

## 🎛️ Patterns

**Mic level meter (single-subscription `record` stream):**

```dart
final micLevel = StreamController<double>.broadcast(); // field, created once

Future<void> startMic() async {
  final mic = (await recorder.startStream(const RecordConfig(
    encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1,
  ))).asBroadcastStream();
  mic.listen(controller.sendRealtimeAudio);
  mic.listen((chunk) => micLevel.add(GeminiLiveAudioUtils.calculateRms(chunk)));
}

// build(): GeminiLiveWaveform(amplitudeStream: micLevel.stream)
```

**Barge-in:** when `controller.isInterrupted` (or `serverContent.interrupted == true`) flips on, stop local playback immediately, and the widgets follow: `isModelSpeaking` turns `false`, so the voice indicator stops and the caption's dismiss timer resumes.

**Push-to-talk** (manual VAD: connect with `RealtimeInputConfig(automaticActivityDetection: AutomaticActivityDetection(disabled: true))`):

```dart
GeminiLiveMicButton(
  isRecording: holding,
  tooltip: 'Hold to talk',
  onLongPressStart: () {
    setState(() => holding = true);
    controller.session?.sendActivityStart();
    startMic();
  },
  onLongPressEnd: () {
    setState(() => holding = false);
    stopMic();
    controller.session?.sendActivityEnd();
    controller.stopUserSpeaking();
  },
);
```

**Localization:** pass `GeminiLiveStatusBadge(customLabel: ...)` and caption `speaker:` strings from your l10n source; the default labels are English.

**Theming:** all widgets switch between built-in light and dark palettes from `Theme.of(context).brightness`, so dark mode works without overrides. Only `GeminiLiveWaveform` uses your `colorScheme.primary`; the others use fixed neutral/red/status colors. Pass the color parameters to match a brand palette.

---

## ✅ Verification

1. `dart analyze` passes.
2. Widget tests: pump each widget with fixed values (e.g. `GeminiLiveCaptionBubble(text: 'hi', role: 'user', autoDismissDuration: null)`) and use `pump(duration)` rather than `pumpAndSettle()`; `GeminiLiveWaveform` and the speaking indicators animate continuously.
3. Run the app: check captions for both roles, the waveform moving with model audio, the badge changing on connect/disconnect, and the UI recovering after an interruption.
