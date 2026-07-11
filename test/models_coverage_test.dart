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
        partialArgs: [
          PartialArg(
            jsonPath: r'$.city',
            stringValue: 'Seo',
            willContinue: true,
          ),
        ],
        willContinue: true,
      );
      expect(FunctionCall.fromJson(normalizeJson(functionCall.toJson())).args, {
        'city': 'Seoul',
      });
      expect(
        FunctionCall.fromJson(
          normalizeJson(functionCall.toJson()),
        ).partialArgs?.single.stringValue,
        'Seo',
      );

      final responseBlob = FunctionResponseBlob(
        mimeType: 'image/png',
        data: 'base64',
        displayName: 'image.png',
      );
      expect(
        FunctionResponseBlob.fromJson(
          normalizeJson(responseBlob.toJson()),
        ).displayName,
        'image.png',
      );

      final fileData = FunctionResponseFileData(
        fileUri: 'gs://bucket/file',
        mimeType: 'application/pdf',
        displayName: 'file.pdf',
      );
      expect(
        FunctionResponseFileData.fromJson(
          normalizeJson(fileData.toJson()),
        ).displayName,
        'file.pdf',
      );

      final responsePart = FunctionResponsePart(
        inlineData: responseBlob,
        fileData: fileData,
      );
      expect(
        FunctionResponsePart.fromJson(
          normalizeJson(responsePart.toJson()),
        ).fileData?.mimeType,
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
      expect(
        functionResponseRoundTrip.scheduling,
        FunctionResponseScheduling.WHEN_IDLE,
      );
      expect(
        functionResponseRoundTrip.parts?.single.inlineData?.data,
        'base64',
      );

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
      expect(declarationRoundTrip.parametersJsonSchema, {
        'type': 'object',
        'required': ['city'],
      });

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
        GoogleSearch.fromJson(
          normalizeJson(googleSearch.toJson()),
        ).excludeDomains,
        ['example.com'],
      );

      final retrievalConfig = DynamicRetrievalConfig(
        dynamicThreshold: 0.6,
        mode: 'MODE_DYNAMIC',
      );
      expect(
        DynamicRetrievalConfig.fromJson(
          normalizeJson(retrievalConfig.toJson()),
        ).mode,
        'MODE_DYNAMIC',
      );

      final searchRetrieval = GoogleSearchRetrieval(
        dynamicRetrievalConfig: retrievalConfig,
      );
      expect(
        GoogleSearchRetrieval.fromJson(
          normalizeJson(searchRetrieval.toJson()),
        ).dynamicRetrievalConfig?.dynamicThreshold,
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

      final typedComputerUseTool = Tool(
        computerUse: ComputerUse(
          environment: Environment.ENVIRONMENT_BROWSER,
          excludedPredefinedFunctions: ['drag_and_drop'],
          enablePromptInjectionDetection: true,
        ),
      );
      final typedComputerUseJson = typedComputerUseTool.toJson();
      expect(
        typedComputerUseJson['computer_use']['enable_prompt_injection_detection'],
        true,
      );
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
        turnCoverage: TurnCoverage.TURN_INCLUDES_AUDIO_ACTIVITY_AND_ALL_VIDEO,
      );
      final realtimeInputConfigRoundTrip = RealtimeInputConfig.fromJson(
        normalizeJson(realtimeInputConfig.toJson()),
      );
      expect(
        realtimeInputConfigRoundTrip.turnCoverage,
        TurnCoverage.TURN_INCLUDES_AUDIO_ACTIVITY_AND_ALL_VIDEO,
      );

      final sessionResumption = SessionResumptionConfig(
        handle: 'resume-token',
        transparent: true,
      );
      expect(
        SessionResumptionConfig.fromJson(
          normalizeJson(sessionResumption.toJson()),
        ).transparent,
        true,
      );

      final slidingWindow = SlidingWindow(targetTokens: '2048');
      expect(
        SlidingWindow.fromJson(
          normalizeJson(slidingWindow.toJson()),
        ).targetTokens,
        '2048',
      );

      final compressionConfig = ContextWindowCompressionConfig(
        triggerTokens: '4096',
        slidingWindow: slidingWindow,
      );
      expect(
        ContextWindowCompressionConfig.fromJson(
          normalizeJson(compressionConfig.toJson()),
        ).slidingWindow?.targetTokens,
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
        ProactivityConfig.fromJson(
          normalizeJson(proactivity.toJson()),
        ).proactiveAudio,
        true,
      );

      final generationConfig = GenerationConfig(
        temperature: 0.8,
        topK: 16,
        topP: 0.9,
        maxOutputTokens: 1024,
        responseModalities: [Modality.TEXT, Modality.AUDIO, Modality.VIDEO],
        mediaResolution: MediaResolution.MEDIA_RESOLUTION_HIGH,
        seed: 7,
        speechConfig: SpeechConfig(
          voiceConfig: VoiceConfig(
            replicatedVoiceConfig: ReplicatedVoiceConfig(
              mimeType: 'audio/wav',
              voiceSampleAudio: 'c2FtcGxl',
            ),
            prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: 'Aoede'),
          ),
          languageCode: 'ko-KR',
          multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig(
            speakerVoiceConfigs: [
              SpeakerVoiceConfig(
                speaker: 'A',
                voiceConfig: VoiceConfig(
                  prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: 'Kore'),
                ),
              ),
              SpeakerVoiceConfig(
                speaker: 'B',
                voiceConfig: VoiceConfig(
                  prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: 'Puck'),
                ),
              ),
            ],
          ),
        ),
        thinkingConfig: ThinkingConfig(
          includeThoughts: true,
          thinkingBudget: 2048,
          thinkingLevel: ThinkingLevel.MEDIUM,
        ),
        enableAffectiveDialog: true,
        translationConfig: TranslationConfig(
          echoTargetLanguage: true,
          targetLanguageCode: 'en',
        ),
      );

      final tool = Tool(
        functionDeclarations: [
          FunctionDeclaration(name: 'lookup', behavior: Behavior.NON_BLOCKING),
        ],
      );
      final avatarConfig = AvatarConfig(
        avatarName: 'hero',
        customizedAvatar: CustomizedAvatar(
          imageMimeType: 'image/jpeg',
          imageData: 'aW1hZ2U=',
        ),
        audioBitrateBps: 64000,
        videoBitrateBps: 1500000,
      );
      final safetySettings = [
        SafetySetting(
          category: HarmCategory.HARM_CATEGORY_HARASSMENT,
          threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH,
        ),
      ];

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
        avatarConfig: avatarConfig,
        safetySettings: safetySettings,
      );
      final setupRoundTrip = LiveClientSetup.fromJson(
        normalizeJson(setup.toJson()),
      );
      expect(setupRoundTrip.model, 'models/gemini-live');
      expect(setupRoundTrip.proactivity?.proactiveAudio, true);
      expect(setupRoundTrip.generationConfig?.responseModalities, [
        Modality.TEXT,
        Modality.AUDIO,
        Modality.VIDEO,
      ]);
      expect(
        setupRoundTrip
            .generationConfig
            ?.speechConfig
            ?.voiceConfig
            ?.replicatedVoiceConfig
            ?.mimeType,
        'audio/wav',
      );
      expect(
        setupRoundTrip
            .generationConfig
            ?.speechConfig
            ?.multiSpeakerVoiceConfig
            ?.speakerVoiceConfigs
            ?.last
            .speaker,
        'B',
      );
      expect(
        setupRoundTrip.generationConfig?.thinkingConfig?.thinkingLevel,
        ThinkingLevel.MEDIUM,
      );
      expect(
        setupRoundTrip
            .generationConfig
            ?.translationConfig
            ?.targetLanguageCode,
        'en',
      );
      expect(setupRoundTrip.avatarConfig?.avatarName, 'hero');
      expect(
        setupRoundTrip.avatarConfig?.customizedAvatar?.imageMimeType,
        'image/jpeg',
      );
      expect(
        setupRoundTrip.safetySettings?.single.threshold,
        HarmBlockThreshold.BLOCK_ONLY_HIGH,
      );

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
        LiveClientContent.fromJson(
          normalizeJson(clientContent.toJson()),
        ).turnComplete,
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
        LiveClientToolResponse.fromJson(
          normalizeJson(toolResponse.toJson()),
        ).functionResponses?.single.response,
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

      final executableCode = ExecutableCode(
        language: 'python',
        code: 'print(1)',
        id: 'exec-1',
      );
      expect(
        ExecutableCode.fromJson(normalizeJson(executableCode.toJson())).id,
        'exec-1',
      );
      expect(
        ExecutableCode.fromJson(
          normalizeJson(executableCode.toJson()),
        ).language,
        'python',
      );

      final codeExecutionResult = CodeExecutionResult(
        outcome: 'OUTCOME_OK',
        output: '1',
        id: 'exec-1',
      );
      expect(
        CodeExecutionResult.fromJson(
          normalizeJson(codeExecutionResult.toJson()),
        ).id,
        'exec-1',
      );
      expect(
        CodeExecutionResult.fromJson(
          normalizeJson(codeExecutionResult.toJson()),
        ).output,
        '1',
      );

      final setupComplete = LiveServerSetupComplete(
        sessionId: 'server-session',
      );
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
        LiveServerGoAway.fromJson({
          'timeLeft': '45s',
          'reason': 'rotate',
        }).timeLeft,
        '45s',
      );

      final sessionUpdate = LiveServerSessionResumptionUpdate(
        newHandle: 'new-handle',
        resumable: true,
        lastConsumedClientMessageIndex: '5',
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
      expect(
        usageMetadata.cacheTokensDetails?.single.modality,
        MediaModality.IMAGE,
      );
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
                'inlineData': {'mimeType': 'audio/pcm', 'data': 'Ynl0ZXMx'},
                'functionCall': {
                  'id': 'call-1',
                  'name': 'lookup',
                  'args': {'city': 'Seoul'},
                  'partial_args': [
                    {
                      'json_path': r'$.city',
                      'string_value': 'Seoul',
                      'will_continue': false,
                    },
                  ],
                  'will_continue': false,
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
                        'display_name': 'image.png',
                      },
                      'file_data': {
                        'file_uri': 'gs://bucket/report.pdf',
                        'mime_type': 'application/pdf',
                        'display_name': 'report.pdf',
                      },
                    },
                  ],
                },
                'executableCode': {
                  'language': 'python',
                  'code': 'print(1)',
                  'id': 'exec-1',
                },
                'codeExecutionResult': {
                  'outcome': 'OUTCOME_OK',
                  'output': '1',
                  'id': 'exec-1',
                },
              },
              {'text': 'hidden', 'thought': true},
              {
                'inlineData': {'mimeType': 'audio/pcm', 'data': 'Ynl0ZXMy'},
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
          'turnCompleteReason': 'GENERATED_VIDEO_SAFETY',
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
              'partial_args': [
                {
                  'json_path': r'$.city',
                  'string_value': 'Seoul',
                  'will_continue': false,
                },
              ],
              'will_continue': false,
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
          'lastConsumedClientMessageIndex': '5',
        },
        'voiceActivityDetectionSignal': {
          'vadSignalType': 'VAD_SIGNAL_TYPE_EOS',
        },
        'voiceActivity': {'voiceActivityType': 'ACTIVITY_END'},
      });

      expect(message.setupComplete?.sessionId, 'server-session');
      expect(
        message.serverContent?.turnCompleteReason,
        TurnCompleteReason.GENERATED_VIDEO_SAFETY,
      );
      expect(message.serverContent?.inputTranscription?.finished, true);
      expect(message.toolCall?.functionCalls?.single.args, {'city': 'Seoul'});
      expect(
        message.toolCall?.functionCalls?.single.partialArgs?.single.jsonPath,
        r'$.city',
      );
      expect(message.toolCallCancellation?.ids, ['call-1']);
      expect(message.goAway?.timeRemaining, 45);
      expect(
        message.sessionResumptionUpdate?.lastConsumedClientMessageIndex,
        '5',
      );
      expect(message.voiceActivityDetectionSignal?.end, true);
      expect(message.voiceActivity?.speechActive, false);
      expect(
        message.usageMetadata?.trafficType,
        TrafficType.PROVISIONED_THROUGHPUT,
      );
      expect(message.text, 'visible');
      expect(message.data, 'Ynl0ZXMxYnl0ZXMy');
      expect(
        message
            .serverContent
            ?.modelTurn
            ?.parts
            ?.first
            .functionResponse
            ?.parts
            ?.single
            .fileData
            ?.fileUri,
        'gs://bucket/report.pdf',
      );
      expect(
        message
            .serverContent
            ?.modelTurn
            ?.parts
            ?.first
            .functionResponse
            ?.parts
            ?.single
            .inlineData
            ?.displayName,
        'image.png',
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
          modelTurn: Content(parts: [Part(thought: true, text: 'hidden')]),
        ),
      );
      expect(thoughtOnly.text, isNull);

      final textOnly = LiveServerMessage(
        serverContent: LiveServerContent(
          modelTurn: Content(parts: [Part(text: 'visible')]),
        ),
      );
      expect(textOnly.data, isNull);

      expect(LiveServerGoAway(timeLeft: null).timeRemaining, isNull);
      expect(LiveServerGoAway(timeLeft: 'soon').timeRemaining, isNull);
    });
  });

  group('js-genai 2.11.0 sync', () {
    test('TranslationConfig serializes under translation_config', () {
      final config = GenerationConfig(
        translationConfig: TranslationConfig(
          echoTargetLanguage: true,
          targetLanguageCode: 'es',
        ),
      );
      final json = normalizeJson(config.toJson());
      expect(json['translation_config'], {
        'echo_target_language': true,
        'target_language_code': 'es',
      });

      final roundTrip = GenerationConfig.fromJson(json);
      expect(roundTrip.translationConfig?.targetLanguageCode, 'es');
      expect(roundTrip.translationConfig?.echoTargetLanguage, true);
    });

    test('AudioTranscriptionConfig serializes new language options', () {
      final config = AudioTranscriptionConfig(
        languageAuto: LanguageAuto(),
        adaptationPhrases: ['Gemini', 'Vertex'],
      );
      final json = normalizeJson(config.toJson());
      expect(json['language_auto'], <String, dynamic>{});
      expect(json['adaptation_phrases'], ['Gemini', 'Vertex']);

      final roundTrip = AudioTranscriptionConfig.fromJson(json);
      expect(roundTrip.languageAuto, isA<LanguageAuto>());
      expect(roundTrip.adaptationPhrases, ['Gemini', 'Vertex']);

      final hintsConfig = AudioTranscriptionConfig(
        languageHints: LanguageHints(languageCodes: ['en', 'ko']),
      );
      final hintsJson = normalizeJson(hintsConfig.toJson());
      expect(hintsJson['language_hints'], {
        'language_codes': ['en', 'ko'],
      });
      expect(
        AudioTranscriptionConfig.fromJson(
          hintsJson,
        ).languageHints?.languageCodes,
        ['en', 'ko'],
      );
    });

    test('ReplicatedVoiceConfig serializes consent fields', () {
      final config = ReplicatedVoiceConfig(
        mimeType: 'audio/wav',
        voiceSampleAudio: 'c2FtcGxl',
        consentAudio: 'Y29uc2VudA==',
        voiceConsentSignature: VoiceConsentSignature(signature: 'sig-123'),
      );
      final json = normalizeJson(config.toJson());
      expect(json['consent_audio'], 'Y29uc2VudA==');
      expect(json['voice_consent_signature'], {'signature': 'sig-123'});

      final roundTrip = ReplicatedVoiceConfig.fromJson(json);
      expect(roundTrip.consentAudio, 'Y29uc2VudA==');
      expect(roundTrip.voiceConsentSignature?.signature, 'sig-123');
    });

    test('ComputerUse serializes disabledSafetyPolicies', () {
      final config = ComputerUse(
        environment: Environment.ENVIRONMENT_BROWSER,
        disabledSafetyPolicies: [
          SafetyPolicy.FINANCIAL_TRANSACTIONS,
          SafetyPolicy.DATA_MODIFICATION,
        ],
      );
      final json = normalizeJson(config.toJson());
      expect(json['disabled_safety_policies'], [
        'FINANCIAL_TRANSACTIONS',
        'DATA_MODIFICATION',
      ]);

      final roundTrip = ComputerUse.fromJson(json);
      expect(roundTrip.disabledSafetyPolicies, [
        SafetyPolicy.FINANCIAL_TRANSACTIONS,
        SafetyPolicy.DATA_MODIFICATION,
      ]);
    });

    test('Tool serializes exaAiSearch', () {
      final tool = Tool(
        exaAiSearch: ToolExaAiSearch(
          apiKey: 'exa-key',
          customConfigs: {'numResults': 5},
        ),
      );
      final json = normalizeJson(tool.toJson());
      expect(json['exa_ai_search'], {
        'api_key': 'exa-key',
        'custom_configs': {'numResults': 5},
      });

      final roundTrip = Tool.fromJson(json);
      expect(roundTrip.exaAiSearch?.apiKey, 'exa-key');
      expect(roundTrip.exaAiSearch?.customConfigs, {'numResults': 5});
    });

    test('server fields parse from camelCase JSON', () {
      final setupComplete = LiveServerSetupComplete.fromJson({
        'sessionId': 'sess-1',
        'voiceConsentSignature': {'signature': 'server-sig'},
      });
      expect(setupComplete.voiceConsentSignature?.signature, 'server-sig');

      final transcription = Transcription.fromJson({
        'text': 'hola',
        'finished': true,
        'languageCode': 'es',
      });
      expect(transcription.languageCode, 'es');

      final serverContent = LiveServerContent.fromJson({
        'interimInputTranscription': {
          'text': 'partial',
          'finished': false,
          'languageCode': 'en',
        },
      });
      expect(serverContent.interimInputTranscription?.text, 'partial');
      expect(serverContent.interimInputTranscription?.languageCode, 'en');

      final voiceActivity = VoiceActivity.fromJson({
        'voiceActivityType': 'ACTIVITY_START',
        'audioOffset': '1.5s',
      });
      expect(voiceActivity.audioOffset, '1.5s');
      expect(voiceActivity.speechActive, true);

      final usageMetadata = UsageMetadata.fromJson({
        'totalTokenCount': 10,
        'serviceTier': 'flex',
      });
      expect(usageMetadata.serviceTier, ServiceTier.FLEX);
    });

    test('deprecated StreamTranslationConfig alias still works', () {
      // ignore: deprecated_member_use_from_same_package
      final StreamTranslationConfig legacy = StreamTranslationConfig(
        targetLanguageCode: 'fr',
      );
      final config = GenerationConfig(translationConfig: legacy);
      // ignore: deprecated_member_use_from_same_package
      expect(config.streamTranslationConfig?.targetLanguageCode, 'fr');
    });
  });

  test('send parameter containers retain constructor arguments', () {
    final sendClientContent = LiveSendClientContentParameters(
      turns: [
        Content(parts: [Part(text: 'hello')]),
      ],
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
