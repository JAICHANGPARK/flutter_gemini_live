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
          'google-genai-sdk/1.50.1 dart/9.9',
        );
        expect(seenHeaders['user-agent'], 'google-genai-sdk/1.50.1 dart/9.9');

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
