// lib/src/models.dart
import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

// ============================================================================
// Enums
// ============================================================================

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

@JsonEnum(alwaysCreate: true)
enum ActivityHandling {
  @JsonValue('ACTIVITY_HANDLING_UNSPECIFIED')
  ACTIVITY_HANDLING_UNSPECIFIED,
  @JsonValue('START_OF_ACTIVITY_INTERRUPTS')
  START_OF_ACTIVITY_INTERRUPTS,
  @JsonValue('START_OF_ACTIVITY_DOES_NOT_INTERRUPT')
  START_OF_ACTIVITY_DOES_NOT_INTERRUPT,
}

@JsonEnum(alwaysCreate: true)
enum TurnCoverage {
  @JsonValue('TURN_COVERAGE_UNSPECIFIED')
  TURN_COVERAGE_UNSPECIFIED,
  @JsonValue('TURN_INCLUDES_ONLY_ACTIVITY')
  TURN_INCLUDES_ONLY_ACTIVITY,
  @JsonValue('TURN_INCLUDES_ALL_INPUT')
  TURN_INCLUDES_ALL_INPUT,
}

@JsonEnum(alwaysCreate: true)
enum StartSensitivity {
  @JsonValue('START_SENSITIVITY_UNSPECIFIED')
  START_SENSITIVITY_UNSPECIFIED,
  @JsonValue('START_SENSITIVITY_LOW')
  START_SENSITIVITY_LOW,
  @JsonValue('START_SENSITIVITY_HIGH')
  START_SENSITIVITY_HIGH,
}

@JsonEnum(alwaysCreate: true)
enum EndSensitivity {
  @JsonValue('END_SENSITIVITY_UNSPECIFIED')
  END_SENSITIVITY_UNSPECIFIED,
  @JsonValue('END_SENSITIVITY_LOW')
  END_SENSITIVITY_LOW,
  @JsonValue('END_SENSITIVITY_HIGH')
  END_SENSITIVITY_HIGH,
}

// ============================================================================
// Data Classes - Base
// ============================================================================

@JsonSerializable(includeIfNull: false)
class Part {
  final String? text;
  final Blob? inlineData;
  final FunctionCall? functionCall;
  final FunctionResponse? functionResponse;

  Part({this.text, this.inlineData, this.functionCall, this.functionResponse});

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

// ============================================================================
// Function Calling Models
// ============================================================================

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionCall {
  final String? id;
  final String? name;
  final Map<String, dynamic>? args;

  FunctionCall({this.id, this.name, this.args});

  factory FunctionCall.fromJson(Map<String, dynamic> json) =>
      _$FunctionCallFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionCallToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionResponse {
  final String? id;
  final String? name;
  final Map<String, dynamic>? response;

  FunctionResponse({this.id, this.name, this.response});

  factory FunctionResponse.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionResponseToJson(this);
}

// ============================================================================
// Live API Setup & Config Models
// ============================================================================

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

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class SessionResumptionConfig {
  final String? handle;
  final bool? transparent;

  SessionResumptionConfig({this.handle, this.transparent});

  factory SessionResumptionConfig.fromJson(Map<String, dynamic> json) =>
      _$SessionResumptionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SessionResumptionConfigToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class SlidingWindow {
  final String? targetTokens;

  SlidingWindow({this.targetTokens});

  factory SlidingWindow.fromJson(Map<String, dynamic> json) =>
      _$SlidingWindowFromJson(json);

  Map<String, dynamic> toJson() => _$SlidingWindowToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ContextWindowCompressionConfig {
  final String? triggerTokens;
  final SlidingWindow? slidingWindow;

  ContextWindowCompressionConfig({this.triggerTokens, this.slidingWindow});

  factory ContextWindowCompressionConfig.fromJson(Map<String, dynamic> json) =>
      _$ContextWindowCompressionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ContextWindowCompressionConfigToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class AudioTranscriptionConfig {
  AudioTranscriptionConfig();

  factory AudioTranscriptionConfig.fromJson(Map<String, dynamic> json) =>
      _$AudioTranscriptionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AudioTranscriptionConfigToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ProactivityConfig {
  final bool? proactiveAudio;

  ProactivityConfig({this.proactiveAudio});

  factory ProactivityConfig.fromJson(Map<String, dynamic> json) =>
      _$ProactivityConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ProactivityConfigToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Tool {
  Tool();

  factory Tool.fromJson(Map<String, dynamic> json) => _$ToolFromJson(json);

  Map<String, dynamic> toJson() => _$ToolToJson(this);
}

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
  });

  factory LiveClientSetup.fromJson(Map<String, dynamic> json) =>
      _$LiveClientSetupFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientSetupToJson(this);
}

// ============================================================================
// Live API Client Content Models
// ============================================================================

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
class ActivityStart {
  ActivityStart();

  factory ActivityStart.fromJson(Map<String, dynamic> json) =>
      _$ActivityStartFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityStartToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ActivityEnd {
  ActivityEnd();

  factory ActivityEnd.fromJson(Map<String, dynamic> json) =>
      _$ActivityEndFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityEndToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LiveClientRealtimeInput {
  final List<Blob>? mediaChunks;
  final Blob? audio;
  final Blob? video;
  final bool? audioStreamEnd;
  final String? text;
  final ActivityStart? activityStart;
  final ActivityEnd? activityEnd;

  LiveClientRealtimeInput({
    this.mediaChunks,
    this.audio,
    this.video,
    this.audioStreamEnd,
    this.text,
    this.activityStart,
    this.activityEnd,
  });

  factory LiveClientRealtimeInput.fromJson(Map<String, dynamic> json) =>
      _$LiveClientRealtimeInputFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientRealtimeInputToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LiveClientToolResponse {
  final List<FunctionResponse>? functionResponses;

  LiveClientToolResponse({this.functionResponses});

  factory LiveClientToolResponse.fromJson(Map<String, dynamic> json) =>
      _$LiveClientToolResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientToolResponseToJson(this);
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

// ============================================================================
// Live API Server Response Models
// ============================================================================

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

@JsonSerializable(includeIfNull: false, createToJson: false)
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

@JsonSerializable(
  includeIfNull: false,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class LiveServerToolCall {
  final List<FunctionCall>? functionCalls;

  LiveServerToolCall({this.functionCalls});

  factory LiveServerToolCall.fromJson(Map<String, dynamic> json) =>
      _$LiveServerToolCallFromJson(json);
}

@JsonSerializable(
  includeIfNull: false,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class LiveServerToolCallCancellation {
  final List<String>? ids;

  LiveServerToolCallCancellation({this.ids});

  factory LiveServerToolCallCancellation.fromJson(Map<String, dynamic> json) =>
      _$LiveServerToolCallCancellationFromJson(json);
}

@JsonSerializable(
  includeIfNull: false,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class LiveServerGoAway {
  final String? reason;
  final int? timeRemaining;

  LiveServerGoAway({this.reason, this.timeRemaining});

  factory LiveServerGoAway.fromJson(Map<String, dynamic> json) =>
      _$LiveServerGoAwayFromJson(json);
}

@JsonSerializable(
  includeIfNull: false,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class LiveServerSessionResumptionUpdate {
  final String? newHandle;
  final String? resumable;
  final int? lastConsumedClientMessageIndex;

  LiveServerSessionResumptionUpdate({
    this.newHandle,
    this.resumable,
    this.lastConsumedClientMessageIndex,
  });

  factory LiveServerSessionResumptionUpdate.fromJson(
    Map<String, dynamic> json,
  ) => _$LiveServerSessionResumptionUpdateFromJson(json);
}

@JsonSerializable(
  includeIfNull: false,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class VoiceActivityDetectionSignal {
  final bool? start;
  final bool? end;

  VoiceActivityDetectionSignal({this.start, this.end});

  factory VoiceActivityDetectionSignal.fromJson(Map<String, dynamic> json) =>
      _$VoiceActivityDetectionSignalFromJson(json);
}

@JsonSerializable(
  includeIfNull: false,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class VoiceActivity {
  final bool? speechActive;

  VoiceActivity({this.speechActive});

  factory VoiceActivity.fromJson(Map<String, dynamic> json) =>
      _$VoiceActivityFromJson(json);
}

@JsonSerializable(includeIfNull: false, createToJson: false)
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

@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerMessage {
  final LiveServerSetupComplete? setupComplete;
  final LiveServerContent? serverContent;
  final UsageMetadata? usageMetadata;
  final LiveServerToolCall? toolCall;
  final LiveServerToolCallCancellation? toolCallCancellation;
  final LiveServerGoAway? goAway;
  final LiveServerSessionResumptionUpdate? sessionResumptionUpdate;
  final VoiceActivityDetectionSignal? voiceActivityDetectionSignal;
  final VoiceActivity? voiceActivity;

  LiveServerMessage({
    this.setupComplete,
    this.serverContent,
    this.usageMetadata,
    this.toolCall,
    this.toolCallCancellation,
    this.goAway,
    this.sessionResumptionUpdate,
    this.voiceActivityDetectionSignal,
    this.voiceActivity,
  });

  factory LiveServerMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveServerMessageFromJson(json);

  String? get text {
    final textParts = serverContent?.modelTurn?.parts
        ?.map((p) => p.text)
        .where((t) => t != null);
    if (textParts == null || textParts.isEmpty) return null;
    return textParts.join('');
  }

  String? get data {
    final buffer = StringBuffer();
    for (final part in serverContent?.modelTurn?.parts ?? []) {
      if (part.inlineData?.data != null) {
        buffer.write(part.inlineData!.data);
      }
    }
    return buffer.isNotEmpty ? buffer.toString() : null;
  }
}

// ============================================================================
// Send Parameters
// ============================================================================

class LiveSendClientContentParameters {
  final List<Content>? turns;
  final bool turnComplete;

  LiveSendClientContentParameters({this.turns, this.turnComplete = true});
}

class LiveSendRealtimeInputParameters {
  final List<Blob>? mediaChunks;
  final Blob? audio;
  final Blob? video;
  final String? text;
  final bool? audioStreamEnd;
  final bool? activityStart;
  final bool? activityEnd;

  LiveSendRealtimeInputParameters({
    this.mediaChunks,
    this.audio,
    this.video,
    this.text,
    this.audioStreamEnd,
    this.activityStart,
    this.activityEnd,
  });
}

class LiveSendToolResponseParameters {
  final List<FunctionResponse> functionResponses;

  LiveSendToolResponseParameters({required this.functionResponses});
}
