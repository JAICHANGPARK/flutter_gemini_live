import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  group('Function and search models', () {
    test('round-trip populated client DTOs', () {
      final functionCall = FunctionCall(
        id: 'call-1',
        name: 'lookup',
        args: {'city': 'Seoul'},
      );
      expect(
        FunctionCall.fromJson(normalizeJson(functionCall.toJson())).args,
        {'city': 'Seoul'},
      );

      final responseBlob = FunctionResponseBlob(
        mimeType: 'image/png',
        data: 'base64',
      );
      expect(
        FunctionResponseBlob.fromJson(normalizeJson(responseBlob.toJson()))
            .mimeType,
        'image/png',
      );

      final fileData = FunctionResponseFileData(
        fileUri: 'gs://bucket/file',
        mimeType: 'application/pdf',
      );
      expect(
        FunctionResponseFileData.fromJson(normalizeJson(fileData.toJson()))
            .fileUri,
        'gs://bucket/file',
      );

      final responsePart = FunctionResponsePart(
        inlineData: responseBlob,
        fileData: fileData,
      );
      expect(
        FunctionResponsePart.fromJson(normalizeJson(responsePart.toJson()))
            .fileData
            ?.mimeType,
        'application/pdf',
      );

      final functionResponse = FunctionResponse(
        id: 'call-1',
        name: 'lookup',
        response: {'ok': true},
        willContinue: false,
        scheduling: FunctionResponseScheduling.WHEN_IDLE,
        parts: [responsePart],
      );
      final functionResponseRoundTrip = FunctionResponse.fromJson(
        normalizeJson(functionResponse.toJson()),
      );
      expect(functionResponseRoundTrip.scheduling, FunctionResponseScheduling.WHEN_IDLE);
      expect(functionResponseRoundTrip.parts?.single.inlineData?.data, 'base64');

      final declaration = FunctionDeclaration(
        description: 'Find a city',
        name: 'lookup',
        parameters: {
          'type': 'OBJECT',
          'properties': {
            'city': {'type': 'STRING'},
          },
        },
        parametersJsonSchema: {
          'type': 'object',
          'required': ['city'],
        },
        response: {
          'type': 'OBJECT',
          'properties': {
            'forecast': {'type': 'STRING'},
          },
        },
        responseJsonSchema: {
          'type': 'object',
          'required': ['forecast'],
        },
        behavior: Behavior.BLOCKING,
      );
      final declarationRoundTrip = FunctionDeclaration.fromJson(
        normalizeJson(declaration.toJson()),
      );
      expect(declarationRoundTrip.behavior, Behavior.BLOCKING);
      expect(
        declarationRoundTrip.parametersJsonSchema,
        {'type': 'object', 'required': ['city']},
      );

      final interval = Interval(
        startTime: DateTime.parse('2026-03-01T00:00:00Z'),
        endTime: DateTime.parse('2026-03-02T00:00:00Z'),
      );
      expect(
        Interval.fromJson(normalizeJson(interval.toJson())).endTime,
        DateTime.parse('2026-03-02T00:00:00.000Z'),
      );

      final googleSearch = GoogleSearch(
        excludeDomains: ['example.com'],
        timeRangeFilter: interval,
        blockingConfidence: 'HIGH',
      );
      expect(
        GoogleSearch.fromJson(normalizeJson(googleSearch.toJson()))
            .excludeDomains,
        ['example.com'],
      );

      final retrievalConfig = DynamicRetrievalConfig(
        dynamicThreshold: 0.6,
        mode: 'MODE_DYNAMIC',
      );
      expect(
        DynamicRetrievalConfig.fromJson(normalizeJson(retrievalConfig.toJson()))
            .mode,
        'MODE_DYNAMIC',
      );

      final searchRetrieval = GoogleSearchRetrieval(
        dynamicRetrievalConfig: retrievalConfig,
      );
      expect(
        GoogleSearchRetrieval.fromJson(normalizeJson(searchRetrieval.toJson()))
            .dynamicRetrievalConfig
            ?.dynamicThreshold,
        0.6,
      );

      final tool = Tool(
        functionDeclarations: [declaration],
        googleSearch: googleSearch,
        googleSearchRetrieval: searchRetrieval,
        codeExecution: {'enabled': true},
        urlContext: {'allowed': true},
        googleMaps: {'mode': 'drive'},
        retrieval: {'source': 'docs'},
        computerUse: {'enabled': false},
        fileSearch: {'scope': 'all'},
        enterpriseWebSearch: {'scope': 'workspace'},
        mcpServers: [
          {'name': 'server-1'},
        ],
      );
      final toolRoundTrip = Tool.fromJson(normalizeJson(tool.toJson()));
      expect(toolRoundTrip.codeExecution, {'enabled': true});
      expect(toolRoundTrip.mcpServers?.single['name'], 'server-1');
    });
  });

  group('Realtime setup models', () {
    test('round-trip setup, realtime input, and message DTOs', () {
      final automaticActivityDetection = AutomaticActivityDetection(
        disabled: false,
        startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
        endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
        prefixPaddingMs: 250,
        silenceDurationMs: 800,
      );
      final automaticRoundTrip = AutomaticActivityDetection.fromJson(
        normalizeJson(automaticActivityDetection.toJson()),
      );
      expect(
        automaticRoundTrip.startOfSpeechSensitivity,
        StartSensitivity.START_SENSITIVITY_HIGH,
      );

      final realtimeInputConfig = RealtimeInputConfig(
        automaticActivityDetection: automaticActivityDetection,
        activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
        turnCoverage: TurnCoverage.TURN_INCLUDES_ALL_INPUT,
      );
      final realtimeInputConfigRoundTrip = RealtimeInputConfig.fromJson(
        normalizeJson(realtimeInputConfig.toJson()),
      );
      expect(
        realtimeInputConfigRoundTrip.turnCoverage,
        TurnCoverage.TURN_INCLUDES_ALL_INPUT,
      );

      final sessionResumption = SessionResumptionConfig(
        handle: 'resume-token',
        transparent: true,
      );
      expect(
        SessionResumptionConfig.fromJson(normalizeJson(sessionResumption.toJson()))
            .transparent,
        true,
      );

      final slidingWindow = SlidingWindow(targetTokens: '2048');
      expect(
        SlidingWindow.fromJson(normalizeJson(slidingWindow.toJson()))
            .targetTokens,
        '2048',
      );

      final compressionConfig = ContextWindowCompressionConfig(
        triggerTokens: '4096',
        slidingWindow: slidingWindow,
      );
      expect(
        ContextWindowCompressionConfig.fromJson(
          normalizeJson(compressionConfig.toJson()),
        )
            .slidingWindow
            ?.targetTokens,
        '2048',
      );

      final inputTranscription = AudioTranscriptionConfig();
      expect(
        AudioTranscriptionConfig.fromJson(
          normalizeJson(inputTranscription.toJson()),
        ),
        isA<AudioTranscriptionConfig>(),
      );

      final proactivity = ProactivityConfig(proactiveAudio: true);
      expect(
        ProactivityConfig.fromJson(normalizeJson(proactivity.toJson()))
            .proactiveAudio,
        true,
      );

      final generationConfig = GenerationConfig(
        temperature: 0.8,
        topK: 16,
        topP: 0.9,
        maxOutputTokens: 1024,
        responseModalities: [Modality.TEXT, Modality.AUDIO],
        mediaResolution: MediaResolution.MEDIA_RESOLUTION_HIGH,
        seed: 7,
        speechConfig: SpeechConfig(
          voiceConfig: VoiceConfig(
            prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: 'Aoede'),
          ),
          languageCode: 'ko-KR',
        ),
        thinkingConfig: ThinkingConfig(
          includeThoughts: true,
          thinkingBudget: 2048,
        ),
        enableAffectiveDialog: true,
      );

      final tool = Tool(
        functionDeclarations: [
          FunctionDeclaration(name: 'lookup', behavior: Behavior.NON_BLOCKING),
        ],
      );

      final setup = LiveClientSetup(
        model: 'models/gemini-live',
        generationConfig: generationConfig,
        systemInstruction: Content(
          role: 'system',
          parts: [Part(text: 'be concise')],
        ),
        tools: [tool],
        realtimeInputConfig: realtimeInputConfig,
        sessionResumption: sessionResumption,
        contextWindowCompression: compressionConfig,
        inputAudioTranscription: inputTranscription,
        outputAudioTranscription: AudioTranscriptionConfig(),
        proactivity: proactivity,
        explicitVadSignal: true,
      );
      final setupRoundTrip = LiveClientSetup.fromJson(normalizeJson(setup.toJson()));
      expect(setupRoundTrip.model, 'models/gemini-live');
      expect(setupRoundTrip.proactivity?.proactiveAudio, true);

      final clientContent = LiveClientContent(
        turns: [
          Content(
            role: 'user',
            parts: [Part(text: 'hello')],
          ),
        ],
        turnComplete: false,
      );
      expect(
        LiveClientContent.fromJson(normalizeJson(clientContent.toJson()))
            .turnComplete,
        false,
      );

      final activityStart = ActivityStart();
      final activityEnd = ActivityEnd();
      expect(
        ActivityStart.fromJson(normalizeJson(activityStart.toJson())),
        isA<ActivityStart>(),
      );
      expect(
        ActivityEnd.fromJson(normalizeJson(activityEnd.toJson())),
        isA<ActivityEnd>(),
      );

      final realtimeInput = LiveClientRealtimeInput(
        mediaChunks: [Blob(mimeType: 'image/jpeg', data: 'chunk')],
        audio: Blob(mimeType: 'audio/pcm', data: 'audio'),
        video: Blob(mimeType: 'image/png', data: 'video'),
        audioStreamEnd: true,
        text: 'say hi',
        activityStart: activityStart,
        activityEnd: activityEnd,
      );
      final realtimeInputRoundTrip = LiveClientRealtimeInput.fromJson(
        normalizeJson(realtimeInput.toJson()),
      );
      expect(realtimeInputRoundTrip.mediaChunks?.single.data, 'chunk');
      expect(realtimeInputRoundTrip.activityEnd, isA<ActivityEnd>());

      final toolResponse = LiveClientToolResponse(
        functionResponses: [
          FunctionResponse(
            id: 'call-2',
            name: 'lookup',
            response: {'status': 'ok'},
            scheduling: FunctionResponseScheduling.SILENT,
          ),
        ],
      );
      expect(
        LiveClientToolResponse.fromJson(normalizeJson(toolResponse.toJson()))
            .functionResponses
            ?.single
            .response,
        {'status': 'ok'},
      );

      final message = LiveClientMessage(
        setup: setup,
        clientContent: clientContent,
        realtimeInput: realtimeInput,
        toolResponse: toolResponse,
      );
      final messageRoundTrip = LiveClientMessage.fromJson(
        normalizeJson(message.toJson()),
      );
      expect(messageRoundTrip.setup?.model, 'models/gemini-live');
      expect(messageRoundTrip.clientContent?.turns?.single.role, 'user');
      expect(messageRoundTrip.realtimeInput?.text, 'say hi');
      expect(
        messageRoundTrip.toolResponse?.functionResponses?.single.scheduling,
        FunctionResponseScheduling.SILENT,
      );
    });
  });

  group('Server models and derived helpers', () {
    test('parse server DTOs with nested content and metadata', () {
      final transcription = Transcription(text: 'heard', finished: true);
      expect(transcription.text, 'heard');
      expect(
        Transcription.fromJson({'text': 'heard', 'finished': true}).finished,
        true,
      );

      final executableCode = ExecutableCode(language: 'python', code: 'print(1)');
      expect(
        ExecutableCode.fromJson(normalizeJson(executableCode.toJson())).language,
        'python',
      );

      final codeExecutionResult = CodeExecutionResult(
        outcome: 'OUTCOME_OK',
        output: '1',
      );
      expect(
        CodeExecutionResult.fromJson(normalizeJson(codeExecutionResult.toJson()))
            .output,
        '1',
      );

      final setupComplete = LiveServerSetupComplete(sessionId: 'server-session');
      expect(setupComplete.sessionId, 'server-session');

      final toolCancellation = LiveServerToolCallCancellation(ids: ['call-1']);
      expect(toolCancellation.ids, ['call-1']);
      expect(
        LiveServerToolCallCancellation.fromJson({
          'ids': ['call-1'],
        }).ids,
        ['call-1'],
      );

      final goAway = LiveServerGoAway(timeLeft: '45s', reason: 'rotate');
      expect(goAway.reason, 'rotate');
      expect(
        LiveServerGoAway.fromJson({'timeLeft': '45s', 'reason': 'rotate'}).timeLeft,
        '45s',
      );

      final sessionUpdate = LiveServerSessionResumptionUpdate(
        newHandle: 'new-handle',
        resumable: true,
        lastConsumedClientMessageIndex: 5,
      );
      expect(sessionUpdate.newHandle, 'new-handle');

      final toolCall = LiveServerToolCall(
        functionCalls: [
          FunctionCall(id: 'call-1', name: 'lookup', args: {'city': 'Seoul'}),
        ],
      );
      expect(toolCall.functionCalls?.single.name, 'lookup');

      final voiceSignal = VoiceActivityDetectionSignal.fromJson({
        'vadSignalType': 'VAD_SIGNAL_TYPE_EOS',
      });
      expect(voiceSignal.end, true);

      final endedVoiceActivity = VoiceActivity.fromJson({
        'voiceActivityType': 'ACTIVITY_END',
      });
      expect(endedVoiceActivity.speechActive, false);

      final unspecifiedVoiceActivity = VoiceActivity(
        voiceActivityType: VoiceActivityType.TYPE_UNSPECIFIED,
      );
      expect(unspecifiedVoiceActivity.speechActive, isNull);

      final modalityTokenCount = ModalityTokenCount(
        modality: MediaModality.DOCUMENT,
        tokenCount: 4,
      );
      expect(modalityTokenCount.modality, MediaModality.DOCUMENT);

      final usageMetadata = UsageMetadata.fromJson({
        'promptTokenCount': 1,
        'cachedContentTokenCount': 2,
        'responseTokenCount': 3,
        'toolUsePromptTokenCount': 4,
        'thoughtsTokenCount': 5,
        'totalTokenCount': 6,
        'promptTokensDetails': [
          {'modality': 'TEXT', 'tokenCount': 1},
        ],
        'cacheTokensDetails': [
          {'modality': 'IMAGE', 'tokenCount': 2},
        ],
        'responseTokensDetails': [
          {'modality': 'AUDIO', 'tokenCount': 3},
        ],
        'toolUsePromptTokensDetails': [
          {'modality': 'DOCUMENT', 'tokenCount': 4},
        ],
        'trafficType': 'PROVISIONED_THROUGHPUT',
      });
      expect(usageMetadata.cacheTokensDetails?.single.modality, MediaModality.IMAGE);
      expect(
        usageMetadata.toolUsePromptTokensDetails?.single.modality,
        MediaModality.DOCUMENT,
      );
      expect(usageMetadata.trafficType, TrafficType.PROVISIONED_THROUGHPUT);

      final message = LiveServerMessage.fromJson({
        'setupComplete': {'sessionId': 'server-session'},
        'serverContent': {
          'modelTurn': {
            'parts': [
              {
                'text': 'visible',
                'thought': false,
                'inlineData': {'mimeType': 'audio/pcm', 'data': 'bytes1'},
                'functionCall': {
                  'id': 'call-1',
                  'name': 'lookup',
                  'args': {'city': 'Seoul'},
                },
                'functionResponse': {
                  'id': 'call-1',
                  'name': 'lookup',
                  'response': {'status': 'ok'},
                  'will_continue': false,
                  'scheduling': 'INTERRUPT',
                  'parts': [
                    {
                      'inline_data': {
                        'mime_type': 'image/png',
                        'data': 'raw',
                      },
                      'file_data': {
                        'file_uri': 'gs://bucket/report.pdf',
                        'mime_type': 'application/pdf',
                      },
                    },
                  ],
                },
                'executableCode': {
                  'language': 'python',
                  'code': 'print(1)',
                },
                'codeExecutionResult': {
                  'outcome': 'OUTCOME_OK',
                  'output': '1',
                },
              },
              {
                'text': 'hidden',
                'thought': true,
              },
              {
                'inlineData': {'mimeType': 'audio/pcm', 'data': 'bytes2'},
              },
            ],
            'role': 'model',
          },
          'turnComplete': true,
          'interrupted': false,
          'groundingMetadata': {'source': 'web'},
          'inputTranscription': {'text': 'input', 'finished': true},
          'outputTranscription': {'text': 'output', 'finished': true},
          'generationComplete': true,
          'urlContextMetadata': {'url': 'https://example.com'},
          'turnCompleteReason': 'NEED_MORE_INPUT',
          'waitingForInput': true,
        },
        'usageMetadata': {
          'promptTokenCount': 1,
          'cachedContentTokenCount': 2,
          'responseTokenCount': 3,
          'toolUsePromptTokenCount': 4,
          'thoughtsTokenCount': 5,
          'totalTokenCount': 6,
          'promptTokensDetails': [
            {'modality': 'TEXT', 'tokenCount': 1},
          ],
          'cacheTokensDetails': [
            {'modality': 'IMAGE', 'tokenCount': 2},
          ],
          'responseTokensDetails': [
            {'modality': 'AUDIO', 'tokenCount': 3},
          ],
          'toolUsePromptTokensDetails': [
            {'modality': 'DOCUMENT', 'tokenCount': 4},
          ],
          'trafficType': 'PROVISIONED_THROUGHPUT',
        },
        'toolCall': {
          'functionCalls': [
            {
              'id': 'call-1',
              'name': 'lookup',
              'args': {'city': 'Seoul'},
            },
          ],
        },
        'toolCallCancellation': {
          'ids': ['call-1'],
        },
        'goAway': {'timeLeft': '45s', 'reason': 'rotate'},
        'sessionResumptionUpdate': {
          'newHandle': 'new-handle',
          'resumable': true,
          'lastConsumedClientMessageIndex': 5,
        },
        'voiceActivityDetectionSignal': {
          'vadSignalType': 'VAD_SIGNAL_TYPE_EOS',
        },
        'voiceActivity': {
          'voiceActivityType': 'ACTIVITY_END',
        },
      });

      expect(message.setupComplete?.sessionId, 'server-session');
      expect(message.serverContent?.turnCompleteReason, TurnCompleteReason.NEED_MORE_INPUT);
      expect(
        message.serverContent?.inputTranscription?.finished,
        true,
      );
      expect(message.toolCall?.functionCalls?.single.args, {'city': 'Seoul'});
      expect(message.toolCallCancellation?.ids, ['call-1']);
      expect(message.goAway?.timeRemaining, 45);
      expect(message.sessionResumptionUpdate?.lastConsumedClientMessageIndex, 5);
      expect(message.voiceActivityDetectionSignal?.end, true);
      expect(message.voiceActivity?.speechActive, false);
      expect(message.usageMetadata?.trafficType, TrafficType.PROVISIONED_THROUGHPUT);
      expect(message.text, 'visible');
      expect(message.data, 'bytes1bytes2');
      expect(
        message.serverContent?.modelTurn?.parts?.first.functionResponse?.parts?.single.fileData?.fileUri,
        'gs://bucket/report.pdf',
      );
    });

    test('derived getters return null for empty and invalid cases', () {
      final emptyMessage = LiveServerMessage(
        serverContent: LiveServerContent(modelTurn: Content(parts: [])),
      );
      expect(emptyMessage.text, isNull);
      expect(emptyMessage.data, isNull);

      final thoughtOnly = LiveServerMessage(
        serverContent: LiveServerContent(
          modelTurn: Content(
            parts: [
              Part(thought: true, text: 'hidden'),
            ],
          ),
        ),
      );
      expect(thoughtOnly.text, isNull);

      final textOnly = LiveServerMessage(
        serverContent: LiveServerContent(
          modelTurn: Content(
            parts: [
              Part(text: 'visible'),
            ],
          ),
        ),
      );
      expect(textOnly.data, isNull);

      expect(LiveServerGoAway(timeLeft: null).timeRemaining, isNull);
      expect(LiveServerGoAway(timeLeft: 'soon').timeRemaining, isNull);
    });
  });

  test('send parameter containers retain constructor arguments', () {
    final sendClientContent = LiveSendClientContentParameters(
      turns: [Content(parts: [Part(text: 'hello')])],
    );
    final sendRealtimeInput = LiveSendRealtimeInputParameters(
      mediaChunks: [Blob(mimeType: 'image/png', data: 'raw')],
      audio: Blob(mimeType: 'audio/pcm', data: 'audio'),
      video: Blob(mimeType: 'image/png', data: 'video'),
      text: 'hello',
      audioStreamEnd: true,
      activityStart: true,
      activityEnd: false,
    );
    final sendToolResponse = LiveSendToolResponseParameters(
      functionResponses: [
        FunctionResponse(name: 'lookup', response: {'ok': true}),
      ],
    );

    expect(sendClientContent.turnComplete, true);
    expect(sendRealtimeInput.audio?.data, 'audio');
    expect(sendRealtimeInput.activityEnd, false);
    expect(sendToolResponse.functionResponses.single.response, {'ok': true});
  });
}

Map<String, dynamic> normalizeJson(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
