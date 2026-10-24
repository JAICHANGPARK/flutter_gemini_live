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

  /// If true, enables interim transcript timestamps.
  final bool? interimTranscriptTimestampEnabled;

  RealtimeInputConfig({
    this.automaticActivityDetection,
    this.activityHandling,
    this.turnCoverage,
    this.interimTranscriptTimestampEnabled,
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

  /// Creates a [SlidingWindow] configuration.
  ///
  /// [targetTokens] accepts an `int` or `String` token count.
  SlidingWindow({Object? targetTokens})
    : targetTokens = targetTokens?.toString();

  factory SlidingWindow.fromJson(Map<String, dynamic> json) =>
      _$SlidingWindowFromJson({
        ...json,
        if ((json['target_tokens'] ?? json['targetTokens']) != null)
          'target_tokens':
              (json['target_tokens'] ?? json['targetTokens']).toString(),
      });

  Map<String, dynamic> toJson() => _$SlidingWindowToJson(this);
}

/// Context compression settings for long-running sessions.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ContextWindowCompressionConfig {
  final String? triggerTokens;
  final SlidingWindow? slidingWindow;

  /// Creates a [ContextWindowCompressionConfig].
  ///
  /// [triggerTokens] accepts an `int` or `String` token threshold.
  ContextWindowCompressionConfig({Object? triggerTokens, this.slidingWindow})
    : triggerTokens = triggerTokens?.toString();

  factory ContextWindowCompressionConfig.fromJson(Map<String, dynamic> json) =>
      _$ContextWindowCompressionConfigFromJson({
        ...json,
        if ((json['trigger_tokens'] ?? json['triggerTokens']) != null)
          'trigger_tokens':
              (json['trigger_tokens'] ?? json['triggerTokens']).toString(),
        if (json['slidingWindow'] != null && json['sliding_window'] == null)
          'sliding_window': json['slidingWindow'],
      });

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

/// HTTP and WebSocket transport options for API requests and Live sessions.
///
/// Mirrors `HttpOptions` in the upstream `@google/genai` (JS/TS) and
/// `google-genai` (Python) SDKs.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class HttpOptions {
  /// The base URL for the AI platform service endpoint.
  final String? baseUrl;

  /// Specifies the version of the API to use (e.g. `'v1beta'`, `'v1alpha'`).
  final String? apiVersion;

  /// Additional HTTP headers to be sent with the request or WebSocket handshake.
  final Map<String, String>? headers;

  /// Timeout for the request in milliseconds.
  final int? timeout;

  /// Extra parameters to add to the request body.
  final Map<String, dynamic>? extraBody;

  /// HTTP retry options for the request.
  final Map<String, dynamic>? retryOptions;

  /// Args passed to the HTTP client.
  final Map<String, dynamic>? clientArgs;

  /// Args passed to the async HTTP client.
  final Map<String, dynamic>? asyncClientArgs;

  /// Creates [HttpOptions].
  const HttpOptions({
    this.baseUrl,
    this.apiVersion,
    this.headers,
    this.timeout,
    this.extraBody,
    this.retryOptions,
    this.clientArgs,
    this.asyncClientArgs,
  });

  /// Creates [HttpOptions] from a JSON map (supports both `camelCase` and `snake_case`).
  factory HttpOptions.fromJson(Map<String, dynamic> json) {
    final normalized = <String, dynamic>{
      ...json,
      if (!json.containsKey('base_url') && json.containsKey('baseUrl'))
        'base_url': json['baseUrl'],
      if (!json.containsKey('api_version') && json.containsKey('apiVersion'))
        'api_version': json['apiVersion'],
      if (!json.containsKey('extra_body') && json.containsKey('extraBody'))
        'extra_body': json['extraBody'],
      if (!json.containsKey('retry_options') &&
          json.containsKey('retryOptions'))
        'retry_options': json['retryOptions'],
      if (!json.containsKey('client_args') && json.containsKey('clientArgs'))
        'client_args': json['clientArgs'],
      if (!json.containsKey('async_client_args') &&
          json.containsKey('asyncClientArgs'))
        'async_client_args': json['asyncClientArgs'],
    };
    return _$HttpOptionsFromJson(normalized);
  }

  /// Serializes this [HttpOptions] to a JSON map.
  Map<String, dynamic> toJson() => _$HttpOptionsToJson(this);

  /// Returns a new [HttpOptions] patched with non-null fields from [patch].
  ///
  /// Header maps from both options are merged, with [patch] headers taking
  /// precedence over existing headers.
  HttpOptions merge(HttpOptions? patch) {
    if (patch == null) return this;
    final mergedHeaders = (headers != null || patch.headers != null)
        ? <String, String>{...?headers, ...?patch.headers}
        : null;
    return HttpOptions(
      baseUrl: patch.baseUrl ?? baseUrl,
      apiVersion: patch.apiVersion ?? apiVersion,
      headers: mergedHeaders,
      timeout: patch.timeout ?? timeout,
      extraBody: patch.extraBody ?? extraBody,
      retryOptions: patch.retryOptions ?? retryOptions,
      clientArgs: patch.clientArgs ?? clientArgs,
      asyncClientArgs: patch.asyncClientArgs ?? asyncClientArgs,
    );
  }
}

/// Session configuration for Live API connections.
///
/// Mirrors `LiveConnectConfig` in the upstream `@google/genai` (JS/TS) and
/// `google-genai` (Python) SDKs. Combines [GenerationConfig] fields with
/// session-level settings such as [httpOptions], [systemInstruction], [tools],
/// [realtimeInputConfig], [sessionResumption], [contextWindowCompression],
/// [inputAudioTranscription], [outputAudioTranscription], [proactivity],
/// [explicitVadSignal], [avatarConfig], [safetySettings], and [historyConfig].
class LiveConnectConfig extends GenerationConfig {
  /// Optional HTTP/WebSocket transport options (`baseUrl`, `apiVersion`, `headers`)
  /// that override client-level options for this session.
  final HttpOptions? httpOptions;

  /// Optional nested generation configuration.
  final GenerationConfig? generationConfig;

  /// System instruction guiding the model's persona and behavior.
  final Content? systemInstruction;

  /// Tools and function declarations available to the model.
  final List<Tool>? tools;

  /// Asynchronous [CallableTool] instances provided in `tools`.
  final List<CallableTool>? callableTools;

  /// Configuration for realtime audio/video input and voice activity detection.
  final RealtimeInputConfig? realtimeInputConfig;

  /// Configuration for session resumption across reconnects.
  final SessionResumptionConfig? sessionResumption;

  /// Configuration for sliding-window context compression in long sessions.
  final ContextWindowCompressionConfig? contextWindowCompression;

  /// Configuration for user input audio transcription.
  final AudioTranscriptionConfig? inputAudioTranscription;

  /// Configuration for model output audio transcription.
  final AudioTranscriptionConfig? outputAudioTranscription;

  /// Proactivity configuration controlling when the model speaks up.
  final ProactivityConfig? proactivity;

  /// Whether explicit voice activity detection signals are enabled.
  final bool? explicitVadSignal;

  /// Avatar configuration for visual avatar streaming.
  final AvatarConfig? avatarConfig;

  /// Safety settings applied to model generation.
  final List<SafetySetting>? safetySettings;

  /// Configuration for exchanging prior conversation history with the server.
  final HistoryConfig? historyConfig;

  /// Creates a [LiveConnectConfig] for a Gemini Live session.
  LiveConnectConfig({
    Object? httpOptions,
    this.generationConfig,
    super.temperature,
    super.topK,
    super.topP,
    super.maxOutputTokens,
    super.responseModalities,
    super.mediaResolution,
    super.seed,
    Object? speechConfig,
    super.thinkingConfig,
    super.enableAffectiveDialog,
    super.translationConfig,
    super.audioTranscriptionConfig,
    super.labels,
    Object? systemInstruction,
    List<Object>? tools,
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
  }) : httpOptions = _parseConfigHttpOptions(httpOptions),
       systemInstruction = _parseConfigSystemInstruction(systemInstruction),
       tools = _extractTools(tools),
       callableTools = _extractCallableTools(tools),
       super(speechConfig: _parseConfigSpeechConfig(speechConfig));

  static HttpOptions? _parseConfigHttpOptions(Object? value) {
    if (value == null) return null;
    if (value is HttpOptions) return value;
    if (value is Map<String, dynamic>) {
      return HttpOptions.fromJson(value);
    }
    throw ArgumentError.value(
      value,
      'httpOptions',
      'Must be an HttpOptions or Map<String, dynamic>.',
    );
  }

  static Content? _parseConfigSystemInstruction(Object? value) {
    if (value == null) return null;
    if (value is Content) return value;
    if (value is String) {
      return Content(parts: [Part(text: value)], role: 'user');
    }
    if (value is Part) {
      return Content(parts: [value], role: 'user');
    }
    if (value is List<Part>) {
      return Content(parts: value, role: 'user');
    }
    if (value is Map<String, dynamic>) {
      if (value.containsKey('parts') || value.containsKey('role')) {
        return Content.fromJson(value);
      }
      return Content(parts: [Part.fromJson(value)], role: 'user');
    }
    throw ArgumentError.value(
      value,
      'systemInstruction',
      'Must be a Content, String, Part, List<Part>, or Map<String, dynamic>.',
    );
  }

  static SpeechConfig? _parseConfigSpeechConfig(Object? value) {
    if (value == null) return null;
    if (value is SpeechConfig) return value;
    if (value is GeminiLiveVoice) return SpeechConfig.fromLiveVoice(value);
    if (value is String) {
      return SpeechConfig(
        voiceConfig: VoiceConfig(
          prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: value),
        ),
      );
    }
    if (value is Map<String, dynamic>) {
      return SpeechConfig.fromJson(value);
    }
    throw ArgumentError.value(
      value,
      'speechConfig',
      'Must be a SpeechConfig, GeminiLiveVoice, String (voiceName), or Map<String, dynamic>.',
    );
  }

  static List<Tool>? _extractTools(List<Object>? rawTools) {
    if (rawTools == null) return null;
    final list = <Tool>[];
    for (final item in rawTools) {
      if (item is Tool) {
        list.add(item);
      } else if (item is Map<String, dynamic>) {
        list.add(Tool.fromJson(item));
      } else if (item is! CallableTool) {
        throw ArgumentError.value(
          item,
          'tools',
          'Each tool must be a Tool, CallableTool, or Map<String, dynamic>.',
        );
      }
    }
    return list;
  }

  static List<CallableTool>? _extractCallableTools(List<Object>? rawTools) {
    if (rawTools == null) return null;
    final list = rawTools.whereType<CallableTool>().toList();
    return list.isEmpty ? null : list;
  }

  /// Creates a [LiveConnectConfig] from a JSON payload.
  factory LiveConnectConfig.fromJson(Map<String, dynamic> json) {
    final base = _$GenerationConfigFromJson(json);
    final rawHttpOptions = json['httpOptions'] ?? json['http_options'];
    final rawGen = json['generationConfig'] ?? json['generation_config'];
    final rawSys = json['systemInstruction'] ?? json['system_instruction'];
    final rawTools = json['tools'] as List<dynamic>?;
    final rawRealtime =
        json['realtimeInputConfig'] ?? json['realtime_input_config'];
    final rawResumption =
        json['sessionResumption'] ?? json['session_resumption'];
    final rawCompression =
        json['contextWindowCompression'] ?? json['context_window_compression'];
    final rawInputTrans =
        json['inputAudioTranscription'] ?? json['input_audio_transcription'];
    final rawOutputTrans =
        json['outputAudioTranscription'] ?? json['output_audio_transcription'];
    final rawProactivity = json['proactivity'];
    final rawVad = json['explicitVadSignal'] ?? json['explicit_vad_signal'];
    final rawAvatar = json['avatarConfig'] ?? json['avatar_config'];
    final rawSafety =
        (json['safetySettings'] ?? json['safety_settings']) as List<dynamic>?;
    final rawHistory = json['historyConfig'] ?? json['history_config'];
    return LiveConnectConfig(
      httpOptions: rawHttpOptions == null
          ? null
          : HttpOptions.fromJson(rawHttpOptions as Map<String, dynamic>),
      generationConfig: rawGen == null
          ? null
          : GenerationConfig.fromJson(rawGen as Map<String, dynamic>),
      temperature: base.temperature,
      topK: base.topK,
      topP: base.topP,
      maxOutputTokens: base.maxOutputTokens,
      responseModalities: base.responseModalities,
      mediaResolution: base.mediaResolution,
      seed: base.seed,
      speechConfig: base.speechConfig,
      thinkingConfig: base.thinkingConfig,
      enableAffectiveDialog: base.enableAffectiveDialog,
      translationConfig: base.translationConfig,
      audioTranscriptionConfig: base.audioTranscriptionConfig,
      labels: base.labels,
      systemInstruction: rawSys,
      tools: rawTools?.cast<Object>(),
      realtimeInputConfig: rawRealtime == null
          ? null
          : RealtimeInputConfig.fromJson(rawRealtime as Map<String, dynamic>),
      sessionResumption: rawResumption == null
          ? null
          : SessionResumptionConfig.fromJson(
              rawResumption as Map<String, dynamic>,
            ),
      contextWindowCompression: rawCompression == null
          ? null
          : ContextWindowCompressionConfig.fromJson(
              rawCompression as Map<String, dynamic>,
            ),
      inputAudioTranscription: rawInputTrans == null
          ? null
          : AudioTranscriptionConfig.fromJson(
              rawInputTrans as Map<String, dynamic>,
            ),
      outputAudioTranscription: rawOutputTrans == null
          ? null
          : AudioTranscriptionConfig.fromJson(
              rawOutputTrans as Map<String, dynamic>,
            ),
      proactivity: rawProactivity == null
          ? null
          : ProactivityConfig.fromJson(rawProactivity as Map<String, dynamic>),
      explicitVadSignal: rawVad as bool?,
      avatarConfig: rawAvatar == null
          ? null
          : AvatarConfig.fromJson(rawAvatar as Map<String, dynamic>),
      safetySettings: rawSafety
          ?.map((e) => SafetySetting.fromJson(e as Map<String, dynamic>))
          .toList(),
      historyConfig: rawHistory == null
          ? null
          : HistoryConfig.fromJson(rawHistory as Map<String, dynamic>),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      if (generationConfig != null) ...generationConfig!.toJson(),
      ...super.toJson(),
    };
    if (systemInstruction != null) {
      json['systemInstruction'] = systemInstruction!.toJson();
    }
    if (tools != null) {
      json['tools'] = tools!.map((t) => t.toJson()).toList();
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
    if (proactivity != null) {
      json['proactivity'] = proactivity!.toJson();
    }
    if (explicitVadSignal != null) {
      json['explicitVadSignal'] = explicitVadSignal;
    }
    if (avatarConfig != null) {
      json['avatarConfig'] = avatarConfig!.toJson();
    }
    if (safetySettings != null) {
      json['safetySettings'] = safetySettings!.map((s) => s.toJson()).toList();
    }
    if (historyConfig != null) {
      json['historyConfig'] = historyConfig!.toJson();
    }
    return json;
  }
}


