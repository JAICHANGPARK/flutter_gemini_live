import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  group('Live API Models Tests', () {
    // =========================================================================
    // LiveClientMessage Tests
    // =========================================================================

    group('LiveClientMessage', () {
      test('should serialize and deserialize setup message correctly', () {
        final message = LiveClientMessage(
          setup: LiveClientSetup(
            model: 'models/gemini-live-2.5-flash-preview',
            generationConfig: GenerationConfig(
              temperature: 0.7,
              responseModalities: [Modality.AUDIO, Modality.TEXT],
            ),
          ),
        );

        final jsonStr = jsonEncode(message.toJson());
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final restored = LiveClientMessage.fromJson(decoded);

        expect(restored.setup?.model, 'models/gemini-live-2.5-flash-preview');
        expect(restored.setup?.generationConfig?.temperature, 0.7);
        expect(restored.setup?.generationConfig?.responseModalities, [
          Modality.AUDIO,
          Modality.TEXT,
        ]);
      });

      test(
        'should serialize and deserialize client content message correctly',
        () {
          final message = LiveClientMessage(
            clientContent: LiveClientContent(
              turns: [
                Content(
                  parts: [Part(text: 'Hello')],
                  role: 'user',
                ),
              ],
              turnComplete: true,
            ),
          );

          final jsonStr = jsonEncode(message.toJson());
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final restored = LiveClientMessage.fromJson(decoded);

          expect(
            restored.clientContent?.turns?.first.parts?.first.text,
            'Hello',
          );
          expect(restored.clientContent?.turns?.first.role, 'user');
          expect(restored.clientContent?.turnComplete, true);
        },
      );

      test(
        'should serialize and deserialize realtime input with audio correctly',
        () {
          final message = LiveClientMessage(
            realtimeInput: LiveClientRealtimeInput(
              audio: Blob(mimeType: 'audio/pcm', data: 'base64AudioData'),
            ),
          );

          final jsonStr = jsonEncode(message.toJson());
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final restored = LiveClientMessage.fromJson(decoded);

          expect(restored.realtimeInput?.audio?.mimeType, 'audio/pcm');
          expect(restored.realtimeInput?.audio?.data, 'base64AudioData');
        },
      );

      test(
        'should serialize and deserialize realtime input with video correctly',
        () {
          final message = LiveClientMessage(
            realtimeInput: LiveClientRealtimeInput(
              video: Blob(mimeType: 'image/jpeg', data: 'base64VideoData'),
            ),
          );

          final jsonStr = jsonEncode(message.toJson());
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final restored = LiveClientMessage.fromJson(decoded);

          expect(restored.realtimeInput?.video?.mimeType, 'image/jpeg');
          expect(restored.realtimeInput?.video?.data, 'base64VideoData');
        },
      );

      test(
        'should serialize and deserialize realtime input with media chunks correctly',
        () {
          final message = LiveClientMessage(
            realtimeInput: LiveClientRealtimeInput(
              mediaChunks: [
                Blob(mimeType: 'audio/pcm', data: 'chunk1'),
                Blob(mimeType: 'audio/pcm', data: 'chunk2'),
              ],
            ),
          );

          final jsonStr = jsonEncode(message.toJson());
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final restored = LiveClientMessage.fromJson(decoded);

          expect(restored.realtimeInput?.mediaChunks?.length, 2);
          expect(
            restored.realtimeInput?.mediaChunks?.first.mimeType,
            'audio/pcm',
          );
          expect(restored.realtimeInput?.mediaChunks?.first.data, 'chunk1');
        },
      );

      test(
        'should serialize and deserialize realtime input with text correctly',
        () {
          final message = LiveClientMessage(
            realtimeInput: LiveClientRealtimeInput(text: 'Realtime text input'),
          );

          final jsonStr = jsonEncode(message.toJson());
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final restored = LiveClientMessage.fromJson(decoded);

          expect(restored.realtimeInput?.text, 'Realtime text input');
        },
      );

      test(
        'should serialize and deserialize tool response message correctly',
        () {
          final message = LiveClientMessage(
            toolResponse: LiveClientToolResponse(
              functionResponses: [
                FunctionResponse(
                  id: 'function-call-1',
                  name: 'get_weather',
                  response: {'temperature': 22, 'unit': 'celsius'},
                ),
              ],
            ),
          );

          final jsonStr = jsonEncode(message.toJson());
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final restored = LiveClientMessage.fromJson(decoded);

          expect(
            restored.toolResponse?.functionResponses?.first.id,
            'function-call-1',
          );
          expect(
            restored.toolResponse?.functionResponses?.first.name,
            'get_weather',
          );
          expect(
            restored
                .toolResponse
                ?.functionResponses
                ?.first
                .response?['temperature'],
            22,
          );
        },
      );
    });

    // =========================================================================
    // LiveClientSetup Tests
    // =========================================================================

    group('LiveClientSetup', () {
      test('should include all configuration options', () {
        final setup = LiveClientSetup(
          model: 'models/gemini-live-2.5-flash-preview',
          generationConfig: GenerationConfig(
            temperature: 0.7,
            responseModalities: [Modality.AUDIO],
          ),
          systemInstruction: Content(
            parts: [Part(text: 'You are a helpful assistant.')],
          ),
          realtimeInputConfig: RealtimeInputConfig(
            automaticActivityDetection: AutomaticActivityDetection(
              disabled: false,
              startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
              endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
              prefixPaddingMs: 300,
              silenceDurationMs: 500,
            ),
            activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
            turnCoverage: TurnCoverage.TURN_INCLUDES_ALL_INPUT,
          ),
          sessionResumption: SessionResumptionConfig(
            handle: 'previous-session-handle',
            transparent: true,
          ),
          contextWindowCompression: ContextWindowCompressionConfig(
            triggerTokens: '10000',
            slidingWindow: SlidingWindow(targetTokens: '5000'),
          ),
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
          proactivity: ProactivityConfig(proactiveAudio: true),
          explicitVadSignal: false,
        );

        final jsonStr = jsonEncode(setup.toJson());
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final restored = LiveClientSetup.fromJson(decoded);

        expect(restored.model, 'models/gemini-live-2.5-flash-preview');
        expect(restored.generationConfig?.temperature, 0.7);
        expect(
          restored.realtimeInputConfig?.automaticActivityDetection?.disabled,
          false,
        );
        expect(
          restored
              .realtimeInputConfig
              ?.automaticActivityDetection
              ?.startOfSpeechSensitivity,
          StartSensitivity.START_SENSITIVITY_HIGH,
        );
        expect(restored.sessionResumption?.handle, 'previous-session-handle');
        expect(restored.sessionResumption?.transparent, true);
        expect(restored.contextWindowCompression?.triggerTokens, '10000');
        expect(restored.proactivity?.proactiveAudio, true);
        expect(restored.explicitVadSignal, false);
      });
    });

    // =========================================================================
    // LiveClientRealtimeInput Tests
    // =========================================================================

    group('LiveClientRealtimeInput', () {
      test('should handle audio stream end signal', () {
        final input = LiveClientRealtimeInput(audioStreamEnd: true);

        final jsonStr = jsonEncode(input.toJson());
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final restored = LiveClientRealtimeInput.fromJson(decoded);

        expect(restored.audioStreamEnd, true);
      });

      test('should handle activity start', () {
        final input = LiveClientRealtimeInput(activityStart: ActivityStart());

        final jsonStr = jsonEncode(input.toJson());
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final restored = LiveClientRealtimeInput.fromJson(decoded);

        expect(restored.activityStart, isNotNull);
      });

      test('should handle activity end', () {
        final input = LiveClientRealtimeInput(activityEnd: ActivityEnd());

        final jsonStr = jsonEncode(input.toJson());
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final restored = LiveClientRealtimeInput.fromJson(decoded);

        expect(restored.activityEnd, isNotNull);
      });
    });

    // =========================================================================
    // LiveServerMessage Tests
    // =========================================================================

    group('LiveServerMessage', () {
      test('should parse server content correctly', () {
        final json = {
          'serverContent': {
            'modelTurn': {
              'parts': [
                {'text': 'Hello! How can I help you?'},
              ],
              'role': 'model',
            },
            'turnComplete': true,
          },
        };

        final message = LiveServerMessage.fromJson(json);
        expect(
          message.serverContent?.modelTurn?.parts?.first.text,
          'Hello! How can I help you?',
        );
        expect(message.serverContent?.turnComplete, true);
      });

      test('should parse tool call correctly', () {
        final json = {
          'toolCall': {
            'function_calls': [
              {
                'id': 'call-1',
                'name': 'get_weather',
                'args': {'location': 'New York'},
              },
            ],
          },
        };

        final message = LiveServerMessage.fromJson(json);
        expect(message.toolCall?.functionCalls?.first.id, 'call-1');
        expect(message.toolCall?.functionCalls?.first.name, 'get_weather');
      });

      test('should parse tool call cancellation correctly', () {
        final json = {
          'toolCallCancellation': {
            'ids': ['call-1', 'call-2'],
          },
        };

        final message = LiveServerMessage.fromJson(json);
        expect(message.toolCallCancellation?.ids, ['call-1', 'call-2']);
      });

      test('should parse go away message correctly', () {
        final json = {
          'goAway': {'reason': 'SESSION_EXPIRED', 'time_remaining': 30},
        };

        final message = LiveServerMessage.fromJson(json);
        expect(message.goAway?.reason, 'SESSION_EXPIRED');
        expect(message.goAway?.timeRemaining, 30);
      });

      test('should parse session resumption update correctly', () {
        final json = {
          'sessionResumptionUpdate': {
            'new_handle': 'new-session-handle',
            'resumable': 'true',
            'last_consumed_client_message_index': 42,
          },
        };

        final message = LiveServerMessage.fromJson(json);
        expect(
          message.sessionResumptionUpdate?.newHandle,
          'new-session-handle',
        );
        expect(
          message.sessionResumptionUpdate?.lastConsumedClientMessageIndex,
          42,
        );
      });

      test('should parse voice activity detection signal correctly', () {
        final json = {
          'voiceActivityDetectionSignal': {'start': true, 'end': false},
        };

        final message = LiveServerMessage.fromJson(json);
        expect(message.voiceActivityDetectionSignal?.start, true);
        expect(message.voiceActivityDetectionSignal?.end, false);
      });

      test('should parse voice activity correctly', () {
        final json = {
          'voiceActivity': {'speech_active': true},
        };

        final message = LiveServerMessage.fromJson(json);
        expect(message.voiceActivity?.speechActive, true);
      });

      test('should parse usage metadata correctly', () {
        final json = {
          'usageMetadata': {
            'promptTokenCount': 100,
            'responseTokenCount': 50,
            'totalTokenCount': 150,
          },
        };

        final message = LiveServerMessage.fromJson(json);
        expect(message.usageMetadata?.promptTokenCount, 100);
        expect(message.usageMetadata?.responseTokenCount, 50);
        expect(message.usageMetadata?.totalTokenCount, 150);
      });

      test('should get text from model turn correctly', () {
        final message = LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [
                Part(text: 'Hello'),
                Part(text: ' World'),
              ],
            ),
          ),
        );

        expect(message.text, 'Hello World');
      });

      test('should get data from inline data parts correctly', () {
        final message = LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [
                Part(
                  inlineData: Blob(mimeType: 'audio/pcm', data: 'base64data1'),
                ),
                Part(
                  inlineData: Blob(mimeType: 'audio/pcm', data: 'base64data2'),
                ),
              ],
            ),
          ),
        );

        expect(message.data, 'base64data1base64data2');
      });
    });

    // =========================================================================
    // Function Calling Tests
    // =========================================================================

    group('Function Calling', () {
      test('should create function call correctly', () {
        final functionCall = FunctionCall(
          id: 'call-123',
          name: 'get_weather',
          args: {'location': 'Seattle', 'unit': 'celsius'},
        );

        final json = functionCall.toJson();
        expect(json['id'], 'call-123');
        expect(json['name'], 'get_weather');
        expect(json['args']['location'], 'Seattle');
      });

      test('should create function response correctly', () {
        final functionResponse = FunctionResponse(
          id: 'call-123',
          name: 'get_weather',
          response: {'temperature': 15, 'condition': 'cloudy'},
        );

        final json = functionResponse.toJson();
        expect(json['id'], 'call-123');
        expect(json['name'], 'get_weather');
        expect(json['response']['temperature'], 15);
      });

      test('should parse function call correctly', () {
        final json = {
          'id': 'call-456',
          'name': 'search_database',
          'args': {'query': 'flutter dart'},
        };

        final functionCall = FunctionCall.fromJson(json);
        expect(functionCall.id, 'call-456');
        expect(functionCall.name, 'search_database');
        expect(functionCall.args?['query'], 'flutter dart');
      });
    });

    // =========================================================================
    // Enum Tests
    // =========================================================================

    group('Enums', () {
      test('ActivityHandling should serialize correctly', () {
        expect(
          ActivityHandling.START_OF_ACTIVITY_INTERRUPTS.name,
          'START_OF_ACTIVITY_INTERRUPTS',
        );

        final config = RealtimeInputConfig(
          activityHandling:
              ActivityHandling.START_OF_ACTIVITY_DOES_NOT_INTERRUPT,
        );

        final json = config.toJson();
        expect(
          json['activity_handling'],
          'START_OF_ACTIVITY_DOES_NOT_INTERRUPT',
        );
      });

      test('TurnCoverage should serialize correctly', () {
        final config = RealtimeInputConfig(
          turnCoverage: TurnCoverage.TURN_INCLUDES_ONLY_ACTIVITY,
        );

        final json = config.toJson();
        expect(json['turn_coverage'], 'TURN_INCLUDES_ONLY_ACTIVITY');
      });

      test('StartSensitivity should serialize correctly', () {
        final detection = AutomaticActivityDetection(
          startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
        );

        final json = detection.toJson();
        expect(json['start_of_speech_sensitivity'], 'START_SENSITIVITY_HIGH');
      });

      test('EndSensitivity should serialize correctly', () {
        final detection = AutomaticActivityDetection(
          endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
        );

        final json = detection.toJson();
        expect(json['end_of_speech_sensitivity'], 'END_SENSITIVITY_LOW');
      });

      test('Modality should serialize correctly', () {
        final config = GenerationConfig(
          responseModalities: [Modality.TEXT, Modality.AUDIO],
        );

        final json = config.toJson();
        expect(json['response_modalities'], ['TEXT', 'AUDIO']);
      });
    });

    // =========================================================================
    // Transcription Tests
    // =========================================================================

    group('Transcription', () {
      test('should parse transcription correctly', () {
        final json = {'text': 'Hello, this is a test.', 'finished': true};

        final transcription = Transcription.fromJson(json);
        expect(transcription.text, 'Hello, this is a test.');
        expect(transcription.finished, true);
      });
    });

    // =========================================================================
    // LiveServerContent Tests
    // =========================================================================

    group('LiveServerContent', () {
      test('should parse server content with transcriptions correctly', () {
        final json = {
          'modelTurn': {
            'parts': [
              {'text': 'Response text'},
            ],
          },
          'turnComplete': true,
          'inputTranscription': {'text': 'User input', 'finished': true},
          'outputTranscription': {'text': 'Model output', 'finished': false},
          'generationComplete': true,
        };

        final content = LiveServerContent.fromJson(json);
        expect(content.inputTranscription?.text, 'User input');
        expect(content.outputTranscription?.text, 'Model output');
        expect(content.generationComplete, true);
      });
    });
  });
}
