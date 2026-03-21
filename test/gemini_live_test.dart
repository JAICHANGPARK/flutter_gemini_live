import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  group('Live Models', () {
    test('buildSetupMessage normalizes model and defaults to AUDIO output', () {
      final message = LiveService.buildSetupMessage(
        LiveConnectParameters(
          model: 'gemini-live-2.5-flash-preview',
          callbacks: LiveCallbacks(),
        ),
      );

      expect(message.setup?.model, 'models/gemini-live-2.5-flash-preview');
      expect(message.setup?.generationConfig?.responseModalities, [
        Modality.AUDIO,
      ]);
    });

    test('buildSetupMessage keeps existing generation config values', () {
      final message = LiveService.buildSetupMessage(
        LiveConnectParameters(
          model: 'models/gemini-live-2.5-flash-preview',
          callbacks: LiveCallbacks(),
          config: GenerationConfig(
            temperature: 0.4,
            responseModalities: [Modality.TEXT],
          ),
        ),
      );

      expect(message.setup?.generationConfig?.temperature, 0.4);
      expect(message.setup?.generationConfig?.responseModalities, [
        Modality.TEXT,
      ]);
    });

    test('buildSetupMessage rejects transparent session resumption', () {
      expect(
        () => LiveService.buildSetupMessage(
          LiveConnectParameters(
            model: 'models/gemini-live-2.5-flash-preview',
            callbacks: LiveCallbacks(),
            sessionResumption: SessionResumptionConfig(
              handle: 'handle',
              transparent: true,
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            'transparent parameter is not supported in Gemini API.',
          ),
        ),
      );
    });

    test('buildSetupMessage rejects explicit VAD signal', () {
      expect(
        () => LiveService.buildSetupMessage(
          LiveConnectParameters(
            model: 'models/gemini-live-2.5-flash-preview',
            callbacks: LiveCallbacks(),
            explicitVadSignal: true,
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            'explicitVadSignal parameter is not supported in Gemini API.',
          ),
        ),
      );
    });

    test('buildSetupMessage rejects transcription language codes', () {
      expect(
        () => LiveService.buildSetupMessage(
          LiveConnectParameters(
            model: 'models/gemini-live-2.5-flash-preview',
            callbacks: LiveCallbacks(),
            inputAudioTranscription: AudioTranscriptionConfig(
              languageCodes: ['ko-KR'],
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            'languageCodes parameter is not supported in Gemini API.',
          ),
        ),
      );
    });

    test('serializes setup with advanced live config', () {
      final message = LiveClientMessage(
        setup: LiveClientSetup(
          model: 'models/gemini-live-2.5-flash-preview',
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 512,
            responseModalities: [Modality.AUDIO],
            mediaResolution: MediaResolution.MEDIA_RESOLUTION_LOW,
            seed: 42,
            speechConfig: SpeechConfig(
              voiceConfig: VoiceConfig(
                prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: 'Kore'),
              ),
            ),
            thinkingConfig: ThinkingConfig(
              thinkingBudget: 1024,
              includeThoughts: true,
            ),
            enableAffectiveDialog: true,
          ),
          tools: [
            Tool(
              functionDeclarations: [
                FunctionDeclaration(
                  name: 'get_weather',
                  description: 'Get weather by city',
                  behavior: Behavior.NON_BLOCKING,
                  parameters: {
                    'type': 'OBJECT',
                    'properties': {
                      'city': {'type': 'STRING'},
                    },
                  },
                ),
              ],
              googleSearch: GoogleSearch(),
            ),
          ],
          sessionResumption: SessionResumptionConfig(
            handle: 'session-handle',
            transparent: true,
          ),
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
        ),
      );

      final restored = LiveClientMessage.fromJson(
        jsonDecode(jsonEncode(message.toJson())) as Map<String, dynamic>,
      );

      expect(restored.setup?.model, 'models/gemini-live-2.5-flash-preview');
      expect(
        restored.setup?.generationConfig?.mediaResolution,
        MediaResolution.MEDIA_RESOLUTION_LOW,
      );
      expect(
        restored
            .setup
            ?.generationConfig
            ?.speechConfig
            ?.voiceConfig
            ?.prebuiltVoiceConfig
            ?.voiceName,
        'Kore',
      );
      expect(
        restored.setup?.tools?.first.functionDeclarations?.first.behavior,
        Behavior.NON_BLOCKING,
      );
      expect(restored.setup?.sessionResumption?.transparent, true);
    });

    test('serializes latest part fields from ref live schema', () {
      final part = Part(
        mediaResolution: PartMediaResolution(
          level: PartMediaResolutionLevel.MEDIA_RESOLUTION_HIGH,
          numTokens: 128,
        ),
        fileData: FileData(
          displayName: 'demo.mp4',
          fileUri: 'gs://bucket/demo.mp4',
          mimeType: 'video/mp4',
        ),
        videoMetadata: VideoMetadata(
          startOffset: '0s',
          endOffset: '2s',
          fps: 24,
        ),
        thought: true,
        thoughtSignature: 'c2lnbmF0dXJl',
        toolCall: ToolCall(
          id: 'tool-call-1',
          toolType: ToolType.URL_CONTEXT,
          args: {'url': 'https://example.com'},
        ),
        toolResponse: ToolResponse(
          id: 'tool-call-1',
          toolType: ToolType.URL_CONTEXT,
          response: {'status': 'ok'},
        ),
        partMetadata: {'source': 'ref-sync'},
      );

      final restored = Part.fromJson(
        jsonDecode(jsonEncode(part.toJson())) as Map<String, dynamic>,
      );

      expect(
        restored.mediaResolution?.level,
        PartMediaResolutionLevel.MEDIA_RESOLUTION_HIGH,
      );
      expect(restored.fileData?.fileUri, 'gs://bucket/demo.mp4');
      expect(restored.videoMetadata?.fps, 24);
      expect(restored.thoughtSignature, 'c2lnbmF0dXJl');
      expect(restored.toolCall?.toolType, ToolType.URL_CONTEXT);
      expect(restored.toolResponse?.response?['status'], 'ok');
      expect(restored.partMetadata?['source'], 'ref-sync');
    });

    test('serializes realtime input and tool response', () {
      final realtime = LiveClientRealtimeInput(
        audio: Blob(mimeType: 'audio/pcm', data: 'base64Audio'),
        text: 'hello',
        audioStreamEnd: true,
      );
      final toolResponse = LiveClientToolResponse(
        functionResponses: [
          FunctionResponse(
            id: 'call-1',
            name: 'get_weather',
            response: {'output': 'sunny'},
            scheduling: FunctionResponseScheduling.INTERRUPT,
            willContinue: false,
          ),
        ],
      );

      final realtimeJson =
          jsonDecode(jsonEncode(realtime.toJson())) as Map<String, dynamic>;
      final toolJson =
          jsonDecode(jsonEncode(toolResponse.toJson())) as Map<String, dynamic>;

      expect(realtimeJson['audio_stream_end'], true);
      expect(
        (realtimeJson['audio'] as Map<String, dynamic>)['mimeType'],
        'audio/pcm',
      );
      expect(toolJson['function_responses'][0]['scheduling'], 'INTERRUPT');
      expect(toolJson['function_responses'][0]['will_continue'], false);
    });

    test('parses server content and tool call with camelCase fields', () {
      final message = LiveServerMessage.fromJson({
        'serverContent': {
          'modelTurn': {
            'parts': [
              {'text': 'Hello'},
            ],
            'role': 'model',
          },
          'interrupted': true,
          'turnComplete': true,
          'waitingForInput': false,
          'generationComplete': true,
        },
        'toolCall': {
          'functionCalls': [
            {
              'id': 'call-1',
              'name': 'get_weather',
              'args': {'city': 'Seoul'},
            },
          ],
        },
      });

      expect(message.serverContent?.interrupted, true);
      expect(message.serverContent?.turnComplete, true);
      expect(message.serverContent?.waitingForInput, false);
      expect(message.toolCall?.functionCalls?.first.name, 'get_weather');
    });

    test('parses goAway/session resumption/voice activity/usage metadata', () {
      final message = LiveServerMessage.fromJson({
        'goAway': {'timeLeft': '30s'},
        'sessionResumptionUpdate': {
          'newHandle': 'new-handle',
          'resumable': true,
          'lastConsumedClientMessageIndex': '42',
        },
        'voiceActivityDetectionSignal': {
          'vadSignalType': 'VAD_SIGNAL_TYPE_SOS',
        },
        'voiceActivity': {'voiceActivityType': 'ACTIVITY_START'},
        'usageMetadata': {
          'promptTokenCount': 10,
          'responseTokenCount': 5,
          'totalTokenCount': 15,
          'responseTokensDetails': [
            {'modality': 'AUDIO', 'tokenCount': 5},
          ],
          'trafficType': 'ON_DEMAND',
        },
      });

      expect(message.goAway?.timeLeft, '30s');
      expect(message.goAway?.timeRemaining, 30);
      expect(message.sessionResumptionUpdate?.newHandle, 'new-handle');
      expect(message.sessionResumptionUpdate?.resumable, true);
      expect(
        message.sessionResumptionUpdate?.lastConsumedClientMessageIndex,
        '42',
      );
      expect(message.voiceActivityDetectionSignal?.start, true);
      expect(message.voiceActivityDetectionSignal?.end, false);
      expect(message.voiceActivity?.speechActive, true);
      expect(
        message.usageMetadata?.responseTokensDetails?.first.modality,
        MediaModality.AUDIO,
      );
      expect(message.usageMetadata?.trafficType, TrafficType.ON_DEMAND);
    });

    test(
      'text getter ignores thought parts and data getter concatenates data',
      () {
        final message = LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [
                Part(text: 'A'),
                Part(text: 'B', thought: true),
                Part(text: 'C'),
                Part(
                  inlineData: Blob(mimeType: 'audio/pcm', data: 'eA=='),
                ),
                Part(
                  inlineData: Blob(mimeType: 'audio/pcm', data: 'eQ=='),
                ),
              ],
            ),
          ),
        );

        expect(message.text, 'AC');
        expect(message.data, 'eHk=');
      },
    );
  });

  group('Enums', () {
    test('validateFunctionResponses requires a Gemini tool call id', () {
      expect(
        () => LiveService.validateFunctionResponses([
          FunctionResponse(name: 'get_weather', response: {'output': 'sunny'}),
        ]),
        throwsArgumentError,
      );
    });

    test('validateFunctionResponses accepts well-formed responses', () {
      final responses = LiveService.validateFunctionResponses([
        FunctionResponse(
          id: 'call-1',
          name: 'get_weather',
          response: {'output': 'sunny'},
        ),
      ]);

      expect(responses.single.id, 'call-1');
    });

    test('ActivityHandling NO_INTERRUPTION serializes to latest value', () {
      final config = RealtimeInputConfig(
        activityHandling: ActivityHandling.NO_INTERRUPTION,
      );
      final json = config.toJson();
      expect(json['activity_handling'], 'NO_INTERRUPTION');
    });

    test('Legacy ActivityHandling alias is still accepted', () {
      final config = RealtimeInputConfig(
        activityHandling: ActivityHandling.START_OF_ACTIVITY_DOES_NOT_INTERRUPT,
      );
      final json = config.toJson();
      expect(json['activity_handling'], 'NO_INTERRUPTION');
    });
  });
}
