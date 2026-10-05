// ignore_for_file: constant_identifier_names

part of '../models.dart';


/// Thinking controls for models that can emit thought content.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ThinkingConfig {
  final bool? includeThoughts;
  final int? thinkingBudget;
  final ThinkingLevel? thinkingLevel;

  ThinkingConfig({
    this.includeThoughts,
    this.thinkingBudget,
    this.thinkingLevel,
  });

  factory ThinkingConfig.fromJson(Map<String, dynamic> json) =>
      _$ThinkingConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ThinkingConfigToJson(this);
}

/// Stream translation settings for Live sessions.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class TranslationConfig {
  final bool? echoTargetLanguage;
  final String? targetLanguageCode;

  TranslationConfig({this.echoTargetLanguage, this.targetLanguageCode});

  factory TranslationConfig.fromJson(Map<String, dynamic> json) =>
      _$TranslationConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TranslationConfigToJson(this);
}

/// Deprecated alias for [TranslationConfig].
@Deprecated('Use TranslationConfig instead.')
typedef StreamTranslationConfig = TranslationConfig;

/// Generation parameters used when starting a Live API session.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class GenerationConfig {
  final double? temperature;
  final int? topK;
  final double? topP;
  final int? maxOutputTokens;
  final List<Modality>? responseModalities;
  final MediaResolution? mediaResolution;
  final int? seed;
  final SpeechConfig? speechConfig;
  final ThinkingConfig? thinkingConfig;
  final bool? enableAffectiveDialog;
  final TranslationConfig? translationConfig;
  final AudioTranscriptionConfig? audioTranscriptionConfig;
  final Map<String, String>? labels;

  GenerationConfig({
    this.temperature,
    this.topK,
    this.topP,
    this.maxOutputTokens,
    this.responseModalities,
    this.mediaResolution,
    this.seed,
    this.speechConfig,
    this.thinkingConfig,
    this.enableAffectiveDialog,
    this.translationConfig,
    this.audioTranscriptionConfig,
    this.labels,
  });

  /// Deprecated alias for [translationConfig].
  @Deprecated('Use translationConfig instead.')
  TranslationConfig? get streamTranslationConfig => translationConfig;

  factory GenerationConfig.fromJson(Map<String, dynamic> json) =>
      _$GenerationConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationConfigToJson(this);
}


// ============================================================================
// Live API Setup & Config Models
// ============================================================================

/// Automatic voice activity detection settings for realtime audio.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class AutomaticActivityDetection {
  final bool? disabled;
  final StartSensitivity? startOfSpeechSensitivity;
  final EndSensitivity? endOfSpeechSensitivity;
  final int? prefixPaddingMs;
  final int? silenceDurationMs;

  AutomaticActivityDetection({
    this.disabled,
    this.startOfSpeechSensitivity,
    this.endOfSpeechSensitivity,
    this.prefixPaddingMs,
    this.silenceDurationMs,
  });

  factory AutomaticActivityDetection.fromJson(Map<String, dynamic> json) =>
      _$AutomaticActivityDetectionFromJson(json);

  Map<String, dynamic> toJson() => _$AutomaticActivityDetectionToJson(this);
}

/// Realtime input settings sent during session setup.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class RealtimeInputConfig {
  final AutomaticActivityDetection? automaticActivityDetection;
  final ActivityHandling? activityHandling;
  final TurnCoverage? turnCoverage;

  RealtimeInputConfig({
    this.automaticActivityDetection,
    this.activityHandling,
    this.turnCoverage,
  });

  factory RealtimeInputConfig.fromJson(Map<String, dynamic> json) =>
      _$RealtimeInputConfigFromJson(json);

  Map<String, dynamic> toJson() => _$RealtimeInputConfigToJson(this);
}

/// Session resumption settings for reconnectable sessions.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class SessionResumptionConfig {
  final String? handle;
  final bool? transparent;

  SessionResumptionConfig({this.handle, this.transparent});

  factory SessionResumptionConfig.fromJson(Map<String, dynamic> json) =>
      _$SessionResumptionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SessionResumptionConfigToJson(this);
}

/// Sliding window targets used during context compression.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class SlidingWindow {
  final String? targetTokens;

  SlidingWindow({this.targetTokens});

  factory SlidingWindow.fromJson(Map<String, dynamic> json) =>
      _$SlidingWindowFromJson(json);

  Map<String, dynamic> toJson() => _$SlidingWindowToJson(this);
}

/// Context compression settings for long-running sessions.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ContextWindowCompressionConfig {
  final String? triggerTokens;
  final SlidingWindow? slidingWindow;

  ContextWindowCompressionConfig({this.triggerTokens, this.slidingWindow});

  factory ContextWindowCompressionConfig.fromJson(Map<String, dynamic> json) =>
      _$ContextWindowCompressionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ContextWindowCompressionConfigToJson(this);
}

/// Indicates the language of the audio should be automatically detected.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LanguageAuto {
  /// Creates a language auto-detection marker.
  LanguageAuto();

  /// Creates a [LanguageAuto] from a JSON payload.
  factory LanguageAuto.fromJson(Map<String, dynamic> json) =>
      _$LanguageAutoFromJson(json);

  /// Converts this marker to a JSON payload.
  Map<String, dynamic> toJson() => _$LanguageAutoToJson(this);
}

/// Provides hints to the model about possible languages present in the audio.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LanguageHints {
  final List<String>? languageCodes;

  LanguageHints({this.languageCodes});

  factory LanguageHints.fromJson(Map<String, dynamic> json) =>
      _$LanguageHintsFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageHintsToJson(this);
}

/// Configures transcription mode for audio transcription.
@JsonEnum(alwaysCreate: true)
enum AudioTranscriptionConfigMode {
  @JsonValue('MODE_UNSPECIFIED')
  MODE_UNSPECIFIED,
  @JsonValue('VERBATIM')
  VERBATIM,
  @JsonValue('SMART')
  SMART,
}

/// Audio transcription settings for input or output streams.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class AudioTranscriptionConfig {
  /// BCP-47 language codes providing hints about the languages present in the audio.
  /// If omitted or empty, defaults to automatic language detection. Standard upstream
  /// field (preferred over deprecated [languageHints] and [languageAuto]).
  final List<String>? languageCodes;

  /// The model will detect the language automatically. Do not use together
  /// with [languageHints].
  final LanguageAuto? languageAuto;

  /// Specifies one or more languages in the audio. Do not use together with
  /// [languageAuto].
  final LanguageHints? languageHints;

  /// A list of custom vocabulary phrases which bias the ASR model to improve
  /// recognition of these specific terms. Prefer this over [adaptationPhrases].
  final List<String>? customVocabulary;

  /// Deprecated: use [customVocabulary] instead. A list of phrases used for
  /// speech adaptation, which biases the ASR model to improve recognition of
  /// these specific terms.
  @Deprecated('Use customVocabulary instead.')
  final List<String>? adaptationPhrases;

  /// Optional. Configures transcription mode. Supported values: `VERBATIM`, `SMART`.
  /// Defaults to `VERBATIM` transcription if unspecified.
  final AudioTranscriptionConfigMode? mode;

  AudioTranscriptionConfig({
    this.languageCodes,
    this.languageAuto,
    this.languageHints,
    this.customVocabulary,
    // ignore: deprecated_member_use_from_same_package
    this.adaptationPhrases,
    this.mode,
  });

  factory AudioTranscriptionConfig.fromJson(Map<String, dynamic> json) =>
      _$AudioTranscriptionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AudioTranscriptionConfigToJson(this);
}

/// Proactivity options for realtime audio sessions.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ProactivityConfig {
  final bool? proactiveAudio;

  ProactivityConfig({this.proactiveAudio});

  factory ProactivityConfig.fromJson(Map<String, dynamic> json) =>
      _$ProactivityConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ProactivityConfigToJson(this);
}

/// Configuration for history exchange between client and server.
///
/// When [initialHistoryInClientContent] is `true`, after sending
/// `setup_complete` the server waits for `client_content` messages until
/// `turn_complete` is `true`. This initial history will not trigger a model
/// call and may end with model content. After `turn_complete` the client can
/// start the realtime conversation via `realtime_input`.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class HistoryConfig {
  final bool? initialHistoryInClientContent;

  HistoryConfig({this.initialHistoryInClientContent});

  factory HistoryConfig.fromJson(Map<String, dynamic> json) =>
      _$HistoryConfigFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryConfigToJson(this);
}

/// Safety settings to block unsafe content in Gemini responses.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class SafetySetting {
  final HarmCategory? category;
  final HarmBlockMethod? method;
  final HarmBlockThreshold? threshold;

  SafetySetting({this.category, this.method, this.threshold});

  factory SafetySetting.fromJson(Map<String, dynamic> json) =>
      _$SafetySettingFromJson(json);

  Map<String, dynamic> toJson() => _$SafetySettingToJson(this);
}

/// A customized avatar reference image.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class CustomizedAvatar {
  final String? imageMimeType;
  final String? imageData;

  CustomizedAvatar({this.imageMimeType, this.imageData});

  factory CustomizedAvatar.fromJson(Map<String, dynamic> json) =>
      _$CustomizedAvatarFromJson(json);

  Map<String, dynamic> toJson() => _$CustomizedAvatarToJson(this);
}

/// Avatar options for live video-capable sessions.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class AvatarConfig {
  final String? avatarName;
  final CustomizedAvatar? customizedAvatar;
  final int? audioBitrateBps;
  final int? videoBitrateBps;

  AvatarConfig({
    this.avatarName,
    this.customizedAvatar,
    this.audioBitrateBps,
    this.videoBitrateBps,
  });

  factory AvatarConfig.fromJson(Map<String, dynamic> json) =>
      _$AvatarConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AvatarConfigToJson(this);
}

/// The initial setup message sent when opening a Live API session.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LiveClientSetup {
  final String model;
  final GenerationConfig? generationConfig;
  final Content? systemInstruction;
  final List<Tool>? tools;
  final RealtimeInputConfig? realtimeInputConfig;
  final SessionResumptionConfig? sessionResumption;
  final ContextWindowCompressionConfig? contextWindowCompression;
  final AudioTranscriptionConfig? inputAudioTranscription;
  final AudioTranscriptionConfig? outputAudioTranscription;
  final ProactivityConfig? proactivity;
  final bool? explicitVadSignal;
  final AvatarConfig? avatarConfig;
  final List<SafetySetting>? safetySettings;

  /// Configures the exchange of history between the client and the server.
  final HistoryConfig? historyConfig;

  /// User-defined metadata labels for tracking or billing categorization.
  final Map<String, String>? labels;

  LiveClientSetup({
    required this.model,
    this.generationConfig,
    this.systemInstruction,
    this.tools,
    this.realtimeInputConfig,
    this.sessionResumption,
    this.contextWindowCompression,
    this.inputAudioTranscription,
    this.outputAudioTranscription,
    this.proactivity,
    this.explicitVadSignal,
    this.avatarConfig,
    this.safetySettings,
    this.historyConfig,
    this.labels,
  });

  factory LiveClientSetup.fromJson(Map<String, dynamic> json) =>
      _$LiveClientSetupFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$LiveClientSetupToJson(this);
    if (generationConfig != null) {
      json['generationConfig'] = generationConfig!.toJson();
    }
    if (systemInstruction != null) {
      json['systemInstruction'] = systemInstruction!.toJson();
    }
    if (realtimeInputConfig != null) {
      json['realtimeInputConfig'] = realtimeInputConfig!.toJson();
    }
    if (sessionResumption != null) {
      json['sessionResumption'] = sessionResumption!.toJson();
    }
    if (contextWindowCompression != null) {
      json['contextWindowCompression'] = contextWindowCompression!.toJson();
    }
    if (inputAudioTranscription != null) {
      json['inputAudioTranscription'] = inputAudioTranscription!.toJson();
    }
    if (outputAudioTranscription != null) {
      json['outputAudioTranscription'] = outputAudioTranscription!.toJson();
    }
    if (explicitVadSignal != null) {
      json['explicitVadSignal'] = explicitVadSignal;
    }
    if (avatarConfig != null) {
      json['avatarConfig'] = avatarConfig!.toJson();
    }
    if (safetySettings != null) {
      json['safetySettings'] = safetySettings!.map((e) => e.toJson()).toList();
    }
    if (historyConfig != null) {
      json['historyConfig'] = historyConfig!.toJson();
    }
    if (labels != null) {
      json['labels'] = labels;
    }
    return json;
  }
}

