import 'dart:async';
import 'dart:async' as dart_async;
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
        expect(
          client.requests.single.headers['Content-Type'],
          'application/json',
        );
        expect(
          client.requests.single.headers['User-Agent'],
          startsWith('google-genai-sdk/'),
        );
        expect(
          client.requests.single.headers['x-goog-api-client'],
          startsWith('google-genai-sdk/'),
        );
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
          'google-genai-sdk/3.6.1 dart/9.9',
        );
        expect(seenHeaders['user-agent'], 'google-genai-sdk/3.6.1 dart/9.9');

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

    test('LiveService.connect rejects when WebSocket closes before setupComplete and closes channel on error', () async {
      final channel = FakeWebSocketChannel();
      int? observedCloseCode;
      String? observedCloseReason;
      final service = LiveService(
        apiKey: 'plain-key',
        connector: (uri, headers) async {
          unawaited(
            Future<void>.delayed(
              Duration.zero,
              () => channel.finish(1011, 'You exceeded your current quota.'),
            ),
          );
          return channel;
        },
      );

      await expectLater(
        () => service.connect(
          LiveConnectParameters(
            model: 'gemini-live-test',
            callbacks: LiveCallbacks(
              onClose: (code, reason) {
                observedCloseCode = code;
                observedCloseReason = reason;
              },
            ),
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('code 1011): You exceeded your current quota.'),
          ),
        ),
      );
      expect(observedCloseCode, 1011);
      expect(observedCloseReason, 'You exceeded your current quota.');
      expect(channel.sinkCloseCalls, greaterThanOrEqualTo(1));

      // Fallback when close event has no code or reason
      final fallbackChannel = FakeWebSocketChannel();
      final fallbackService = LiveService(
        apiKey: 'plain-key',
        connector: (uri, headers) async {
          unawaited(
            Future<void>.delayed(
              Duration.zero,
              () => fallbackChannel.finish(),
            ),
          );
          return fallbackChannel;
        },
      );

      await expectLater(
        () => fallbackService.connect(
          LiveConnectParameters(model: 'gemini-live-test'),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('code 1006): Abnormal closure.'),
          ),
        ),
      );
    });

    test('AudioTranscriptionConfig sourceText, SmartTranscriptionMode, and FinishReason', () {
      final transcriptionConfig = AudioTranscriptionConfig(
        languageCodes: const ['en-US', 'ko-KR'],
        wordTimestamp: true,
        diarization: false,
        mode: AudioTranscriptionConfigMode.SMART,
        sourceText: 'Original draft text',
      );
      final json = transcriptionConfig.toJson();
      expect(json['word_timestamp'], isTrue);
      expect(json['diarization'], isFalse);
      expect(json['mode'], 'SMART');
      expect(json['source_text'], 'Original draft text');

      final parsedCamel = AudioTranscriptionConfig.fromJson(const {
        'wordTimestamp': true,
        'diarization': true,
        'mode': 'SMART',
        'sourceText': 'Camel draft',
      });
      expect(parsedCamel.wordTimestamp, isTrue);
      expect(parsedCamel.diarization, isTrue);
      expect(parsedCamel.mode, AudioTranscriptionConfigMode.SMART);
      expect(parsedCamel.sourceText, 'Camel draft');

      final smartMode = SmartTranscriptionMode(sourceText: 'Rewrite this');
      expect(smartMode.toJson(), {
        'type': 'smart',
        'source_text': 'Rewrite this',
      });
      final smartFromCamel = SmartTranscriptionMode.fromJson(const {
        'sourceText': 'Edit via voice',
      });
      expect(smartFromCamel.type, 'smart');
      expect(smartFromCamel.sourceText, 'Edit via voice');

      expect(
        FinishReason.values,
        containsAll([
          FinishReason.STOP,
          FinishReason.CONTINUATION,
          FinishReason.MALFORMED_RESPONSE,
        ]),
      );
    });

    test('ApiClient resolves {api_version} placeholder and GOOGLE_GENAI_API_VERSION overrides', () async {
      expect(
        ApiClient.resolveApiVersionInPath('upload/{api_version}/files', 'v1alpha'),
        'upload/v1alpha/files',
      );
      expect(
        ApiClient.resolveApiVersionInPath('upload/{api_version}/files', ''),
        'upload/files',
      );
      expect(
        ApiClient.resolveDefaultApiVersion(
          environmentOverride: const {'GOOGLE_GENAI_API_VERSION': 'beta'},
        ),
        'v1beta',
      );
      expect(
        ApiClient.resolveDefaultApiVersion(
          environmentOverride: const {'GOOGLE_GENAI_API_VERSION': 'v1alpha'},
        ),
        'v1alpha',
      );

      ApiClient.setDefaultGoogleAiApiVersion('v1');
      try {
        expect(
          ApiClient.resolveDefaultApiVersion(environmentOverride: const {}),
          'v1',
        );
      } finally {
        ApiClient.setDefaultGoogleAiApiVersion(null);
      }

      final recorder = RecordingHttpClient(
        responder: (_) async => http.Response('{}', 200),
      );
      final client = ApiClient(
        apiKey: 'secret-key',
        apiVersion: 'v1beta',
        httpClient: recorder,
      );
      await client.post(
        'upload/{api_version}/files',
        const {'displayName': 'sample.txt'},
        httpOptions: const HttpOptions(apiVersion: 'v1alpha'),
      );
      expect(
        recorder.requests.single.uri.toString(),
        'https://generativelanguage.googleapis.com/upload/v1alpha/files?key=secret-key',
      );
      client.close();
    });

    test('FinishReason, ReinforcementTuningThinkingLevel, DocumentMimeTypes, multimodal CodeExecutionResult, ApiClientError/ApiServerError, and AFC extractCuratedHistory', () async {
      expect(
        FinishReason.values,
        containsAll([
          FinishReason.MISSING_THOUGHT_SIGNATURE,
          FinishReason.ESCALATION,
          FinishReason.PUP_LIMITED_DISABLED,
          FinishReason.MODEL_ARMOR,
        ]),
      );
      expect(
        ReinforcementTuningThinkingLevel.values,
        containsAll([
          ReinforcementTuningThinkingLevel.MINIMAL,
          ReinforcementTuningThinkingLevel.LOW,
          ReinforcementTuningThinkingLevel.MEDIUM,
          ReinforcementTuningThinkingLevel.HIGH,
        ]),
      );

      expect(DocumentMimeTypes.all.length, 12);
      expect(DocumentMimeTypes.isSupported(DocumentMimeTypes.pptx), isTrue);
      expect(DocumentMimeTypes.isSupported(DocumentMimeTypes.docx), isTrue);
      expect(DocumentMimeTypes.isSupported(DocumentMimeTypes.xlsx), isTrue);
      expect(DocumentMimeTypes.isSupported(DocumentMimeTypes.odt), isTrue);
      expect(DocumentMimeTypes.isSupported('application/octet-stream'), isFalse);

      // CodeExecutionResult text & multimodal content union
      final textExec = CodeExecutionResult.fromJson(const {
        'call_id': 'call_1',
        'is_error': false,
        'result': '42\n',
        'signature': 'sig_abc',
      });
      expect(textExec.id, 'call_1');
      expect(textExec.isError, isFalse);
      expect(textExec.output, '42\n');
      expect(textExec.result, '42\n');
      expect(textExec.signature, 'sig_abc');

      final multimodalExec = CodeExecutionResult.fromJson({
        'call_id': 'call_2',
        'result': [
          {
            'role': 'model',
            'parts': [
              {'text': 'Generated chart'},
              {
                'inlineData': {'mimeType': 'image/png', 'data': 'aGVsbG8='},
              },
            ],
          },
        ],
      });
      expect(multimodalExec.content, hasLength(1));
      expect(multimodalExec.result, isA<List<Content>>());
      expect(multimodalExec.toJson()['content'], isA<List<dynamic>>());

      // UsageMetadata snake_case traffic_type and service_tier
      final usage = UsageMetadata.fromJson(const {
        'prompt_token_count': 10,
        'candidates_token_count': 20,
        'traffic_type': 'ON_DEMAND_PRIORITY',
        'service_tier': 'priority',
      });
      expect(usage.promptTokenCount, 10);
      expect(usage.responseTokenCount, 20);
      expect(usage.trafficType, TrafficType.ON_DEMAND_PRIORITY);
      expect(usage.serviceTier, ServiceTier.PRIORITY);

      // Typed 4XX ApiClientError and 5XX ApiServerError
      final error400Client = ApiClient(
        apiKey: 'secret-key',
        httpClient: RecordingHttpClient(
          responder: (_) async => http.Response(
            jsonEncode({
              'error': {
                'code': 400,
                'message': 'Invalid model parameter',
                'status': 'INVALID_ARGUMENT',
              },
            }),
            400,
          ),
        ),
      );
      await expectLater(
        () => error400Client.get('voices'),
        throwsA(
          isA<ApiClientError>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'Invalid model parameter')
              .having((e) => e.error?.status, 'status', 'INVALID_ARGUMENT'),
        ),
      );
      error400Client.close();

      final error503Client = ApiClient(
        apiKey: 'secret-key',
        httpClient: RecordingHttpClient(
          responder: (_) async => http.Response(
            jsonEncode({
              'error': {
                'code': 503,
                'message': 'Service temporarily unavailable',
                'status': 'UNAVAILABLE',
              },
            }),
            503,
          ),
        ),
      );
      await expectLater(
        () => error503Client.post('voices', const {}),
        throwsA(
          isA<ApiServerError>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having(
                (e) => e.message,
                'message',
                'Service temporarily unavailable',
              ),
        ),
      );
      error503Client.close();

      // Curated history drops entire AFC exchange when final model turn is invalid
      final priorUser = Content(role: 'user', parts: [Part(text: 'hi')]);
      final priorModel = Content(role: 'model', parts: [Part(text: 'hello')]);
      final afcUser = Content(
        role: 'user',
        parts: [Part(text: 'what is the weather in Paris')],
      );
      final afcCall = Content(
        role: 'model',
        parts: [
          Part(
            functionCall: FunctionCall(
              name: 'get_weather',
              args: const {'city': 'Paris'},
            ),
          ),
        ],
      );
      final afcResp = Content(
        role: 'user',
        parts: [
          Part(
            functionResponse: FunctionResponse(
              name: 'get_weather',
              response: const {'result': 'sunny, 21C'},
            ),
          ),
        ],
      );
      final emptyModel = Content(role: 'model', parts: const []);

      final curated = GeminiLiveTranscriptExporter.extractCuratedHistory([
        priorUser,
        priorModel,
        afcUser,
        afcCall,
        afcResp,
        afcCall,
        afcResp,
        emptyModel,
      ]);
      expect(curated, [priorUser, priorModel]);

      // Spent-budget unanswered function call survives a rejected subsequent plain turn
      final spentBudgetHistory = [
        afcUser,
        afcCall,
        Content(role: 'user', parts: [Part(text: 'and in Rome?')]),
        emptyModel,
      ];
      expect(
        GeminiLiveTranscriptExporter.extractCuratedHistory(spentBudgetHistory),
        [afcUser, afcCall],
      );
    });

    test(
      'Upstream v3.1.0/v3.2.0 parity: ProactivityConfig.proactiveVideo, ThinkingLevel.XHIGH, InteractionModels/Agents, EnvironmentMode, and DecisionsService',
      () async {
        // 1. ProactivityConfig.proactiveVideo (snake_case & camelCase + LiveClientSetup)
        final proactivity = ProactivityConfig(
          proactiveAudio: true,
          proactiveVideo: true,
        );
        expect(proactivity.toJson(), {
          'proactive_audio': true,
          'proactive_video': true,
        });
        final fromCamel = ProactivityConfig.fromJson(const {
          'proactiveAudio': true,
          'proactiveVideo': true,
        });
        expect(fromCamel.proactiveAudio, isTrue);
        expect(fromCamel.proactiveVideo, isTrue);

        final setup = LiveClientSetup(
          model: LiveModels.gemini38Live,
          proactivity: proactivity,
        );
        expect(setup.toJson()['proactivity'], {
          'proactive_audio': true,
          'proactive_video': true,
        });

        // 2. ThinkingLevel.XHIGH & lowercase 'xhigh' normalization
        final xhighConfig = ThinkingConfig(
          includeThoughts: true,
          thinkingLevel: ThinkingLevel.XHIGH,
        );
        expect(xhighConfig.toJson(), {
          'include_thoughts': true,
          'thinking_level': 'XHIGH',
        });
        final parsedLowerXhigh = ThinkingConfig.fromJson(const {
          'includeThoughts': true,
          'thinkingBudget': 4096,
          'thinkingLevel': 'xhigh',
        });
        expect(parsedLowerXhigh.includeThoughts, isTrue);
        expect(parsedLowerXhigh.thinkingBudget, 4096);
        expect(parsedLowerXhigh.thinkingLevel, ThinkingLevel.XHIGH);

        // 3. InteractionModels, InteractionAgents, and EnvironmentMode
        expect(InteractionModels.gemini4Carbon, 'gemini-4-carbon');
        expect(InteractionModels.geminiOmni12Flash, 'gemini-omni-1.2-flash');
        expect(
          InteractionAgents.antigravityPreview092026,
          'antigravity-preview-09-2026',
        );
        expect(
          EnvironmentMode.fromJson('SELF_HOSTED'),
          EnvironmentMode.SELF_HOSTED,
        );
        expect(EnvironmentMode.ON_DEMAND.toJson(), 'on_demand');

        // 4. DecisionsService (client.decisions.create)
        late RecordedRequest capturedRequest;
        final recorder = RecordingHttpClient(
          responder: (request) async {
            capturedRequest = request;
            return http.Response(
              jsonEncode({
                'answers': {
                  'q1': {'type': 'noul', 'noul': 0.95, 'confidence': 0.95},
                  'q2': {
                    'type': 'choice',
                    'choice': 'replace',
                    'confidence': 0.88,
                    'probabilities': {'refund': 0.12, 'replace': 0.88},
                  },
                  'q3': {
                    'type': 'score',
                    'score': 1.8,
                    'confidence': 0.8,
                    'probabilities': {'0': 0.0, '1': 0.2, '2': 0.8},
                    'legend': {
                      '0': 'Poor',
                      '1': 'Acceptable',
                      '2': 'Excellent',
                    },
                  },
                },
                'prompt_feedback': {
                  'block_reason': 'safety',
                  'block_reason_message': 'none',
                },
                'usage': {'total_tokens': 42},
              }),
              200,
              headers: const {'content-type': 'application/json'},
            );
          },
        );
        final genAI = GoogleGenAI(
          apiKey: 'test-api-key',
          httpClient: recorder,
          httpOptions: const HttpOptions(
            apiVersion: 'v1beta',
            baseUrl: 'https://example.googleapis.com',
          ),
        );

        final response = await genAI.decisions.create(
          CreateDecisionRequest(
            model: 'decisions-prerelease',
            input: 'User prompt context',
            questions: {
              'q1': const NoulQuestion(
                instructions: 'Does the user want a summary?',
                criteria: NoulCriteria(
                  trueDescription: 'User asks for summary',
                  falseDescription: 'User asks for full text',
                ),
              ),
              'q2': const ChoiceQuestion(
                instructions: 'Pick action.',
                criteria: {'refund': '', 'replace': 'Ship a new unit.'},
              ),
              'q3': const {
                'type': 'score',
                'instructions': 'Rate quality.',
                'criteria': ['Poor', 'Acceptable', 'Excellent'],
              },
            },
          ),
        );

        expect(
          capturedRequest.uri.toString(),
          'https://example.googleapis.com/v1beta/decisions?key=test-api-key',
        );
        expect(capturedRequest.method, 'POST');
        final sentJson =
            jsonDecode(capturedRequest.body) as Map<String, dynamic>;
        expect(sentJson['model'], 'decisions-prerelease');
        expect(sentJson['input'], 'User prompt context');
        expect(
          (sentJson['questions'] as Map<String, dynamic>)['q2'],
          {
            'type': 'choice',
            'instructions': 'Pick action.',
            'criteria': {'refund': '', 'replace': 'Ship a new unit.'},
          },
        );

        final a1 = response.answers?['q1'];
        expect(a1, isA<NoulAnswer>());
        expect((a1 as NoulAnswer).noul, 0.95);
        expect(a1.confidence, 0.95);

        final a2 = response.answers?['q2'];
        expect(a2, isA<ChoiceAnswer>());
        expect((a2 as ChoiceAnswer).choice, 'replace');
        expect(a2.probabilities['replace'], 0.88);

        final a3 = response.answers?['q3'];
        expect(a3, isA<ScoreAnswer>());
        expect((a3 as ScoreAnswer).score, 1.8);
        expect(a3.legend['2'], 'Excellent');

        expect(
          response.promptFeedback?.blockReason,
          DecisionBlockReason.SAFETY,
        );
        expect(response.usage?['total_tokens'], 42);
        expect(
          CreateDecisionResponse.fromJson(response.toJson()).answers?.keys,
          containsAll(['q1', 'q2', 'q3']),
        );

        genAI.close();
      },
    );

    test(
      'Upstream v3.3.0 parity: InteractionModels.gemini4Hydrogen, default UTF-8 HTTP/SSE decoding, and GEMINI_API_KEY / GOOGLE_GENAI_DEBUG env helpers',
      () async {
        // 1. InteractionModels.gemini4Hydrogen and full Interactions model catalog
        expect(InteractionModels.gemini4Hydrogen, 'gemini-4-hydrogen');
        expect(InteractionModels.gemini4Carbon, 'gemini-4-carbon');
        expect(InteractionModels.gemini4Argon, 'gemini-4-argon');
        expect(InteractionModels.gemma4_26bA4bIt, 'gemma-4-26b-a4b-it');
        expect(InteractionModels.gemma4_31bIt, 'gemma-4-31b-it');
        expect(InteractionModels.geminiFlashLatest, 'gemini-flash-latest');
        expect(
          InteractionModels.geminiFlashLiteLatest,
          'gemini-flash-lite-latest',
        );
        expect(InteractionModels.geminiProLatest, 'gemini-pro-latest');
        expect(InteractionModels.gemini37Flash, 'gemini-3.7-flash');
        expect(InteractionModels.gemini36Flash, 'gemini-3.6-flash');
        expect(InteractionModels.gemini35Flash, 'gemini-3.5-flash');
        expect(InteractionModels.gemini35FlashLite, 'gemini-3.5-flash-lite');
        expect(InteractionModels.gemini38FlashTts, 'gemini-3.8-flash-tts');
        expect(
          InteractionModels.gemini38FlashLiteTts,
          'gemini-3.8-flash-lite-tts',
        );
        expect(InteractionModels.gemini35Transcribe, 'gemini-3.5-transcribe');
        expect(
          InteractionModels.geminiNanoBanana21,
          'gemini-nano-banana-2.1',
        );
        expect(
          InteractionModels.geminiRoboticsEr2Preview,
          'gemini-robotics-er-2-preview',
        );
        expect(
          InteractionModels.geminiRoboticsEr16Preview,
          'gemini-robotics-er-1.6-preview',
        );
        expect(InteractionModels.lyria35, 'lyria-3.5');
        expect(InteractionModels.lyria3ClipPreview, 'lyria-3-clip-preview');
        expect(InteractionModels.lyria3ProPreview, 'lyria-3-pro-preview');

        // 2. Default UTF-8 HTTP decoding when Content-Type omits charset
        final utf8PayloadBytes = utf8.encode(
          '{"text":"café 🎉 안녕하세요"}',
        );
        var mode = 'utf8_no_charset';
        final recorder = RecordingHttpClient(
          responder: (request) async {
            if (mode == 'utf8_no_charset') {
              return http.Response.bytes(
                utf8PayloadBytes,
                200,
                headers: const {'content-type': 'application/json'},
              );
            }
            if (mode == 'explicit_latin1') {
              return http.Response.bytes(
                latin1.encode('{"text":"café"}'),
                200,
                headers: const {
                  'content-type': 'application/json; charset=iso-8859-1',
                },
              );
            }
            return http.Response.bytes(
              utf8.encode(
                '{"error":{"code":400,"message":"잘못된 요청 café 🎉","status":"INVALID_ARGUMENT"}}',
              ),
              400,
              headers: const {'content-type': 'application/json'},
            );
          },
        );
        final client = ApiClient(apiKey: 'test-key', httpClient: recorder);

        final utf8Result = await client.get('models');
        expect(utf8Result['text'], 'café 🎉 안녕하세요');

        // Explicit non-UTF-8 charset is still respected
        mode = 'explicit_latin1';
        final latin1Result = await client.get('models');
        expect(latin1Result['text'], 'café');

        // Error envelopes without charset also decode multi-byte UTF-8 cleanly
        mode = 'utf8_error';
        await expectLater(
          () => client.get('models'),
          throwsA(
            isA<ApiClientError>().having(
              (e) => e.message,
              'message',
              '잘못된 요청 café 🎉',
            ),
          ),
        );
        client.close();

        // 3. SSE stream UTF-8 decoding across chunk boundaries
        final fullSseBytes = utf8.encode(
          ': keep-alive\n\n'
          'data: {"delta":"café 🎉 안녕하세요"}\n\n'
          'data: [DONE]\n\n',
        );
        // Split right inside the 4-byte UTF-8 sequence for 🎉 (0xF0 0x9F 0x8E 0x89)
        final emojiStart = fullSseBytes.indexOf(0xF0);
        expect(emojiStart, greaterThan(0));
        final chunk1 = fullSseBytes.sublist(0, emojiStart + 2);
        final chunk2 = fullSseBytes.sublist(emojiStart + 2);
        final events = await ApiClient.decodeSseJsonStream(
          Stream<List<int>>.fromIterable([chunk1, chunk2]),
          headers: const {'content-type': 'text/event-stream'},
        ).toList();
        expect(events, [
          {'delta': 'café 🎉 안녕하세요'},
        ]);

        // 4. GEMINI_API_KEY / GOOGLE_API_KEY precedence & GOOGLE_GENAI_DEBUG
        expect(
          ApiClient.resolveDefaultApiKey(
            environmentOverride: const {
              'GEMINI_API_KEY': 'gemini-env-key',
              'GOOGLE_API_KEY': 'google-env-key',
            },
          ),
          'gemini-env-key',
        );
        expect(
          ApiClient.resolveDefaultApiKey(
            environmentOverride: const {'GOOGLE_API_KEY': '  google-env-key  '},
          ),
          'google-env-key',
        );
        expect(
          ApiClient.resolveDefaultApiKey(environmentOverride: const {}),
          '',
        );

        for (final truthy in ['true', 'TRUE', '1', 'yes', 'Yes', 'on', ' ON ']) {
          expect(
            ApiClient.isDebugEnabled(
              environmentOverride: {'GOOGLE_GENAI_DEBUG': truthy},
            ),
            isTrue,
            reason: 'Expected "$truthy" to enable debug mode',
          );
        }
        for (final falsy in ['false', '0', 'no', 'off', '']) {
          expect(
            ApiClient.isDebugEnabled(
              environmentOverride: {'GOOGLE_GENAI_DEBUG': falsy},
            ),
            isFalse,
            reason: 'Expected "$falsy" not to enable debug mode',
          );
        }
        expect(ApiClient.isDebugEnabled(environmentOverride: const {}), isFalse);

        // GoogleGenAI() can be constructed without an explicit apiKey
        final keylessGenAI = GoogleGenAI(
          credentials: GenAICredentials(token: 'bearer-token'),
        );
        expect(keylessGenAI.apiKey, isA<String>());
        keylessGenAI.close();
      },
    );

    test(
      'Upstream 2026-11-16 parity: FunctionResponsePart Files API URIs, header case-variant merging, SSE CR/LF/CRLF & RawJsonLineBuffer, static media processing, ToolSearch, and recursive union schemas',
      () async {
        // 1. FunctionResponsePart.fromBytes / fromUri displayName, auto MIME, and Files API URIs
        final bytesPart = FunctionResponsePart.fromBytes(
          data: const [1, 2, 3],
          mimeType: 'image/png',
          displayName: 'chart.png',
        );
        expect(bytesPart.inlineData?.displayName, 'chart.png');

        final gcsPart = FunctionResponsePart.fromUri(
          fileUri: 'gs://generativeai-downloads/images/scones.jpg',
          displayName: 'scones.jpg',
        );
        expect(gcsPart.fileData?.mimeType, 'image/jpeg');
        expect(gcsPart.fileData?.displayName, 'scones.jpg');

        for (final filesUri in const [
          'https://generativelanguage.googleapis.com/v1beta/files/abc123',
          'https://autopush-generativelanguage.sandbox.googleapis.com/v1beta/files/abc123',
          'https://generativelanguage.googleapis.com/v1beta/files/abc123:download?alt=media',
        ]) {
          final filesPart = FunctionResponsePart.fromUri(fileUri: filesUri);
          expect(filesPart.fileData?.fileUri, filesUri);
          expect(filesPart.fileData?.mimeType, isNull);
        }

        for (final invalidUri in const [
          'gs://bucket/no_extension',
          'files/abc123',
          'https://example.com/v1beta/files/abc123',
          'https://generativelanguage.googleapis.com/v1beta/models/x?q=/files/a.jpg',
        ]) {
          expect(
            () => FunctionResponsePart.fromUri(fileUri: invalidUri),
            throwsArgumentError,
            reason: 'Expected unknown MIME error for $invalidUri',
          );
        }

        // 2. Collapse & merge User-Agent and x-goog-api-client case variants
        final mixedHeaders = <String, String>{
          'User-Agent': 'first/1',
          'user-agent': 'second/2',
          'USER-AGENT': 'first/1',
          'X-Goog-Api-Client': 'custom-sdk/1.0',
        };
        ApiClient.appendLibraryVersionHeaders(mixedHeaders);
        expect(
          mixedHeaders.keys.where((k) => k.toLowerCase() == 'user-agent'),
          ['user-agent'],
        );
        expect(
          mixedHeaders.keys
              .where((k) => k.toLowerCase() == 'x-goog-api-client'),
          ['x-goog-api-client'],
        );
        expect(mixedHeaders['user-agent'], contains('first/1 second/2'));
        expect(mixedHeaders['user-agent'], contains('google-genai-sdk/3.6.1'));
        expect(
          'first/1'.allMatches(mixedHeaders['user-agent']!).length,
          1,
        );
        final snapshotUa = mixedHeaders['user-agent'];
        ApiClient.appendLibraryVersionHeaders(mixedHeaders);
        expect(mixedHeaders['user-agent'], snapshotUa);

        final apiClient = ApiClient(
          apiKey: 'test-key',
          headers: const {'User-Agent': 'client-agent/1.0'},
        );
        final builtHeaders = await apiClient.buildRequestHeaders(
          const {},
          const HttpOptions(
            headers: {
              'user-agent': 'request-agent/2.0',
              'X-Goog-Api-Client': 'custom-client/3.0',
            },
          ),
        );
        expect(
          builtHeaders.keys.where((k) => k.toLowerCase() == 'user-agent'),
          ['user-agent'],
        );
        expect(
          builtHeaders['user-agent'],
          'client-agent/1.0 request-agent/2.0',
        );
        expect(
          builtHeaders.keys
              .where((k) => k.toLowerCase() == 'x-goog-api-client'),
          ['x-goog-api-client'],
        );
        expect(builtHeaders['x-goog-api-client'], 'custom-client/3.0');
        apiClient.close();

        // 3. SSE line splitting on CR/LF/CRLF only (ignoring U+2028/U+2029/U+0085)
        //    and RawJsonLineBuffer ignoring braces inside JSON strings
        final ssePayload =
            'data: {"text":"line1\u2028line2\u2029line3\u0085end"}\r\n'
            '\r\n';
        final sseBytes = utf8.encode(ssePayload);
        final crIndex = sseBytes.indexOf(0x0D);
        // Split right between \r and \n to verify CRLF across chunk boundaries
        final sseChunks = [
          sseBytes.sublist(0, crIndex + 1),
          sseBytes.sublist(crIndex + 1),
        ];
        final decodedSse = await ApiClient.decodeSseJsonStream(
          Stream<List<int>>.fromIterable(sseChunks),
        ).toList();
        expect(decodedSse, [
          {'text': 'line1\u2028line2\u2029line3\u0085end'},
        ]);

        // Raw multi-line JSON stream with unmatched braces & escaped quotes inside strings
        final rawJsonLines = [
          '{\n',
          '  "error": {\n',
          '    "code": 400,\n',
          '    "message": "Unmatched } and \\"{\\" inside string"\n',
          '  }\n',
          '}\n',
        ];
        final rawEvents = await ApiClient.decodeSseJsonStream(
          Stream<List<int>>.fromIterable(rawJsonLines.map(utf8.encode)),
        ).toList();
        expect(rawEvents, [
          {
            'error': {
              'code': 400,
              'message': 'Unmatched } and "{" inside string',
            },
          },
        ]);

        // 4. Static media processing options (video, audio, document page & spreadsheet)
        const videoProc = StaticMediaProcessing(
          contentLayers: [
            VideoContentLayer.frames,
            VideoContentLayer.audio,
            VideoContentLayer.transcript,
          ],
          startOffset: '5s',
          endOffset: '25.5s',
          fps: 2.0,
        );
        expect(
          StaticMediaProcessing.fromJson(videoProc.toJson()).toJson(),
          {
            'type': 'static',
            'content_layers': ['frames', 'audio', 'transcript'],
            'start_offset': '5s',
            'end_offset': '25.5s',
            'fps': 2.0,
          },
        );

        const audioProc = AudioStaticMediaProcessing(
          startOffset: '10.5s',
          endOffset: '30s',
        );
        expect(
          AudioStaticMediaProcessing.fromJson(audioProc.toJson()).toJson(),
          {'type': 'static', 'start_offset': '10.5s', 'end_offset': '30s'},
        );

        const docProc = DocumentStaticMediaProcessing(
          pageOptions: PageProcessingOptions(
            contentLayers: [
              PageContentLayer.pageImage,
              PageContentLayer.pageText,
            ],
            startPage: 1,
            endPage: 5,
          ),
          spreadsheetOptions: SpreadsheetProcessingOptions(
            contentLayers: [
              SpreadsheetContentLayer.visual,
              SpreadsheetContentLayer.data,
              SpreadsheetContentLayer.formulas,
            ],
            sheetIndex: 2,
            visibleCells: 'A1:D10',
          ),
        );
        expect(
          DocumentStaticMediaProcessing.fromJson(docProc.toJson()).toJson(),
          {
            'type': 'static',
            'page_options': {
              'content_layers': ['page_image', 'page_text'],
              'start_page': 1,
              'end_page': 5,
            },
            'spreadsheet_options': {
              'content_layers': ['visual', 'data', 'formulas'],
              'sheet_index': 2,
              'visible_cells': 'A1:D10',
            },
          },
        );

        // 5. Interactions ToolSearch, deferred FunctionDeclaration, steps & deltas
        final deferredDecl = FunctionDeclaration(
          name: 'lookup_order',
          description: 'Looks up full order details by ID.',
          shortDescription: 'Lookup order by ID',
          deferLoading: true,
        );
        expect(FunctionDeclaration.fromJson(deferredDecl.toJson()).toJson(), {
          'description': 'Looks up full order details by ID.',
          'name': 'lookup_order',
          'defer_loading': true,
          'short_description': 'Lookup order by ID',
        });

        const toolSearch = ToolSearch(
          execution: ToolSearchExecution.client,
          name: 'search_tools',
          description: 'Searches deferred client tools',
          parameters: {'type': 'object'},
        );
        expect(ToolSearch.fromJson(toolSearch.toJson()).toJson(), {
          'type': 'tool_search',
          'execution': 'client',
          'name': 'search_tools',
          'description': 'Searches deferred client tools',
          'parameters': {'type': 'object'},
        });

        const callStep = ToolSearchCallStep(
          id: 'ts-1',
          arguments: ToolSearchCallArguments(functionNames: ['lookup_order']),
          signature: 'sig-call',
        );
        expect(ToolSearchCallStep.fromJson(callStep.toJson()).toJson(), {
          'type': 'tool_search_call',
          'id': 'ts-1',
          'arguments': {
            'function_names': ['lookup_order'],
          },
          'signature': 'sig-call',
        });

        const resultStep = ToolSearchResultStep(
          callId: 'ts-1',
          result: [
            InteractionFunction(
              name: 'lookup_order',
              description: 'Looks up full order details by ID.',
              shortDescription: 'Lookup order by ID',
              deferLoading: true,
            ),
          ],
          signature: 'sig-res',
        );
        expect(ToolSearchResultStep.fromJson(resultStep.toJson()).toJson(), {
          'type': 'tool_search_result',
          'call_id': 'ts-1',
          'result': [
            {
              'type': 'function',
              'name': 'lookup_order',
              'description': 'Looks up full order details by ID.',
              'short_description': 'Lookup order by ID',
              'defer_loading': true,
            },
          ],
          'signature': 'sig-res',
        });

        const callDelta = ToolSearchCallDelta(
          arguments: ToolSearchCallArguments(functionNames: ['lookup_order']),
          signature: 'sig-d1',
        );
        expect(ToolSearchCallDelta.fromJson(callDelta.toJson()).toJson(), {
          'type': 'tool_search_call',
          'arguments': {
            'function_names': ['lookup_order'],
          },
          'signature': 'sig-d1',
        });

        const resultDelta = ToolSearchResultDelta(
          result: [InteractionFunction(name: 'lookup_order')],
          signature: 'sig-d2',
        );
        expect(ToolSearchResultDelta.fromJson(resultDelta.toJson()).toJson(), {
          'type': 'tool_search_result',
          'result': [
            {'type': 'function', 'name': 'lookup_order'},
          ],
          'signature': 'sig-d2',
        });

        // 6. Recursive union schema $defs / $ref resolution per path
        final recursiveUnionSchema = <String, dynamic>{
          r'$ref': r'#/$defs/Root',
          r'$defs': {
            'Shared': {
              'type': 'OBJECT',
              'properties': {
                'a': {'type': 'STRING'},
                'b': {'type': 'STRING'},
              },
            },
            'A': {
              'type': 'OBJECT',
              'properties': {
                's': {r'$ref': r'#/$defs/Shared'},
                'root': {r'$ref': r'#/$defs/Root'},
              },
            },
            'B': {
              'type': 'OBJECT',
              'properties': {
                's': {r'$ref': r'#/$defs/Shared'},
              },
            },
            'Root': {
              'anyOf': [
                {r'$ref': r'#/$defs/A'},
                {r'$ref': r'#/$defs/B'},
              ],
            },
          },
        };
        JsonSchemaTransformer.processSchema(recursiveUnionSchema);
        expect(recursiveUnionSchema, {
          'anyOf': [
            {
              'type': 'OBJECT',
              'properties': {
                's': {
                  'type': 'OBJECT',
                  'properties': {
                    'a': {'type': 'STRING'},
                    'b': {'type': 'STRING'},
                  },
                  'property_ordering': ['a', 'b'],
                },
                'root': <String, dynamic>{},
              },
              'property_ordering': ['s', 'root'],
            },
            {
              'type': 'OBJECT',
              'properties': {
                's': {
                  'type': 'OBJECT',
                  'properties': {
                    'a': {'type': 'STRING'},
                    'b': {'type': 'STRING'},
                  },
                  'property_ordering': ['a', 'b'],
                },
              },
            },
          ],
        });

        final nullableSelfRefSchema = <String, dynamic>{
          r'$ref': r'#/$defs/Node',
          r'$defs': {
            'Node': {
              'type': 'OBJECT',
              'properties': {
                'value': {'type': 'INTEGER'},
                'next': {
                  'anyOf': [
                    {r'$ref': r'#/$defs/Node'},
                    {'type': 'null'},
                  ],
                  'default': null,
                },
              },
            },
          },
        };
        JsonSchemaTransformer.processSchema(nullableSelfRefSchema);
        expect(nullableSelfRefSchema, {
          'type': 'OBJECT',
          'properties': {
            'value': {'type': 'INTEGER'},
            'next': {'default': null, 'nullable': true},
          },
          'property_ordering': ['value', 'next'],
        });
        expect(() => jsonEncode(nullableSelfRefSchema), returnsNormally);
      },
    );

    test(
      'Upstream v3.4.0..v3.6.1 parity: gemini-4-neon, file processing metadata on Part & FunctionResponsePart, McpServer.deferLoading, and Live Interactions auth tokens & events',
      () async {
        // 1. InteractionModels.gemini4Neon
        expect(InteractionModels.gemini4Neon, 'gemini-4-neon');

        // 2. DocumentMetadata, SpreadsheetMetadata, AudioMetadata, and VideoMetadata.contentLayers on Part
        final mediaPart = Part(
          fileData: FileData(
            fileUri: 'gs://bucket/report.pdf',
            mimeType: DocumentMimeTypes.pdf,
          ),
          videoMetadata: VideoMetadata(
            startOffset: '2s',
            endOffset: '12s',
            fps: 1.5,
            contentLayers: const [
              VideoMetadataContentLayer.FRAMES,
              VideoMetadataContentLayer.AUDIO,
              VideoMetadataContentLayer.TRANSCRIPT,
            ],
          ),
          documentMetadata: const DocumentMetadata(
            startPage: 1,
            endPage: 4,
            contentLayers: [
              DocumentMetadataContentLayer.PAGE_IMAGE,
              DocumentMetadataContentLayer.PAGE_TEXT,
            ],
          ),
          spreadsheetMetadata: const SpreadsheetMetadata(
            visibleCells: 'A1:F20',
            sheetIndex: 2,
            contentLayers: [
              SpreadsheetMetadataContentLayer.DATA,
              SpreadsheetMetadataContentLayer.FORMULAS,
              SpreadsheetMetadataContentLayer.VISUAL,
            ],
          ),
          audioMetadata: const AudioMetadata(
            startOffset: '0s',
            endOffset: '45.5s',
          ),
        );
        final reparsedPart = Part.fromJson(
          jsonDecode(jsonEncode(mediaPart.toJson())) as Map<String, dynamic>,
        );
        expect(reparsedPart.videoMetadata?.contentLayers, [
          VideoMetadataContentLayer.FRAMES,
          VideoMetadataContentLayer.AUDIO,
          VideoMetadataContentLayer.TRANSCRIPT,
        ]);
        expect(reparsedPart.documentMetadata?.startPage, 1);
        expect(reparsedPart.documentMetadata?.endPage, 4);
        expect(reparsedPart.documentMetadata?.contentLayers, [
          DocumentMetadataContentLayer.PAGE_IMAGE,
          DocumentMetadataContentLayer.PAGE_TEXT,
        ]);
        expect(reparsedPart.spreadsheetMetadata?.visibleCells, 'A1:F20');
        expect(reparsedPart.spreadsheetMetadata?.sheetIndex, 2);
        expect(reparsedPart.spreadsheetMetadata?.contentLayers, [
          SpreadsheetMetadataContentLayer.DATA,
          SpreadsheetMetadataContentLayer.FORMULAS,
          SpreadsheetMetadataContentLayer.VISUAL,
        ]);
        expect(reparsedPart.audioMetadata?.startOffset, '0s');
        expect(reparsedPart.audioMetadata?.endOffset, '45.5s');

        // Snake-case normalization on Part.fromJson
        final snakePart = Part.fromJson(const {
          'document_metadata': {
            'start_page': 2,
            'end_page': 3,
            'content_layers': ['PAGE_TEXT'],
          },
          'spreadsheet_metadata': {
            'visible_cells': 'B2:D5',
            'sheet_index': 1,
            'content_layers': ['DATA'],
          },
          'audio_metadata': {'start_offset': '5s', 'end_offset': '15s'},
        });
        expect(snakePart.documentMetadata?.startPage, 2);
        expect(snakePart.spreadsheetMetadata?.visibleCells, 'B2:D5');
        expect(snakePart.audioMetadata?.endOffset, '15s');

        // 3. FunctionResponsePart mediaResolution & file processing metadata
        final fnRespPart = FunctionResponsePart.fromUri(
          fileUri: 'gs://bucket/deck.pdf',
          displayName: 'deck.pdf',
          mediaResolution: PartMediaResolution(
            level: PartMediaResolutionLevel.MEDIA_RESOLUTION_HIGH,
            numTokens: 512,
          ),
          documentMetadata: const DocumentMetadata(
            startPage: 1,
            endPage: 2,
            contentLayers: [DocumentMetadataContentLayer.PAGE_IMAGE],
          ),
          spreadsheetMetadata: const SpreadsheetMetadata(
            visibleCells: 'A1:C10',
            sheetIndex: 1,
          ),
          audioMetadata: const AudioMetadata(
            startOffset: '1s',
            endOffset: '9s',
          ),
          videoMetadata: VideoMetadata(
            fps: 2.0,
            contentLayers: const [VideoMetadataContentLayer.FRAMES],
          ),
        );
        final reparsedFnPart = FunctionResponsePart.fromJson(
          jsonDecode(jsonEncode(fnRespPart.toJson())) as Map<String, dynamic>,
        );
        expect(
          reparsedFnPart.mediaResolution?.level,
          PartMediaResolutionLevel.MEDIA_RESOLUTION_HIGH,
        );
        expect(reparsedFnPart.documentMetadata?.endPage, 2);
        expect(reparsedFnPart.spreadsheetMetadata?.visibleCells, 'A1:C10');
        expect(reparsedFnPart.audioMetadata?.endOffset, '9s');
        expect(reparsedFnPart.videoMetadata?.contentLayers, [
          VideoMetadataContentLayer.FRAMES,
        ]);

        // 4. McpServer.deferLoading
        const mcpServer = McpServer(
          name: 'warehouse-tools',
          streamableHttpTransport: StreamableHttpTransport(
            url: 'https://mcp.example.com',
          ),
          deferLoading: true,
        );
        final reparsedMcp = McpServer.fromJson(mcpServer.toJson());
        expect(reparsedMcp.deferLoading, isTrue);
        expect(
          McpServer.fromJson(const {
            'name': 'camel-mcp',
            'deferLoading': true,
          }).deferLoading,
          isTrue,
        );

        // 5. AuthTokensService.createForInteraction & deleteForInteraction
        final recordedRequests = <RecordedRequest>[];
        final recorder = RecordingHttpClient(
          responder: (request) async {
            recordedRequests.add(request);
            if (request.method == 'POST') {
              return http.Response(
                jsonEncode({
                  'auth_token': 'int-token-123',
                  'expires_at': '2026-11-19T15:00:00Z',
                }),
                200,
                headers: const {'content-type': 'application/json'},
              );
            }
            return http.Response('', 200);
          },
        );
        final genAI = GoogleGenAI(
          apiKey: 'test-api-key',
          httpClient: recorder,
          httpOptions: const HttpOptions(
            apiVersion: 'v1beta',
            baseUrl: 'https://example.googleapis.com',
          ),
        );
        final token = await genAI.authTokens.createForInteraction(
          'interaction-42',
          params: const InteractionAuthTokenCreateParams(
            expireTime: '2026-11-19T15:00:00Z',
          ),
        );
        expect(token.authToken, 'int-token-123');
        expect(token.expiresAt, '2026-11-19T15:00:00Z');
        expect(
          recordedRequests.first.uri.toString(),
          'https://example.googleapis.com/v1beta/interactions/interaction-42/auth_tokens?key=test-api-key',
        );
        expect(
          jsonDecode(recordedRequests.first.body),
          {'expire_time': '2026-11-19T15:00:00Z'},
        );

        await genAI.authTokens.deleteForInteraction(
          'interaction-42',
          'int-token-123',
        );
        expect(recordedRequests.last.method, 'DELETE');
        expect(
          recordedRequests.last.uri.toString(),
          'https://example.googleapis.com/v1beta/interactions/interaction-42/auth_tokens/int-token-123?key=test-api-key',
        );
        genAI.close();

        // 6. Live Interactions & World Simulation event round-trips
        const createEvent = CreateInteractionEvent(
          model: InteractionModels.gemini4Neon,
          store: true,
          systemInstruction: 'Be concise.',
        );
        expect(CreateInteractionEvent.fromJson(createEvent.toJson()).toJson(), {
          'event_type': 'interaction.create',
          'model': 'gemini-4-neon',
          'store': true,
          'system_instruction': 'Be concise.',
        });

        const connectEvent = ConnectInteractionEvent(
          id: 'int-1',
          background: true,
        );
        expect(
          ConnectInteractionEvent.fromJson(connectEvent.toJson()).toJson(),
          {
            'event_type': 'interaction.connect',
            'id': 'int-1',
            'background': true,
          },
        );
        expect(
          CompleteInteractionEvent.fromJson(
            const CompleteInteractionEvent().toJson(),
          ).eventType,
          'interaction.complete',
        );
        expect(
          CancelInteractionEvent.fromJson(
            const CancelInteractionEvent().toJson(),
          ).eventType,
          'interaction.cancel',
        );
        expect(
          DisconnectEvent.fromJson(const DisconnectEvent().toJson()).eventType,
          'interaction.disconnect',
        );
        expect(
          LiveInteractionCreatedEvent.fromJson(
            const LiveInteractionCreatedEvent(interactionId: 'int-1').toJson(),
          ).interactionId,
          'int-1',
        );
        expect(
          InteractionConnectedEvent.fromJson(
            const InteractionConnectedEvent().toJson(),
          ).eventType,
          'interaction.connected',
        );
        expect(
          LiveInteractionCompletedEvent.fromJson(
            const LiveInteractionCompletedEvent(
              created: '2026-11-19T12:00:00Z',
              usage: {'total_tokens': 100},
            ).toJson(),
          ).usage?['total_tokens'],
          100,
        );
        expect(
          InteractionCancelledEvent.fromJson(
            const InteractionCancelledEvent(usage: {'total_tokens': 5}).toJson(),
          ).usage?['total_tokens'],
          5,
        );

        const worldSetup = WorldSetupEvent(
          worldPrompt: WorldPromptContent(text: 'A sunlit coastal village'),
          referenceImage: WorldReferenceImage(
            uri: 'gs://bucket/start.png',
            mimeType: 'image/png',
          ),
        );
        expect(WorldSetupEvent.fromJson(worldSetup.toJson()).toJson(), {
          'event_type': 'world_setup',
          'reference_image': {
            'mime_type': 'image/png',
            'uri': 'gs://bucket/start.png',
          },
          'world_prompt': {'text': 'A sunlit coastal village'},
        });

        const actionInput = UserActionInput(
          action: UserActionType.keyDown,
          input: UserActionKey.keyW,
        );
        expect(UserActionInput.fromJson(actionInput.toJson()).toJson(), {
          'event_type': 'user_action',
          'action': 'key_down',
          'input': 'key_w',
        });
      },
    );

    test(
      'Upstream 2026-11-23 parity: TextNormalization on SpeechConfig & SpeakerConfig, and UTF-8 default decoding on text/* responses',
      () {
        // 1. SpeechConfig.textNormalization round-trip and camelCase/lowercase normalization
        final speech = SpeechConfig.fromLiveVoice(
          GeminiLiveVoice.puck,
          languageCode: 'en-US',
          textNormalization: TextNormalization.ENABLED,
        );
        expect(speech.toJson()['text_normalization'], 'ENABLED');

        final reparsedSpeech = SpeechConfig.fromJson(speech.toJson());
        expect(reparsedSpeech.textNormalization, TextNormalization.ENABLED);

        final lowerCamelSpeech = SpeechConfig.fromJson(const {
          'languageCode': 'ko-KR',
          'textNormalization': 'disabled',
        });
        expect(lowerCamelSpeech.languageCode, 'ko-KR');
        expect(lowerCamelSpeech.textNormalization, TextNormalization.DISABLED);

        final promptedSpeech = SpeechConfig.withPromptedVoice(
          input: 'Calm documentary narrator',
          textNormalization: TextNormalization.AUTO,
        );
        expect(promptedSpeech.textNormalization, TextNormalization.AUTO);
        expect(promptedSpeech.toJson()['text_normalization'], 'AUTO');

        // 2. SpeakerConfig with speakers & text_normalization
        final speakerConfig = SpeakerConfig(
          speakers: [speech],
          textNormalization: 'enabled',
        );
        final reparsedSpeaker = SpeakerConfig.fromJson(speakerConfig.toJson());
        expect(reparsedSpeaker.textNormalization, 'enabled');
        expect(reparsedSpeaker.speakers?.single.voice, 'Puck');
        expect(
          SpeakerConfig.fromJson(const {
            'textNormalization': TextNormalization.DISABLED,
          }).textNormalization,
          'disabled',
        );

        // 3. UTF-8 default decoding on text/* HTTP responses without explicit charset
        final textResponse = http.Response.bytes(
          utf8.encode('안녕 café 🎉'),
          200,
          headers: const {'content-type': 'text/plain'},
        );
        expect(ApiClient.decodeResponseBody(textResponse), '안녕 café 🎉');
      },
    );

    test(
      'Upstream 2026-11-24 parity: HttpRetryOptions retries timeouts, transport/credential errors, and transient HTTP status codes',
      () async {
        // 1. HttpRetryOptions defaults, zero-delay preservation, and attempts==0 -> 1
        final parsedOptions = HttpRetryOptions.fromJson(const {
          'attempts': 0,
          'initialDelay': 0.0,
          'maxDelay': 0.0,
          'expBase': 2.0,
          'jitter': 0.0,
          'httpStatusCodes': [429, 503],
        });
        expect(parsedOptions.effectiveAttempts, 1);
        expect(parsedOptions.effectiveInitialDelay, 0.0);
        expect(parsedOptions.effectiveMaxDelay, 0.0);
        expect(parsedOptions.effectiveJitter, 0.0);
        expect(parsedOptions.effectiveHttpStatusCodes, [429, 503]);
        expect(ApiClient.computeRetryDelay(parsedOptions, 0), Duration.zero);

        // 2. Retries TimeoutException, ClientException (including credential refresh), and 503
        var tokenAttempts = 0;
        var httpAttempts = 0;
        final retryRecorder = RecordingHttpClient(
          responder: (request) async {
            httpAttempts += 1;
            if (httpAttempts == 1) {
              throw dart_async.TimeoutException('request timed out');
            }
            if (httpAttempts == 2) {
              return http.Response(
                '{"error":{"code":503,"message":"unavailable"}}',
                503,
                headers: const {'content-type': 'application/json'},
              );
            }
            return http.Response(
              '{"ok":true}',
              200,
              headers: const {'content-type': 'application/json'},
            );
          },
        );
        final retryClient = ApiClient(
          apiKey: '',
          httpClient: retryRecorder,
          credentials: GenAICredentials(
            tokenProvider: () async {
              tokenAttempts += 1;
              if (tokenAttempts == 1) {
                throw http.ClientException('temporary token refresh network drop');
              }
              return 'fresh-token';
            },
          ),
          httpOptions: HttpOptions(
            retryOptions: const HttpRetryOptions(
              attempts: 5,
              initialDelay: 0.0,
              maxDelay: 0.0,
              jitter: 0.0,
            ).toJson(),
          ),
        );

        final retryResult = await retryClient.post('models', const {'ping': 1});
        expect(retryResult, {'ok': true});
        // 1 credential transport failure + 1 HTTP timeout + 1 HTTP 503 + 1 HTTP 200
        expect(tokenAttempts, 4);
        expect(httpAttempts, 3);

        // 3. Non-retryable 400 ApiClientError fails immediately without retry
        var badRequestAttempts = 0;
        final nonRetryRecorder = RecordingHttpClient(
          responder: (request) async {
            badRequestAttempts += 1;
            return http.Response(
              '{"error":{"code":400,"message":"invalid argument"}}',
              400,
              headers: const {'content-type': 'application/json'},
            );
          },
        );
        final nonRetryClient = ApiClient(
          apiKey: 'test-key',
          httpClient: nonRetryRecorder,
          httpOptions: HttpOptions(
            retryOptions: const HttpRetryOptions(
              attempts: 4,
              initialDelay: 0.0,
              jitter: 0.0,
            ).toJson(),
          ),
        );
        await expectLater(
          () => nonRetryClient.get('models'),
          throwsA(isA<ApiClientError>()),
        );
        expect(badRequestAttempts, 1);

        retryClient.close();
        nonRetryClient.close();
      },
    );

    test(
      'Upstream 2026-11-26 parity: Part.fromFunctionResponse id propagation, GeminiLiveToolRegistry call id handling, and WorldReferenceImage.fromBytes',
      () async {
        // 1. Part.fromFunctionResponse with id, multimodal parts, scheduling, willContinue
        final partWithId = Part.fromFunctionResponse(
          name: 'func',
          response: const {'response': 'value'},
          id: 'call_1',
          parts: [
            FunctionResponsePart.fromBytes(
              data: const [1, 2, 3],
              mimeType: 'image/png',
            ),
          ],
          scheduling: FunctionResponseScheduling.WHEN_IDLE,
          willContinue: true,
        );
        expect(partWithId.functionResponse?.id, 'call_1');
        expect(partWithId.functionResponse?.name, 'func');
        expect(partWithId.functionResponse?.response, {'response': 'value'});
        expect(partWithId.functionResponse?.parts?.length, 1);
        expect(
          partWithId.functionResponse?.scheduling,
          FunctionResponseScheduling.WHEN_IDLE,
        );
        expect(partWithId.functionResponse?.willContinue, isTrue);

        // 2. GeminiLiveToolRegistry preserves distinct FunctionCall.id on success & error
        final registry = GeminiLiveToolRegistry([
          GeminiLiveFunctionTool(
            name: 'func_under_test',
            description: 'Increments integer input.',
            handler: (args) {
              final a = args['a'] as int;
              if (a < 0) {
                throw StateError('negative input');
              }
              return {'result': a + 1};
            },
          ),
        ]);
        final toolParts = await registry.callTool([
          FunctionCall(id: 'call_1', name: 'func_under_test', args: {'a': 1}),
          FunctionCall(id: 'call_2', name: 'func_under_test', args: {'a': 2}),
          FunctionCall(id: 'call_err', name: 'func_under_test', args: {'a': -1}),
        ]);
        expect(toolParts.length, 3);
        expect(toolParts[0].functionResponse?.id, 'call_1');
        expect(toolParts[0].functionResponse?.name, 'func_under_test');
        expect(toolParts[0].functionResponse?.response, {'result': 2});
        expect(toolParts[1].functionResponse?.id, 'call_2');
        expect(toolParts[1].functionResponse?.response, {'result': 3});
        expect(toolParts[2].functionResponse?.id, 'call_err');
        expect(
          toolParts[2].functionResponse?.response?['error'] as String?,
          contains('negative input'),
        );

        // 3. WorldReferenceImage.fromBytes and raw byte/base64 fromJson handling
        final rawBytes = utf8.encode('fake-png-bytes');
        final expectedB64 = base64Encode(rawBytes);
        final imgFromBytes = WorldReferenceImage.fromBytes(
          bytes: rawBytes,
          mimeType: 'image/png',
        );
        expect(imgFromBytes.data, expectedB64);
        expect(imgFromBytes.mimeType, 'image/png');

        final imgFromRawJson = WorldReferenceImage.fromJson({
          'data': rawBytes,
          'mimeType': 'image/png',
        });
        expect(imgFromRawJson.data, expectedB64);
        expect(imgFromRawJson.mimeType, 'image/png');

        final imgFromB64Json = WorldReferenceImage.fromJson({
          'data': expectedB64,
          'mime_type': 'image/png',
        });
        expect(imgFromB64Json.data, expectedB64);
      },
    );
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

