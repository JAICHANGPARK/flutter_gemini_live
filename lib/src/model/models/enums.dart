// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Enums
// ============================================================================

/// Harm categories reported by Gemini safety metadata.
@JsonEnum(alwaysCreate: true)
enum HarmCategory {
  @JsonValue('HARM_CATEGORY_UNSPECIFIED')
  HARM_CATEGORY_UNSPECIFIED,
  @JsonValue('HARM_CATEGORY_HATE_SPEECH')
  HARM_CATEGORY_HATE_SPEECH,
  @JsonValue('HARM_CATEGORY_DANGEROUS_CONTENT')
  HARM_CATEGORY_DANGEROUS_CONTENT,
  @JsonValue('HARM_CATEGORY_HARASSMENT')
  HARM_CATEGORY_HARASSMENT,
  @JsonValue('HARM_CATEGORY_SEXUALLY_EXPLICIT')
  HARM_CATEGORY_SEXUALLY_EXPLICIT,
  @JsonValue('HARM_CATEGORY_CIVIC_INTEGRITY')
  HARM_CATEGORY_CIVIC_INTEGRITY,
  @JsonValue('HARM_CATEGORY_IMAGE_HATE')
  HARM_CATEGORY_IMAGE_HATE,
  @JsonValue('HARM_CATEGORY_IMAGE_DANGEROUS_CONTENT')
  HARM_CATEGORY_IMAGE_DANGEROUS_CONTENT,
  @JsonValue('HARM_CATEGORY_IMAGE_HARASSMENT')
  HARM_CATEGORY_IMAGE_HARASSMENT,
  @JsonValue('HARM_CATEGORY_IMAGE_SEXUALLY_EXPLICIT')
  HARM_CATEGORY_IMAGE_SEXUALLY_EXPLICIT,
  @JsonValue('HARM_CATEGORY_JAILBREAK')
  HARM_CATEGORY_JAILBREAK,
}

/// Safety blocking methods.
@JsonEnum(alwaysCreate: true)
enum HarmBlockMethod {
  @JsonValue('HARM_BLOCK_METHOD_UNSPECIFIED')
  HARM_BLOCK_METHOD_UNSPECIFIED,
  @JsonValue('SEVERITY')
  SEVERITY,
  @JsonValue('PROBABILITY')
  PROBABILITY,
}

/// Safety thresholds used to block unsafe content.
@JsonEnum(alwaysCreate: true)
enum HarmBlockThreshold {
  @JsonValue('HARM_BLOCK_THRESHOLD_UNSPECIFIED')
  HARM_BLOCK_THRESHOLD_UNSPECIFIED,
  @JsonValue('BLOCK_LOW_AND_ABOVE')
  BLOCK_LOW_AND_ABOVE,
  @JsonValue('BLOCK_MEDIUM_AND_ABOVE')
  BLOCK_MEDIUM_AND_ABOVE,
  @JsonValue('BLOCK_ONLY_HIGH')
  BLOCK_ONLY_HIGH,
  @JsonValue('BLOCK_NONE')
  BLOCK_NONE,
  @JsonValue('OFF')
  OFF,
}

/// Modalities that a request or response can contain.
@JsonEnum(alwaysCreate: true)
enum Modality {
  @JsonValue('MODALITY_UNSPECIFIED')
  MODALITY_UNSPECIFIED,
  @JsonValue('TEXT')
  TEXT,
  @JsonValue('IMAGE')
  IMAGE,
  @JsonValue('AUDIO')
  AUDIO,
  @JsonValue('VIDEO')
  VIDEO,
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
  @JsonValue('TURN_INCLUDES_AUDIO_ACTIVITY_AND_ALL_VIDEO')
  TURN_INCLUDES_AUDIO_ACTIVITY_AND_ALL_VIDEO,
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
  @JsonValue('PROHIBITED_INPUT_CONTENT')
  PROHIBITED_INPUT_CONTENT,
  @JsonValue('IMAGE_PROHIBITED_INPUT_CONTENT')
  IMAGE_PROHIBITED_INPUT_CONTENT,
  @JsonValue('INPUT_TEXT_CONTAIN_PROMINENT_PERSON_PROHIBITED')
  INPUT_TEXT_CONTAIN_PROMINENT_PERSON_PROHIBITED,
  @JsonValue('INPUT_IMAGE_CELEBRITY')
  INPUT_IMAGE_CELEBRITY,
  @JsonValue('INPUT_IMAGE_PHOTO_REALISTIC_CHILD_PROHIBITED')
  INPUT_IMAGE_PHOTO_REALISTIC_CHILD_PROHIBITED,
  @JsonValue('INPUT_TEXT_NCII_PROHIBITED')
  INPUT_TEXT_NCII_PROHIBITED,
  @JsonValue('INPUT_OTHER')
  INPUT_OTHER,
  @JsonValue('INPUT_IP_PROHIBITED')
  INPUT_IP_PROHIBITED,
  @JsonValue('BLOCKLIST')
  BLOCKLIST,
  @JsonValue('UNSAFE_PROMPT_FOR_IMAGE_GENERATION')
  UNSAFE_PROMPT_FOR_IMAGE_GENERATION,
  @JsonValue('GENERATED_IMAGE_SAFETY')
  GENERATED_IMAGE_SAFETY,
  @JsonValue('GENERATED_CONTENT_SAFETY')
  GENERATED_CONTENT_SAFETY,
  @JsonValue('GENERATED_AUDIO_SAFETY')
  GENERATED_AUDIO_SAFETY,
  @JsonValue('GENERATED_VIDEO_SAFETY')
  GENERATED_VIDEO_SAFETY,
  @JsonValue('GENERATED_CONTENT_PROHIBITED')
  GENERATED_CONTENT_PROHIBITED,
  @JsonValue('GENERATED_CONTENT_BLOCKLIST')
  GENERATED_CONTENT_BLOCKLIST,
  @JsonValue('GENERATED_IMAGE_PROHIBITED')
  GENERATED_IMAGE_PROHIBITED,
  @JsonValue('GENERATED_IMAGE_CELEBRITY')
  GENERATED_IMAGE_CELEBRITY,
  @JsonValue('GENERATED_IMAGE_PROMINENT_PEOPLE_DETECTED_BY_REWRITER')
  GENERATED_IMAGE_PROMINENT_PEOPLE_DETECTED_BY_REWRITER,
  @JsonValue('GENERATED_IMAGE_IDENTIFIABLE_PEOPLE')
  GENERATED_IMAGE_IDENTIFIABLE_PEOPLE,
  @JsonValue('GENERATED_IMAGE_MINORS')
  GENERATED_IMAGE_MINORS,
  @JsonValue('OUTPUT_IMAGE_IP_PROHIBITED')
  OUTPUT_IMAGE_IP_PROHIBITED,
  @JsonValue('GENERATED_OTHER')
  GENERATED_OTHER,
  @JsonValue('MAX_REGENERATION_REACHED')
  MAX_REGENERATION_REACHED,
  @JsonValue('TOO_MANY_TOOL_CALLS')
  TOO_MANY_TOOL_CALLS,
}

/// The different activity states of the live session.
@JsonEnum(alwaysCreate: true)
enum InteractionStatus {
  @JsonValue('INTERACTION_STATUS_UNSPECIFIED')
  INTERACTION_STATUS_UNSPECIFIED,
  @JsonValue('IN_PROGRESS')
  IN_PROGRESS,
  /// Deprecated: Use [IDLE] instead.
  @Deprecated('Use IDLE instead.')
  @JsonValue('REQUIRES_ACTION')
  REQUIRES_ACTION,
  @JsonValue('IDLE')
  IDLE,
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
  @JsonValue('ON_DEMAND_PRIORITY')
  ON_DEMAND_PRIORITY,
  @JsonValue('ON_DEMAND_FLEX')
  ON_DEMAND_FLEX,
  @JsonValue('ON_DEMAND_OFFPEAK')
  ON_DEMAND_OFFPEAK,
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

/// Media tokenization quality used for a specific part.
@JsonEnum(alwaysCreate: true)
enum PartMediaResolutionLevel {
  @JsonValue('MEDIA_RESOLUTION_UNSPECIFIED')
  MEDIA_RESOLUTION_UNSPECIFIED,
  @JsonValue('MEDIA_RESOLUTION_LOW')
  MEDIA_RESOLUTION_LOW,
  @JsonValue('MEDIA_RESOLUTION_MEDIUM')
  MEDIA_RESOLUTION_MEDIUM,
  @JsonValue('MEDIA_RESOLUTION_HIGH')
  MEDIA_RESOLUTION_HIGH,
  @JsonValue('MEDIA_RESOLUTION_ULTRA_HIGH')
  MEDIA_RESOLUTION_ULTRA_HIGH,
}

/// Tool categories reported in server-side tool call parts.
@JsonEnum(alwaysCreate: true)
enum ToolType {
  @JsonValue('TOOL_TYPE_UNSPECIFIED')
  TOOL_TYPE_UNSPECIFIED,
  @JsonValue('GOOGLE_SEARCH_WEB')
  GOOGLE_SEARCH_WEB,
  @JsonValue('GOOGLE_SEARCH_IMAGE')
  GOOGLE_SEARCH_IMAGE,
  @JsonValue('URL_CONTEXT')
  URL_CONTEXT,
  @JsonValue('GOOGLE_MAPS')
  GOOGLE_MAPS,
  @JsonValue('FILE_SEARCH')
  FILE_SEARCH,
  @JsonValue('MEDIA_PROCESSING')
  MEDIA_PROCESSING,
}

/// Environments supported by the computer-use tool.
@JsonEnum(alwaysCreate: true)
enum Environment {
  @JsonValue('ENVIRONMENT_UNSPECIFIED')
  ENVIRONMENT_UNSPECIFIED,
  @JsonValue('ENVIRONMENT_BROWSER')
  ENVIRONMENT_BROWSER,
  @JsonValue('ENVIRONMENT_MOBILE')
  ENVIRONMENT_MOBILE,
  @JsonValue('ENVIRONMENT_DESKTOP')
  ENVIRONMENT_DESKTOP,
}

/// Thinking effort levels for models that support thought generation.
@JsonEnum(alwaysCreate: true)
enum ThinkingLevel {
  @JsonValue('THINKING_LEVEL_UNSPECIFIED')
  THINKING_LEVEL_UNSPECIFIED,
  @JsonValue('MINIMAL')
  MINIMAL,
  @JsonValue('LOW')
  LOW,
  @JsonValue('MEDIUM')
  MEDIUM,
  @JsonValue('HIGH')
  HIGH,
}

/// Safety policies that can be disabled for the computer-use tool.
@JsonEnum(alwaysCreate: true)
enum SafetyPolicy {
  @JsonValue('SAFETY_POLICY_UNSPECIFIED')
  SAFETY_POLICY_UNSPECIFIED,
  @JsonValue('FINANCIAL_TRANSACTIONS')
  FINANCIAL_TRANSACTIONS,
  @JsonValue('SENSITIVE_DATA_MODIFICATION')
  SENSITIVE_DATA_MODIFICATION,
  @JsonValue('COMMUNICATION_TOOL')
  COMMUNICATION_TOOL,
  @JsonValue('ACCOUNT_CREATION')
  ACCOUNT_CREATION,
  @JsonValue('DATA_MODIFICATION')
  DATA_MODIFICATION,
  @JsonValue('USER_CONSENT_MANAGEMENT')
  USER_CONSENT_MANAGEMENT,
  @JsonValue('LEGAL_TERMS_AND_AGREEMENTS')
  LEGAL_TERMS_AND_AGREEMENTS,
}

/// Pricing and performance service tier reported in usage metadata.
///
/// Note: wire values are lowercase.
@JsonEnum(alwaysCreate: true)
enum ServiceTier {
  @JsonValue('unspecified')
  UNSPECIFIED,
  @JsonValue('flex')
  FLEX,
  @JsonValue('standard')
  STANDARD,
  @JsonValue('priority')
  PRIORITY,
  @JsonValue('deferred')
  DEFERRED,
}

/// How the model processes input media for understanding.
@JsonEnum(alwaysCreate: true)
enum MediaProcessing {
  @JsonValue('MEDIA_PROCESSING_UNSPECIFIED')
  MEDIA_PROCESSING_UNSPECIFIED,
  @JsonValue('STATIC')
  STATIC,
  @JsonValue('AGENTIC')
  AGENTIC,
}

/// Musical scale of generated music.
@JsonEnum(alwaysCreate: true)
enum Scale {
  @JsonValue('SCALE_UNSPECIFIED')
  SCALE_UNSPECIFIED,
  @JsonValue('C_MAJOR_A_MINOR')
  C_MAJOR_A_MINOR,
  @JsonValue('D_FLAT_MAJOR_B_FLAT_MINOR')
  D_FLAT_MAJOR_B_FLAT_MINOR,
  @JsonValue('D_MAJOR_B_MINOR')
  D_MAJOR_B_MINOR,
  @JsonValue('E_FLAT_MAJOR_C_MINOR')
  E_FLAT_MAJOR_C_MINOR,
  @JsonValue('E_MAJOR_D_FLAT_MINOR')
  E_MAJOR_D_FLAT_MINOR,
  @JsonValue('F_MAJOR_D_MINOR')
  F_MAJOR_D_MINOR,
  @JsonValue('G_FLAT_MAJOR_E_FLAT_MINOR')
  G_FLAT_MAJOR_E_FLAT_MINOR,
  @JsonValue('G_MAJOR_E_MINOR')
  G_MAJOR_E_MINOR,
  @JsonValue('A_FLAT_MAJOR_F_MINOR')
  A_FLAT_MAJOR_F_MINOR,
  @JsonValue('A_MAJOR_G_FLAT_MINOR')
  A_MAJOR_G_FLAT_MINOR,
  @JsonValue('B_FLAT_MAJOR_G_MINOR')
  B_FLAT_MAJOR_G_MINOR,
  @JsonValue('B_MAJOR_A_FLAT_MINOR')
  B_MAJOR_A_FLAT_MINOR,
}

/// The mode of music generation.
@JsonEnum(alwaysCreate: true)
enum MusicGenerationMode {
  @JsonValue('MUSIC_GENERATION_MODE_UNSPECIFIED')
  MUSIC_GENERATION_MODE_UNSPECIFIED,
  @JsonValue('QUALITY')
  QUALITY,
  @JsonValue('DIVERSITY')
  DIVERSITY,
  @JsonValue('VOCALIZATION')
  VOCALIZATION,
}

/// Playback control signal for music generation.
@JsonEnum(alwaysCreate: true)
enum LiveMusicPlaybackControl {
  @JsonValue('PLAYBACK_CONTROL_UNSPECIFIED')
  PLAYBACK_CONTROL_UNSPECIFIED,
  @JsonValue('PLAY')
  PLAY,
  @JsonValue('PAUSE')
  PAUSE,
  @JsonValue('STOP')
  STOP,
  @JsonValue('RESET_CONTEXT')
  RESET_CONTEXT,
}

