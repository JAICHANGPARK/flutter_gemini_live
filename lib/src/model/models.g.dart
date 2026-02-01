// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Part _$PartFromJson(Map<String, dynamic> json) => Part(
  text: json['text'] as String?,
  inlineData: json['inlineData'] == null
      ? null
      : Blob.fromJson(json['inlineData'] as Map<String, dynamic>),
  functionCall: json['functionCall'] == null
      ? null
      : FunctionCall.fromJson(json['functionCall'] as Map<String, dynamic>),
  functionResponse: json['functionResponse'] == null
      ? null
      : FunctionResponse.fromJson(
          json['functionResponse'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PartToJson(Part instance) => <String, dynamic>{
  'text': ?instance.text,
  'inlineData': ?instance.inlineData,
  'functionCall': ?instance.functionCall,
  'functionResponse': ?instance.functionResponse,
};

Blob _$BlobFromJson(Map<String, dynamic> json) =>
    Blob(mimeType: json['mimeType'] as String, data: json['data'] as String);

Map<String, dynamic> _$BlobToJson(Blob instance) => <String, dynamic>{
  'mimeType': instance.mimeType,
  'data': instance.data,
};

Content _$ContentFromJson(Map<String, dynamic> json) => Content(
  parts: (json['parts'] as List<dynamic>?)
      ?.map((e) => Part.fromJson(e as Map<String, dynamic>))
      .toList(),
  role: json['role'] as String?,
);

Map<String, dynamic> _$ContentToJson(Content instance) => <String, dynamic>{
  'parts': ?instance.parts,
  'role': ?instance.role,
};

GenerationConfig _$GenerationConfigFromJson(Map<String, dynamic> json) =>
    GenerationConfig(
      temperature: (json['temperature'] as num?)?.toDouble(),
      topK: (json['top_k'] as num?)?.toInt(),
      topP: (json['top_p'] as num?)?.toDouble(),
      maxOutputTokens: (json['max_output_tokens'] as num?)?.toInt(),
      responseModalities: (json['response_modalities'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$ModalityEnumMap, e))
          .toList(),
    );

Map<String, dynamic> _$GenerationConfigToJson(GenerationConfig instance) =>
    <String, dynamic>{
      'temperature': ?instance.temperature,
      'top_k': ?instance.topK,
      'top_p': ?instance.topP,
      'max_output_tokens': ?instance.maxOutputTokens,
      'response_modalities': ?instance.responseModalities
          ?.map((e) => _$ModalityEnumMap[e]!)
          .toList(),
    };

const _$ModalityEnumMap = {
  Modality.TEXT: 'TEXT',
  Modality.IMAGE: 'IMAGE',
  Modality.AUDIO: 'AUDIO',
};

FunctionCall _$FunctionCallFromJson(Map<String, dynamic> json) => FunctionCall(
  id: json['id'] as String?,
  name: json['name'] as String?,
  args: json['args'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$FunctionCallToJson(FunctionCall instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'name': ?instance.name,
      'args': ?instance.args,
    };

FunctionResponse _$FunctionResponseFromJson(Map<String, dynamic> json) =>
    FunctionResponse(
      id: json['id'] as String?,
      name: json['name'] as String?,
      response: json['response'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$FunctionResponseToJson(FunctionResponse instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'name': ?instance.name,
      'response': ?instance.response,
    };

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
  prefixPaddingMs: (json['prefix_padding_ms'] as num?)?.toInt(),
  silenceDurationMs: (json['silence_duration_ms'] as num?)?.toInt(),
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
  StartSensitivity.START_SENSITIVITY_UNSPECIFIED:
      'START_SENSITIVITY_UNSPECIFIED',
  StartSensitivity.START_SENSITIVITY_LOW: 'START_SENSITIVITY_LOW',
  StartSensitivity.START_SENSITIVITY_HIGH: 'START_SENSITIVITY_HIGH',
};

const _$EndSensitivityEnumMap = {
  EndSensitivity.END_SENSITIVITY_UNSPECIFIED: 'END_SENSITIVITY_UNSPECIFIED',
  EndSensitivity.END_SENSITIVITY_LOW: 'END_SENSITIVITY_LOW',
  EndSensitivity.END_SENSITIVITY_HIGH: 'END_SENSITIVITY_HIGH',
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
  ActivityHandling.ACTIVITY_HANDLING_UNSPECIFIED:
      'ACTIVITY_HANDLING_UNSPECIFIED',
  ActivityHandling.START_OF_ACTIVITY_INTERRUPTS: 'START_OF_ACTIVITY_INTERRUPTS',
  ActivityHandling.START_OF_ACTIVITY_DOES_NOT_INTERRUPT:
      'START_OF_ACTIVITY_DOES_NOT_INTERRUPT',
};

const _$TurnCoverageEnumMap = {
  TurnCoverage.TURN_COVERAGE_UNSPECIFIED: 'TURN_COVERAGE_UNSPECIFIED',
  TurnCoverage.TURN_INCLUDES_ONLY_ACTIVITY: 'TURN_INCLUDES_ONLY_ACTIVITY',
  TurnCoverage.TURN_INCLUDES_ALL_INPUT: 'TURN_INCLUDES_ALL_INPUT',
};

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

Tool _$ToolFromJson(Map<String, dynamic> json) => Tool();

Map<String, dynamic> _$ToolToJson(Tool instance) => <String, dynamic>{};

LiveClientSetup _$LiveClientSetupFromJson(
  Map<String, dynamic> json,
) => LiveClientSetup(
  model: json['model'] as String,
  generationConfig: json['generation_config'] == null
      ? null
      : GenerationConfig.fromJson(
          json['generation_config'] as Map<String, dynamic>,
        ),
  systemInstruction: json['system_instruction'] == null
      ? null
      : Content.fromJson(json['system_instruction'] as Map<String, dynamic>),
  tools: (json['tools'] as List<dynamic>?)
      ?.map((e) => Tool.fromJson(e as Map<String, dynamic>))
      .toList(),
  realtimeInputConfig: json['realtime_input_config'] == null
      ? null
      : RealtimeInputConfig.fromJson(
          json['realtime_input_config'] as Map<String, dynamic>,
        ),
  sessionResumption: json['session_resumption'] == null
      ? null
      : SessionResumptionConfig.fromJson(
          json['session_resumption'] as Map<String, dynamic>,
        ),
  contextWindowCompression: json['context_window_compression'] == null
      ? null
      : ContextWindowCompressionConfig.fromJson(
          json['context_window_compression'] as Map<String, dynamic>,
        ),
  inputAudioTranscription: json['input_audio_transcription'] == null
      ? null
      : AudioTranscriptionConfig.fromJson(
          json['input_audio_transcription'] as Map<String, dynamic>,
        ),
  outputAudioTranscription: json['output_audio_transcription'] == null
      ? null
      : AudioTranscriptionConfig.fromJson(
          json['output_audio_transcription'] as Map<String, dynamic>,
        ),
  proactivity: json['proactivity'] == null
      ? null
      : ProactivityConfig.fromJson(json['proactivity'] as Map<String, dynamic>),
  explicitVadSignal: json['explicit_vad_signal'] as bool?,
);

Map<String, dynamic> _$LiveClientSetupToJson(LiveClientSetup instance) =>
    <String, dynamic>{
      'model': instance.model,
      'generation_config': ?instance.generationConfig,
      'system_instruction': ?instance.systemInstruction,
      'tools': ?instance.tools,
      'realtime_input_config': ?instance.realtimeInputConfig,
      'session_resumption': ?instance.sessionResumption,
      'context_window_compression': ?instance.contextWindowCompression,
      'input_audio_transcription': ?instance.inputAudioTranscription,
      'output_audio_transcription': ?instance.outputAudioTranscription,
      'proactivity': ?instance.proactivity,
      'explicit_vad_signal': ?instance.explicitVadSignal,
    };

LiveClientContent _$LiveClientContentFromJson(Map<String, dynamic> json) =>
    LiveClientContent(
      turns: (json['turns'] as List<dynamic>?)
          ?.map((e) => Content.fromJson(e as Map<String, dynamic>))
          .toList(),
      turnComplete: json['turn_complete'] as bool?,
    );

Map<String, dynamic> _$LiveClientContentToJson(LiveClientContent instance) =>
    <String, dynamic>{
      'turns': ?instance.turns,
      'turn_complete': ?instance.turnComplete,
    };

ActivityStart _$ActivityStartFromJson(Map<String, dynamic> json) =>
    ActivityStart();

Map<String, dynamic> _$ActivityStartToJson(ActivityStart instance) =>
    <String, dynamic>{};

ActivityEnd _$ActivityEndFromJson(Map<String, dynamic> json) => ActivityEnd();

Map<String, dynamic> _$ActivityEndToJson(ActivityEnd instance) =>
    <String, dynamic>{};

LiveClientRealtimeInput _$LiveClientRealtimeInputFromJson(
  Map<String, dynamic> json,
) => LiveClientRealtimeInput(
  mediaChunks: (json['media_chunks'] as List<dynamic>?)
      ?.map((e) => Blob.fromJson(e as Map<String, dynamic>))
      .toList(),
  audio: json['audio'] == null
      ? null
      : Blob.fromJson(json['audio'] as Map<String, dynamic>),
  video: json['video'] == null
      ? null
      : Blob.fromJson(json['video'] as Map<String, dynamic>),
  audioStreamEnd: json['audio_stream_end'] as bool?,
  text: json['text'] as String?,
  activityStart: json['activity_start'] == null
      ? null
      : ActivityStart.fromJson(json['activity_start'] as Map<String, dynamic>),
  activityEnd: json['activity_end'] == null
      ? null
      : ActivityEnd.fromJson(json['activity_end'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LiveClientRealtimeInputToJson(
  LiveClientRealtimeInput instance,
) => <String, dynamic>{
  'media_chunks': ?instance.mediaChunks,
  'audio': ?instance.audio,
  'video': ?instance.video,
  'audio_stream_end': ?instance.audioStreamEnd,
  'text': ?instance.text,
  'activity_start': ?instance.activityStart,
  'activity_end': ?instance.activityEnd,
};

LiveClientToolResponse _$LiveClientToolResponseFromJson(
  Map<String, dynamic> json,
) => LiveClientToolResponse(
  functionResponses: (json['function_responses'] as List<dynamic>?)
      ?.map((e) => FunctionResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LiveClientToolResponseToJson(
  LiveClientToolResponse instance,
) => <String, dynamic>{'function_responses': ?instance.functionResponses};

LiveClientMessage _$LiveClientMessageFromJson(Map<String, dynamic> json) =>
    LiveClientMessage(
      setup: json['setup'] == null
          ? null
          : LiveClientSetup.fromJson(json['setup'] as Map<String, dynamic>),
      clientContent: json['clientContent'] == null
          ? null
          : LiveClientContent.fromJson(
              json['clientContent'] as Map<String, dynamic>,
            ),
      realtimeInput: json['realtimeInput'] == null
          ? null
          : LiveClientRealtimeInput.fromJson(
              json['realtimeInput'] as Map<String, dynamic>,
            ),
      toolResponse: json['toolResponse'] == null
          ? null
          : LiveClientToolResponse.fromJson(
              json['toolResponse'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$LiveClientMessageToJson(LiveClientMessage instance) =>
    <String, dynamic>{
      'setup': ?instance.setup,
      'clientContent': ?instance.clientContent,
      'realtimeInput': ?instance.realtimeInput,
      'toolResponse': ?instance.toolResponse,
    };

LiveServerSetupComplete _$LiveServerSetupCompleteFromJson(
  Map<String, dynamic> json,
) => LiveServerSetupComplete();

Transcription _$TranscriptionFromJson(Map<String, dynamic> json) =>
    Transcription(
      text: json['text'] as String?,
      finished: json['finished'] as bool?,
    );

LiveServerContent _$LiveServerContentFromJson(Map<String, dynamic> json) =>
    LiveServerContent(
      modelTurn: json['modelTurn'] == null
          ? null
          : Content.fromJson(json['modelTurn'] as Map<String, dynamic>),
      turnComplete: json['turnComplete'] as bool?,
      inputTranscription: json['inputTranscription'] == null
          ? null
          : Transcription.fromJson(
              json['inputTranscription'] as Map<String, dynamic>,
            ),
      outputTranscription: json['outputTranscription'] == null
          ? null
          : Transcription.fromJson(
              json['outputTranscription'] as Map<String, dynamic>,
            ),
      generationComplete: json['generationComplete'] as bool?,
    );

LiveServerToolCall _$LiveServerToolCallFromJson(Map<String, dynamic> json) =>
    LiveServerToolCall(
      functionCalls: (json['function_calls'] as List<dynamic>?)
          ?.map((e) => FunctionCall.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

LiveServerToolCallCancellation _$LiveServerToolCallCancellationFromJson(
  Map<String, dynamic> json,
) => LiveServerToolCallCancellation(
  ids: (json['ids'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

LiveServerGoAway _$LiveServerGoAwayFromJson(Map<String, dynamic> json) =>
    LiveServerGoAway(
      reason: json['reason'] as String?,
      timeRemaining: (json['time_remaining'] as num?)?.toInt(),
    );

LiveServerSessionResumptionUpdate _$LiveServerSessionResumptionUpdateFromJson(
  Map<String, dynamic> json,
) => LiveServerSessionResumptionUpdate(
  newHandle: json['new_handle'] as String?,
  resumable: json['resumable'] as String?,
  lastConsumedClientMessageIndex:
      (json['last_consumed_client_message_index'] as num?)?.toInt(),
);

VoiceActivityDetectionSignal _$VoiceActivityDetectionSignalFromJson(
  Map<String, dynamic> json,
) => VoiceActivityDetectionSignal(
  start: json['start'] as bool?,
  end: json['end'] as bool?,
);

VoiceActivity _$VoiceActivityFromJson(Map<String, dynamic> json) =>
    VoiceActivity(speechActive: json['speech_active'] as bool?);

UsageMetadata _$UsageMetadataFromJson(Map<String, dynamic> json) =>
    UsageMetadata(
      promptTokenCount: (json['promptTokenCount'] as num).toInt(),
      responseTokenCount: (json['responseTokenCount'] as num).toInt(),
      totalTokenCount: (json['totalTokenCount'] as num).toInt(),
    );

LiveServerMessage _$LiveServerMessageFromJson(
  Map<String, dynamic> json,
) => LiveServerMessage(
  setupComplete: json['setupComplete'] == null
      ? null
      : LiveServerSetupComplete.fromJson(
          json['setupComplete'] as Map<String, dynamic>,
        ),
  serverContent: json['serverContent'] == null
      ? null
      : LiveServerContent.fromJson(
          json['serverContent'] as Map<String, dynamic>,
        ),
  usageMetadata: json['usageMetadata'] == null
      ? null
      : UsageMetadata.fromJson(json['usageMetadata'] as Map<String, dynamic>),
  toolCall: json['toolCall'] == null
      ? null
      : LiveServerToolCall.fromJson(json['toolCall'] as Map<String, dynamic>),
  toolCallCancellation: json['toolCallCancellation'] == null
      ? null
      : LiveServerToolCallCancellation.fromJson(
          json['toolCallCancellation'] as Map<String, dynamic>,
        ),
  goAway: json['goAway'] == null
      ? null
      : LiveServerGoAway.fromJson(json['goAway'] as Map<String, dynamic>),
  sessionResumptionUpdate: json['sessionResumptionUpdate'] == null
      ? null
      : LiveServerSessionResumptionUpdate.fromJson(
          json['sessionResumptionUpdate'] as Map<String, dynamic>,
        ),
  voiceActivityDetectionSignal: json['voiceActivityDetectionSignal'] == null
      ? null
      : VoiceActivityDetectionSignal.fromJson(
          json['voiceActivityDetectionSignal'] as Map<String, dynamic>,
        ),
  voiceActivity: json['voiceActivity'] == null
      ? null
      : VoiceActivity.fromJson(json['voiceActivity'] as Map<String, dynamic>),
);
