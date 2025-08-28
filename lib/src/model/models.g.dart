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

LiveClientRealtimeInput _$LiveClientRealtimeInputFromJson(
  Map<String, dynamic> json,
) => LiveClientRealtimeInput(
  audio: json['audio'] == null
      ? null
      : Blob.fromJson(json['audio'] as Map<String, dynamic>),
  video: json['video'] == null
      ? null
      : Blob.fromJson(json['video'] as Map<String, dynamic>),
  audioStreamEnd: json['audio_stream_end'] as bool?,
  activityEnd: json['activity_end'] == null
      ? null
      : ActivityEnd.fromJson(json['activity_end'] as Map<String, dynamic>),
  activityStart: json['activity_start'] == null
      ? null
      : ActivityStart.fromJson(json['activity_start'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LiveClientRealtimeInputToJson(
  LiveClientRealtimeInput instance,
) => <String, dynamic>{
  'audio': ?instance.audio,
  'video': ?instance.video,
  'audio_stream_end': ?instance.audioStreamEnd,
  'activity_start': ?instance.activityStart,
  'activity_end': ?instance.activityEnd,
};

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

LiveServerMessage _$LiveServerMessageFromJson(Map<String, dynamic> json) =>
    LiveServerMessage(
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
          : UsageMetadata.fromJson(
              json['usageMetadata'] as Map<String, dynamic>,
            ),
      toolCall: json['toolCall'] == null
          ? null
          : ToolCall.fromJson(json['toolCall'] as Map<String, dynamic>),
      goAway: json['goAway'] == null
          ? null
          : LiveServerGoAway.fromJson(json['goAway'] as Map<String, dynamic>),
      sessionResumptionUpdate: json['sessionResumptionUpdate'] == null
          ? null
          : LiveServerSessionResumptionUpdate.fromJson(
              json['sessionResumptionUpdate'] as Map<String, dynamic>,
            ),
      toolCallCancellation: json['toolCallCancellation'] == null
          ? null
          : LiveServerToolCallCancellation.fromJson(
              json['toolCallCancellation'] as Map<String, dynamic>,
            ),
    );

UsageMetadata _$UsageMetadataFromJson(Map<String, dynamic> json) =>
    UsageMetadata(
      promptTokenCount: (json['promptTokenCount'] as num).toInt(),
      responseTokenCount: (json['responseTokenCount'] as num).toInt(),
      totalTokenCount: (json['totalTokenCount'] as num).toInt(),
    );

Tool _$ToolFromJson(Map<String, dynamic> json) => Tool(
  functionDeclarations:
      (json['functionDeclarations'] as List<dynamic>?)
          ?.map((e) => FunctionDeclaration.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ToolToJson(Tool instance) => <String, dynamic>{
  'functionDeclarations': instance.functionDeclarations,
};

ToolCall _$ToolCallFromJson(Map<String, dynamic> json) => ToolCall(
  functionCalls:
      (json['functionCalls'] as List<dynamic>?)
          ?.map((e) => FunctionCall.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ToolCallToJson(ToolCall instance) => <String, dynamic>{
  'functionCalls': instance.functionCalls,
};
