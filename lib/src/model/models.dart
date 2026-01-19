// lib/src/models.dart
import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

// Enums
enum HarmCategory {
  HARM_CATEGORY_UNSPECIFIED,
  HARM_CATEGORY_HATE_SPEECH,
  HARM_CATEGORY_DANGEROUS_CONTENT,
  HARM_CATEGORY_HARASSMENT,
  HARM_CATEGORY_SEXUALLY_EXPLICIT,
}

@JsonEnum(alwaysCreate: true)
enum Modality {
  @JsonValue('TEXT')
  TEXT,
  @JsonValue('IMAGE')
  IMAGE,
  @JsonValue('AUDIO')
  AUDIO,
}

// Data Classes
@JsonSerializable(
  includeIfNull: false,
  // fieldRename: FieldRename.snake
)
class Part {
  final String? text;
  final Blob? inlineData;

  Part({this.text, this.inlineData});

  factory Part.fromJson(Map<String, dynamic> json) => _$PartFromJson(json);

  Map<String, dynamic> toJson() => _$PartToJson(this);
}

@JsonSerializable(includeIfNull: false)
class Blob {
  final String mimeType;
  final String data; // Base64 encoded string

  Blob({required this.mimeType, required this.data});

  factory Blob.fromJson(Map<String, dynamic> json) => _$BlobFromJson(json);

  Map<String, dynamic> toJson() => _$BlobToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Content {
  final List<Part>? parts;
  final String? role;

  Content({this.parts, this.role});

  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json);

  Map<String, dynamic> toJson() => _$ContentToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class GenerationConfig {
  final double? temperature;
  final int? topK;
  final double? topP;
  final int? maxOutputTokens;
  final List<Modality>? responseModalities;

  GenerationConfig({
    this.temperature,
    this.topK,
    this.topP,
    this.maxOutputTokens,
    this.responseModalities,
  });

  factory GenerationConfig.fromJson(Map<String, dynamic> json) =>
      _$GenerationConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationConfigToJson(this);
}

// --- Live API Specific Models ---

// Client -> Server
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LiveClientSetup {
  final String model;
  final GenerationConfig? generationConfig;
  final Content? systemInstruction;
  final List<Tool>? tools;

  /// Enable transcription of user audio input
  final AudioTranscriptionConfig? inputAudioTranscription;

  /// Enable transcription of model audio output
  final AudioTranscriptionConfig? outputAudioTranscription;

  LiveClientSetup({
    required this.model,
    this.generationConfig,
    this.systemInstruction,
    this.tools,
    this.inputAudioTranscription,
    this.outputAudioTranscription,
  });

  factory LiveClientSetup.fromJson(Map<String, dynamic> json) =>
      _$LiveClientSetupFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientSetupToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LiveClientContent {
  final List<Content>? turns;
  final bool? turnComplete;

  LiveClientContent({this.turns, this.turnComplete});

  factory LiveClientContent.fromJson(Map<String, dynamic> json) =>
      _$LiveClientContentFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientContentToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LiveClientRealtimeInput {
  final Blob? audio;
  final Blob? video; // *** 추가: 비디오/이미지 프레임용 필드 ***

  LiveClientRealtimeInput({this.audio, this.video});

  factory LiveClientRealtimeInput.fromJson(Map<String, dynamic> json) =>
      _$LiveClientRealtimeInputFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientRealtimeInputToJson(this);
}

@JsonSerializable(includeIfNull: false)
class LiveClientMessage {
  final LiveClientSetup? setup;
  final LiveClientContent? clientContent;
  final LiveClientRealtimeInput? realtimeInput;

  LiveClientMessage({this.setup, this.clientContent, this.realtimeInput});

  factory LiveClientMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveClientMessageFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientMessageToJson(this);
}

// Server -> Client
@JsonSerializable(
  includeIfNull: false,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class LiveServerSetupComplete {
  LiveServerSetupComplete();

  factory LiveServerSetupComplete.fromJson(Map<String, dynamic> json) =>
      _$LiveServerSetupCompleteFromJson(json);
}

@JsonSerializable(
  includeIfNull: false,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class Transcription {
  final String? text;
  final bool? finished;

  Transcription({this.text, this.finished});

  factory Transcription.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionFromJson(json);
}

@JsonSerializable(
  includeIfNull: false,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class LiveServerContent {
  final Content? modelTurn;
  final bool? turnComplete;
  final Transcription? inputTranscription;
  final Transcription? outputTranscription;
  final bool? generationComplete;

  LiveServerContent({
    this.modelTurn,
    this.turnComplete,
    this.inputTranscription,
    this.outputTranscription,
    this.generationComplete,
  });

  factory LiveServerContent.fromJson(Map<String, dynamic> json) =>
      _$LiveServerContentFromJson(json);
}

@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerMessage {
  final LiveServerSetupComplete? setupComplete;
  final LiveServerContent? serverContent;
  final UsageMetadata? usageMetadata;

  LiveServerMessage({
    this.setupComplete,
    this.serverContent,
    this.usageMetadata,
  });

  factory LiveServerMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveServerMessageFromJson(json);

  String? get text {
    return serverContent?.modelTurn?.parts
        ?.map((p) => p.text)
        .where((t) => t != null)
        .join('');
  }
}

@JsonSerializable(
  includeIfNull: false,
  createToJson: false,
  // fieldRename: FieldRename.snake,
)
class UsageMetadata {
  final int promptTokenCount;
  final int responseTokenCount;
  final int totalTokenCount;

  UsageMetadata({
    required this.promptTokenCount,
    required this.responseTokenCount,
    required this.totalTokenCount,
  });

  factory UsageMetadata.fromJson(Map<String, dynamic> json) =>
      _$UsageMetadataFromJson(json);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Tool {
  Tool();

  factory Tool.fromJson(Map<String, dynamic> json) => _$ToolFromJson(json);

  Map<String, dynamic> toJson() => _$ToolToJson(this);
}

/// Configuration for audio transcription.
/// When provided in the setup, enables transcription of audio input/output.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class AudioTranscriptionConfig {
  AudioTranscriptionConfig();

  factory AudioTranscriptionConfig.fromJson(Map<String, dynamic> json) =>
      _$AudioTranscriptionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AudioTranscriptionConfigToJson(this);
}
