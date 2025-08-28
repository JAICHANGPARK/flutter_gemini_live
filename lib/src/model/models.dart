// lib/src/models.dart
import 'package:json_annotation/json_annotation.dart';

import 'google_models.dart';

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
  final FunctionCall? functionCall;
  final FunctionResponse? functionResponse;

  factory Part.fromJson(Map<String, dynamic> json) => _$PartFromJson(json);

  Part({this.text, this.inlineData, this.functionCall, this.functionResponse});

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
  final RealtimeInputConfig? realtimeInputConfig;
  final SessionResumptionConfig? sessionResumption;
  final ContextWindowCompressionConfig? contextWindowCompression;
  final AudioTranscriptionConfig? inputAudioTranscription;
  final AudioTranscriptionConfig? outputAudioTranscription;
  final ProactivityConfig? proactivity;

  LiveClientSetup({
    required this.model,
    this.generationConfig,
    this.systemInstruction,
    this.tools,
    this.contextWindowCompression,
    this.inputAudioTranscription,
    this.outputAudioTranscription,
    this.proactivity,
    this.realtimeInputConfig,
    this.sessionResumption,
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

  /// Indicates that the audio stream has ended, e.g. because the microphone was
  /// turned off.
  ///
  /// This should only be sent when automatic activity detection is enabled
  /// (which is the default).
  ///
  /// The client can reopen the stream by sending an audio message.
  final bool? audioStreamEnd;

  /// Marks the start of user activity.
  final ActivityStart? activityStart;

  /// Marks the end of user activity.
  final ActivityEnd? activityEnd;

  LiveClientRealtimeInput({
    this.audio,
    this.video,
    this.audioStreamEnd,
    this.activityEnd,
    this.activityStart,
  });

  factory LiveClientRealtimeInput.fromJson(Map<String, dynamic> json) =>
      _$LiveClientRealtimeInputFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientRealtimeInputToJson(this);
}

@JsonSerializable(includeIfNull: false)
class LiveClientMessage {
  final LiveClientSetup? setup;
  final LiveClientContent? clientContent;
  final LiveClientRealtimeInput? realtimeInput;
  final LiveClientToolResponse? toolResponse;

  LiveClientMessage({
    this.setup,
    this.clientContent,
    this.realtimeInput,
    this.toolResponse,
  });

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
  // fieldRename: FieldRename.snake,
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
  final ToolCall? toolCall;

  /// Notification for the client that a previously issued `ToolCallMessage`
  /// with the specified `id`s should have been not executed and should be cancelled.
  final LiveServerToolCallCancellation? toolCallCancellation;

  /// Server will disconnect soon.
  final LiveServerGoAway? goAway;

  /// Update of the session resumption state.
  final LiveServerSessionResumptionUpdate? sessionResumptionUpdate;

  LiveServerMessage({
    this.setupComplete,
    this.serverContent,
    this.usageMetadata,
    this.toolCall,
    this.goAway,
    this.sessionResumptionUpdate,
    this.toolCallCancellation,
  });

  factory LiveServerMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveServerMessageFromJson(json);

  String? get text {
    return serverContent?.modelTurn?.parts
        ?.map((p) => p.text)
        .where((t) => t != null)
        .join('');
  }

  List<FunctionCall> get functionCalls {
    List<FunctionCall> result =
        serverContent?.modelTurn?.parts
            ?.where((part) => part.functionCall != null)
            .map((part) => part.functionCall!)
            .toList() ??
        [];

    result.addAll(toolCall?.functionCalls ?? []);

    return result;
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

@JsonSerializable(includeIfNull: false)
class Tool {
  final List<FunctionDeclaration> functionDeclarations;

  Tool({this.functionDeclarations = const []});

  factory Tool.fromJson(Map<String, dynamic> json) => _$ToolFromJson(json);

  Map<String, dynamic> toJson() => _$ToolToJson(this);
}

@JsonSerializable(includeIfNull: false)
class ToolCall {
  final List<FunctionCall> functionCalls;

  ToolCall({this.functionCalls = const []});

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallToJson(this);
}
