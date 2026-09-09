# Flutter Gemini Live - Widgets Guide & Specification

This guide provides a complete specification and copy-pasteable examples for the built-in Flutter Material UI widgets included in `package:gemini_live/gemini_live.dart`.

These widgets are **lightweight, dependency-free**, and designed to integrate seamlessly into any Flutter application using the Gemini Live API.

---

## Table of Contents
1. [GeminiLiveStatusBadge](#1-geminilivestatusbadge)
2. [GeminiLiveMicButton](#2-geminilivemicbutton)
3. [GeminiLiveVoiceIndicator](#3-geminilivevoiceindicator)
4. [Complete End-to-End Chat & Voice Screen Example](#4-complete-end-to-end-chat--voice-screen-example)

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
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
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
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
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
| `onPressed` | `VoidCallback?` | *(required)* | Callback triggered when the button is tapped. When `null`, the button is disabled. |
| `size` | `double` | `48.0` | Outer diameter of the button in logical pixels. |
| `iconSize` | `double` | `24.0` | Size of the microphone icon inside the button. |
| `activeColor` | `Color?` | `Colors.redAccent` | Background color when `isRecording == true`. |
| `inactiveColor` | `Color?` | `Theme.primary` / `Colors.blueAccent` | Background color when `isRecording == false`. |
| `iconColor` | `Color?` | `Colors.white` | Color of the microphone icon. |
| `tooltip` | `String?` | Auto | Accessibility tooltip text. |

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
| `isSpeaking` | `bool` | `true` | When true, bars animate actively. When false, bars rest at minimal baseline height. |
| `barCount` | `int` | `5` | Number of vertical equalizer bars (typically 3 to 7). |
| `height` | `double` | `24.0` | Maximum peak height of the waveform bars. |
| `color` | `Color?` | `Theme.primary` / `Colors.blueAccent` | Fill color for the equalizer bars. |

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

## 4. Complete End-to-End Chat & Voice Screen Example

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
