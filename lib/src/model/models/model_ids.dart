// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Live Model Identifiers
// ============================================================================

/// Well-known model identifiers supported by the Gemini Live API.
abstract final class LiveModels {
  /// Default stable Live model for low-latency voice and multimodal dialogue
  /// without reasoning-induced delays.
  static const String gemini38Live = 'gemini-3.8-live';

  /// Stable high-reasoning Live model for voice interactions requiring
  /// deep background reasoning.
  static const String gemini38LiveExtendedThinking =
      'gemini-3.8-live-extended-thinking';

  /// Previous-generation preview Live model.
  static const String gemini31FlashLivePreview = 'gemini-3.1-flash-live-preview';

  /// Native audio output preview model.
  static const String gemini25FlashNativeAudioPreview =
      'gemini-2.5-flash-native-audio-preview-12-2025';

  /// Speech-to-speech translation preview Live model.
  ///
  /// Use with [TranslationConfig].
  static const String gemini35LiveTranslatePreview =
      'gemini-3.5-live-translate-preview';

  /// Speech transcription model (`gemini-3.5-transcribe`).
  static const String gemini35Transcribe = 'gemini-3.5-transcribe';

  /// Gemini 3.8 Flash TTS model for text-to-speech generation.
  @Deprecated('Not a Live API model. TTS models are served by the Interactions/generateContent APIs, not BidiGenerateContent. Will be removed in a future release.')
  static const String gemini38FlashTts = 'gemini-3.8-flash-tts';

  /// Gemini 3.8 Flash Lite TTS model for high-efficiency text-to-speech generation.
  @Deprecated('Not a Live API model. TTS models are served by the Interactions/generateContent APIs, not BidiGenerateContent. Will be removed in a future release.')
  static const String gemini38FlashLiteTts = 'gemini-3.8-flash-lite-tts';

  /// Gemini 3.1 Flash TTS preview model.
  @Deprecated('Not a Live API model. TTS models are served by the Interactions/generateContent APIs, not BidiGenerateContent. Will be removed in a future release.')
  static const String gemini31FlashTtsPreview = 'gemini-3.1-flash-tts-preview';

  /// Gemini Omni 1.1 Flash video generation model (Interactions API only).
  @Deprecated('Not a Live API model. Gemini Omni is a video generation model served by the Interactions API. Will be removed in a future release.')
  static const String geminiOmni11Flash = 'gemini-omni-1.1-flash';

  /// Gemini Omni Flash preview video generation model (Interactions API only).
  @Deprecated('Not a Live API model. Gemini Omni is a video generation model served by the Interactions API. Will be removed in a future release.')
  static const String geminiOmniFlashPreview = 'gemini-omni-flash-preview';
}

/// Well-known model identifiers supported by the Realtime Music (Lyria Live) API.
abstract final class LiveMusicModels {
  /// Default experimental Realtime Music generation model.
  static const String lyriaRealtimeExp = 'models/lyria-realtime-exp';

  /// Lyria 3.5 music generation model (Interactions API only).
  @Deprecated('Not a Realtime Music (BidiGenerateMusic) model. Lyria 3.x models are served by the Interactions API. Use lyriaRealtimeExp. Will be removed in a future release.')
  static const String lyria35 = 'models/lyria-3.5';

  /// Lyria 3 Clip preview model for short generation clips.
  @Deprecated('Not a Realtime Music (BidiGenerateMusic) model. Lyria 3.x models are served by the Interactions API. Use lyriaRealtimeExp. Will be removed in a future release.')
  static const String lyria3ClipPreview = 'models/lyria-3-clip-preview';

  /// Lyria 3 Pro preview model for professional composition.
  @Deprecated('Not a Realtime Music (BidiGenerateMusic) model. Lyria 3.x models are served by the Interactions API. Use lyriaRealtimeExp. Will be removed in a future release.')
  static const String lyria3ProPreview = 'models/lyria-3-pro-preview';
}

/// Well-known model identifiers supported by the Gemini Interactions API.
abstract final class InteractionModels {
  /// Gemma 4 26B A4B instruction-tuned model (`gemma-4-26b-a4b-it`).
  static const String gemma4_26bA4bIt = 'gemma-4-26b-a4b-it';

  /// Gemma 4 31B instruction-tuned model (`gemma-4-31b-it`).
  static const String gemma4_31bIt = 'gemma-4-31b-it';

  /// Latest release alias of Gemini Flash (`gemini-flash-latest`).
  static const String geminiFlashLatest = 'gemini-flash-latest';

  /// Latest release alias of Gemini Flash-Lite (`gemini-flash-lite-latest`).
  static const String geminiFlashLiteLatest = 'gemini-flash-lite-latest';

  /// Latest release alias of Gemini Pro (`gemini-pro-latest`).
  static const String geminiProLatest = 'gemini-pro-latest';

  /// Gemini 4 Carbon frontier reasoning model (`gemini-4-carbon`).
  static const String gemini4Carbon = 'gemini-4-carbon';

  /// Gemini 4 Argon frontier engineering and knowledge model (`gemini-4-argon`).
  static const String gemini4Argon = 'gemini-4-argon';

  /// Gemini 4 Hydrogen frontier fast execution model (`gemini-4-hydrogen`).
  ///
  /// Built for fast, dependable execution across coding, agentic workflows,
  /// and multimodal knowledge work.
  static const String gemini4Hydrogen = 'gemini-4-hydrogen';

  /// Gemini 3.8 Flash model (`gemini-3.8-flash`).
  static const String gemini38Flash = 'gemini-3.8-flash';

  /// Gemini 3.7 Flash model (`gemini-3.7-flash`).
  static const String gemini37Flash = 'gemini-3.7-flash';

  /// Gemini 3.6 Flash model (`gemini-3.6-flash`).
  static const String gemini36Flash = 'gemini-3.6-flash';

  /// Gemini 3.5 Flash model (`gemini-3.5-flash`).
  static const String gemini35Flash = 'gemini-3.5-flash';

  /// Gemini 3.5 Flash-Lite model (`gemini-3.5-flash-lite`).
  static const String gemini35FlashLite = 'gemini-3.5-flash-lite';

  /// Gemini 3.8 Flash TTS speech generation model (`gemini-3.8-flash-tts`).
  static const String gemini38FlashTts = 'gemini-3.8-flash-tts';

  /// Gemini 3.8 Flash Lite TTS speech generation model (`gemini-3.8-flash-lite-tts`).
  static const String gemini38FlashLiteTts = 'gemini-3.8-flash-lite-tts';

  /// Gemini 3.5 Transcribe speech-to-text model (`gemini-3.5-transcribe`).
  static const String gemini35Transcribe = 'gemini-3.5-transcribe';

  /// Gemini Nano Banana 2.1 image generation model (`gemini-nano-banana-2.1`).
  static const String geminiNanoBanana21 = 'gemini-nano-banana-2.1';

  /// Gemini Robotics Embodied Reasoning 2 preview model (`gemini-robotics-er-2-preview`).
  static const String geminiRoboticsEr2Preview = 'gemini-robotics-er-2-preview';

  /// Gemini Robotics-ER 1.6 preview model (`gemini-robotics-er-1.6-preview`).
  static const String geminiRoboticsEr16Preview =
      'gemini-robotics-er-1.6-preview';

  /// Lyria 3.5 full-length music generation model (`lyria-3.5`).
  static const String lyria35 = 'lyria-3.5';

  /// Lyria 3 Clip preview music generation model (`lyria-3-clip-preview`).
  static const String lyria3ClipPreview = 'lyria-3-clip-preview';

  /// Lyria 3 Pro preview music generation model (`lyria-3-pro-preview`).
  static const String lyria3ProPreview = 'lyria-3-pro-preview';

  /// Default Gemini Omni 1.2 Flash video generation model (`gemini-omni-1.2-flash`).
  static const String geminiOmni12Flash = 'gemini-omni-1.2-flash';

  /// Previous Gemini Omni 1.1 Flash video generation model (`gemini-omni-1.1-flash`).
  static const String geminiOmni11Flash = 'gemini-omni-1.1-flash';

  /// Gemini Omni Flash preview video generation model (`gemini-omni-flash-preview`).
  static const String geminiOmniFlashPreview = 'gemini-omni-flash-preview';
}

/// Well-known agent identifiers supported by the Gemini Interactions API.
abstract final class InteractionAgents {
  /// Antigravity preview agent (`antigravity-preview-09-2026`).
  static const String antigravityPreview092026 = 'antigravity-preview-09-2026';

  /// Antigravity preview agent (`antigravity-preview-05-2026`).
  static const String antigravityPreview052026 = 'antigravity-preview-05-2026';

  /// Deep Research Pro preview agent (`deep-research-pro-preview-12-2025`).
  static const String deepResearchProPreview122025 =
      'deep-research-pro-preview-12-2025';

  /// Deep Research preview agent (`deep-research-preview-04-2026`).
  static const String deepResearchPreview042026 =
      'deep-research-preview-04-2026';

  /// Deep Research Max preview agent (`deep-research-max-preview-04-2026`).
  static const String deepResearchMaxPreview042026 =
      'deep-research-max-preview-04-2026';
}

