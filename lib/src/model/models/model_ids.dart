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

