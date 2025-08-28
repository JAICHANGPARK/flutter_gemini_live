// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FunctionCall _$FunctionCallFromJson(Map<String, dynamic> json) => FunctionCall(
  name: json['name'] as String,
  args: json['args'] as Map<String, dynamic>,
  id: json['id'] as String?,
);

Map<String, dynamic> _$FunctionCallToJson(FunctionCall instance) =>
    <String, dynamic>{
      'name': instance.name,
      'args': instance.args,
      'id': ?instance.id,
    };

FunctionResponse _$FunctionResponseFromJson(Map<String, dynamic> json) =>
    FunctionResponse(
      name: json['name'] as String,
      response: json['response'] as Map<String, dynamic>,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$FunctionResponseToJson(FunctionResponse instance) =>
    <String, dynamic>{
      'name': instance.name,
      'response': instance.response,
      'id': ?instance.id,
    };

LiveClientToolResponse _$LiveClientToolResponseFromJson(
  Map<String, dynamic> json,
) => LiveClientToolResponse(
  functionResponses:
      (json['function_responses'] as List<dynamic>?)
          ?.map((e) => FunctionResponse.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$LiveClientToolResponseToJson(
  LiveClientToolResponse instance,
) => <String, dynamic>{'function_responses': instance.functionResponses};

ActivityStart _$ActivityStartFromJson(Map<String, dynamic> json) =>
    ActivityStart();

Map<String, dynamic> _$ActivityStartToJson(ActivityStart instance) =>
    <String, dynamic>{};

ActivityEnd _$ActivityEndFromJson(Map<String, dynamic> json) => ActivityEnd();

Map<String, dynamic> _$ActivityEndToJson(ActivityEnd instance) =>
    <String, dynamic>{};

AutomaticActivityDetection _$AutomaticActivityDetectionFromJson(
  Map<String, dynamic> json,
) => AutomaticActivityDetection(
  disabled: json['disabled'] as bool?,
  startOfSpeechSensitivity: $enumDecodeNullable(
    _$StartSensitivityEnumMap,
    json['start_of_speech_sensitivity'],
  ),
  endOfSpeechSensitivity: $enumDecodeNullable(
    _$EndSensitivityEnumMap,
    json['end_of_speech_sensitivity'],
  ),
  prefixPaddingMs: json['prefix_padding_ms'] as num?,
  silenceDurationMs: json['silence_duration_ms'] as num?,
);

Map<String, dynamic> _$AutomaticActivityDetectionToJson(
  AutomaticActivityDetection instance,
) => <String, dynamic>{
  'disabled': ?instance.disabled,
  'start_of_speech_sensitivity':
      ?_$StartSensitivityEnumMap[instance.startOfSpeechSensitivity],
  'end_of_speech_sensitivity':
      ?_$EndSensitivityEnumMap[instance.endOfSpeechSensitivity],
  'prefix_padding_ms': ?instance.prefixPaddingMs,
  'silence_duration_ms': ?instance.silenceDurationMs,
};

const _$StartSensitivityEnumMap = {
  StartSensitivity.startSensitivityUnspecified: 'START_SENSITIVITY_UNSPECIFIED',
  StartSensitivity.startSensitivityHigh: 'START_SENSITIVITY_HIGH',
  StartSensitivity.startSensitivityLow: 'START_SENSITIVITY_LOW',
};

const _$EndSensitivityEnumMap = {
  EndSensitivity.endSensitivityUnspecified: 'END_SENSITIVITY_UNSPECIFIED',
  EndSensitivity.endSensitivityHigh: 'END_SENSITIVITY_HIGH',
  EndSensitivity.endSensitivityLow: 'END_SENSITIVITY_LOW',
};

RealtimeInputConfig _$RealtimeInputConfigFromJson(Map<String, dynamic> json) =>
    RealtimeInputConfig(
      automaticActivityDetection: json['automatic_activity_detection'] == null
          ? null
          : AutomaticActivityDetection.fromJson(
              json['automatic_activity_detection'] as Map<String, dynamic>,
            ),
      activityHandling: $enumDecodeNullable(
        _$ActivityHandlingEnumMap,
        json['activity_handling'],
      ),
      turnCoverage: $enumDecodeNullable(
        _$TurnCoverageEnumMap,
        json['turn_coverage'],
      ),
    );

Map<String, dynamic> _$RealtimeInputConfigToJson(
  RealtimeInputConfig instance,
) => <String, dynamic>{
  'automatic_activity_detection': ?instance.automaticActivityDetection,
  'activity_handling': ?_$ActivityHandlingEnumMap[instance.activityHandling],
  'turn_coverage': ?_$TurnCoverageEnumMap[instance.turnCoverage],
};

const _$ActivityHandlingEnumMap = {
  ActivityHandling.activityHandlingUnspecified: 'ACTIVITY_HANDLING_UNSPECIFIED',
  ActivityHandling.startOfActivityInterrupts: 'START_OF_ACTIVITY_INTERRUPTS',
  ActivityHandling.noInterruption: 'NO_INTERRUPTION',
};

const _$TurnCoverageEnumMap = {
  TurnCoverage.turnCoverageUnspecified: 'TURN_COVERAGE_UNSPECIFIED',
  TurnCoverage.turnIncludesOnlyActivity: 'TURN_INCLUDES_ONLY_ACTIVITY',
  TurnCoverage.turnIncludesAllInput: 'TURN_INCLUDES_ALL_INPUT',
};

LiveServerToolCallCancellation _$LiveServerToolCallCancellationFromJson(
  Map<String, dynamic> json,
) => LiveServerToolCallCancellation(
  ids:
      (json['ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

LiveServerGoAway _$LiveServerGoAwayFromJson(Map<String, dynamic> json) =>
    LiveServerGoAway(timeLeft: json['timeLeft'] as String?);

LiveServerSessionResumptionUpdate _$LiveServerSessionResumptionUpdateFromJson(
  Map<String, dynamic> json,
) => LiveServerSessionResumptionUpdate(
  newHandle: json['newHandle'] as String?,
  resumable: json['resumable'] as bool?,
  lastConsumedClientMessageIndex:
      json['lastConsumedClientMessageIndex'] as String?,
);

SessionResumptionConfig _$SessionResumptionConfigFromJson(
  Map<String, dynamic> json,
) => SessionResumptionConfig(
  handle: json['handle'] as String?,
  transparent: json['transparent'] as bool?,
);

Map<String, dynamic> _$SessionResumptionConfigToJson(
  SessionResumptionConfig instance,
) => <String, dynamic>{
  'handle': ?instance.handle,
  'transparent': ?instance.transparent,
};

SlidingWindow _$SlidingWindowFromJson(Map<String, dynamic> json) =>
    SlidingWindow(targetTokens: json['target_tokens'] as String?);

Map<String, dynamic> _$SlidingWindowToJson(SlidingWindow instance) =>
    <String, dynamic>{'target_tokens': ?instance.targetTokens};

ContextWindowCompressionConfig _$ContextWindowCompressionConfigFromJson(
  Map<String, dynamic> json,
) => ContextWindowCompressionConfig(
  triggerTokens: json['trigger_tokens'] as String?,
  slidingWindow: json['sliding_window'] == null
      ? null
      : SlidingWindow.fromJson(json['sliding_window'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ContextWindowCompressionConfigToJson(
  ContextWindowCompressionConfig instance,
) => <String, dynamic>{
  'trigger_tokens': ?instance.triggerTokens,
  'sliding_window': ?instance.slidingWindow,
};

AudioTranscriptionConfig _$AudioTranscriptionConfigFromJson(
  Map<String, dynamic> json,
) => AudioTranscriptionConfig();

Map<String, dynamic> _$AudioTranscriptionConfigToJson(
  AudioTranscriptionConfig instance,
) => <String, dynamic>{};

ProactivityConfig _$ProactivityConfigFromJson(Map<String, dynamic> json) =>
    ProactivityConfig(proactiveAudio: json['proactive_audio'] as bool?);

Map<String, dynamic> _$ProactivityConfigToJson(ProactivityConfig instance) =>
    <String, dynamic>{'proactive_audio': ?instance.proactiveAudio};
