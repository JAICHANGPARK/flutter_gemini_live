// ignore_for_file: constant_identifier_names

part of '../models.dart';


/// The type of voice resource.
enum VoiceType {
  @JsonValue('replicated')
  replicated,
  @JsonValue('prompted')
  prompted,
  @JsonValue('prebuilt')
  prebuilt,
}

/// The perceived pitch of a synthesized voice.
enum VoicePitch {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
}

/// Audio data containing base64-encoded audio bytes and mime type.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class VoiceAudioData {
  /// Base64-encoded audio bytes.
  final String data;

  /// The IANA standard MIME type of the source data (e.g. `audio/wav`, `audio/pcm`).
  final String mimeType;

  VoiceAudioData({required this.data, required this.mimeType});

  factory VoiceAudioData.fromJson(Map<String, dynamic> json) =>
      _$VoiceAudioDataFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceAudioDataToJson(this);
}

/// Parameters for prompted voice generation.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class PromptedVoice {
  /// Natural-language prompt describing the desired voice personality, tone, and character.
  final String input;

  PromptedVoice({required this.input});

  factory PromptedVoice.fromJson(Map<String, dynamic> json) =>
      _$PromptedVoiceFromJson(json);

  Map<String, dynamic> toJson() => _$PromptedVoiceToJson(this);
}

/// Parameters for replicated (cloned) voice generation.
@JsonSerializable(includeIfNull: false, explicitToJson: true, fieldRename: FieldRename.snake)
class ReplicatedVoice {
  /// Recorded consent audio verifying ownership/permission of the voice.
  final VoiceAudioData? consentAudio;

  /// Source reference audio sample used for voice cloning.
  final VoiceAudioData? sourceAudio;

  ReplicatedVoice({this.consentAudio, this.sourceAudio});

  factory ReplicatedVoice.fromJson(Map<String, dynamic> json) =>
      _$ReplicatedVoiceFromJson(json);

  Map<String, dynamic> toJson() => _$ReplicatedVoiceToJson(this);
}

/// A custom voice resource (created via CreateVoice) or prebuilt system voice (returned by ListVoices).
@JsonSerializable(includeIfNull: false, explicitToJson: true, fieldRename: FieldRename.snake)
class VoiceResource {
  /// Unique voice identifier (e.g. `voice_abc123` for Google-managed voices, or catalog name).
  final String? id;

  /// Client-managed voice replication key (`voicekey_...`) returned when `store == false`.
  final String? key;

  /// The voice type: `replicated`, `prompted`, or `prebuilt`.
  final VoiceType? type;

  /// User-provided display name or catalog name.
  final String? displayName;

  /// Descriptive summary of vocal timbre, personality, and tone.
  final String? description;

  /// Regional accent descriptor (e.g. "American", "British").
  final String? accent;

  /// Perceived voice gender presentation (e.g. "female", "male", "neutral").
  final String? gender;

  /// Primary BCP-47 language tag (e.g. "en-US", "fr-FR", "ko-KR").
  final String? languageCode;

  /// Intended persona or character archetype (e.g. "Warm, Friendly", "Narrator").
  final String? persona;

  /// Pitch of the voice: `low`, `medium`, or `high`.
  final VoicePitch? pitch;

  /// Optimal usage context or domain (e.g. "Conversational", "Audiobook", "News").
  final String? context;

  /// Geographic region code (e.g. "US", "GB", "KR").
  final String? regionCode;

  /// Model used to design or replicate the voice.
  final String? model;

  /// Expiration timestamp for custom stored voices or keys.
  final String? expireTime;

  /// Parameters for prompted voice generation, if applicable.
  final PromptedVoice? prompted;

  /// Parameters for replicated voice generation, if applicable.
  final ReplicatedVoice? replicated;

  /// Audio payload used for voice creation or sample audio preview.
  final VoiceAudioData? sampleAudio;

  VoiceResource({
    this.id,
    this.key,
    this.type,
    this.displayName,
    this.description,
    this.accent,
    this.gender,
    this.languageCode,
    this.persona,
    this.pitch,
    this.context,
    this.regionCode,
    this.model,
    this.expireTime,
    this.prompted,
    this.replicated,
    this.sampleAudio,
  });

  factory VoiceResource.fromJson(Map<String, dynamic> json) =>
      _$VoiceResourceFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceResourceToJson(this);
}

/// Request payload for creating a custom voice.
@JsonSerializable(includeIfNull: false, explicitToJson: true, fieldRename: FieldRename.snake)
class CreateVoiceRequest {
  /// Required. The type of voice to create (`prompted` or `replicated`).
  final VoiceType type;

  /// Required if [type] is [VoiceType.prompted].
  final PromptedVoice? prompted;

  /// Required if [type] is [VoiceType.replicated].
  final ReplicatedVoice? replicated;

  /// Optional. Audio payload used for voice creation.
  final VoiceAudioData? sampleAudio;

  /// Whether to store the voice in Google's voice repository (`true`), or return an ephemeral replication key (`false`).
  final bool? store;

  /// User-facing display name.
  final String? displayName;

  /// Descriptive summary of vocal timbre and personality.
  final String? description;

  /// Regional accent descriptor.
  final String? accent;

  /// Perceived voice gender presentation.
  final String? gender;

  /// Primary BCP-47 language tag.
  final String? languageCode;

  /// Intended persona or character archetype.
  final String? persona;

  /// Pitch setting.
  final VoicePitch? pitch;

  /// Optimal usage context or domain.
  final String? context;

  /// Geographic region code.
  final String? regionCode;

  /// Model used to design or replicate the voice.
  final String? model;

  CreateVoiceRequest({
    required this.type,
    this.prompted,
    this.replicated,
    this.sampleAudio,
    this.store,
    this.displayName,
    this.description,
    this.accent,
    this.gender,
    this.languageCode,
    this.persona,
    this.pitch,
    this.context,
    this.regionCode,
    this.model,
  });

  /// Factory helper for creating a prompted voice.
  factory CreateVoiceRequest.prompted({
    required String prompt,
    String? displayName,
    String? description,
    String? accent,
    String? gender,
    String? languageCode,
    String? persona,
    VoicePitch? pitch,
    String? context,
    String? regionCode,
    String? model,
    bool store = true,
  }) =>
      CreateVoiceRequest(
        type: VoiceType.prompted,
        prompted: PromptedVoice(input: prompt),
        displayName: displayName,
        description: description,
        accent: accent,
        gender: gender,
        languageCode: languageCode,
        persona: persona,
        pitch: pitch,
        context: context,
        regionCode: regionCode,
        model: model,
        store: store,
      );

  /// Factory helper for creating a replicated (cloned) voice.
  factory CreateVoiceRequest.replicated({
    required VoiceAudioData sourceAudio,
    VoiceAudioData? consentAudio,
    VoiceAudioData? sampleAudio,
    String? displayName,
    String? description,
    String? accent,
    String? gender,
    String? languageCode,
    String? persona,
    VoicePitch? pitch,
    String? context,
    String? regionCode,
    String? model,
    bool store = true,
  }) =>
      CreateVoiceRequest(
        type: VoiceType.replicated,
        replicated: ReplicatedVoice(
          sourceAudio: sourceAudio,
          consentAudio: consentAudio,
        ),
        sampleAudio: sampleAudio,
        displayName: displayName,
        description: description,
        accent: accent,
        gender: gender,
        languageCode: languageCode,
        persona: persona,
        pitch: pitch,
        context: context,
        regionCode: regionCode,
        model: model,
        store: store,
      );

  factory CreateVoiceRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateVoiceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateVoiceRequestToJson(this);
}

/// Response returned by ListVoices.
@JsonSerializable(includeIfNull: false, explicitToJson: true, fieldRename: FieldRename.snake)
class ListVoicesResponse {
  final List<VoiceResource>? voices;
  final String? nextPageToken;

  ListVoicesResponse({this.voices, this.nextPageToken});

  factory ListVoicesResponse.fromJson(Map<String, dynamic> json) =>
      _$ListVoicesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListVoicesResponseToJson(this);
}

/// Response returned by DeleteVoice.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class DeleteVoiceResponse {
  final String? message;

  DeleteVoiceResponse({this.message});

  factory DeleteVoiceResponse.fromJson(Map<String, dynamic> json) =>
      _$DeleteVoiceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteVoiceResponseToJson(this);
}

/// Standard prebuilt voice personas available in Google Gemini Live and Text-to-Speech (TTS).
///
/// Provides type-safe access to Google's official 30 voice personas, eliminating
/// string typos and providing descriptive tonal metadata for each persona.
enum GeminiLiveVoice {
  /// Upbeat, playful, and lively voice (Default for many Gemini Live experiences).
  puck('Puck', tone: 'Upbeat, playful, and lively', gender: 'Neutral / Expressive'),

  /// Deep, calm, and informative resonant voice.
  charon('Charon', tone: 'Deep, calm, and resonant', gender: 'Male / Deep'),

  /// Warm, soothing, and empathetic voice.
  kore('Kore', tone: 'Warm, soothing, and empathetic', gender: 'Female / Warm'),

  /// Authoritative, excitable, clear, and confident voice.
  fenrir('Fenrir', tone: 'Authoritative, clear, and confident', gender: 'Male / Strong'),

  /// Melodic, breezy, gentle, and thoughtful voice.
  aoede('Aoede', tone: 'Melodic, gentle, and thoughtful', gender: 'Female / Calm'),

  /// Youthful, bright, energetic, and articulate voice.
  leda('Leda', tone: 'Bright, energetic, and articulate', gender: 'Female / Bright'),

  /// Steady, firm, direct, and composed voice.
  orus('Orus', tone: 'Steady, direct, and composed', gender: 'Male / Neutral'),

  /// Crisp, modern, bright, and friendly voice.
  zephyr('Zephyr', tone: 'Crisp, modern, and friendly', gender: 'Neutral / Crisp'),

  /// Easy-going and relaxed warm voice.
  callirrhoe('Callirrhoe', tone: 'Easy-going and gentle', gender: 'Female / Warm'),

  /// Bright and radiant voice.
  autonoe('Autonoe', tone: 'Bright and energetic', gender: 'Female / Bright'),

  /// Breathy and soft gentle voice.
  enceladus('Enceladus', tone: 'Breathy and soft', gender: 'Neutral / Soft'),

  /// Clear, articulate, and distinct voice.
  iapetus('Iapetus', tone: 'Clear and distinct', gender: 'Male / Clear'),

  /// Easy-going and composed voice.
  umbriel('Umbriel', tone: 'Easy-going and calm', gender: 'Neutral / Calm'),

  /// Smooth and balanced voice.
  algieba('Algieba', tone: 'Smooth and balanced', gender: 'Neutral / Smooth'),

  /// Smooth, natural, and gentle voice.
  despina('Despina', tone: 'Smooth and natural', gender: 'Female / Smooth'),

  /// Clear and crisp voice.
  erinome('Erinome', tone: 'Clear and bright', gender: 'Female / Clear'),

  /// Gravelly, deep, and textured voice.
  algenib('Algenib', tone: 'Gravelly and deep', gender: 'Male / Textured'),

  /// Informative, scholarly, and measured voice.
  rasalgethi('Rasalgethi', tone: 'Informative and measured', gender: 'Male / Informative'),

  /// Upbeat, vibrant, and optimistic voice.
  laomedeia('Laomedeia', tone: 'Upbeat and vibrant', gender: 'Female / Upbeat'),

  /// Soft, quiet, and delicate voice.
  achernar('Achernar', tone: 'Soft and quiet', gender: 'Female / Soft'),

  /// Firm, deliberate, and dependable voice.
  alnilam('Alnilam', tone: 'Firm and deliberate', gender: 'Male / Firm'),

  /// Even, measured, and steady voice.
  schedar('Schedar', tone: 'Even and steady', gender: 'Neutral / Even'),

  /// Mature, grounded, and experienced voice.
  gacrux('Gacrux', tone: 'Mature and grounded', gender: 'Male / Mature'),

  /// Forward, vivid, and confident voice.
  pulcherrima('Pulcherrima', tone: 'Forward and vivid', gender: 'Female / Forward'),

  /// Friendly, approachable, and warm voice.
  achird('Achird', tone: 'Friendly and warm', gender: 'Neutral / Friendly'),

  /// Casual, conversational, and relaxed voice.
  zubenelgenubi('Zubenelgenubi', tone: 'Casual and relaxed', gender: 'Male / Casual'),

  /// Gentle, sweet, and comforting voice.
  vindemiatrix('Vindemiatrix', tone: 'Gentle and kind', gender: 'Female / Gentle'),

  /// Lively, spirited, and active voice.
  sadachbia('Sadachbia', tone: 'Lively and active', gender: 'Neutral / Lively'),

  /// Knowledgeable, articulate, and professional voice.
  sadaltager('Sadaltager', tone: 'Knowledgeable and scholarly', gender: 'Male / Knowledgeable'),

  /// Warm, comforting, and resonant voice.
  sulafat('Sulafat', tone: 'Warm and resonant', gender: 'Female / Warm');

  /// The official name string sent to Google Gemini API (e.g. "Puck", "Charon").
  final String voiceName;

  /// The characteristic tonal style and persona description.
  final String tone;

  /// The perceived vocal pitch or gender profile.
  final String gender;

  const GeminiLiveVoice(
    this.voiceName, {
    required this.tone,
    required this.gender,
  });

  /// Convenience method to create a [SpeechConfig] directly from this voice.
  SpeechConfig toSpeechConfig({String? languageCode}) =>
      SpeechConfig.fromVoice(voiceName, languageCode: languageCode);

  /// Convenience method to create a [VoiceConfig] directly from this voice.
  VoiceConfig toVoiceConfig() => VoiceConfig.fromVoiceName(voiceName);

  /// Convenience method to create a [PrebuiltVoiceConfig] directly from this voice.
  PrebuiltVoiceConfig toPrebuiltVoiceConfig() =>
      PrebuiltVoiceConfig(voiceName: voiceName);

  /// Case-insensitive lookup from string voice name or enum identifier.
  ///
  /// Returns null if no matching prebuilt voice is found.
  static GeminiLiveVoice? fromName(String? name) {
    if (name == null || name.isEmpty) return null;
    final normalized = name.trim().toLowerCase();
    for (final voice in GeminiLiveVoice.values) {
      if (voice.voiceName.toLowerCase() == normalized ||
          voice.name.toLowerCase() == normalized) {
        return voice;
      }
    }
    return null;
  }

  /// Alias for [fromName].
  static GeminiLiveVoice? fromString(String? name) => fromName(name);

  /// Serializes to the standard voice name string.
  String toJson() => voiceName;
}

/// A prebuilt voice selection for synthesized audio output.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class PrebuiltVoiceConfig {
  final String? voiceName;

  PrebuiltVoiceConfig({this.voiceName});

  /// Convenience constructor to create a [PrebuiltVoiceConfig] with a [GeminiLiveVoice] enum.
  factory PrebuiltVoiceConfig.fromLiveVoice(GeminiLiveVoice voice) =>
      PrebuiltVoiceConfig(voiceName: voice.voiceName);

  /// Returns the corresponding [GeminiLiveVoice] enum if matched with a prebuilt voice.
  GeminiLiveVoice? get liveVoice => GeminiLiveVoice.fromName(voiceName);

  factory PrebuiltVoiceConfig.fromJson(Map<String, dynamic> json) =>
      _$PrebuiltVoiceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PrebuiltVoiceConfigToJson(this);
}

/// Voice settings applied to spoken responses.
@JsonSerializable(includeIfNull: false, explicitToJson: true, fieldRename: FieldRename.snake)
class VoiceConfig {
  final ReplicatedVoiceConfig? replicatedVoiceConfig;
  final PrebuiltVoiceConfig? prebuiltVoiceConfig;

  /// Optional. Direct voice identifier or key (e.g. Google-managed custom voice
  /// ID `voice_...`, replication key `voicekey_...`, or catalog voice name).
  final String? voice;

  /// Optional. Prompted voice parameters for generating natural-language designed voices.
  final PromptedVoice? promptedVoiceConfig;

  VoiceConfig({
    this.replicatedVoiceConfig,
    this.prebuiltVoiceConfig,
    this.voice,
    this.promptedVoiceConfig,
  });

  /// Convenience constructor to create a [VoiceConfig] with a prebuilt voice name.
  factory VoiceConfig.fromVoiceName(String voiceName) =>
      VoiceConfig(prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: voiceName), voice: voiceName);

  /// Convenience constructor to create a [VoiceConfig] with a [GeminiLiveVoice] enum.
  factory VoiceConfig.fromLiveVoice(GeminiLiveVoice voice) =>
      VoiceConfig.fromVoiceName(voice.voiceName);

  /// Convenience constructor to create a [VoiceConfig] with a custom voice ID or key.
  factory VoiceConfig.fromVoiceId(String voiceId) =>
      VoiceConfig(voice: voiceId);

  /// Returns the corresponding [GeminiLiveVoice] enum if matched with a prebuilt voice.
  GeminiLiveVoice? get liveVoice =>
      GeminiLiveVoice.fromName(voice ?? prebuiltVoiceConfig?.voiceName);

  factory VoiceConfig.fromJson(Map<String, dynamic> json) =>
      _$VoiceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceConfigToJson(this);
}

/// The signature of a voice consent check.
@JsonSerializable(includeIfNull: false)
class VoiceConsentSignature {
  final String? signature;

  VoiceConsentSignature({this.signature});

  factory VoiceConsentSignature.fromJson(Map<String, dynamic> json) =>
      _$VoiceConsentSignatureFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceConsentSignatureToJson(this);
}

/// Voice cloning settings for custom speech output.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ReplicatedVoiceConfig {
  final String? mimeType;
  final String? voiceSampleAudio;

  /// Recorded consent verifying ownership of the voice, as base64-encoded
  /// 16-bit signed little-endian WAV data with a 24kHz sampling rate.
  final String? consentAudio;

  /// Signature of a previously verified consent audio, used instead of
  /// [consentAudio] to reduce latency.
  final VoiceConsentSignature? voiceConsentSignature;

  ReplicatedVoiceConfig({
    this.mimeType,
    this.voiceSampleAudio,
    this.consentAudio,
    this.voiceConsentSignature,
  });

  factory ReplicatedVoiceConfig.fromJson(Map<String, dynamic> json) =>
      _$ReplicatedVoiceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ReplicatedVoiceConfigToJson(this);
}

/// Voice assignment for one speaker in a multi-speaker response.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class SpeakerVoiceConfig {
  final String? speaker;
  final VoiceConfig? voiceConfig;

  SpeakerVoiceConfig({this.speaker, this.voiceConfig});

  factory SpeakerVoiceConfig.fromJson(Map<String, dynamic> json) =>
      _$SpeakerVoiceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SpeakerVoiceConfigToJson(this);
}

/// Speech settings for two-speaker text-to-speech output.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class MultiSpeakerVoiceConfig {
  final List<SpeakerVoiceConfig>? speakerVoiceConfigs;

  MultiSpeakerVoiceConfig({this.speakerVoiceConfigs});

  factory MultiSpeakerVoiceConfig.fromJson(Map<String, dynamic> json) =>
      _$MultiSpeakerVoiceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$MultiSpeakerVoiceConfigToJson(this);
}

/// Speech generation settings for audio responses.
@JsonSerializable(includeIfNull: false, explicitToJson: true, fieldRename: FieldRename.snake)
class SpeechConfig {
  final VoiceConfig? voiceConfig;
  final String? languageCode;
  final MultiSpeakerVoiceConfig? multiSpeakerVoiceConfig;

  /// Optional. Direct voice identifier or name shortcut.
  final String? voice;

  SpeechConfig({
    this.voiceConfig,
    this.languageCode,
    this.multiSpeakerVoiceConfig,
    this.voice,
  });

  /// Convenience constructor for single-voice configuration with a given voice name, custom voice ID, or [GeminiLiveVoice].
  factory SpeechConfig.fromVoice(Object voiceNameOrId, {String? languageCode}) {
    final name = voiceNameOrId is GeminiLiveVoice
        ? voiceNameOrId.voiceName
        : voiceNameOrId.toString();
    return SpeechConfig(
      voiceConfig: VoiceConfig.fromVoiceName(name),
      voice: name,
      languageCode: languageCode,
    );
  }

  /// Convenience constructor for single-voice configuration using a [GeminiLiveVoice] enum.
  factory SpeechConfig.fromLiveVoice(GeminiLiveVoice voice, {String? languageCode}) =>
      SpeechConfig.fromVoice(voice.voiceName, languageCode: languageCode);

  /// Returns the corresponding [GeminiLiveVoice] enum if matched with a prebuilt voice.
  GeminiLiveVoice? get liveVoice =>
      GeminiLiveVoice.fromName(voice ?? voiceConfig?.prebuiltVoiceConfig?.voiceName);

  factory SpeechConfig.fromJson(Map<String, dynamic> json) =>
      _$SpeechConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SpeechConfigToJson(this);
}
