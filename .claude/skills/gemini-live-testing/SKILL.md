---
name: gemini-live-testing
description: Write deterministic unit and widget tests for Flutter Gemini Live applications without opening real WebSocket connections or spending API quota. Use when testing GeminiLiveSessionController state transitions, simulating server audio/transcript/barge-in/toolCall messages via handleServerMessageForTesting, verifying PCM WAV buffers, or testing gemini_live UI widgets with WidgetTester.
---

# Gemini Live Unit & Widget Testing Skill

This skill teaches AI coding agents how to write fast, deterministic `flutter test` unit and widget tests for apps using `package:gemini_live` without requiring live network sockets, microphones, or API keys.

---

## 🧪 1. Simulating Server Events (`handleServerMessageForTesting`)

`GeminiLiveSessionController` exposes `handleServerMessageForTesting(LiveServerMessage)` specifically for unit and widget tests. You can inject any server event and verify controller state, transcripts, audio buffers, active tool calls, and token usage deterministically.

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  late GoogleGenAI genAI;
  late GeminiLiveSessionController controller;

  setUp(() {
    genAI = GoogleGenAI(apiKey: 'test-api-key');
    controller = GeminiLiveSessionController(liveService: genAI.live);
  });

  tearDown(() {
    controller.dispose();
  });

  test('accumulates streaming transcripts, audio PCM chunks, and handles barge-in', () async {
    final receivedPcm = <Uint8List>[];
    final sub = controller.incomingAudioStream.listen(receivedPcm.add);

    // 1. Simulate incoming 24kHz PCM audio + output transcription
    final samplePcm = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);
    controller.handleServerMessageForTesting(
      LiveServerMessage(
        serverContent: LiveServerContent(
          modelTurn: Content(
            role: 'model',
            parts: [
              Part(
                inlineData: Blob(
                  mimeType: 'audio/pcm;rate=24000',
                  data: base64Encode(samplePcm),
                ),
              ),
            ],
          ),
          outputTranscription: Transcription(text: 'Hello from Gemini!'),
          turnComplete: false,
        ),
        usageMetadata: UsageMetadata(
          promptTokenCount: 100,
          responseTokenCount: 250,
          totalTokenCount: 350,
        ),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(controller.isModelSpeaking, isTrue);
    expect(controller.latestTranscript, 'Hello from Gemini!');
    expect(controller.tokenTracker.totalTokens, 350);
    expect(receivedPcm, hasLength(1));

    // 2. Simulate user barge-in interruption
    controller.handleServerMessageForTesting(
      LiveServerMessage(
        serverContent: LiveServerContent(interrupted: true),
      ),
    );

    expect(controller.isInterrupted, isTrue);
    expect(controller.isModelSpeaking, isFalse);
    expect(controller.currentTurnAudioBuffer.isEmpty, isTrue);

    await sub.cancel();
  });
}
```

---

## 🛠️ 2. Testing Tool Calls & Cancellations

Verify that your app responds to `toolCall` and cleans up in-flight calls on `toolCallCancellation`:

```dart
test('tracks in-flight FunctionCalls and removes cancelled tool calls', () {
  // Inject server toolCall request
  controller.handleServerMessageForTesting(
    LiveServerMessage(
      toolCall: LiveServerToolCall(
        functionCalls: [
          FunctionCall(
            id: 'call_1',
            name: 'getWeather',
            args: {'city': 'Tokyo'},
          ),
        ],
      ),
    ),
  );

  expect(controller.isExecutingTool, isTrue);
  expect(controller.activeToolCalls.first.name, 'getWeather');

  // Inject server toolCallCancellation (e.g., user interrupted during non-blocking tool)
  controller.handleServerMessageForTesting(
    LiveServerMessage(
      toolCallCancellation: LiveServerToolCallCancellation(ids: ['call_1']),
    ),
  );

  expect(controller.isExecutingTool, isFalse);
  expect(controller.activeToolCalls, isEmpty);
});
```

---

## 🎨 3. Widget Testing Rules (`WidgetTester`)

Many `gemini_live` widgets (`GeminiLiveWaveform`, `GeminiLiveVoiceIndicator`, `GeminiLiveVisionOverlay`, `GeminiLiveMicButton` when recording) run continuous `AnimationController.repeat()` loops.

### Critical `WidgetTester` Guidelines:
1. **Use `tester.pump(duration)` instead of `tester.pumpAndSettle()`** when continuous animations (`isRecording: true`, `isSpeaking: true`, `GeminiLiveWaveform`) are active, otherwise `pumpAndSettle()` will time out waiting for repeating animations to stop.
2. **Pass `autoDismissDuration: null` to `GeminiLiveCaptionBubble`** in static widget tests if you do not want a pending 6-second auto-dismiss timer, or advance the clock with `await tester.pump(const Duration(seconds: 7))` before tearing down.

```dart
testWidgets('renders live call HUD and updates on server message', (tester) async {
  final genAI = GoogleGenAI(apiKey: 'test-key');
  final controller = GeminiLiveSessionController(liveService: genAI.live);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Column(
            children: [
              GeminiLiveStatusBadge.fromFlags(isConnected: controller.isConnected),
              GeminiLiveUsageBadge(tracker: controller.tokenTracker),
              GeminiLiveToolActivityChip.fromController(controller: controller),
              if (controller.latestTranscript != null)
                GeminiLiveCaptionBubble(
                  text: controller.latestTranscript!,
                  role: controller.latestTranscriptRole ?? 'model',
                  autoDismissDuration: null,
                ),
            ],
          ),
        ),
      ),
    ),
  );

  // Simulate model transcript & tool execution
  controller.handleServerMessageForTesting(
    LiveServerMessage(
      serverContent: LiveServerContent(
        outputTranscription: Transcription(text: 'Checking Tokyo weather...'),
      ),
      toolCall: LiveServerToolCall(
        functionCalls: [FunctionCall(id: '1', name: 'get_weather')],
      ),
    ),
  );

  await tester.pump(const Duration(milliseconds: 250));
  expect(find.text('Checking Tokyo weather...'), findsOneWidget);
  expect(find.byType(GeminiLiveToolActivityChip), findsOneWidget);
});
```
