// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Part _$PartFromJson(Map<String, dynamic> json) => Part(
  text: json['text'] as String?,
  thought: json['thought'] as bool?,
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
  executableCode: json['executableCode'] == null
      ? null
      : ExecutableCode.fromJson(json['executableCode'] as Map<String, dynamic>),
  codeExecutionResult: json['codeExecutionResult'] == null
      ? null
      : CodeExecutionResult.fromJson(
          json['codeExecutionResult'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PartToJson(Part instance) => <String, dynamic>{
  'text': ?instance.text,
  'thought': ?instance.thought,
  'inlineData': ?instance.inlineData,
  'functionCall': ?instance.functionCall,
  'functionResponse': ?instance.functionResponse,
  'executableCode': ?instance.executableCode,
  'codeExecutionResult': ?instance.codeExecutionResult,
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

PrebuiltVoiceConfig _$PrebuiltVoiceConfigFromJson(Map<String, dynamic> json) =>
    PrebuiltVoiceConfig(voiceName: json['voice_name'] as String?);

Map<String, dynamic> _$PrebuiltVoiceConfigToJson(
  PrebuiltVoiceConfig instance,
) => <String, dynamic>{'voice_name': ?instance.voiceName};

VoiceConfig _$VoiceConfigFromJson(Map<String, dynamic> json) => VoiceConfig(
  prebuiltVoiceConfig: json['prebuilt_voice_config'] == null
      ? null
      : PrebuiltVoiceConfig.fromJson(
          json['prebuilt_voice_config'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$VoiceConfigToJson(VoiceConfig instance) =>
    <String, dynamic>{'prebuilt_voice_config': ?instance.prebuiltVoiceConfig};

SpeechConfig _$SpeechConfigFromJson(Map<String, dynamic> json) => SpeechConfig(
  voiceConfig: json['voice_config'] == null
      ? null
      : VoiceConfig.fromJson(json['voice_config'] as Map<String, dynamic>),
  languageCode: json['language_code'] as String?,
);

Map<String, dynamic> _$SpeechConfigToJson(SpeechConfig instance) =>
    <String, dynamic>{
      'voice_config': ?instance.voiceConfig,
      'language_code': ?instance.languageCode,
    };

ThinkingConfig _$ThinkingConfigFromJson(Map<String, dynamic> json) =>
    ThinkingConfig(
      includeThoughts: json['include_thoughts'] as bool?,
      thinkingBudget: (json['thinking_budget'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ThinkingConfigToJson(ThinkingConfig instance) =>
    <String, dynamic>{
      'include_thoughts': ?instance.includeThoughts,
      'thinking_budget': ?instance.thinkingBudget,
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
      mediaResolution: $enumDecodeNullable(
        _$MediaResolutionEnumMap,
        json['media_resolution'],
      ),
      seed: (json['seed'] as num?)?.toInt(),
      speechConfig: json['speech_config'] == null
          ? null
          : SpeechConfig.fromJson(
              json['speech_config'] as Map<String, dynamic>,
            ),
      thinkingConfig: json['thinking_config'] == null
          ? null
          : ThinkingConfig.fromJson(
              json['thinking_config'] as Map<String, dynamic>,
            ),
      enableAffectiveDialog: json['enable_affective_dialog'] as bool?,
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
      'media_resolution': ?_$MediaResolutionEnumMap[instance.mediaResolution],
      'seed': ?instance.seed,
      'speech_config': ?instance.speechConfig,
      'thinking_config': ?instance.thinkingConfig,
      'enable_affective_dialog': ?instance.enableAffectiveDialog,
    };

const _$ModalityEnumMap = {
  Modality.TEXT: 'TEXT',
  Modality.IMAGE: 'IMAGE',
  Modality.AUDIO: 'AUDIO',
};

const _$MediaResolutionEnumMap = {
  MediaResolution.MEDIA_RESOLUTION_UNSPECIFIED: 'MEDIA_RESOLUTION_UNSPECIFIED',
  MediaResolution.MEDIA_RESOLUTION_LOW: 'MEDIA_RESOLUTION_LOW',
  MediaResolution.MEDIA_RESOLUTION_MEDIUM: 'MEDIA_RESOLUTION_MEDIUM',
  MediaResolution.MEDIA_RESOLUTION_HIGH: 'MEDIA_RESOLUTION_HIGH',
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

FunctionResponseBlob _$FunctionResponseBlobFromJson(
  Map<String, dynamic> json,
) => FunctionResponseBlob(
  mimeType: json['mime_type'] as String?,
  data: json['data'] as String?,
);

Map<String, dynamic> _$FunctionResponseBlobToJson(
  FunctionResponseBlob instance,
) => <String, dynamic>{'mime_type': ?instance.mimeType, 'data': ?instance.data};

FunctionResponseFileData _$FunctionResponseFileDataFromJson(
  Map<String, dynamic> json,
) => FunctionResponseFileData(
  fileUri: json['file_uri'] as String?,
  mimeType: json['mime_type'] as String?,
);

Map<String, dynamic> _$FunctionResponseFileDataToJson(
  FunctionResponseFileData instance,
) => <String, dynamic>{
  'file_uri': ?instance.fileUri,
  'mime_type': ?instance.mimeType,
};

FunctionResponsePart _$FunctionResponsePartFromJson(
  Map<String, dynamic> json,
) => FunctionResponsePart(
  inlineData: json['inline_data'] == null
      ? null
      : FunctionResponseBlob.fromJson(
          json['inline_data'] as Map<String, dynamic>,
        ),
  fileData: json['file_data'] == null
      ? null
      : FunctionResponseFileData.fromJson(
          json['file_data'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$FunctionResponsePartToJson(
  FunctionResponsePart instance,
) => <String, dynamic>{
  'inline_data': ?instance.inlineData,
  'file_data': ?instance.fileData,
};

FunctionResponse _$FunctionResponseFromJson(Map<String, dynamic> json) =>
    FunctionResponse(
      id: json['id'] as String?,
      name: json['name'] as String?,
      response: json['response'] as Map<String, dynamic>?,
      willContinue: json['will_continue'] as bool?,
      scheduling: $enumDecodeNullable(
        _$FunctionResponseSchedulingEnumMap,
        json['scheduling'],
      ),
      parts: (json['parts'] as List<dynamic>?)
          ?.map((e) => FunctionResponsePart.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FunctionResponseToJson(FunctionResponse instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'name': ?instance.name,
      'response': ?instance.response,
      'will_continue': ?instance.willContinue,
      'scheduling': ?_$FunctionResponseSchedulingEnumMap[instance.scheduling],
      'parts': ?instance.parts,
    };

const _$FunctionResponseSchedulingEnumMap = {
  FunctionResponseScheduling.SCHEDULING_UNSPECIFIED: 'SCHEDULING_UNSPECIFIED',
  FunctionResponseScheduling.SILENT: 'SILENT',
  FunctionResponseScheduling.WHEN_IDLE: 'WHEN_IDLE',
  FunctionResponseScheduling.INTERRUPT: 'INTERRUPT',
};

FunctionDeclaration _$FunctionDeclarationFromJson(Map<String, dynamic> json) =>
    FunctionDeclaration(
      description: json['description'] as String?,
      name: json['name'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
      parametersJsonSchema: json['parameters_json_schema'],
      response: json['response'] as Map<String, dynamic>?,
      responseJsonSchema: json['response_json_schema'],
      behavior: $enumDecodeNullable(_$BehaviorEnumMap, json['behavior']),
    );

Map<String, dynamic> _$FunctionDeclarationToJson(
  FunctionDeclaration instance,
) => <String, dynamic>{
  'description': ?instance.description,
  'name': ?instance.name,
  'parameters': ?instance.parameters,
  'parameters_json_schema': ?instance.parametersJsonSchema,
  'response': ?instance.response,
  'response_json_schema': ?instance.responseJsonSchema,
  'behavior': ?_$BehaviorEnumMap[instance.behavior],
};

const _$BehaviorEnumMap = {
  Behavior.UNSPECIFIED: 'UNSPECIFIED',
  Behavior.BLOCKING: 'BLOCKING',
  Behavior.NON_BLOCKING: 'NON_BLOCKING',
};

Interval _$IntervalFromJson(Map<String, dynamic> json) => Interval(
  startTime: json['start_time'] == null
      ? null
      : DateTime.parse(json['start_time'] as String),
  endTime: json['end_time'] == null
      ? null
      : DateTime.parse(json['end_time'] as String),
);

Map<String, dynamic> _$IntervalToJson(Interval instance) => <String, dynamic>{
  'start_time': ?instance.startTime?.toIso8601String(),
  'end_time': ?instance.endTime?.toIso8601String(),
};

GoogleSearch _$GoogleSearchFromJson(Map<String, dynamic> json) => GoogleSearch(
  excludeDomains: (json['exclude_domains'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  timeRangeFilter: json['time_range_filter'] == null
      ? null
      : Interval.fromJson(json['time_range_filter'] as Map<String, dynamic>),
  blockingConfidence: json['blocking_confidence'] as String?,
);

Map<String, dynamic> _$GoogleSearchToJson(GoogleSearch instance) =>
    <String, dynamic>{
      'exclude_domains': ?instance.excludeDomains,
      'time_range_filter': ?instance.timeRangeFilter,
      'blocking_confidence': ?instance.blockingConfidence,
    };

DynamicRetrievalConfig _$DynamicRetrievalConfigFromJson(
  Map<String, dynamic> json,
) => DynamicRetrievalConfig(
  dynamicThreshold: (json['dynamic_threshold'] as num?)?.toDouble(),
  mode: json['mode'] as String?,
);

Map<String, dynamic> _$DynamicRetrievalConfigToJson(
  DynamicRetrievalConfig instance,
) => <String, dynamic>{
  'dynamic_threshold': ?instance.dynamicThreshold,
  'mode': ?instance.mode,
};

GoogleSearchRetrieval _$GoogleSearchRetrievalFromJson(
  Map<String, dynamic> json,
) => GoogleSearchRetrieval(
  dynamicRetrievalConfig: json['dynamic_retrieval_config'] == null
      ? null
      : DynamicRetrievalConfig.fromJson(
          json['dynamic_retrieval_config'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$GoogleSearchRetrievalToJson(
  GoogleSearchRetrieval instance,
) => <String, dynamic>{
  'dynamic_retrieval_config': ?instance.dynamicRetrievalConfig,
};

Tool _$ToolFromJson(Map<String, dynamic> json) => Tool(
  functionDeclarations: (json['function_declarations'] as List<dynamic>?)
      ?.map((e) => FunctionDeclaration.fromJson(e as Map<String, dynamic>))
      .toList(),
  googleSearch: json['google_search'] == null
      ? null
      : GoogleSearch.fromJson(json['google_search'] as Map<String, dynamic>),
  googleSearchRetrieval: json['google_search_retrieval'] == null
      ? null
      : GoogleSearchRetrieval.fromJson(
          json['google_search_retrieval'] as Map<String, dynamic>,
        ),
  codeExecution: json['code_execution'] as Map<String, dynamic>?,
  urlContext: json['url_context'] as Map<String, dynamic>?,
  googleMaps: json['google_maps'] as Map<String, dynamic>?,
  retrieval: json['retrieval'] as Map<String, dynamic>?,
  computerUse: json['computer_use'] as Map<String, dynamic>?,
  fileSearch: json['file_search'] as Map<String, dynamic>?,
  enterpriseWebSearch: json['enterprise_web_search'] as Map<String, dynamic>?,
  mcpServers: (json['mcp_servers'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
);

Map<String, dynamic> _$ToolToJson(Tool instance) => <String, dynamic>{
  'function_declarations': ?instance.functionDeclarations,
  'google_search': ?instance.googleSearch,
  'google_search_retrieval': ?instance.googleSearchRetrieval,
  'code_execution': ?instance.codeExecution,
  'url_context': ?instance.urlContext,
  'google_maps': ?instance.googleMaps,
  'retrieval': ?instance.retrieval,
  'computer_use': ?instance.computerUse,
  'file_search': ?instance.fileSearch,
  'enterprise_web_search': ?instance.enterpriseWebSearch,
  'mcp_servers': ?instance.mcpServers,
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
  ActivityHandling.NO_INTERRUPTION: 'NO_INTERRUPTION',
  ActivityHandling.START_OF_ACTIVITY_DOES_NOT_INTERRUPT: 'NO_INTERRUPTION',
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
) => LiveServerSetupComplete(sessionId: json['sessionId'] as String?);

Transcription _$TranscriptionFromJson(Map<String, dynamic> json) =>
    Transcription(
      text: json['text'] as String?,
      finished: json['finished'] as bool?,
    );

ExecutableCode _$ExecutableCodeFromJson(Map<String, dynamic> json) =>
    ExecutableCode(
      language: json['language'] as String?,
      code: json['code'] as String?,
    );

Map<String, dynamic> _$ExecutableCodeToJson(ExecutableCode instance) =>
    <String, dynamic>{'language': ?instance.language, 'code': ?instance.code};

CodeExecutionResult _$CodeExecutionResultFromJson(Map<String, dynamic> json) =>
    CodeExecutionResult(
      outcome: json['outcome'] as String?,
      output: json['output'] as String?,
    );

Map<String, dynamic> _$CodeExecutionResultToJson(
  CodeExecutionResult instance,
) => <String, dynamic>{
  'outcome': ?instance.outcome,
  'output': ?instance.output,
};

LiveServerContent _$LiveServerContentFromJson(Map<String, dynamic> json) =>
    LiveServerContent(
      modelTurn: json['modelTurn'] == null
          ? null
          : Content.fromJson(json['modelTurn'] as Map<String, dynamic>),
      turnComplete: json['turnComplete'] as bool?,
      interrupted: json['interrupted'] as bool?,
      groundingMetadata: json['groundingMetadata'] as Map<String, dynamic>?,
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
      urlContextMetadata: json['urlContextMetadata'] as Map<String, dynamic>?,
      turnCompleteReason: $enumDecodeNullable(
        _$TurnCompleteReasonEnumMap,
        json['turnCompleteReason'],
      ),
      waitingForInput: json['waitingForInput'] as bool?,
    );

const _$TurnCompleteReasonEnumMap = {
  TurnCompleteReason.TURN_COMPLETE_REASON_UNSPECIFIED:
      'TURN_COMPLETE_REASON_UNSPECIFIED',
  TurnCompleteReason.MALFORMED_FUNCTION_CALL: 'MALFORMED_FUNCTION_CALL',
  TurnCompleteReason.RESPONSE_REJECTED: 'RESPONSE_REJECTED',
  TurnCompleteReason.NEED_MORE_INPUT: 'NEED_MORE_INPUT',
};

LiveServerToolCall _$LiveServerToolCallFromJson(Map<String, dynamic> json) =>
    LiveServerToolCall(
      functionCalls: (json['functionCalls'] as List<dynamic>?)
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
      timeLeft: json['timeLeft'] as String?,
      reason: json['reason'] as String?,
    );

LiveServerSessionResumptionUpdate _$LiveServerSessionResumptionUpdateFromJson(
  Map<String, dynamic> json,
) => LiveServerSessionResumptionUpdate(
  newHandle: json['newHandle'] as String?,
  resumable: json['resumable'] as bool?,
  lastConsumedClientMessageIndex:
      (json['lastConsumedClientMessageIndex'] as num?)?.toInt(),
);

VoiceActivityDetectionSignal _$VoiceActivityDetectionSignalFromJson(
  Map<String, dynamic> json,
) => VoiceActivityDetectionSignal(
  vadSignalType: $enumDecodeNullable(
    _$VadSignalTypeEnumMap,
    json['vadSignalType'],
  ),
);

const _$VadSignalTypeEnumMap = {
  VadSignalType.VAD_SIGNAL_TYPE_UNSPECIFIED: 'VAD_SIGNAL_TYPE_UNSPECIFIED',
  VadSignalType.VAD_SIGNAL_TYPE_SOS: 'VAD_SIGNAL_TYPE_SOS',
  VadSignalType.VAD_SIGNAL_TYPE_EOS: 'VAD_SIGNAL_TYPE_EOS',
};

VoiceActivity _$VoiceActivityFromJson(Map<String, dynamic> json) =>
    VoiceActivity(
      voiceActivityType: $enumDecodeNullable(
        _$VoiceActivityTypeEnumMap,
        json['voiceActivityType'],
      ),
    );

const _$VoiceActivityTypeEnumMap = {
  VoiceActivityType.TYPE_UNSPECIFIED: 'TYPE_UNSPECIFIED',
  VoiceActivityType.ACTIVITY_START: 'ACTIVITY_START',
  VoiceActivityType.ACTIVITY_END: 'ACTIVITY_END',
};

ModalityTokenCount _$ModalityTokenCountFromJson(Map<String, dynamic> json) =>
    ModalityTokenCount(
      modality: $enumDecodeNullable(_$MediaModalityEnumMap, json['modality']),
      tokenCount: (json['tokenCount'] as num?)?.toInt(),
    );

const _$MediaModalityEnumMap = {
  MediaModality.MODALITY_UNSPECIFIED: 'MODALITY_UNSPECIFIED',
  MediaModality.TEXT: 'TEXT',
  MediaModality.IMAGE: 'IMAGE',
  MediaModality.VIDEO: 'VIDEO',
  MediaModality.AUDIO: 'AUDIO',
  MediaModality.DOCUMENT: 'DOCUMENT',
};

UsageMetadata _$UsageMetadataFromJson(
  Map<String, dynamic> json,
) => UsageMetadata(
  promptTokenCount: (json['promptTokenCount'] as num?)?.toInt(),
  cachedContentTokenCount: (json['cachedContentTokenCount'] as num?)?.toInt(),
  responseTokenCount: (json['responseTokenCount'] as num?)?.toInt(),
  toolUsePromptTokenCount: (json['toolUsePromptTokenCount'] as num?)?.toInt(),
  thoughtsTokenCount: (json['thoughtsTokenCount'] as num?)?.toInt(),
  totalTokenCount: (json['totalTokenCount'] as num?)?.toInt(),
  promptTokensDetails: (json['promptTokensDetails'] as List<dynamic>?)
      ?.map((e) => ModalityTokenCount.fromJson(e as Map<String, dynamic>))
      .toList(),
  cacheTokensDetails: (json['cacheTokensDetails'] as List<dynamic>?)
      ?.map((e) => ModalityTokenCount.fromJson(e as Map<String, dynamic>))
      .toList(),
  responseTokensDetails: (json['responseTokensDetails'] as List<dynamic>?)
      ?.map((e) => ModalityTokenCount.fromJson(e as Map<String, dynamic>))
      .toList(),
  toolUsePromptTokensDetails:
      (json['toolUsePromptTokensDetails'] as List<dynamic>?)
          ?.map((e) => ModalityTokenCount.fromJson(e as Map<String, dynamic>))
          .toList(),
  trafficType: $enumDecodeNullable(_$TrafficTypeEnumMap, json['trafficType']),
);

const _$TrafficTypeEnumMap = {
  TrafficType.TRAFFIC_TYPE_UNSPECIFIED: 'TRAFFIC_TYPE_UNSPECIFIED',
  TrafficType.ON_DEMAND: 'ON_DEMAND',
  TrafficType.PROVISIONED_THROUGHPUT: 'PROVISIONED_THROUGHPUT',
};

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
