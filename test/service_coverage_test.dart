import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:gemini_live/gemini_live.dart' as gemini_live;
import 'package:gemini_live/src/client/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('ApiClient', () {
    test(
      'post sends JSON to the default endpoint and decodes success bodies',
      () async {
        final client = RecordingHttpClient(
          responder: (request) async => http.Response(
            jsonEncode({'ok': true, 'echo': request.body}),
            200,
          ),
        );
        final apiClient = ApiClient(apiKey: 'secret-key', httpClient: client);

        final response = await apiClient.post(
          'models/gemini-2.0:generateContent',
          {'prompt': 'hello'},
        );

        expect(
          client.requests.single.uri.toString(),
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0:generateContent?key=secret-key',
        );
        expect(client.requests.single.method, 'POST');
        expect(client.requests.single.headers, {
          'Content-Type': 'application/json',
        });
        expect(
          jsonDecode(client.requests.single.body) as Map<String, dynamic>,
          {'prompt': 'hello'},
        );
        expect(response['ok'], true);
        expect(response['echo'], '{"prompt":"hello"}');
      },
    );

    test('post uses custom baseUrl and throws for non-2xx responses', () async {
      final client = RecordingHttpClient(
        responder: (_) async => http.Response('bad request', 400),
      );
      final apiClient = ApiClient(
        apiKey: 'token',
        apiVersion: 'v9',
        baseUrl: 'https://example.test',
        httpClient: client,
      );

      await expectLater(
        () => apiClient.post('models/test:call', {'x': 1}),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('API Error: 400 bad request'),
          ),
        ),
      );

      expect(
        client.requests.single.uri.toString(),
        'https://example.test/v9/models/test:call?key=token',
      );
    });

    test('close delegates to the provided HTTP client', () {
      final client = RecordingHttpClient(
        responder: (_) async => http.Response('{}', 200),
      );
      final apiClient = ApiClient(apiKey: 'token', httpClient: client);

      apiClient.close();

      expect(client.closeCalled, true);
    });

    test('creates and closes its own HTTP client when none is injected', () {
      final apiClient = ApiClient(apiKey: 'token');

      apiClient.close();
    });
  });

  group('GoogleGenAI', () {
    test('constructs live service and closes the injected HTTP client', () {
      final client = RecordingHttpClient(
        responder: (_) async => http.Response('{}', 200),
      );
      final genAi = GoogleGenAI(
        apiKey: 'api-key',
        apiVersion: 'v1alpha',
        httpClient: client,
      );

      expect(genAi.apiKey, 'api-key');
      expect(genAi.apiVersion, 'v1alpha');
      expect(genAi.live.apiKey, 'api-key');
      expect(genAi.live.apiVersion, 'v1alpha');
      expect(genAi.music, same(genAi.live.music));
      expect(genAi.httpClient, same(client));

      genAi.close();

      expect(client.closeCalled, true);
    });
  });

  group('WAV header', () {
    test('prepends a valid PCM WAV header and preserves payload bytes', () {
      final pcmBytes = List<int>.generate(8, (index) => index + 1);

      final wavBytes = addWavHeader(
        Uint8List.fromList(pcmBytes),
        sampleRate: 24000,
        numChannels: 2,
        bitsPerSample: 16,
      );

      expect(wavBytes.length, 52);
      expect(ascii.decode(wavBytes.sublist(0, 4)), 'RIFF');
      expect(ascii.decode(wavBytes.sublist(8, 12)), 'WAVE');
      expect(ascii.decode(wavBytes.sublist(12, 16)), 'fmt ');
      expect(ascii.decode(wavBytes.sublist(36, 40)), 'data');

      final header = ByteData.sublistView(wavBytes);
      expect(header.getUint32(4, Endian.little), 44);
      expect(header.getUint16(22, Endian.little), 2);
      expect(header.getUint32(24, Endian.little), 24000);
      expect(header.getUint32(28, Endian.little), 96000);
      expect(header.getUint16(32, Endian.little), 4);
      expect(header.getUint16(34, Endian.little), 16);
      expect(header.getUint32(40, Endian.little), pcmBytes.length);
      expect(wavBytes.sublist(44), pcmBytes);
    });
  });

  group('LiveService', () {
    test('dartVersion returns a major.minor pair', () {
      expect(LiveService.dartVersion(), matches(RegExp(r'^\d+\.\d+$')));
    });

    test('handleWebSocketData parses string and binary payloads', () {
      final messages = <LiveServerMessage>[];
      final errors = <Object>[];
      final service = LiveService(apiKey: 'key');
      final callbacks = LiveCallbacks(
        onMessage: messages.add,
        onError: (error, _) => errors.add(error),
      );

      service.handleWebSocketDataForTesting(
        '{"serverContent":{"modelTurn":{"parts":[{"text":"hello"}]}}}',
        callbacks,
      );
      service.handleWebSocketDataForTesting(
        utf8.encode(
          '{"serverContent":{"modelTurn":{"parts":[{"inlineData":{"mimeType":"audio/pcm","data":"YWI="}}]}}}',
        ),
        callbacks,
      );

      expect(errors, isEmpty);
      expect(messages[0].text, 'hello');
      expect(messages[1].data, 'YWI=');
    });

    test('handleWebSocketData reports invalid JSON and unexpected types', () {
      final errors = <Object>[];
      final service = LiveService(apiKey: 'key');
      final callbacks = LiveCallbacks(onError: (error, _) => errors.add(error));

      service.handleWebSocketDataForTesting('{not-json}', callbacks);
      service.handleWebSocketDataForTesting(42, callbacks);

      expect(errors, hasLength(2));
      expect(errors.first, isA<FormatException>());
      expect(
        errors.last.toString(),
        contains('Received unexpected data type from WebSocket: int'),
      );
    });

    test(
      'buildSetupMessage normalizes defaults and rejects unsupported parameters',
      () {
        final baseParams = LiveConnectParameters(
          model: 'gemini-live-test',
          callbacks: LiveCallbacks(),
          config: GenerationConfig(temperature: 0.3),
        );

        final message = LiveService.buildSetupMessage(baseParams);
        expect(message.setup?.generationConfig?.responseModalities, [
          Modality.AUDIO,
        ]);

        expect(
          () => LiveService.buildSetupMessage(
            LiveConnectParameters(
              model: 'gemini-live-test',
              callbacks: LiveCallbacks(),
              sessionResumption: SessionResumptionConfig(
                handle: 'resume-me',
                transparent: true,
              ),
            ),
          ),
          throwsA(isA<UnsupportedError>()),
        );

        expect(
          () => LiveService.buildSetupMessage(
            LiveConnectParameters(
              model: 'gemini-live-test',
              callbacks: LiveCallbacks(),
              explicitVadSignal: true,
            ),
          ),
          throwsA(isA<UnsupportedError>()),
        );

        expect(
          () => LiveService.buildSetupMessage(
            LiveConnectParameters(
              model: 'gemini-live-test',
              callbacks: LiveCallbacks(),
              safetySettings: [
                SafetySetting(
                  category: HarmCategory.HARM_CATEGORY_HARASSMENT,
                  method: HarmBlockMethod.PROBABILITY,
                  threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH,
                ),
              ],
            ),
          ),
          throwsA(isA<UnsupportedError>()),
        );
      },
    );

    test('buildSetupMessage throws for tools with exaAiSearch', () {
      expect(
        () => LiveService.buildSetupMessage(
          LiveConnectParameters(
            model: 'gemini-live-test',
            callbacks: LiveCallbacks(),
            tools: [Tool(exaAiSearch: ToolExaAiSearch(apiKey: 'exa-key'))],
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('exaAiSearch parameter is not supported in Gemini API'),
          ),
        ),
      );
    });

    test('buildSetupMessage throws for tools with parallelAiSearch', () {
      expect(
        () => LiveService.buildSetupMessage(
          LiveConnectParameters(
            model: 'gemini-live-test',
            callbacks: LiveCallbacks(),
            tools: [
              Tool(
                parallelAiSearch: ToolParallelAiSearch(
                  apiKey: 'parallel-key',
                ),
              ),
            ],
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('parallelAiSearch parameter is not supported in Gemini API'),
          ),
        ),
      );
    });

    test('validateFunctionResponses rejects invalid tool payloads', () {
      expect(
        () => LiveService.validateFunctionResponses([]),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => LiveService.validateFunctionResponses([
          FunctionResponse(id: '1', response: {'ok': true}),
        ]),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => LiveService.validateFunctionResponses([
          FunctionResponse(id: '1', name: 'lookup'),
        ]),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => LiveService.validateFunctionResponses([
          FunctionResponse(name: 'lookup', response: {'ok': true}),
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'connect builds URI and headers, sends setup, and returns a session',
      () async {
        final channel = FakeWebSocketChannel();
        late Uri seenUri;
        late Map<String, dynamic> seenHeaders;
        var opened = false;
        LiveServerMessage? receivedMessage;
        int? closeCode;
        String? closeReason;

        final service = LiveService(
          apiKey: 'plain-key',
          connector: (uri, headers) async {
            seenUri = uri;
            seenHeaders = headers;
            unawaited(
              Future<void>.delayed(
                Duration.zero,
                () => channel.emit('{"setupComplete":{"sessionId":"abc"}}'),
              ),
            );
            return channel;
          },
          dartVersionProvider: () => '9.9',
        );

        final session = await service.connect(
          LiveConnectParameters(
            model: 'gemini-live-test',
            callbacks: LiveCallbacks(
              onOpen: () => opened = true,
              onMessage: (message) => receivedMessage = message,
              onClose: (code, reason) {
                closeCode = code;
                closeReason = reason;
              },
            ),
            config: GenerationConfig(
              temperature: 0.2,
              responseModalities: [Modality.TEXT],
            ),
            systemInstruction: Content(
              role: 'user',
              parts: [Part(text: 'system')],
            ),
            tools: [
              Tool(functionDeclarations: [FunctionDeclaration(name: 'lookup')]),
            ],
            realtimeInputConfig: RealtimeInputConfig(
              activityHandling: ActivityHandling.NO_INTERRUPTION,
            ),
            sessionResumption: SessionResumptionConfig(handle: 'resume-me'),
            contextWindowCompression: ContextWindowCompressionConfig(
              triggerTokens: '128',
              slidingWindow: SlidingWindow(targetTokens: '64'),
            ),
            inputAudioTranscription: AudioTranscriptionConfig(),
            outputAudioTranscription: AudioTranscriptionConfig(),
            proactivity: ProactivityConfig(proactiveAudio: true),
            avatarConfig: AvatarConfig(
              avatarName: 'hero',
              audioBitrateBps: 64000,
              videoBitrateBps: 1500000,
            ),
            safetySettings: [
              SafetySetting(
                category: HarmCategory.HARM_CATEGORY_HARASSMENT,
                threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH,
              ),
            ],
          ),
        );

        expect(opened, true);
        expect(receivedMessage?.setupComplete?.sessionId, 'abc');
        expect(
          seenUri.toString(),
          'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=plain-key',
        );
        expect(seenHeaders['Content-Type'], 'application/json');
        expect(seenHeaders['x-goog-api-key'], 'plain-key');
        expect(
          seenHeaders['x-goog-api-client'],
          'google-genai-sdk/2.33.0 dart/9.9',
        );
        expect(seenHeaders['user-agent'], 'google-genai-sdk/2.33.0 dart/9.9');

        final sentSetup =
            jsonDecode(channel.sentMessages.single as String)
                as Map<String, dynamic>;
        expect(sentSetup['setup']['model'], 'models/gemini-live-test');
        expect(
          sentSetup['setup']['system_instruction']['parts'][0]['text'],
          'system',
        );
        expect(
          sentSetup['setup']['context_window_compression']['sliding_window']['target_tokens'],
          '64',
        );
        expect(sentSetup['setup']['avatar_config']['avatar_name'], 'hero');
        expect(
          sentSetup['setup']['avatar_config']['video_bitrate_bps'],
          1500000,
        );
        expect(
          sentSetup['setup']['safety_settings'][0]['threshold'],
          'BLOCK_ONLY_HIGH',
        );
        expect(session.isClosed, false);

        channel.finish(1000, 'done');
        await pumpEventQueue();

        expect(closeCode, 1000);
        expect(closeReason, 'done');
      },
    );

    test('connect uses constrained endpoint for ephemeral tokens', () async {
      final channel = FakeWebSocketChannel();
      late Uri seenUri;
      final service = LiveService(
        apiKey: 'auth_tokens/ephemeral',
        apiVersion: 'v1alpha',
        connector: (uri, headers) async {
          seenUri = uri;
          unawaited(
            Future<void>.delayed(
              Duration.zero,
              () => channel.emit(
                utf8.encode('{"setupComplete":{"sessionId":"ephemeral"}}'),
              ),
            ),
          );
          return channel;
        },
      );

      final session = await service.connect(
        LiveConnectParameters(
          model: 'models/gemini-live-prefixed',
          callbacks: LiveCallbacks(),
        ),
      );

      expect(
        seenUri.toString(),
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained?access_token=auth_tokens%2Fephemeral',
      );

      final sentSetup =
          jsonDecode(channel.sentMessages.single as String)
              as Map<String, dynamic>;
      expect(sentSetup['setup']['model'], 'models/gemini-live-prefixed');
      expect(session.isClosed, false);
    });

    test('connect forwards stream errors', () async {
      final channel = FakeWebSocketChannel();
      final errors = <Object>[];
      final service = LiveService(
        apiKey: 'plain-key',
        connector: (uri, headers) async {
          unawaited(
            Future<void>.delayed(
              Duration.zero,
              () => channel.emitError(StateError('socket failed')),
            ),
          );
          return channel;
        },
      );

      await expectLater(
        () => service.connect(
          LiveConnectParameters(
            model: 'gemini-live-test',
            callbacks: LiveCallbacks(onError: (error, _) => errors.add(error)),
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(errors.single, isA<StateError>());
    });

    test('connect rethrows connector failures', () async {
      final service = LiveService(
        apiKey: 'plain-key',
        connector: (uri, headers) async => throw ArgumentError('boom'),
      );

      await expectLater(
        () => service.connect(
          LiveConnectParameters(
            model: 'gemini-live-test',
            callbacks: LiveCallbacks(),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'connect still reaches the ephemeral warning branch on non-alpha versions',
      () async {
        final service = LiveService(
          apiKey: 'auth_tokens/preview',
          connector: (uri, headers) async => throw StateError('stop'),
        );

        await expectLater(
          () => service.connect(
            LiveConnectParameters(
              model: 'gemini-live-test',
              callbacks: LiveCallbacks(),
            ),
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('connect times out when setup is never acknowledged', () async {
      final service = LiveService(
        apiKey: 'plain-key',
        connector: (uri, headers) async => FakeWebSocketChannel(),
        setupTimeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        () => service.connect(
          LiveConnectParameters(
            model: 'gemini-live-test',
            callbacks: LiveCallbacks(),
          ),
        ),
        throwsA(
          isA<gemini_live.TimeoutException>().having(
            (error) => error.toString(),
            'message',
            contains('WebSocket setup timed out'),
          ),
        ),
      );
    });

    test('connect does not resolve until setupComplete arrives', () async {
      final channel = FakeWebSocketChannel();
      final service = LiveService(
        apiKey: 'plain-key',
        connector: (uri, headers) async => channel,
      );

      var resolved = false;
      final future = service
          .connect(
            LiveConnectParameters(
              model: 'gemini-live-test',
              callbacks: LiveCallbacks(),
            ),
          )
          .then((session) {
            resolved = true;
            return session;
          });

      // A non-setup message must not resolve connect().
      channel.emit('{"serverContent":{"turnComplete":true}}');
      await pumpEventQueue();
      expect(resolved, isFalse);

      channel.emit('{"setupComplete":{"sessionId":"ready"}}');
      final session = await future;
      expect(resolved, isTrue);
      expect(session.setupComplete?.sessionId, 'ready');
    });

    test(
      'connect queues pre-setup messages and flushes them in order',
      () async {
        final channel = FakeWebSocketChannel();
        final received = <LiveServerMessage>[];
        final service = LiveService(
          apiKey: 'plain-key',
          connector: (uri, headers) async {
            unawaited(
              Future<void>.delayed(Duration.zero, () {
                channel.emit('{"serverContent":{"turnComplete":false}}');
                channel.emit('{"setupComplete":{"sessionId":"ready"}}');
              }),
            );
            return channel;
          },
        );

        final session = await service.connect(
          LiveConnectParameters(
            model: 'gemini-live-test',
            callbacks: LiveCallbacks(onMessage: received.add),
          ),
        );

        // The pre-setup message and the setupComplete message are delivered
        // (in order) only after connect() resolves.
        expect(received, hasLength(2));
        expect(received[0].serverContent?.turnComplete, false);
        expect(received[1].setupComplete?.sessionId, 'ready');
        expect(session.setupComplete?.sessionId, 'ready');

        // Post-setup messages flow straight through.
        channel.emit('{"serverContent":{"turnComplete":true}}');
        await pumpEventQueue();
        expect(received, hasLength(3));
        expect(received[2].serverContent?.turnComplete, true);
      },
    );

    test(
      'connect supports session-level httpOptions (baseUrl, apiVersion, headers) overriding client-level httpOptions',
      () async {
        Uri? seenUri;
        Map<String, dynamic>? seenHeaders;
        final channel = FakeWebSocketChannel();
        final service = LiveService(
          apiKey: 'TEST_API_KEY',
          httpOptions: const HttpOptions(
            headers: {'x-client-header': 'client-value'},
          ),
          connector: (uri, headers) async {
            seenUri = uri;
            seenHeaders = headers;
            unawaited(
              Future<void>.delayed(
                Duration.zero,
                () => channel.emit(
                  '{"setupComplete":{"sessionId":"test_session_id"}}',
                ),
              ),
            );
            return channel;
          },
        );

        final session = await service.connect(
          LiveConnectParameters(
            model: 'test-model',
            config: LiveConnectConfig(
              httpOptions: const HttpOptions(
                baseUrl: 'https://session-base-url.com',
                apiVersion: 'v1alpha',
                headers: {
                  'x-client-header': 'session-value',
                  'x-session-header': 'session-value',
                },
              ),
            ),
          ),
        );

        expect(
          seenUri.toString(),
          'wss://session-base-url.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=TEST_API_KEY',
        );
        expect(seenHeaders?['x-goog-api-key'], 'TEST_API_KEY');
        expect(seenHeaders?['x-client-header'], 'session-value');
        expect(seenHeaders?['x-session-header'], 'session-value');
        // Client-level httpOptions must not be mutated
        expect(service.httpOptions?.headers?['x-client-header'], 'client-value');
        expect(
          service.httpOptions?.headers?.containsKey('x-session-header'),
          isFalse,
        );
        // httpOptions must not be sent in the setup message payload
        final sentSetup = channel.sentMessages.single as String;
        expect(sentSetup.contains('x-session-header'), isFalse);
        expect(session.sessionId, 'test_session_id');
      },
    );

    test(
      'connect keeps client baseUrl when session httpOptions only overrides headers',
      () async {
        Uri? seenUri;
        Map<String, dynamic>? seenHeaders;
        final channel = FakeWebSocketChannel();
        final service = LiveService(
          apiKey: 'TEST_API_KEY',
          httpOptions: {'base_url': 'https://client-base-url.com'},
          connector: (uri, headers) async {
            seenUri = uri;
            seenHeaders = headers;
            unawaited(
              Future<void>.delayed(
                Duration.zero,
                () => channel.emit('{"setupComplete":{"sessionId":"id"}}'),
              ),
            );
            return channel;
          },
        );

        await service.connect(
          LiveConnectParameters(
            model: 'test-model',
            config: LiveConnectConfig(
              httpOptions: const HttpOptions(
                headers: {'x-session-header': 'session-value'},
              ),
            ),
          ),
        );

        expect(
          seenUri.toString(),
          'wss://client-base-url.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=TEST_API_KEY',
        );
        expect(seenHeaders?['x-session-header'], 'session-value');
      },
    );

    test(
      'connect with empty apiKey and custom baseUrl uses custom URL directly with custom Authorization header',
      () async {
        Uri? seenUri;
        Map<String, dynamic>? seenHeaders;
        final channel = FakeWebSocketChannel();
        final service = LiveService(
          apiKey: '',
          httpOptions: const HttpOptions(
            baseUrl: 'https://custom-base-url.com',
            headers: {'Authorization': 'Bearer custom_test_token'},
          ),
          connector: (uri, headers) async {
            seenUri = uri;
            seenHeaders = headers;
            unawaited(
              Future<void>.delayed(
                Duration.zero,
                () => channel.emit('{"setupComplete":{"sessionId":"proxy"}}'),
              ),
            );
            return channel;
          },
        );

        await service.connect(
          LiveConnectParameters(
            model: 'test-model',
            config: LiveConnectConfig(
              httpOptions: const HttpOptions(
                baseUrl: 'https://session-base-url.com',
                headers: {'Authorization': 'Bearer session_test_token'},
              ),
            ),
          ),
        );

        expect(seenUri.toString(), 'https://session-base-url.com');
        expect(seenHeaders?['Authorization'], 'Bearer session_test_token');
        expect(seenHeaders?.containsKey('x-goog-api-key'), isFalse);
      },
    );

    test(
      'connect throws ArgumentError on unsupported session httpOptions fields',
      () async {
        var connectCalled = false;
        final service = LiveService(
          apiKey: 'TEST_API_KEY',
          connector: (uri, headers) async {
            connectCalled = true;
            return FakeWebSocketChannel();
          },
        );

        final unsupportedCases = <String, Map<String, dynamic>>{
          'timeout': {'timeout': 1000},
          'extra_body': {'extra_body': <String, dynamic>{'setup': <String, dynamic>{}}},
          'retry_options': {'retry_options': <String, dynamic>{'attempts': 1}},
          'client_args': {'client_args': <String, dynamic>{'foo': 'bar'}},
          'async_client_args': {'async_client_args': <String, dynamic>{'open_timeout': 5}},
        };

        for (final entry in unsupportedCases.entries) {
          await expectLater(
            () => service.connect(
              LiveConnectParameters(
                model: 'test-model',
                config: {
                  'http_options': {
                    'headers': {'x-header': 'value'},
                    ...entry.value,
                  },
                },
              ),
            ),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.toString(),
                'message',
                contains(entry.key),
              ),
            ),
          );
        }
        expect(connectCalled, isFalse);
      },
    );
  });

  group('LiveSession', () {
    test('send methods encode the expected message payloads', () async {
      final channel = FakeWebSocketChannel();
      final session = LiveSession.forTesting(channel);

      session.sendText('hello');
      session.sendAudio([1, 2, 3]);
      session.sendVideo([4, 5], mimeType: 'image/png');
      session.sendClientContent(
        turns: [
          Content(parts: [Part(text: 'turn')]),
        ],
        turnComplete: false,
      );
      session.sendRealtimeInput(
        mediaChunks: [Blob(mimeType: 'image/jpeg', data: 'media')],
        audio: Blob(mimeType: 'audio/pcm', data: 'audio'),
        video: Blob(mimeType: 'image/png', data: 'video'),
        text: 'text',
        audioStreamEnd: true,
        activityStart: true,
        activityEnd: true,
      );
      session.sendRealtimeInput();
      session.sendMediaChunks([Blob(mimeType: 'image/jpeg', data: 'chunk')]);
      session.sendAudioStreamEnd();
      session.sendRealtimeText('ping');
      session.sendActivityStart();
      session.sendActivityEnd();
      session.sendToolResponse(
        functionResponses: [
          FunctionResponse(id: '1', name: 'tool', response: {'ok': true}),
        ],
      );
      session.sendFunctionResponse(
        id: '2',
        name: 'tool2',
        response: {'value': 3},
      );

      expect(channel.sentMessages, hasLength(12));

      final decoded = channel.sentMessages
          .map(
            (message) => jsonDecode(message as String) as Map<String, dynamic>,
          )
          .toList();

      expect(
        decoded[0]['clientContent']['turns'][0]['parts'][0]['text'],
        'hello',
      );
      expect(decoded[1]['realtimeInput']['audio']['data'], 'AQID');
      expect(decoded[2]['realtimeInput']['video']['mimeType'], 'image/png');
      expect(decoded[3]['clientContent']['turn_complete'], false);
      expect(
        decoded[4]['realtimeInput']['activity_start'],
        isA<Map<String, dynamic>>(),
      );
      expect(
        decoded[4]['realtimeInput']['activity_end'],
        isA<Map<String, dynamic>>(),
      );
      expect(decoded[5]['realtimeInput']['media_chunks'][0]['data'], 'chunk');
      expect(decoded[6]['realtimeInput']['audio_stream_end'], true);
      expect(decoded[7]['realtimeInput']['text'], 'ping');
      expect(
        decoded[8]['realtimeInput']['activity_start'],
        isA<Map<String, dynamic>>(),
      );
      expect(
        decoded[9]['realtimeInput']['activity_end'],
        isA<Map<String, dynamic>>(),
      );
      expect(decoded[10]['toolResponse']['function_responses'][0]['response'], {
        'ok': true,
      });
      expect(decoded[11]['toolResponse']['function_responses'][0]['response'], {
        'value': 3,
      });

      await session.close();

      expect(channel.sinkCloseCalls, 1);
      expect(session.isClosed, true);
    });

    test('LiveSession supports reference SDK union parameters (String turns, media Blob, single FunctionResponse, sendContextUpdate)', () {
      final channel = FakeWebSocketChannel();
      final session = LiveSession.forTesting(channel);

      // 1. sendClientContent with String turns & single Content
      session.sendClientContent(turns: 'Hello from string!');
      session.sendClientContent(
        turns: Content(parts: [Part(text: 'Single content')]),
      );

      // 2. sendRealtimeInput with media Blob and ActivityStart/ActivityEnd objects
      session.sendRealtimeInput(
        media: Blob(mimeType: 'audio/pcm;rate=16000', data: 'AQID'),
        activityStart: ActivityStart(),
        activityEnd: ActivityEnd(),
      );

      // 3. sendToolResponse with single FunctionResponse
      session.sendToolResponse(
        functionResponses: FunctionResponse(
          id: 'call-99',
          name: 'turn_on_lights',
          response: {'result': 'ok'},
        ),
      );

      // 4. sendContextUpdate
      session.sendContextUpdate(
        systemInstruction: 'Be concise.',
        tools: const <Tool>[],
      );

      final decoded = channel.sentMessages
          .map(
            (message) => jsonDecode(message as String) as Map<String, dynamic>,
          )
          .toList();

      expect(decoded, hasLength(5));
      expect(
        decoded[0]['clientContent']['turns'][0]['parts'][0]['text'],
        'Hello from string!',
      );
      expect(decoded[0]['clientContent']['turns'][0]['role'], 'user');
      expect(
        decoded[1]['clientContent']['turns'][0]['parts'][0]['text'],
        'Single content',
      );
      expect(
        decoded[2]['realtimeInput']['mediaChunks'][0]['data'],
        'AQID',
      );
      expect(
        decoded[2]['realtimeInput']['activityStart'],
        isA<Map<String, dynamic>>(),
      );
      expect(
        decoded[3]['toolResponse']['functionResponses'][0]['name'],
        'turn_on_lights',
      );
      expect(
        decoded[4]['contextUpdate']['systemInstruction']['parts'][0]['text'],
        'Be concise.',
      );
      expect(decoded[4]['contextUpdate']['tools'], {'tools': []});
    });

    test('LiveConnectParameters accepts String systemInstruction and validates enterprise-only tools', () {
      final params = LiveConnectParameters(
        model: 'gemini-live-test',
        systemInstruction: 'You are a helpful voice assistant.',
      );
      final setup = LiveService.buildSetupMessage(params);
      expect(
        setup.setup?.systemInstruction?.parts?.first.text,
        'You are a helpful voice assistant.',
      );

      expect(
        () => LiveService.buildSetupMessage(
          LiveConnectParameters(
            model: 'gemini-live-test',
            tools: [Tool(retrieval: {'source': 'vertex'})],
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );

      expect(
        () => LiveService.buildSetupMessage(
          LiveConnectParameters(
            model: 'gemini-live-test',
            tools: [Tool(enterpriseWebSearch: const {})],
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('upstream parity: tModel validation, multiSpeakerVoiceConfig rejection, and top-level LiveConnectParameters config fields', () {
      // 1. tModel validation
      expect(
        () => LiveService.normalizeModelName(''),
        throwsArgumentError,
      );
      expect(
        () => LiveService.normalizeModelName('models/../secret'),
        throwsArgumentError,
      );
      expect(
        () => LiveService.normalizeModelName('gemini-live?foo=bar'),
        throwsArgumentError,
      );
      expect(
        () => LiveService.normalizeModelName('gemini-live&foo=bar'),
        throwsArgumentError,
      );
      expect(
        LiveService.normalizeModelName('tunedModels/my-custom-model'),
        'tunedModels/my-custom-model',
      );
      expect(
        LiveService.normalizeModelName('gemini-2.5-flash'),
        'models/gemini-2.5-flash',
      );

      // 2. multiSpeakerVoiceConfig rejection in Live API
      expect(
        () => LiveService.buildSetupMessage(
          LiveConnectParameters(
            model: 'gemini-live-test',
            speechConfig: SpeechConfig(
              multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig(),
            ),
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );

      // 3. Top-level generation config fields & speechConfig String shorthand
      final setup = LiveService.buildSetupMessage(
        LiveConnectParameters(
          model: 'tunedModels/custom-voice',
          responseModalities: const [Modality.TEXT],
          temperature: 0.4,
          topP: 0.8,
          topK: 20,
          maxOutputTokens: 256,
          mediaResolution: MediaResolution.MEDIA_RESOLUTION_LOW,
          seed: 42,
          speechConfig: 'Puck',
          thinkingConfig: ThinkingConfig(thinkingBudget: 512),
          enableAffectiveDialog: true,
        ),
      );
      expect(setup.setup?.model, 'tunedModels/custom-voice');
      final gen = setup.setup?.generationConfig;
      expect(gen?.responseModalities, const [Modality.TEXT]);
      expect(gen?.temperature, 0.4);
      expect(gen?.topP, 0.8);
      expect(gen?.topK, 20);
      expect(gen?.maxOutputTokens, 256);
      expect(gen?.mediaResolution, MediaResolution.MEDIA_RESOLUTION_LOW);
      expect(gen?.seed, 42);
      expect(
        gen?.speechConfig?.voiceConfig?.prebuiltVoiceConfig?.voiceName,
        'Puck',
      );
      expect(gen?.thinkingConfig?.thinkingBudget, 512);
      expect(gen?.enableAffectiveDialog, true);
    });

    test('upstream parity: tContents part accumulation, mixed Content/Part rejection, unwrapped functionCall rejection, and dict inputs', () {
      final channel = FakeWebSocketChannel();
      final session = LiveSession.forTesting(channel);

      // 1. List of Parts/Strings accumulates into a single Content turn
      session.sendClientContent(
        turns: [
          'First part',
          Part(text: 'Second part'),
          {
            'inline_data': {
              'data': [1, 2, 3],
              'mime_type': 'audio/pcm',
            },
          },
        ],
      );

      // 2. Mixing Content and Part throws ArgumentError
      expect(
        () => session.sendClientContent(
          turns: [
            Content(role: 'user', parts: [Part(text: 'turn 1')]),
            Part(text: 'orphan part'),
          ],
        ),
        throwsArgumentError,
      );

      // 3. Raw unwrapped functionCall / functionResponse Part throws ArgumentError
      expect(
        () => session.sendClientContent(
          turns: Part(functionCall: FunctionCall(name: 'fn', args: const {})),
        ),
        throwsArgumentError,
      );
      expect(
        () => session.sendClientContent(
          turns: [
            Part(
              functionResponse: FunctionResponse(
                id: '1',
                name: 'fn',
                response: const {'ok': true},
              ),
            ),
          ],
        ),
        throwsArgumentError,
      );

      // 4. sendRealtimeInput with Map blobs (including raw byte list) and {} activity markers
      session.sendRealtimeInput(
        media: {
          'data': [4, 5, 6],
          'mime_type': 'audio/pcm',
        },
        activityStart: const <String, dynamic>{},
        activityEnd: const <String, dynamic>{},
      );

      // 5. sendToolResponse with Map input
      session.sendToolResponse(
        functionResponses: {
          'id': 'call-dict-1',
          'name': 'get_weather',
          'response': {'temp': 22},
        },
      );

      final decoded = channel.sentMessages
          .map(
            (message) => jsonDecode(message as String) as Map<String, dynamic>,
          )
          .toList();

      expect(decoded, hasLength(3));
      final turns = decoded[0]['clientContent']['turns'] as List<dynamic>;
      expect(turns, hasLength(1));
      final parts = turns[0]['parts'] as List<dynamic>;
      expect(parts, hasLength(3));
      expect(parts[0]['text'], 'First part');
      expect(parts[1]['text'], 'Second part');
      expect(parts[2]['inlineData']['data'], 'AQID');
      expect(parts[2]['inlineData']['mimeType'], 'audio/pcm');

      expect(decoded[1]['realtimeInput']['mediaChunks'][0]['data'], 'BAUG');
      expect(
        decoded[1]['realtimeInput']['activityStart'],
        isA<Map<String, dynamic>>(),
      );
      expect(
        decoded[1]['realtimeInput']['activityEnd'],
        isA<Map<String, dynamic>>(),
      );

      expect(
        decoded[2]['toolResponse']['functionResponses'][0]['id'],
        'call-dict-1',
      );
    });

    test('upstream parity: LiveConnectConfig, CallableTool, LiveSession.sessionId/receive, and LiveMusic parameter classes', () async {
      // 1. LiveConnectConfig in LiveConnectParameters & CallableTool
      final callable = _TestCallableTool();
      final params = LiveConnectParameters(
        model: 'gemini-3.8-live-preview',
        config: LiveConnectConfig(
          temperature: 0.3,
          speechConfig: 'Aoede',
          systemInstruction: 'You are a helpful AI.',
          tools: [
            Tool(googleSearch: const GoogleSearch()),
            callable,
          ],
          sessionResumption: SessionResumptionConfig(handle: 'res-123'),
          proactivity: ProactivityConfig(proactiveAudio: true),
          historyConfig: HistoryConfig(initialHistoryInClientContent: true),
          generationConfig: GenerationConfig(maxOutputTokens: 512),
        ),
      );

      final setupMsg = await LiveService.buildSetupMessageAsync(params);
      expect(
        setupMsg.setup?.systemInstruction?.parts?.first.text,
        'You are a helpful AI.',
      );
      expect(setupMsg.setup?.generationConfig?.temperature, 0.3);
      expect(setupMsg.setup?.generationConfig?.maxOutputTokens, 512);
      expect(
        setupMsg
            .setup
            ?.generationConfig
            ?.speechConfig
            ?.voiceConfig
            ?.prebuiltVoiceConfig
            ?.voiceName,
        'Aoede',
      );
      expect(setupMsg.setup?.sessionResumption?.handle, 'res-123');
      expect(setupMsg.setup?.proactivity?.proactiveAudio, true);
      expect(
        setupMsg.setup?.historyConfig?.initialHistoryInClientContent,
        true,
      );
      expect(setupMsg.setup?.tools, hasLength(2));
      expect(
        setupMsg.setup?.tools?[1].functionDeclarations?.first.name,
        'callable_fn',
      );
      final callParts = await callable.callTool([
        FunctionCall(id: 'c1', name: 'callable_fn', args: const {'x': 1}),
      ]);
      expect(callParts.first.functionResponse?.name, 'callable_fn');

      // 2. LiveSession.sessionId and receive()
      final channel = FakeWebSocketChannel();
      final session = LiveSession.forTesting(channel);
      channel.emit(
        jsonEncode({
          'setupComplete': {'sessionId': 'sess-abc-999'},
        }),
      );
      expect(session.sessionId, 'sess-abc-999');

      final turnFuture = session.receive().toList();
      channel.emit(
        jsonEncode({
          'serverContent': {
            'modelTurn': {
              'parts': [
                {'text': 'Chunk 1'},
              ],
            },
            'turnComplete': false,
          },
        }),
      );
      channel.emit(
        jsonEncode({
          'serverContent': {
            'modelTurn': {
              'parts': [
                {'text': 'Chunk 2'},
              ],
            },
            'turnComplete': true,
          },
        }),
      );
      final turnMessages = await turnFuture;
      expect(turnMessages, hasLength(2));
      expect(turnMessages.last.serverContent?.turnComplete, isTrue);

      // 3. LiveSendRealtimeInputParameters.media & LiveMusic parameter classes
      final rtParams = LiveSendRealtimeInputParameters(
        media: Blob.fromBytes(bytes: [1, 2], mimeType: 'audio/pcm'),
      );
      expect(rtParams.media?.mimeType, 'audio/pcm');

      final wpParams = LiveMusicSetWeightedPromptsParameters(
        weightedPrompts: [WeightedPrompt(text: 'Jazz piano', weight: 1.0)],
      );
      expect(
        LiveMusicSetWeightedPromptsParameters.fromJson(
          wpParams.toJson(),
        ).weightedPrompts.first.text,
        'Jazz piano',
      );

      final cfgParams = LiveMusicSetConfigParameters(
        musicGenerationConfig: LiveMusicGenerationConfig(bpm: 120),
      );
      expect(
        LiveMusicSetConfigParameters.fromJson(
          cfgParams.toJson(),
        ).musicGenerationConfig?.bpm,
        120,
      );

      // 4. LiveConnectConfig & Map config labels in setup and AuthTokensService
      final setupFromDict =
          jsonDecode(
                jsonEncode(
                  LiveService.buildSetupMessage(
                    LiveConnectParameters(
                      model: 'test_model',
                      config: const {
                        'labels': {'team': 'sdk'},
                      },
                    ),
                  ).toJson(),
                ),
              )
              as Map<String, dynamic>;
      expect(setupFromDict['setup']['model'], 'models/test_model');
      expect(setupFromDict['setup']['labels'], {'team': 'sdk'});
      expect(
        (setupFromDict['setup']['generationConfig'] as Map<String, dynamic>)
            .containsKey('labels'),
        isFalse,
      );

      final setupFromTyped =
          jsonDecode(
                jsonEncode(
                  LiveService.buildSetupMessage(
                    LiveConnectParameters(
                      model: 'test_model',
                      config: LiveConnectConfig(labels: const {'team': 'sdk'}),
                    ),
                  ).toJson(),
                ),
              )
              as Map<String, dynamic>;
      expect(setupFromTyped['setup']['labels'], {'team': 'sdk'});

      final httpClient = RecordingHttpClient(
        responder: (_) async => http.Response(
          jsonEncode({'name': 'auth_tokens/tok-labels'}),
          200,
        ),
      );
      final apiClient = ApiClient(apiKey: 'secret', httpClient: httpClient);
      final authService = AuthTokensService(apiClient);
      await authService.create(
        CreateAuthTokenConfig(
          liveConnectConstraints: LiveConnectConstraints(
            model: 'test_model',
            config: LiveConnectConfig(labels: const {'team': 'sdk'}),
          ),
        ),
      );
      final tokenReqBody =
          jsonDecode(httpClient.requests.single.body) as Map<String, dynamic>;
      expect(
        tokenReqBody['bidiGenerateContentSetup']['labels'],
        {'team': 'sdk'},
      );
      expect(
        tokenReqBody['bidiGenerateContentSetup']['generationConfig'],
        isNull,
      );
    });

    test('send methods reject invalid realtime mime types', () {
      final channel = FakeWebSocketChannel();
      final session = LiveSession.forTesting(channel);

      expect(
        () => session.sendVideo([1], mimeType: 'audio/pcm'),
        throwsArgumentError,
      );
      expect(
        () => session.sendRealtimeInput(
          audio: Blob(mimeType: 'image/png', data: 'abc'),
        ),
        throwsArgumentError,
      );
      expect(
        () => session.sendRealtimeInput(
          video: Blob(mimeType: 'audio/pcm', data: 'abc'),
        ),
        throwsArgumentError,
      );
    });

    test('sendMessage ignores writes after the channel is closed', () {
      final channel = FakeWebSocketChannel(closeCode: 1001);
      final session = LiveSession.forTesting(channel);

      session.sendMessage(
        LiveClientMessage(clientContent: LiveClientContent(turnComplete: true)),
      );

      expect(channel.sentMessages, isEmpty);
    });
  });

  test('TimeoutException uses a readable toString', () {
    expect(
      gemini_live.TimeoutException('bad things happened').toString(),
      'TimeoutException: bad things happened',
    );
  });

  group('Upstream Header Isolation & Credentials Parity (python-genai 0584c960 & js-genai fc5ad300b)', () {
    test('buildRequestHeaders does not mutate client default headers and populates X-Server-Timeout', () async {
      final apiClient = ApiClient(
        apiKey: 'test_api_key',
        httpOptions: const HttpOptions(
          timeout: 10000,
          headers: {'x-client-default': 'keep-me'},
        ),
      );
      final headersBefore = Map<String, String>.from(
        apiClient.httpOptions.headers ?? const {},
      );

      final reqHeaders = await apiClient.buildRequestHeaders(
        const {'Content-Type': 'application/json'},
      );

      expect(reqHeaders['X-Server-Timeout'], '10');
      expect(reqHeaders['x-client-default'], 'keep-me');
      expect(apiClient.httpOptions.headers, equals(headersBefore));
      expect(apiClient.httpOptions.headers!.containsKey('X-Server-Timeout'), isFalse);
      apiClient.close();
    });

    test('per-request timeout is not overridden by earlier client-timeout request', () async {
      final apiClient = ApiClient(
        apiKey: 'test_api_key',
        httpOptions: const HttpOptions(timeout: 10000),
      );

      final firstHeaders = await apiClient.buildRequestHeaders(
        const {'Content-Type': 'application/json'},
      );
      expect(firstHeaders['X-Server-Timeout'], '10');

      final secondHeaders = await apiClient.buildRequestHeaders(
        const {'Content-Type': 'application/json'},
        const HttpOptions(timeout: 3000),
      );
      expect(secondHeaders['X-Server-Timeout'], '3');
      apiClient.close();
    });

    test('REST request does not leak Authorization or x-goog-user-project into client default headers', () async {
      final httpClient = RecordingHttpClient(
        responder: (_) async => http.Response('{}', 200),
      );
      final creds = GenAICredentials(
        token: 'token-1',
        quotaProjectId: 'test-quota-project',
      );
      final apiClient = ApiClient(
        apiKey: 'test_api_key',
        credentials: creds,
        httpClient: httpClient,
      );

      await apiClient.post('sample/path', <String, dynamic>{});

      expect(httpClient.requests, hasLength(1));
      final sentHeaders = httpClient.requests.single.headers;
      expect(sentHeaders['Authorization'], 'Bearer token-1');
      expect(sentHeaders['x-goog-user-project'], 'test-quota-project');
      expect(
        apiClient.httpOptions.headers?.containsKey('Authorization') ?? false,
        isFalse,
      );
      expect(
        apiClient.httpOptions.headers?.containsKey('x-goog-user-project') ??
            false,
        isFalse,
      );
      apiClient.close();
    });

    test('LiveService.connect uses current rotated token after REST call and sets x-goog-user-project when present', () async {
      final httpClient = RecordingHttpClient(
        responder: (_) async => http.Response('{"name":"auth_tokens/t1"}', 200),
      );
      final creds = GenAICredentials(
        token: 'token-1',
        quotaProjectId: 'test-quota-project',
      );
      final genAI = GoogleGenAI(
        apiKey: 'test_api_key',
        credentials: creds,
        httpClient: httpClient,
      );

      // 1. Issue a REST call with token-1
      await genAI.authTokens.create(CreateAuthTokenConfig());
      expect(
        httpClient.requests.single.headers['Authorization'],
        'Bearer token-1',
      );
      expect(
        httpClient.requests.single.headers['x-goog-user-project'],
        'test-quota-project',
      );

      // 2. Rotate token to token-2
      creds.token = 'token-2';

      Map<String, dynamic>? capturedWsHeaders;
      final liveService = LiveService(
        apiKey: 'test_api_key',
        credentials: creds,
        connector: (uri, headers) async {
          capturedWsHeaders = headers;
          final ch = FakeWebSocketChannel();
          unawaited(
            Future<void>.delayed(
              Duration.zero,
              () => ch.emit(jsonEncode({'setupComplete': <String, dynamic>{}})),
            ),
          );
          return ch;
        },
      );

      final session = await liveService.connect(
        LiveConnectParameters(model: 'gemini-2.5-flash'),
      );
      await session.close();

      expect(capturedWsHeaders, isNotNull);
      expect(capturedWsHeaders!['Authorization'], 'Bearer token-2');
      expect(capturedWsHeaders!['x-goog-user-project'], 'test-quota-project');

      // 3. Without quotaProjectId, x-goog-user-project is omitted
      Map<String, dynamic>? capturedNoQuotaHeaders;
      final liveNoQuota = LiveService(
        apiKey: 'test_api_key',
        credentials: GenAICredentials(token: 'token-3'),
        connector: (uri, headers) async {
          capturedNoQuotaHeaders = headers;
          final ch = FakeWebSocketChannel();
          unawaited(
            Future<void>.delayed(
              Duration.zero,
              () => ch.emit(jsonEncode({'setupComplete': <String, dynamic>{}})),
            ),
          );
          return ch;
        },
      );

      final session2 = await liveNoQuota.connect(
        LiveConnectParameters(model: 'gemini-2.5-flash'),
      );
      await session2.close();

      expect(capturedNoQuotaHeaders!['Authorization'], 'Bearer token-3');
      expect(
        capturedNoQuotaHeaders!.containsKey('x-goog-user-project'),
        isFalse,
      );
      expect(liveNoQuota.supportsHeaders, isTrue);

      genAI.close();
    });
  });
}

class RecordingHttpClient extends http.BaseClient {
  RecordingHttpClient({required this.responder});

  final Future<http.Response> Function(RecordedRequest request) responder;
  final List<RecordedRequest> requests = [];
  bool closeCalled = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().bytesToString();
    final recordedRequest = RecordedRequest(
      method: request.method,
      uri: request.url,
      headers: Map<String, String>.from(request.headers),
      body: body,
    );
    requests.add(recordedRequest);

    final response = await responder(recordedRequest);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }

  @override
  void close() {
    closeCalled = true;
  }
}

class RecordedRequest {
  RecordedRequest({
    required this.method,
    required this.uri,
    required this.headers,
    required this.body,
  });

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String body;
}

class FakeWebSocketChannel implements WebSocketChannel {
  FakeWebSocketChannel({int? closeCode, String? closeReason})
    : _closeCode = closeCode,
      _closeReason = closeReason,
      sink = FakeWebSocketSink() {
    sink._owner = this;
  }

  final StreamController<Object?> _incomingController =
      StreamController<Object?>.broadcast(sync: true);
  final List<Object?> sentMessages = [];

  @override
  final FakeWebSocketSink sink;

  int sinkCloseCalls = 0;
  int? _closeCode;
  String? _closeReason;

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => _closeReason;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  Stream<Object?> get stream => _incomingController.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void emit(Object? data) {
    _incomingController.add(data);
  }

  void emitError(Object error) {
    _incomingController.addError(error);
  }

  Future<void> finish([int? code, String? reason]) async {
    _closeCode = code;
    _closeReason = reason;
    await _incomingController.close();
  }
}

class FakeWebSocketSink implements WebSocketSink {
  final StreamController<Object?> _outgoingController =
      StreamController<Object?>.broadcast(sync: true);

  @override
  Future<void> addStream(Stream<Object?> stream) =>
      _outgoingController.addStream(stream);

  @override
  void add(Object? data) {
    _outgoingController.add(data);
    _owner?.sentMessages.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _outgoingController.addError(error, stackTrace);
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    _owner?.sinkCloseCalls += 1;
    _owner?._closeCode ??= closeCode ?? 1000;
    _owner?._closeReason ??= closeReason;
    await _outgoingController.close();
  }

  @override
  Future<void> get done => _outgoingController.done;

  FakeWebSocketChannel? _owner;
}

Future<void> pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _TestCallableTool extends CallableTool {
  @override
  FutureOr<Tool> tool() async => Tool(
    functionDeclarations: [
      FunctionDeclaration(
        name: 'callable_fn',
        description: 'A callable tool declaration',
      ),
    ],
  );

  @override
  FutureOr<List<Part>> callTool(List<FunctionCall> functionCalls) async => [
    for (final call in functionCalls)
      Part(
        functionResponse: FunctionResponse(
          id: call.id,
          name: call.name,
          response: const {'ok': true},
        ),
      ),
  ];
}

