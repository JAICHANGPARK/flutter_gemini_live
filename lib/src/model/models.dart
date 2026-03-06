// ignore_for_file: constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

// ============================================================================
// Enums
// ============================================================================

/// Harm categories reported by Gemini safety metadata.
enum HarmCategory {
  HARM_CATEGORY_UNSPECIFIED,
  HARM_CATEGORY_HATE_SPEECH,
  HARM_CATEGORY_DANGEROUS_CONTENT,
  HARM_CATEGORY_HARASSMENT,
  HARM_CATEGORY_SEXUALLY_EXPLICIT,
}

/// Modalities that a request or response can contain.
@JsonEnum(alwaysCreate: true)
enum Modality {
  @JsonValue('TEXT')
  TEXT,
  @JsonValue('IMAGE')
  IMAGE,
  @JsonValue('AUDIO')
  AUDIO,
}

/// Media resolution presets for multimodal responses.
@JsonEnum(alwaysCreate: true)
enum MediaResolution {
  @JsonValue('MEDIA_RESOLUTION_UNSPECIFIED')
  MEDIA_RESOLUTION_UNSPECIFIED,
  @JsonValue('MEDIA_RESOLUTION_LOW')
  MEDIA_RESOLUTION_LOW,
  @JsonValue('MEDIA_RESOLUTION_MEDIUM')
  MEDIA_RESOLUTION_MEDIUM,
  @JsonValue('MEDIA_RESOLUTION_HIGH')
  MEDIA_RESOLUTION_HIGH,
}

/// How detected user activity affects model generation.
@JsonEnum(alwaysCreate: true)
enum ActivityHandling {
  @JsonValue('ACTIVITY_HANDLING_UNSPECIFIED')
  ACTIVITY_HANDLING_UNSPECIFIED,
  @JsonValue('START_OF_ACTIVITY_INTERRUPTS')
  START_OF_ACTIVITY_INTERRUPTS,
  @JsonValue('NO_INTERRUPTION')
  NO_INTERRUPTION,
  @JsonValue('NO_INTERRUPTION')
  START_OF_ACTIVITY_DOES_NOT_INTERRUPT,
}

/// How much of the user turn is forwarded to the model.
@JsonEnum(alwaysCreate: true)
enum TurnCoverage {
  @JsonValue('TURN_COVERAGE_UNSPECIFIED')
  TURN_COVERAGE_UNSPECIFIED,
  @JsonValue('TURN_INCLUDES_ONLY_ACTIVITY')
  TURN_INCLUDES_ONLY_ACTIVITY,
  @JsonValue('TURN_INCLUDES_ALL_INPUT')
  TURN_INCLUDES_ALL_INPUT,
}

/// Sensitivity levels for detecting the start of speech.
@JsonEnum(alwaysCreate: true)
enum StartSensitivity {
  @JsonValue('START_SENSITIVITY_UNSPECIFIED')
  START_SENSITIVITY_UNSPECIFIED,
  @JsonValue('START_SENSITIVITY_LOW')
  START_SENSITIVITY_LOW,
  @JsonValue('START_SENSITIVITY_HIGH')
  START_SENSITIVITY_HIGH,
}

/// Sensitivity levels for detecting the end of speech.
@JsonEnum(alwaysCreate: true)
enum EndSensitivity {
  @JsonValue('END_SENSITIVITY_UNSPECIFIED')
  END_SENSITIVITY_UNSPECIFIED,
  @JsonValue('END_SENSITIVITY_LOW')
  END_SENSITIVITY_LOW,
  @JsonValue('END_SENSITIVITY_HIGH')
  END_SENSITIVITY_HIGH,
}

/// Scheduling strategies for tool responses.
@JsonEnum(alwaysCreate: true)
enum FunctionResponseScheduling {
  @JsonValue('SCHEDULING_UNSPECIFIED')
  SCHEDULING_UNSPECIFIED,
  @JsonValue('SILENT')
  SILENT,
  @JsonValue('WHEN_IDLE')
  WHEN_IDLE,
  @JsonValue('INTERRUPT')
  INTERRUPT,
}

/// Execution modes for server-side behaviors such as function calling.
@JsonEnum(alwaysCreate: true)
enum Behavior {
  @JsonValue('UNSPECIFIED')
  UNSPECIFIED,
  @JsonValue('BLOCKING')
  BLOCKING,
  @JsonValue('NON_BLOCKING')
  NON_BLOCKING,
}

/// Reasons a model turn completed without a final response.
@JsonEnum(alwaysCreate: true)
enum TurnCompleteReason {
  @JsonValue('TURN_COMPLETE_REASON_UNSPECIFIED')
  TURN_COMPLETE_REASON_UNSPECIFIED,
  @JsonValue('MALFORMED_FUNCTION_CALL')
  MALFORMED_FUNCTION_CALL,
  @JsonValue('RESPONSE_REJECTED')
  RESPONSE_REJECTED,
  @JsonValue('NEED_MORE_INPUT')
  NEED_MORE_INPUT,
}

/// Voice activity detection signals emitted by the server.
@JsonEnum(alwaysCreate: true)
enum VadSignalType {
  @JsonValue('VAD_SIGNAL_TYPE_UNSPECIFIED')
  VAD_SIGNAL_TYPE_UNSPECIFIED,
  @JsonValue('VAD_SIGNAL_TYPE_SOS')
  VAD_SIGNAL_TYPE_SOS,
  @JsonValue('VAD_SIGNAL_TYPE_EOS')
  VAD_SIGNAL_TYPE_EOS,
}

/// Voice activity events detected for an audio stream.
@JsonEnum(alwaysCreate: true)
enum VoiceActivityType {
  @JsonValue('TYPE_UNSPECIFIED')
  TYPE_UNSPECIFIED,
  @JsonValue('ACTIVITY_START')
  ACTIVITY_START,
  @JsonValue('ACTIVITY_END')
  ACTIVITY_END,
}

/// Traffic classes used for usage accounting.
@JsonEnum(alwaysCreate: true)
enum TrafficType {
  @JsonValue('TRAFFIC_TYPE_UNSPECIFIED')
  TRAFFIC_TYPE_UNSPECIFIED,
  @JsonValue('ON_DEMAND')
  ON_DEMAND,
  @JsonValue('PROVISIONED_THROUGHPUT')
  PROVISIONED_THROUGHPUT,
}

/// Media kinds used in token accounting details.
@JsonEnum(alwaysCreate: true)
enum MediaModality {
  @JsonValue('MODALITY_UNSPECIFIED')
  MODALITY_UNSPECIFIED,
  @JsonValue('TEXT')
  TEXT,
  @JsonValue('IMAGE')
  IMAGE,
  @JsonValue('VIDEO')
  VIDEO,
  @JsonValue('AUDIO')
  AUDIO,
  @JsonValue('DOCUMENT')
  DOCUMENT,
}

// ============================================================================
// Data Classes - Base
// ============================================================================

/// A single multimodal part within a content turn.
@JsonSerializable(includeIfNull: false)
class Part {
  final String? text;
  final bool? thought;
  final Blob? inlineData;
  final FunctionCall? functionCall;
  final FunctionResponse? functionResponse;
  final ExecutableCode? executableCode;
  final CodeExecutionResult? codeExecutionResult;

  Part({
    this.text,
    this.thought,
    this.inlineData,
    this.functionCall,
    this.functionResponse,
    this.executableCode,
    this.codeExecutionResult,
  });

  factory Part.fromJson(Map<String, dynamic> json) => _$PartFromJson(json);

  Map<String, dynamic> toJson() => _$PartToJson(this);
}

/// Inline binary data encoded for API transport.
@JsonSerializable(includeIfNull: false)
class Blob {
  final String mimeType;
  final String data;

  Blob({required this.mimeType, required this.data});

  factory Blob.fromJson(Map<String, dynamic> json) => _$BlobFromJson(json);

  Map<String, dynamic> toJson() => _$BlobToJson(this);
}

/// A conversational turn made of one or more [Part] values.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Content {
  final List<Part>? parts;
  final String? role;

  Content({this.parts, this.role});

  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json);

  Map<String, dynamic> toJson() => _$ContentToJson(this);
}

/// A prebuilt voice selection for synthesized audio output.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class PrebuiltVoiceConfig {
  final String? voiceName;

  PrebuiltVoiceConfig({this.voiceName});

  factory PrebuiltVoiceConfig.fromJson(Map<String, dynamic> json) =>
      _$PrebuiltVoiceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PrebuiltVoiceConfigToJson(this);
}

/// Voice settings applied to spoken responses.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class VoiceConfig {
  final PrebuiltVoiceConfig? prebuiltVoiceConfig;

  VoiceConfig({this.prebuiltVoiceConfig});

  factory VoiceConfig.fromJson(Map<String, dynamic> json) =>
      _$VoiceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceConfigToJson(this);
}

/// Speech generation settings for audio responses.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class SpeechConfig {
  final VoiceConfig? voiceConfig;
  final String? languageCode;

  SpeechConfig({this.voiceConfig, this.languageCode});

  factory SpeechConfig.fromJson(Map<String, dynamic> json) =>
      _$SpeechConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SpeechConfigToJson(this);
}

/// Thinking controls for models that can emit thought content.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ThinkingConfig {
  final bool? includeThoughts;
  final int? thinkingBudget;

  ThinkingConfig({this.includeThoughts, this.thinkingBudget});

  factory ThinkingConfig.fromJson(Map<String, dynamic> json) =>
      _$ThinkingConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ThinkingConfigToJson(this);
}

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
  });

  factory GenerationConfig.fromJson(Map<String, dynamic> json) =>
      _$GenerationConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationConfigToJson(this);
}

// ============================================================================
// Function Calling Models
// ============================================================================

/// A tool invocation requested by the model.
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

/// Inline binary data returned from a function response.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionResponseBlob {
  final String? mimeType;
  final String? data;

  FunctionResponseBlob({this.mimeType, this.data});

  factory FunctionResponseBlob.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseBlobFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionResponseBlobToJson(this);
}

/// File metadata returned from a function response.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionResponseFileData {
  final String? fileUri;
  final String? mimeType;

  FunctionResponseFileData({this.fileUri, this.mimeType});

  factory FunctionResponseFileData.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseFileDataFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionResponseFileDataToJson(this);
}

/// A single payload part inside a function response.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionResponsePart {
  final FunctionResponseBlob? inlineData;
  final FunctionResponseFileData? fileData;

  FunctionResponsePart({this.inlineData, this.fileData});

  factory FunctionResponsePart.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponsePartFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionResponsePartToJson(this);
}

/// A tool result sent back to the model.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionResponse {
  final String? id;
  final String? name;
  final Map<String, dynamic>? response;
  final bool? willContinue;
  final FunctionResponseScheduling? scheduling;
  final List<FunctionResponsePart>? parts;

  FunctionResponse({
    this.id,
    this.name,
    this.response,
    this.willContinue,
    this.scheduling,
    this.parts,
  });

  factory FunctionResponse.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionResponseToJson(this);
}

/// A function schema exposed to the model as a callable tool.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class FunctionDeclaration {
  final String? description;
  final String? name;
  final Map<String, dynamic>? parameters;
  final dynamic parametersJsonSchema;
  final Map<String, dynamic>? response;
  final dynamic responseJsonSchema;
  final Behavior? behavior;

  FunctionDeclaration({
    this.description,
    this.name,
    this.parameters,
    this.parametersJsonSchema,
    this.response,
    this.responseJsonSchema,
    this.behavior,
  });

  factory FunctionDeclaration.fromJson(Map<String, dynamic> json) =>
      _$FunctionDeclarationFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionDeclarationToJson(this);
}

/// A time interval used by search filters.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Interval {
  final DateTime? startTime;
  final DateTime? endTime;

  Interval({this.startTime, this.endTime});

  factory Interval.fromJson(Map<String, dynamic> json) =>
      _$IntervalFromJson(json);

  Map<String, dynamic> toJson() => _$IntervalToJson(this);
}

/// Google Search tool configuration.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class GoogleSearch {
  final List<String>? excludeDomains;
  final Interval? timeRangeFilter;
  final String? blockingConfidence;

  GoogleSearch({
    this.excludeDomains,
    this.timeRangeFilter,
    this.blockingConfidence,
  });

  factory GoogleSearch.fromJson(Map<String, dynamic> json) =>
      _$GoogleSearchFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleSearchToJson(this);
}

/// Dynamic retrieval thresholds for grounded search.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class DynamicRetrievalConfig {
  final double? dynamicThreshold;
  final String? mode;

  DynamicRetrievalConfig({this.dynamicThreshold, this.mode});

  factory DynamicRetrievalConfig.fromJson(Map<String, dynamic> json) =>
      _$DynamicRetrievalConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DynamicRetrievalConfigToJson(this);
}

/// Retrieval settings for the Google Search tool.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class GoogleSearchRetrieval {
  final DynamicRetrievalConfig? dynamicRetrievalConfig;

  GoogleSearchRetrieval({this.dynamicRetrievalConfig});

  factory GoogleSearchRetrieval.fromJson(Map<String, dynamic> json) =>
      _$GoogleSearchRetrievalFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleSearchRetrievalToJson(this);
}

/// A tool bundle that can be attached to a model session.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Tool {
  final List<FunctionDeclaration>? functionDeclarations;
  final GoogleSearch? googleSearch;
  final GoogleSearchRetrieval? googleSearchRetrieval;
  final Map<String, dynamic>? codeExecution;
  final Map<String, dynamic>? urlContext;
  final Map<String, dynamic>? googleMaps;
  final Map<String, dynamic>? retrieval;
  final Map<String, dynamic>? computerUse;
  final Map<String, dynamic>? fileSearch;
  final Map<String, dynamic>? enterpriseWebSearch;
  final List<Map<String, dynamic>>? mcpServers;

  Tool({
    this.functionDeclarations,
    this.googleSearch,
    this.googleSearchRetrieval,
    this.codeExecution,
    this.urlContext,
    this.googleMaps,
    this.retrieval,
    this.computerUse,
    this.fileSearch,
    this.enterpriseWebSearch,
    this.mcpServers,
  });

  factory Tool.fromJson(Map<String, dynamic> json) => _$ToolFromJson(json);

  Map<String, dynamic> toJson() => _$ToolToJson(this);
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

/// Audio transcription settings for input or output streams.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class AudioTranscriptionConfig {
  AudioTranscriptionConfig();

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

/// Client-authored conversation turns sent to the model.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LiveClientContent {
  final List<Content>? turns;
  final bool? turnComplete;

  LiveClientContent({this.turns, this.turnComplete});

  factory LiveClientContent.fromJson(Map<String, dynamic> json) =>
      _$LiveClientContentFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientContentToJson(this);
}

/// A signal that marks the start of explicit user activity.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ActivityStart {
  /// Creates an activity-start marker.
  ActivityStart();

  /// Creates an [ActivityStart] from a JSON payload.
  factory ActivityStart.fromJson(Map<String, dynamic> json) =>
      _$ActivityStartFromJson(json);

  /// Converts this marker to a JSON payload.
  Map<String, dynamic> toJson() => _$ActivityStartToJson(this);
}

/// A signal that marks the end of explicit user activity.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ActivityEnd {
  /// Creates an activity-end marker.
  ActivityEnd();

  /// Creates an [ActivityEnd] from a JSON payload.
  factory ActivityEnd.fromJson(Map<String, dynamic> json) =>
      _$ActivityEndFromJson(json);

  /// Converts this marker to a JSON payload.
  Map<String, dynamic> toJson() => _$ActivityEndToJson(this);
}

/// Realtime media or text input sent while a session is active.
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

/// A batch of tool results returned to the server.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LiveClientToolResponse {
  final List<FunctionResponse>? functionResponses;

  LiveClientToolResponse({this.functionResponses});

  factory LiveClientToolResponse.fromJson(Map<String, dynamic> json) =>
      _$LiveClientToolResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientToolResponseToJson(this);
}

/// A top-level client message sent over the Live API socket.
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

/// Acknowledgement payload returned after session setup completes.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerSetupComplete {
  final String? sessionId;

  LiveServerSetupComplete({this.sessionId});

  factory LiveServerSetupComplete.fromJson(Map<String, dynamic> json) =>
      _$LiveServerSetupCompleteFromJson(json);
}

/// A transcription update for input or output audio.
@JsonSerializable(includeIfNull: false, createToJson: false)
class Transcription {
  final String? text;
  final bool? finished;

  Transcription({this.text, this.finished});

  factory Transcription.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionFromJson(json);
}

/// Executable code emitted by the model.
@JsonSerializable(includeIfNull: false)
class ExecutableCode {
  final String? language;
  final String? code;

  ExecutableCode({this.language, this.code});

  factory ExecutableCode.fromJson(Map<String, dynamic> json) =>
      _$ExecutableCodeFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutableCodeToJson(this);
}

/// The result of model-executed code.
@JsonSerializable(includeIfNull: false)
class CodeExecutionResult {
  final String? outcome;
  final String? output;

  CodeExecutionResult({this.outcome, this.output});

  factory CodeExecutionResult.fromJson(Map<String, dynamic> json) =>
      _$CodeExecutionResultFromJson(json);

  Map<String, dynamic> toJson() => _$CodeExecutionResultToJson(this);
}

/// Server-generated content and turn lifecycle updates.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerContent {
  final Content? modelTurn;
  final bool? turnComplete;
  final bool? interrupted;
  final Map<String, dynamic>? groundingMetadata;
  final Transcription? inputTranscription;
  final Transcription? outputTranscription;
  final bool? generationComplete;
  final Map<String, dynamic>? urlContextMetadata;
  final TurnCompleteReason? turnCompleteReason;
  final bool? waitingForInput;

  LiveServerContent({
    this.modelTurn,
    this.turnComplete,
    this.interrupted,
    this.groundingMetadata,
    this.inputTranscription,
    this.outputTranscription,
    this.generationComplete,
    this.urlContextMetadata,
    this.turnCompleteReason,
    this.waitingForInput,
  });

  factory LiveServerContent.fromJson(Map<String, dynamic> json) =>
      _$LiveServerContentFromJson(json);
}

/// A tool call request emitted by the server.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerToolCall {
  final List<FunctionCall>? functionCalls;

  LiveServerToolCall({this.functionCalls});

  factory LiveServerToolCall.fromJson(Map<String, dynamic> json) =>
      _$LiveServerToolCallFromJson(json);
}

/// A cancellation notice for previously issued tool calls.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerToolCallCancellation {
  final List<String>? ids;

  LiveServerToolCallCancellation({this.ids});

  factory LiveServerToolCallCancellation.fromJson(Map<String, dynamic> json) =>
      _$LiveServerToolCallCancellationFromJson(json);
}

/// A shutdown warning indicating when the session will expire.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerGoAway {
  final String? timeLeft;
  final String? reason;

  LiveServerGoAway({this.timeLeft, this.reason});

  factory LiveServerGoAway.fromJson(Map<String, dynamic> json) =>
      _$LiveServerGoAwayFromJson(json);

  /// The remaining session lifetime in seconds when available.
  int? get timeRemaining {
    if (timeLeft == null) return null;
    final match = RegExp(r'^(\d+)s$').firstMatch(timeLeft!);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }
}

/// A session resumption token update from the server.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerSessionResumptionUpdate {
  final String? newHandle;
  final bool? resumable;
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

/// A low-level VAD signal emitted by the server.
@JsonSerializable(includeIfNull: false, createToJson: false)
class VoiceActivityDetectionSignal {
  final VadSignalType? vadSignalType;

  VoiceActivityDetectionSignal({this.vadSignalType});

  factory VoiceActivityDetectionSignal.fromJson(Map<String, dynamic> json) =>
      _$VoiceActivityDetectionSignalFromJson(json);

  /// Whether this signal marks the start of speech.
  bool get start => vadSignalType == VadSignalType.VAD_SIGNAL_TYPE_SOS;

  /// Whether this signal marks the end of speech.
  bool get end => vadSignalType == VadSignalType.VAD_SIGNAL_TYPE_EOS;
}

/// A higher-level voice activity event emitted by the server.
@JsonSerializable(includeIfNull: false, createToJson: false)
class VoiceActivity {
  final VoiceActivityType? voiceActivityType;

  VoiceActivity({this.voiceActivityType});

  factory VoiceActivity.fromJson(Map<String, dynamic> json) =>
      _$VoiceActivityFromJson(json);

  /// Whether speech is currently considered active.
  bool? get speechActive {
    if (voiceActivityType == VoiceActivityType.ACTIVITY_START) return true;
    if (voiceActivityType == VoiceActivityType.ACTIVITY_END) return false;
    return null;
  }
}

/// Token counts broken down by media modality.
@JsonSerializable(includeIfNull: false, createToJson: false)
class ModalityTokenCount {
  final MediaModality? modality;
  final int? tokenCount;

  ModalityTokenCount({this.modality, this.tokenCount});

  factory ModalityTokenCount.fromJson(Map<String, dynamic> json) =>
      _$ModalityTokenCountFromJson(json);
}

/// Usage statistics attached to a server response.
@JsonSerializable(includeIfNull: false, createToJson: false)
class UsageMetadata {
  final int? promptTokenCount;
  final int? cachedContentTokenCount;
  final int? responseTokenCount;
  final int? toolUsePromptTokenCount;
  final int? thoughtsTokenCount;
  final int? totalTokenCount;
  final List<ModalityTokenCount>? promptTokensDetails;
  final List<ModalityTokenCount>? cacheTokensDetails;
  final List<ModalityTokenCount>? responseTokensDetails;
  final List<ModalityTokenCount>? toolUsePromptTokensDetails;
  final TrafficType? trafficType;

  UsageMetadata({
    this.promptTokenCount,
    this.cachedContentTokenCount,
    this.responseTokenCount,
    this.toolUsePromptTokenCount,
    this.thoughtsTokenCount,
    this.totalTokenCount,
    this.promptTokensDetails,
    this.cacheTokensDetails,
    this.responseTokensDetails,
    this.toolUsePromptTokensDetails,
    this.trafficType,
  });

  factory UsageMetadata.fromJson(Map<String, dynamic> json) =>
      _$UsageMetadataFromJson(json);
}

/// A top-level server message received over the Live API socket.
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

  /// The concatenated non-thought text emitted in the current server turn.
  String? get text {
    final parts = serverContent?.modelTurn?.parts;
    if (parts == null || parts.isEmpty) return null;
    final chunks = <String>[];
    for (final part in parts) {
      final text = part.text;
      if (text == null) continue;
      if (part.thought == true) continue;
      chunks.add(text);
    }
    return chunks.isEmpty ? null : chunks.join();
  }

  /// The concatenated inline binary payload emitted in the current server turn.
  String? get data {
    final parts = serverContent?.modelTurn?.parts;
    if (parts == null || parts.isEmpty) return null;
    final buffer = StringBuffer();
    for (final part in parts) {
      final inline = part.inlineData;
      if (inline?.data == null) continue;
      buffer.write(inline!.data);
    }
    return buffer.isNotEmpty ? buffer.toString() : null;
  }
}

// ============================================================================
// Send Parameters
// ============================================================================

/// Parameters for sending conversational turns to the session.
class LiveSendClientContentParameters {
  final List<Content>? turns;
  final bool turnComplete;

  LiveSendClientContentParameters({this.turns, this.turnComplete = true});
}

/// Parameters for sending realtime media or text input.
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

/// Parameters for sending tool results back to the model.
class LiveSendToolResponseParameters {
  final List<FunctionResponse> functionResponses;

  LiveSendToolResponseParameters({required this.functionResponses});
}
