// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Live Music Models (Lyria Realtime)
// ============================================================================

/// Maps a prompt to a relative weight to steer music generation.
@JsonSerializable(includeIfNull: false)
class WeightedPrompt {
  /// Text prompt describing musical styles, instruments, mood, etc.
  final String? text;

  /// Relative weight of the prompt. Weights will be normalized by the server.
  final double? weight;

  const WeightedPrompt({this.text, this.weight});

  factory WeightedPrompt.fromJson(Map<String, dynamic> json) =>
      _$WeightedPromptFromJson(json);

  Map<String, dynamic> toJson() => _$WeightedPromptToJson(this);
}

/// Configuration options for realtime music generation.
@JsonSerializable(includeIfNull: false)
class LiveMusicGenerationConfig {
  /// Controls variance in audio generation from 0.0 to 3.0. Higher values produce higher variance.
  final double? temperature;

  /// Top-K sampling parameter from 1 to 1000.
  final int? topK;

  /// Random seed for reproducible generation.
  final int? seed;

  /// Controls prompt adherence from 0.0 to 6.0. Higher guidance follows more closely.
  final double? guidance;

  /// Beats per minute between 60 and 200.
  final int? bpm;

  /// Density of sounds from 0.0 to 1.0.
  final double? density;

  /// Brightness of the music from 0.0 to 1.0.
  final double? brightness;

  /// Musical scale of the generated music.
  final Scale? scale;

  /// Whether output should mute bass.
  final bool? muteBass;

  /// Whether output should mute drums.
  final bool? muteDrums;

  /// Whether output should contain only bass and drums.
  final bool? onlyBassAndDrums;

  /// Generation mode (QUALITY, DIVERSITY, VOCALIZATION).
  final MusicGenerationMode? musicGenerationMode;

  LiveMusicGenerationConfig({
    this.temperature,
    this.topK,
    this.seed,
    this.guidance,
    this.bpm,
    this.density,
    this.brightness,
    this.scale,
    this.muteBass,
    this.muteDrums,
    this.onlyBassAndDrums,
    this.musicGenerationMode,
  });

  factory LiveMusicGenerationConfig.fromJson(Map<String, dynamic> json) =>
      _$LiveMusicGenerationConfigFromJson(json);

  Map<String, dynamic> toJson() => _$LiveMusicGenerationConfigToJson(this);
}

/// Setup message sent on initial connection to the music stream.
@JsonSerializable(includeIfNull: false)
class LiveMusicClientSetup {
  /// The model resource name, e.g. `models/lyria-realtime-exp`.
  final String? model;

  LiveMusicClientSetup({this.model});

  factory LiveMusicClientSetup.fromJson(Map<String, dynamic> json) =>
      _$LiveMusicClientSetupFromJson(json);

  Map<String, dynamic> toJson() => _$LiveMusicClientSetupToJson(this);
}

/// User input to steer the music stream.
@JsonSerializable(includeIfNull: false)
class LiveMusicClientContent {
  /// Weighted prompts used to guide music generation.
  final List<WeightedPrompt>? weightedPrompts;

  LiveMusicClientContent({this.weightedPrompts});

  factory LiveMusicClientContent.fromJson(Map<String, dynamic> json) =>
      _$LiveMusicClientContentFromJson(json);

  Map<String, dynamic> toJson() => _$LiveMusicClientContentToJson(this);
}

/// Parameters for setting weighted prompts on an active [LiveMusicSession].
///
/// Mirrors `LiveMusicSetWeightedPromptsParameters` in the upstream SDKs.
class LiveMusicSetWeightedPromptsParameters {
  /// Weighted prompts to send to the model; weights are normalized to sum to 1.0.
  final List<WeightedPrompt> weightedPrompts;

  /// Creates [LiveMusicSetWeightedPromptsParameters] with [weightedPrompts].
  LiveMusicSetWeightedPromptsParameters({required this.weightedPrompts});

  /// Creates [LiveMusicSetWeightedPromptsParameters] from a JSON map.
  factory LiveMusicSetWeightedPromptsParameters.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw =
        (json['weightedPrompts'] ?? json['weighted_prompts']) as List<dynamic>?;
    return LiveMusicSetWeightedPromptsParameters(
      weightedPrompts: raw
              ?.map(
                (e) => e is WeightedPrompt
                    ? e
                    : WeightedPrompt.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <WeightedPrompt>[],
    );
  }

  /// Converts these parameters to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'weightedPrompts': weightedPrompts.map((e) => e.toJson()).toList(),
      };
}

/// Parameters for updating the music generation configuration on an active
/// [LiveMusicSession].
///
/// Mirrors `LiveMusicSetConfigParameters` in the upstream SDKs.
class LiveMusicSetConfigParameters {
  /// Music generation configuration to apply. Passing `null` or an empty config
  /// resets the configuration to server defaults.
  final LiveMusicGenerationConfig? musicGenerationConfig;

  /// Creates [LiveMusicSetConfigParameters] with [musicGenerationConfig].
  LiveMusicSetConfigParameters({this.musicGenerationConfig});

  /// Creates [LiveMusicSetConfigParameters] from a JSON map.
  factory LiveMusicSetConfigParameters.fromJson(Map<String, dynamic> json) {
    final raw = json['musicGenerationConfig'] ?? json['music_generation_config'];
    return LiveMusicSetConfigParameters(
      musicGenerationConfig: raw == null
          ? null
          : (raw is LiveMusicGenerationConfig
                ? raw
                : LiveMusicGenerationConfig.fromJson(
                    raw as Map<String, dynamic>,
                  )),
    );
  }

  /// Converts these parameters to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        if (musicGenerationConfig != null)
          'musicGenerationConfig': musicGenerationConfig!.toJson(),
      };
}

/// Messages sent from the client over the Live Music WebSocket.
@JsonSerializable(includeIfNull: false)
class LiveMusicClientMessage {
  final LiveMusicClientSetup? setup;
  final LiveMusicClientContent? clientContent;
  final LiveMusicGenerationConfig? musicGenerationConfig;
  final LiveMusicPlaybackControl? playbackControl;

  LiveMusicClientMessage({
    this.setup,
    this.clientContent,
    this.musicGenerationConfig,
    this.playbackControl,
  });

  factory LiveMusicClientMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveMusicClientMessageFromJson(json);

  Map<String, dynamic> toJson() => _$LiveMusicClientMessageToJson(this);
}

/// Confirmation message sent from the server once setup is complete.
@JsonSerializable(includeIfNull: false)
class LiveMusicServerSetupComplete {
  const LiveMusicServerSetupComplete();

  factory LiveMusicServerSetupComplete.fromJson(Map<String, dynamic> json) =>
      _$LiveMusicServerSetupCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$LiveMusicServerSetupCompleteToJson(this);
}

/// Prompts and configuration used to generate an audio chunk.
@JsonSerializable(includeIfNull: false)
class LiveMusicSourceMetadata {
  final LiveMusicClientContent? clientContent;
  final LiveMusicGenerationConfig? musicGenerationConfig;

  LiveMusicSourceMetadata({this.clientContent, this.musicGenerationConfig});

  factory LiveMusicSourceMetadata.fromJson(Map<String, dynamic> json) =>
      _$LiveMusicSourceMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$LiveMusicSourceMetadataToJson(this);
}

/// A chunk of generated audio from the music model.
@JsonSerializable(includeIfNull: false)
class AudioChunk {
  /// Base64-encoded raw audio bytes.
  final String? data;

  /// MIME type of the audio chunk.
  final String? mimeType;

  /// Metadata about prompts and config used to generate this chunk.
  final LiveMusicSourceMetadata? sourceMetadata;

  AudioChunk({this.data, this.mimeType, this.sourceMetadata});

  /// Decoded raw audio bytes, or null if [data] is null.
  Uint8List? get bytes => data != null ? base64Decode(data!) : null;

  factory AudioChunk.fromJson(Map<String, dynamic> json) =>
      _$AudioChunkFromJson(json);

  Map<String, dynamic> toJson() => _$AudioChunkToJson(this);
}

/// Server content payload containing generated audio chunks.
@JsonSerializable(includeIfNull: false)
class LiveMusicServerContent {
  final List<AudioChunk>? audioChunks;

  LiveMusicServerContent({this.audioChunks});

  factory LiveMusicServerContent.fromJson(Map<String, dynamic> json) =>
      _$LiveMusicServerContentFromJson(json);

  Map<String, dynamic> toJson() => _$LiveMusicServerContentToJson(this);
}

/// Information about a prompt filtered by safety filters.
@JsonSerializable(includeIfNull: false)
class LiveMusicFilteredPrompt {
  final String? text;
  final String? filteredReason;

  LiveMusicFilteredPrompt({this.text, this.filteredReason});

  factory LiveMusicFilteredPrompt.fromJson(Map<String, dynamic> json) =>
      _$LiveMusicFilteredPromptFromJson(json);

  Map<String, dynamic> toJson() => _$LiveMusicFilteredPromptToJson(this);
}

/// Response message received from the Live Music WebSocket server.
@JsonSerializable(includeIfNull: false)
class LiveMusicServerMessage {
  final LiveMusicServerSetupComplete? setupComplete;
  final LiveMusicServerContent? serverContent;
  final LiveMusicFilteredPrompt? filteredPrompt;

  LiveMusicServerMessage({
    this.setupComplete,
    this.serverContent,
    this.filteredPrompt,
  });

  /// Returns the first audio chunk in [serverContent], if present.
  AudioChunk? get audioChunk {
    final chunks = serverContent?.audioChunks;
    if (chunks != null && chunks.isNotEmpty) {
      return chunks.first;
    }
    return null;
  }

  /// Returns raw audio bytes of the first audio chunk, if present.
  Uint8List? get audioBytes => audioChunk?.bytes;

  factory LiveMusicServerMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveMusicServerMessageFromJson(json);

  Map<String, dynamic> toJson() => _$LiveMusicServerMessageToJson(this);
}
