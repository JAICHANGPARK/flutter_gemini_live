// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Auth & Ephemeral Tokens
// ============================================================================

/// Ephemeral authentication token representation.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class AuthToken {
  /// The resource name of the auth token (e.g. `auth_tokens/...`).
  final String? name;

  /// Optional time after which messages in Live API sessions will be rejected.
  final String? expireTime;

  /// Optional time after which new Live API sessions using this token will be rejected.
  final String? newSessionExpireTime;

  /// Optional number of times the token can be used (0 = unlimited, default = 1).
  final int? uses;

  AuthToken({
    this.name,
    this.expireTime,
    this.newSessionExpireTime,
    this.uses,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    final parsed = _$AuthTokenFromJson(json);
    return AuthToken(
      name: parsed.name,
      expireTime: parsed.expireTime ?? json['expireTime'] as String?,
      newSessionExpireTime: parsed.newSessionExpireTime ??
          json['newSessionExpireTime'] as String?,
      uses: parsed.uses,
    );
  }

  Map<String, dynamic> toJson() => _$AuthTokenToJson(this);
}

/// Configuration constraints locked in the ephemeral token for Live API connections.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LiveConnectConstraints {
  /// ID of the model to configure in the ephemeral token for Live API.
  final String? model;

  /// Configuration specific to Live API connections created using this token.
  final GenerationConfig? config;

  /// System instructions locked in the ephemeral token.
  final Content? systemInstruction;

  /// Tools locked in the ephemeral token.
  final List<Tool>? tools;

  /// Realtime input settings locked in the ephemeral token.
  final RealtimeInputConfig? realtimeInputConfig;

  /// Session resumption settings locked in the ephemeral token.
  final SessionResumptionConfig? sessionResumption;

  /// Context window compression settings locked in the ephemeral token.
  final ContextWindowCompressionConfig? contextWindowCompression;

  /// Input audio transcription settings locked in the ephemeral token.
  final AudioTranscriptionConfig? inputAudioTranscription;

  /// Output audio transcription settings locked in the ephemeral token.
  final AudioTranscriptionConfig? outputAudioTranscription;

  /// Proactivity settings locked in the ephemeral token.
  final ProactivityConfig? proactivity;

  /// Avatar settings locked in the ephemeral token.
  final AvatarConfig? avatarConfig;

  /// Safety settings locked in the ephemeral token.
  final List<SafetySetting>? safetySettings;

  /// History exchange settings locked in the ephemeral token.
  final HistoryConfig? historyConfig;

  /// Stream translation settings locked in the ephemeral token.
  final TranslationConfig? translationConfig;

  /// User-defined metadata labels locked in the ephemeral token.
  final Map<String, String>? labels;

  LiveConnectConstraints({
    this.model,
    Object? config,
    this.systemInstruction,
    this.tools,
    this.realtimeInputConfig,
    this.sessionResumption,
    this.contextWindowCompression,
    this.inputAudioTranscription,
    this.outputAudioTranscription,
    this.proactivity,
    this.avatarConfig,
    this.safetySettings,
    this.historyConfig,
    this.translationConfig,
    this.labels,
  }) : config = _parseConstraintsConfig(config);

  static GenerationConfig? _parseConstraintsConfig(Object? value) {
    if (value == null) return null;
    if (value is GenerationConfig) return value;
    if (value is Map<String, dynamic>) {
      return LiveConnectConfig.fromJson(value);
    }
    throw ArgumentError.value(
      value,
      'config',
      'Must be a LiveConnectConfig, GenerationConfig, or Map<String, dynamic>.',
    );
  }

  factory LiveConnectConstraints.fromJson(Map<String, dynamic> json) {
    final normalized = <String, dynamic>{
      ...json,
      if (!json.containsKey('system_instruction') &&
          json.containsKey('systemInstruction'))
        'system_instruction': json['systemInstruction'],
      if (!json.containsKey('realtime_input_config') &&
          json.containsKey('realtimeInputConfig'))
        'realtime_input_config': json['realtimeInputConfig'],
      if (!json.containsKey('session_resumption') &&
          json.containsKey('sessionResumption'))
        'session_resumption': json['sessionResumption'],
      if (!json.containsKey('context_window_compression') &&
          json.containsKey('contextWindowCompression'))
        'context_window_compression': json['contextWindowCompression'],
      if (!json.containsKey('input_audio_transcription') &&
          json.containsKey('inputAudioTranscription'))
        'input_audio_transcription': json['inputAudioTranscription'],
      if (!json.containsKey('output_audio_transcription') &&
          json.containsKey('outputAudioTranscription'))
        'output_audio_transcription': json['outputAudioTranscription'],
      if (!json.containsKey('avatar_config') &&
          json.containsKey('avatarConfig'))
        'avatar_config': json['avatarConfig'],
      if (!json.containsKey('safety_settings') &&
          json.containsKey('safetySettings'))
        'safety_settings': json['safetySettings'],
      if (!json.containsKey('history_config') &&
          json.containsKey('historyConfig'))
        'history_config': json['historyConfig'],
      if (!json.containsKey('translation_config') &&
          json.containsKey('translationConfig'))
        'translation_config': json['translationConfig'],
    };
    final parsed = _$LiveConnectConstraintsFromJson(normalized);
    final rawConfig = json['config'];
    return LiveConnectConstraints(
      model: parsed.model,
      config: rawConfig is Map<String, dynamic>
          ? LiveConnectConfig.fromJson(rawConfig)
          : parsed.config,
      systemInstruction: parsed.systemInstruction,
      tools: parsed.tools,
      realtimeInputConfig: parsed.realtimeInputConfig,
      sessionResumption: parsed.sessionResumption,
      contextWindowCompression: parsed.contextWindowCompression,
      inputAudioTranscription: parsed.inputAudioTranscription,
      outputAudioTranscription: parsed.outputAudioTranscription,
      proactivity: parsed.proactivity,
      avatarConfig: parsed.avatarConfig,
      safetySettings: parsed.safetySettings,
      historyConfig: parsed.historyConfig,
      translationConfig: parsed.translationConfig,
      labels: parsed.labels,
    );
  }

  Map<String, dynamic> toJson() => _$LiveConnectConstraintsToJson(this);
}

/// Configuration parameters for creating an ephemeral authentication token.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class CreateAuthTokenConfig {
  /// Optional time after which messages in Live API sessions will be rejected.
  final String? expireTime;

  /// Optional time after which new Live API sessions using this token will be rejected.
  final String? newSessionExpireTime;

  /// Optional number of times the token can be used.
  final int? uses;

  /// Configuration specific to Live API connections created using this token.
  final LiveConnectConstraints? liveConnectConstraints;

  /// Additional fields to lock in the effective LiveConnectParameters.
  final List<String>? lockAdditionalFields;

  CreateAuthTokenConfig({
    this.expireTime,
    this.newSessionExpireTime,
    this.uses,
    this.liveConnectConstraints,
    this.lockAdditionalFields,
  });

  factory CreateAuthTokenConfig.fromJson(Map<String, dynamic> json) =>
      _$CreateAuthTokenConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAuthTokenConfigToJson(this);
}

