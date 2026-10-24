---
name: gemini-live-thinking-context
description: Configure Gemini 3.8 Live Extended Thinking (ThinkingConfig), long-session Context Window Compression (SlidingWindow), prior chat history seeding (HistoryConfig), dynamic in-session context updates (sendContextUpdate), Proactive Audio, and Affective Dialog in Flutter. Use when building deep-reasoning voice agents, 15+ minute continuous sessions, or dynamically updating system instructions and tools mid-call.
---

# Gemini Live Extended Thinking & Context Management Skill

This skill covers advanced reasoning (`gemini-3.8-live-extended-thinking`), infinite session context compression, prior conversation history seeding, mid-session tool/instruction updates, and affective/proactive audio controls.

---

## 🧠 1. Extended Thinking Mode (`ThinkingConfig`)

With `LiveModels.gemini38LiveExtendedThinking` (or `LiveModels.gemini38Live`), you can configure the model's internal reasoning budget and optionally stream thought summaries.

```dart
import 'package:gemini_live/gemini_live.dart';

await controller.connect(
  LiveConnectParameters(
    model: LiveModels.gemini38LiveExtendedThinking,
    config: GenerationConfig(
      responseModalities: [Modality.AUDIO],
      speechConfig: SpeechConfig.fromLiveVoice(GeminiLiveVoice.kore),
      thinkingConfig: ThinkingConfig(
        includeThoughts: true,
        thinkingBudget: 1024,
        thinkingLevel: ThinkingLevel.HIGH, // LOW, MEDIUM, HIGH
      ),
    ),
    outputAudioTranscription: AudioTranscriptionConfig(),
  ),
);
```

### Handling Internal Thought Parts & `GeminiLiveThinkingIndicator`

`GeminiLiveSessionController` automatically filters out `part.thought == true` from `controller.transcripts` so internal chain-of-thought text never pollutes your user-facing subtitles, while tracking `controller.isThinking`, `controller.latestThought`, and `controller.thoughts`.

Use `GeminiLiveThinkingIndicator` (also built into `GeminiLiveChatView` via `showThinkingIndicator: true`) to render a system-styled expandable reasoning pill:

```dart
GeminiLiveThinkingIndicator.fromController(
  controller: controller,
  expandable: true, // Tapping expands/collapses the live thought stream
)
```

If using low-level `LiveCallbacks.onMessage`, inspect `part.thought`:

```dart
for (final part in message.serverContent?.modelTurn?.parts ?? const <Part>[]) {
  if (part.thought == true && part.text != null) {
    debugPrint('🧠 Model Reasoning: ${part.text}');
  } else if (part.text != null) {
    debugPrint('💬 Spoken Text: ${part.text}');
  }
}
```

---

## ♾️ 2. Infinite Sessions via Context Window Compression

Without context compression, multimodal Live sessions (especially with video/audio) can hit context token limits after 10–15 minutes. Configure `ContextWindowCompressionConfig` with a `SlidingWindow` to keep sessions running indefinitely:

```dart
await controller.connect(
  LiveConnectParameters(
    model: LiveModels.gemini38Live,
    config: GenerationConfig(responseModalities: [Modality.AUDIO]),
    contextWindowCompression: ContextWindowCompressionConfig(
      triggerTokens: '24000',
      slidingWindow: SlidingWindow(targetTokens: '12000'),
    ),
  ),
);
```

---

## 📜 3. Seeding Prior Conversation History (`HistoryConfig` & `GeminiLiveTranscriptExporter`)

To resume a previous text chat or inject multi-turn context before starting real-time voice streaming, enable `HistoryConfig(initialHistoryInClientContent: true)` and send prior turns ending with `turnComplete: true`. You can also convert existing `controller.transcripts` directly via `controller.toHistoryClientContent()`, or export/restore transcripts in Markdown, JSON, WebVTT (`.vtt`), and SubRip (`.srt`) formats using `GeminiLiveTranscriptExporter`:

```dart
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: LiveModels.gemini38Live,
    config: GenerationConfig(responseModalities: [Modality.AUDIO]),
    historyConfig: HistoryConfig(initialHistoryInClientContent: true),
    callbacks: LiveCallbacks(
      onMessage: (msg) {
        if (msg.setupComplete != null) {
          // Seed prior turns immediately after setupComplete without triggering generation
          session.sendClientContent(
            turns: [
              Content(role: 'user', parts: [Part(text: 'My flight is KE703 to Tokyo.')]),
              Content(role: 'model', parts: [Part(text: 'Got it, I will track flight KE703 for you.')]),
            ],
            turnComplete: true,
          );
        }
      },
    ),
  ),
);
```

---

## 🔄 4. Dynamic Mid-Session Context & Tool Updates (`sendContextUpdate`)

You can update `systemInstruction` or swap active `tools` on the fly during an active call without disconnecting the WebSocket:

```dart
// Update system persona and active tools mid-call
controller.sendContextUpdate(
  systemInstruction: 'You are now in checkout mode. Confirm payment details concisely.',
  tools: [
    Tool(functionDeclarations: [processPaymentDeclaration]),
  ],
);

// Clear all tools mid-session by passing an empty list
controller.sendContextUpdate(tools: const <Tool>[]);

// Or present the pre-built interactive Material 3 bottom sheet:
await GeminiLiveContextConfigSheet.show(
  context: context,
  controller: controller,
  presets: const [
    GeminiLiveContextPreset(
      id: 'socratic',
      title: 'Socratic Tutor',
      systemInstruction: 'Ask guiding questions instead of giving direct answers.',
    ),
  ],
  availableTools: {
    'Google Search': Tool(googleSearch: GoogleSearch()),
  },
);
```

---

## 🎭 5. Affective Dialog & Proactive Audio

- **Affective Dialog (`enableAffectiveDialog: true`)**: Adapts Gemini's vocal tone and empathy to the user's emotional prosody.
- **Proactive Audio (`ProactivityConfig(proactiveAudio: true)`)**: Allows the model to decide when to speak up or stay silent during background chatter.

```dart
await controller.connect(
  LiveConnectParameters(
    model: LiveModels.gemini38Live,
    config: GenerationConfig(
      responseModalities: [Modality.AUDIO],
      enableAffectiveDialog: true,
    ),
    proactivity: ProactivityConfig(proactiveAudio: true),
  ),
);
```
