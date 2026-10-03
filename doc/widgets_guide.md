# Flutter Gemini Live - Widgets Guide & Specification

This guide provides a complete specification and copy-pasteable examples for the built-in Flutter Material UI widgets included in `package:gemini_live/gemini_live.dart`.

These widgets are **lightweight, dependency-free**, and designed to integrate seamlessly into any Flutter application using the Gemini Live API.

---

## Table of Contents
1. [GeminiLiveStatusBadge](#1-geminilivestatusbadge)
2. [GeminiLiveMicButton](#2-geminilivemicbutton)
3. [GeminiLiveVoiceIndicator](#3-geminilivevoiceindicator)
4. [GeminiLiveCaptionBubble](#4-geminilivecaptionbubble)
5. [GeminiLiveWaveform](#5-geminilivewaveform)
6. [GeminiLiveUsageBadge](#6-geminiliveusagebadge)
7. [Audio Utilities](#7-audio-utilities)
8. [Complete End-to-End Chat & Voice Screen Example](#8-complete-end-to-end-chat--voice-screen-example)

> AI coding assistants: the [`gemini-live-widgets`](../skills/gemini-live-widgets/SKILL.md) agent skill covers the same widgets plus wiring recipes for `GeminiLiveSessionController`, low-level `LiveSession`, the firebase_ai-compatible layer, and plain `firebase_ai`.

---

## 1. GeminiLiveStatusBadge

A compact status chip/badge displaying real-time session state (`disconnected`, `connecting`, `connected`, `inProgress`) with an animated pulsing dot and automatic color coding.

### Visual States & Colors
| State | Interaction Status | Color | Pulse Animation | Default Label |
| :--- | :--- | :--- | :---: | :--- |
| `disconnected` | Any | Grey | No | `Disconnected` |
| `connecting` | Any | Amber / Orange | Yes | `Connecting...` |
| `connected` | `IDLE` or null | Green | No | `Ready` / `Ready (Idle)` |
| `inProgress` | `IN_PROGRESS` | Blue Accent | Yes | `Thinking / Speaking` |

### Constructors

#### Standard Constructor
```dart
const GeminiLiveStatusBadge({
  Key? key,
  required GeminiLiveSessionState state,
  InteractionStatus? interactionStatus,
  bool showLabel = true,
  String? customLabel,
  Color? backgroundColor,
  Color? textColor,
  double borderRadius = 20.0,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
})
```

#### Convenient Factory Constructor (`fromFlags`)
Automatically maps your UI boolean connection states and server `interactionStatus`:
```dart
GeminiLiveStatusBadge.fromFlags({
  Key? key,
  required bool isConnected,
  bool isConnecting = false,
  InteractionStatus? interactionStatus,
  bool showLabel = true,
  String? customLabel,
  Color? backgroundColor,
  Color? textColor,
  double borderRadius = 20.0,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
})
```

### Usage Examples

#### In an `AppBar`:
```dart
AppBar(
  title: const Text('Gemini Assistant'),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GeminiLiveStatusBadge.fromFlags(
        isConnected: isConnected,
        isConnecting: isConnecting,
        interactionStatus: currentInteractionStatus,
      ),
    ),
  ],
)
```

#### Dot-only Compact Mode (Icon size):
```dart
GeminiLiveStatusBadge.fromFlags(
  isConnected: isConnected,
  showLabel: false, // Only renders the pulsing color dot
)
```

---

## 2. GeminiLiveMicButton

An animated microphone action button for push-to-talk or tap-to-toggle voice input. During active recording/speech, it renders a smooth expanding pulse ripple and glow shadow.

### Properties

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `isRecording` | `bool` | *(required)* | Whether voice recording/streaming is currently active. |
| `onPressed` | `VoidCallback?` | `null` | Callback triggered when the button is tapped. |
| `onLongPressStart` | `VoidCallback?` | `null` | Push-to-talk: called when a long press starts. |
| `onLongPressEnd` | `VoidCallback?` | `null` | Push-to-talk: called when the long press ends. |
| `size` | `double` | `56.0` | Outer diameter of the button in logical pixels. |
| `iconSize` | `double` | `28.0` | Size of the microphone icon inside the button. |
| `activeColor` | `Color?` | Red (light/dark preset) | Background color when `isRecording == true`. |
| `inactiveColor` | `Color?` | Neutral surface (light/dark preset) | Background color when `isRecording == false`. |
| `tooltip` | `String?` | `null` | Accessibility tooltip text. |

The button does not record audio. Start and stop your recorder (for example the `record` package) in the callbacks.

### Usage Example

```dart
GeminiLiveMicButton(
  isRecording: _isRecording,
  size: 56.0,
  iconSize: 28.0,
  onPressed: () {
    if (_isRecording) {
      _stopRecordingAndSend();
    } else {
      _startVoiceRecording();
    }
  },
  tooltip: _isRecording ? 'Stop recording' : 'Start speaking',
)
```

---

## 3. GeminiLiveVoiceIndicator

A lightweight, rhythmically animated waveform audio visualizer. When speaking or streaming audio, the vertical bars animate in sinusoidal waves with randomized phase offsets to mimic natural voice activity without requiring external native audio analyzers.

### Properties

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `isSpeaking` | `bool` | *(required)* | When true, bars animate actively. When false, bars rest at minimal baseline height. |
| `barCount` | `int` | `4` | Number of vertical equalizer bars (typically 3 to 7). |
| `height` | `double` | `24.0` | Maximum peak height of the waveform bars. |
| `color` | `Color?` | `onSurface` (light) / white (dark) | Fill color for the equalizer bars. |

### Usage Example

```dart
Row(
  children: [
    const Icon(Icons.mic, size: 20, color: Colors.blueAccent),
    const SizedBox(width: 8),
    Text(_isSpeaking ? 'Model speaking...' : 'Listening...'),
    const SizedBox(width: 8),
    GeminiLiveVoiceIndicator(
      isSpeaking: _isSpeaking,
      barCount: 5,
      height: 20,
      color: Colors.blueAccent,
    ),
  ],
)
```

---

## 4. GeminiLiveCaptionBubble

A frosted glass subtitle bubble for live transcripts. It fades in when `text` becomes non-empty, shows a speaker tag and an optional style chip, pulses a dot while streaming, and fades out after `autoDismissDuration`.

### Properties

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `text` | `String` | *(required)* | Transcript text. Empty or whitespace text fades the bubble out. |
| `role` | `String` | `'model'` | `'user'` or `'model'`. Pass `'user'` for user transcripts. |
| `speaker` | `String?` | `null` | Name shown in the speaker tag, e.g. `'You'` or `'Gemini'`. |
| `style` | `String?` | `null` | Vocal style chip, e.g. `'whispering'`. |
| `isStreaming` | `bool` | `false` | Shows a pulsing dot and pauses auto-dismiss while `true`. |
| `showSpeakerTag` | `bool` | `true` | Shows the role/speaker pill. |
| `enableBlur` | `bool` | `true` | `BackdropFilter` frosted glass. Turn off in long lists and on Flutter Web. |
| `autoDismissDuration` | `Duration?` | `6 seconds` | Fade-out delay after the last text change. `null` keeps the bubble visible. |
| `maxWidth` | `double` | `480.0` | Maximum bubble width. |
| `backgroundColor` | `Color?` | iOS-style surface (light/dark preset) | Bubble background. |
| `textColor` | `Color?` | Light/dark preset | Text color. |
| `borderRadius` | `double` | `16.0` | Corner radius. |
| `padding` | `EdgeInsetsGeometry` | `EdgeInsets.symmetric(horizontal: 16, vertical: 12)` | Inner padding. |
| `onDismissed` | `VoidCallback?` | `null` | Called after the auto-dismiss fade-out. |

### Usage Example

```dart
// Live subtitle bound to GeminiLiveSessionController
if (controller.latestTranscript case final text?)
  GeminiLiveCaptionBubble(
    text: text,
    role: controller.latestTranscriptRole ?? 'model',
    speaker: controller.latestTranscriptRole == 'user' ? 'You' : 'Gemini',
    isStreaming: controller.isModelSpeaking,
  )

// Transcript history: many bubbles, so no blur and no auto-dismiss
for (final item in controller.transcripts)
  GeminiLiveCaptionBubble(
    text: item.text,
    role: item.role,
    isStreaming: item.isStreaming,
    enableBlur: false,
    autoDismissDuration: null,
  )
```

---

## 5. GeminiLiveWaveform

An audio level visualizer with pill-shaped bars, a bell-shaped bar profile, smooth attack/decay, and optional idle breathing. It accepts a fixed amplitude, an amplitude stream, or raw PCM audio.

### Properties

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `amplitude` | `double?` | `null` | Normalized level `0.0`–`1.0` that you compute yourself. |
| `amplitudeStream` | `Stream<double>?` | `null` | Normalized levels. Takes priority over `audioStream`. |
| `audioStream` | `Stream<Uint8List>?` | `null` | Raw 16-bit PCM little-endian chunks. RMS is computed per chunk. |
| `barCount` | `int` | `7` | Number of bars. |
| `width` | `double` | `120.0` | Total width. Fit it to `barCount * (barWidth + spacing)`. |
| `height` | `double` | `36.0` | Total height. |
| `barWidth` | `double` | `4.0` | Width of each bar. |
| `spacing` | `double` | `3.0` | Gap between bars. |
| `minBarHeight` | `double` | `4.0` | Bar height when silent. |
| `color` | `Color?` | `colorScheme.primary` | Bar color. |
| `gradient` | `Gradient?` | `null` | Vertical gradient applied to each bar. |
| `borderRadius` | `double?` | `barWidth / 2` | Bar corner radius (pill by default). |
| `enableIdleBreathing` | `bool` | `true` | Subtle motion while silent. |

Create the stream once (for example in `initState`) and pass the same instance on every build. A new stream instance makes the widget resubscribe. Single-subscription streams such as the `record` microphone stream must be converted with `asBroadcastStream()` if they are also sent to the session.

### Usage Example

```dart
// Model audio from the controller (already a broadcast stream)
GeminiLiveWaveform(
  audioStream: controller.incomingAudioStream,
  barCount: 24,
  width: 200,
  height: 48,
)

// Microphone level you compute yourself
GeminiLiveWaveform(
  amplitudeStream: micLevelController.stream, // StreamController<double>.broadcast()
  gradient: const LinearGradient(colors: [Colors.teal, Colors.blue]),
)
```

---

## 6. GeminiLiveUsageBadge

A token usage and cost badge bound to a `GeminiTokenUsageTracker`. It rebuilds on every usage update and opens `GeminiLiveUsageDetailsDialog` (per-modality breakdown) on tap.

### Properties

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `tracker` | `GeminiTokenUsageTracker` | *(required)* | Usage source, e.g. `controller.tokenTracker`. |
| `compact` | `bool` | `false` | Hides cost details. |
| `showIcon` | `bool` | `true` | Shows the token icon. |
| `onTap` | `VoidCallback?` | `null` | Custom tap handler. Default opens the details dialog. |
| `backgroundColor` | `Color?` | Light/dark preset | Badge background. |
| `foregroundColor` | `Color?` | Light/dark preset | Text and icon color. |
| `padding` | `EdgeInsetsGeometry` | `EdgeInsets.symmetric(horizontal: 10, vertical: 5)` | Inner padding. |

### Usage Example

```dart
AppBar(
  actions: [
    GeminiLiveUsageBadge(tracker: controller.tokenTracker, compact: true),
  ],
)

// Low-level LiveSession: feed the tracker yourself
final tracker = GeminiTokenUsageTracker(model: 'gemini-3.8-live');
// in LiveCallbacks.onMessage: tracker.recordMessage(message);
```

---

## 7. Audio Utilities

Helpers for 16-bit PCM little-endian buffers, useful for custom meters and recordings.

| API | Returns |
| :--- | :--- |
| `GeminiLiveAudioUtils.calculateRms(bytes)` | RMS amplitude `0.0`–`1.0` |
| `GeminiLiveAudioUtils.calculatePeak(bytes)` | Peak amplitude `0.0`–`1.0` |
| `GeminiLiveAudioUtils.calculateDecibels(bytes, minDb: -96.0)` | dBFS between `minDb` and `0.0` |
| `GeminiLiveAudioUtils.toVisualScale(amplitude, factor: 2.0)` | Log-scaled `0.0`–`1.0` for meters |
| `addWavHeader(pcm, sampleRate: 24000)` | WAV file bytes |

---

## 8. Complete End-to-End Chat & Voice Screen Example

Below is a complete, standalone Flutter widget demonstrating all 3 widgets working together with a `LiveSession`:

```dart
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

class GeminiLiveQuickScreen extends StatefulWidget {
  final String apiKey;

  const GeminiLiveQuickScreen({super.key, required this.apiKey});

  @override
  State<GeminiLiveQuickScreen> createState() => _GeminiLiveQuickScreenState();
}

class _GeminiLiveQuickScreenState extends State<GeminiLiveQuickScreen> {
  late final GoogleGenAI _genAI;
  LiveSession? _session;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isRecording = false;
  InteractionStatus? _interactionStatus;
  String _latestResponse = 'Press connect to start.';

  @override
  void initState() {
    super.initState();
    _genAI = GoogleGenAI(apiKey: widget.apiKey);
  }

  @override
  void dispose() {
    _session?.close();
    super.dispose();
  }

  Future<void> _toggleConnection() async {
    if (_isConnected) {
      await _session?.close();
      setState(() {
        _isConnected = false;
        _session = null;
        _interactionStatus = null;
      });
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final session = await _genAI.live.connect(
        LiveConnectParameters(
          model: 'gemini-3.1-flash-live-preview',
          config: GenerationConfig(
            responseModalities: [Modality.TEXT],
          ),
          callbacks: LiveCallbacks(
            onOpen: () {
              setState(() {
                _isConnected = true;
                _isConnecting = false;
              });
            },
            onMessage: (message) {
              // Track server interaction status (IN_PROGRESS / IDLE)
              if (message.serverContent?.interactionStatus != null) {
                setState(() {
                  _interactionStatus = message.serverContent!.interactionStatus;
                });
              }

              if (message.text != null && message.text!.isNotEmpty) {
                setState(() => _latestResponse = message.text!);
              }
            },
            onError: (err, st) {
              setState(() {
                _isConnecting = false;
                _isConnected = false;
              });
            },
            onClose: (code, reason) {
              setState(() {
                _isConnecting = false;
                _isConnected = false;
                _interactionStatus = null;
              });
            },
          ),
        ),
      );

      setState(() => _session = session);
    } catch (e) {
      setState(() => _isConnecting = false);
    }
  }

  void _sendTextMessage(String text) {
    if (_session != null && _isConnected) {
      _session!.sendText(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Live Assistant'),
        actions: [
          // 1. Status Badge in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GeminiLiveStatusBadge.fromFlags(
              isConnected: _isConnected,
              isConnecting: _isConnecting,
              interactionStatus: _interactionStatus,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Waveform indicator when model or user is active
          if (_isConnected)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Text('Live Audio / Activity:', style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  // 2. Voice Waveform Indicator
                  GeminiLiveVoiceIndicator(
                    isSpeaking: _interactionStatus == InteractionStatus.IN_PROGRESS || _isRecording,
                    barCount: 5,
                    height: 20,
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _latestResponse,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Connect / Disconnect button
                FilledButton.tonal(
                  onPressed: _isConnecting ? null : _toggleConnection,
                  child: Text(_isConnected ? 'Disconnect' : 'Connect'),
                ),
                // 3. Pulsing Mic Button
                GeminiLiveMicButton(
                  isRecording: _isRecording,
                  onPressed: _isConnected
                      ? () {
                          setState(() => _isRecording = !_isRecording);
                          if (!_isRecording) {
                            _sendTextMessage('Hello from GeminiLiveMicButton!');
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```
