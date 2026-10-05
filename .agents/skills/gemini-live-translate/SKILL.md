---
name: gemini-live-translate
description: Implement real-time, bidirectional speech-to-speech translation in Flutter using the Gemini Live Translate model. Use when connecting to gemini-3.5-live-translate-preview, configuring TranslationConfig (targetLanguageCode, echoTargetLanguage), or building dual-sided/split-screen interpreter UI applications.
---

# Gemini Live Speech-to-Speech Translation Skill

This skill provides instructions for building real-time, low-latency live speech translation applications using Google's dedicated Live Translate model (`gemini-3.5-live-translate-preview`).

---

## 🌐 Model & Translation Configuration

The Live translation model operates as a streaming audio-in, audio-out interpreter:

| Parameter | Recommended Value | Notes |
|---|---|---|
| **Model ID** | `gemini-3.5-live-translate-preview` (`LiveModels.gemini35LiveTranslatePreview`) | Dedicated streaming translation model. |
| **`targetLanguageCode`** | BCP-47 tag (e.g., `'es'`, `'ja'`, `'ko'`, `'fr'`) | Language to translate the speaker's voice into. |
| **`echoTargetLanguage`** | `false` (default) | If `true`, repeats the spoken target text before playing translation. |
| **Response Modalities** | `[Modality.AUDIO]` | Audio output containing the translated voice. |

---

## 🚀 Setting Up Live Translation Session

```dart
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

Future<void> connectTranslator({
  required GeminiLiveSessionController controller,
  required String targetLanguage, // e.g. 'es' (Spanish), 'ko' (Korean)
  GeminiLiveVoice voice = GeminiLiveVoice.puck,
}) async {
  await controller.connect(
    LiveConnectParameters(
      model: LiveModels.gemini35LiveTranslatePreview,
      config: GenerationConfig(
        responseModalities: [Modality.AUDIO],
        speechConfig: SpeechConfig.fromLiveVoice(voice),
        // Live speech-to-speech translation settings
        translationConfig: TranslationConfig(
          targetLanguageCode: targetLanguage,
          echoTargetLanguage: false,
        ),
      ),
      // Transcribe both user speech and translated model speech
      inputAudioTranscription: AudioTranscriptionConfig(),
      outputAudioTranscription: AudioTranscriptionConfig(),
      callbacks: LiveCallbacks(
        onError: (e, st) => debugPrint('Translation Error: $e'),
      ),
    ),
  );
}
```

---

## 📱 Face-to-Face Dual-Sided UI Pattern

For in-person conversations where two people sit across from each other, render a split screen where the top half is flipped 180 degrees for the counterparty:

```dart
Widget buildSplitScreenInterpreter(BuildContext context, GeminiLiveSessionController controller) {
  return Column(
    children: [
      // 1. Counterparty Screen (Rotated 180 degrees)
      Expanded(
        child: RotatedBox(
          quarterTurns: 2, // 180 degree flip for person sitting opposite
          child: Container(
            color: Colors.blueGrey.shade900,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                controller.lastModelText ?? 'Listening for counterparty...',
                style: const TextStyle(fontSize: 22, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),

      const Divider(height: 2, thickness: 2, color: Colors.amber),

      // 2. User Screen (Normal Orientation)
      Expanded(
        child: Container(
          color: Colors.grey.shade900,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              controller.lastUserText ?? 'Speak to translate...',
              style: const TextStyle(fontSize: 22, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ],
  );
}
```

---

## 🚨 Critical Translation Rules

1. **Always use the dedicated Translate model:**
   Do not use standard `gemini-3.8-live` with a translation prompt if `gemini-3.5-live-translate-preview` is available. The dedicated translate model has specialized low-latency streaming pipeline optimizations.
2. **Handle target language switches dynamically:**
   When users switch conversational directions (e.g. English -> Korean to Korean -> English), reconnect with the updated `targetLanguageCode`.
