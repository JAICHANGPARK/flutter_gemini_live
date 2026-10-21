import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:gemini_live/src/client/api_client.dart';
import 'package:gemini_live/src/platform/runtime_info_stub.dart' as stub_info;
import 'package:gemini_live/src/platform/runtime_info_web.dart' as web_info;
import 'package:gemini_live/src/platform/web_socket_service_stub.dart' as stub_ws;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) responder;

  _FakeHttpClient(this.responder);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await responder(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class _TestWebSocketChannel implements WebSocketChannel {
  _TestWebSocketChannel({int? closeCode, String? closeReason})
      : _closeCode = closeCode,
        _closeReason = closeReason,
        sink = _TestWebSocketSink() {
    sink._owner = this;
  }

  final StreamController<Object?> _incoming =
      StreamController<Object?>.broadcast(sync: true);
  final List<Object?> sentMessages = [];

  @override
  final _TestWebSocketSink sink;

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
  Stream<Object?> get stream => _incoming.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void emit(Object? data) {
    _incoming.add(data);
  }

  Future<void> finish([int? code, String? reason]) async {
    _closeCode = code;
    _closeReason = reason;
    await _incoming.close();
  }
}

class _TestWebSocketSink implements WebSocketSink {
  final StreamController<Object?> _outgoing =
      StreamController<Object?>.broadcast(sync: true);

  @override
  Future<void> addStream(Stream<Object?> stream) =>
      _outgoing.addStream(stream);

  @override
  void add(Object? data) {
    _outgoing.add(data);
    _owner?.sentMessages.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _outgoing.addError(error, stackTrace);
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    _owner?.sinkCloseCalls += 1;
    _owner?._closeCode ??= closeCode ?? 1000;
    _owner?._closeReason ??= closeReason;
    await _outgoing.close();
    await _owner?.finish(closeCode, closeReason);
  }

  @override
  Future<void> get done => _outgoing.done;

  _TestWebSocketChannel? _owner;
}

void main() {
  group('Part 1 Coverage Tests', () {
    test('platform stubs return expected versions and throw for stub ws', () {
      expect(stub_info.dartVersion(), '3.0');
      expect(web_info.dartVersion(), '3.0');
      expect(
        () => stub_ws.connect(Uri.parse('wss://example.com'), {}),
        throwsUnsupportedError,
      );
    });

    test('ApiClient GET and DELETE non-2xx error handling', () async {
      final client = _FakeHttpClient((req) async {
        return http.Response('error response body', 500);
      });
      final api = ApiClient(apiKey: 'key', httpClient: client);

      expect(() => api.get('test/path'), throwsA(isA<Exception>()));
      expect(() => api.delete('test/path'), throwsA(isA<Exception>()));

      final emptyDeleteClient = _FakeHttpClient((req) async {
        return http.Response('', 200);
      });
      final emptyApi = ApiClient(apiKey: 'key', httpClient: emptyDeleteClient);
      final emptyRes = await emptyApi.delete('test/path');
      expect(emptyRes, isEmpty);
    });

    test('LiveServerError serialization and toString', () {
      final err = LiveServerError(code: 400, message: 'Bad request', status: 'INVALID_ARGUMENT');
      expect(err.code, 400);
      expect(err.message, 'Bad request');
      expect(err.status, 'INVALID_ARGUMENT');
      expect(err.toString(), contains('LiveServerError(code: 400'));

      final json = {'code': 404, 'message': 'Not Found', 'status': 'NOT_FOUND'};
      final fromJson = LiveServerError.fromJson(json);
      expect(fromJson.code, 404);
      expect(fromJson.status, 'NOT_FOUND');
    });

    test('HistoryConfig and LiveClientSetup historyConfig serialization', () {
      final history = HistoryConfig(initialHistoryInClientContent: true);
      expect(history.initialHistoryInClientContent, isTrue);
      final json = history.toJson();
      expect(json['initial_history_in_client_content'], isTrue);

      final roundTrip = HistoryConfig.fromJson(json);
      expect(roundTrip.initialHistoryInClientContent, isTrue);

      final setup = LiveClientSetup(
        model: 'models/gemini-2.0-flash-exp',
        historyConfig: history,
      );
      final setupJson = setup.toJson();
      expect(setupJson['historyConfig'], isNotNull);
      expect(setupJson['historyConfig']['initial_history_in_client_content'], isTrue);
    });

    test('GeminiLiveLogger debugPrint branch when output is null', () {
      final logger = GeminiLiveLogger(
        level: GeminiLiveLogLevel.traffic,
        output: null,
      );
      logger.info('Hello from debugPrint logger');
      logger.warning('Warning message');
      logger.error('Error message');
    });

    test('GeminiLiveTokenUsageTracker thoughtsTokens getter', () {
      final tracker = GeminiTokenUsageTracker();
      tracker.recordUsage(UsageMetadata(
        promptTokenCount: 10,
        responseTokenCount: 20,
        totalTokenCount: 30,
        thoughtsTokenCount: 5,
      ));
      expect(tracker.thoughtsTokens, 5);
    });

    test('VoicesService handles VoiceType.prebuilt filter', () async {
      final client = _FakeHttpClient((req) async {
        expect(req.url.queryParameters['type'], 'prebuilt');
        return http.Response(jsonEncode({'voices': []}), 200);
      });
      final voices = GeminiVoicesService(apiKey: 'key', httpClient: client);
      final res = await voices.listVoices(type: VoiceType.prebuilt);
      expect(res.voices, isEmpty);
    });

    test('CreateAuthTokenConfig fromJson serialization', () {
      final json = {
        'expire_time': '2026-10-18T00:00:00Z',
        'uses': 5,
      };
      final config = CreateAuthTokenConfig.fromJson(json);
      expect(config.expireTime, '2026-10-18T00:00:00Z');
      expect(config.uses, 5);
      final outJson = config.toJson();
      expect(outJson['uses'], 5);
    });

    test('GeminiLiveReconnectPolicy constructor and asserts', () {
      const policy = GeminiLiveReconnectPolicy(
        maxAttempts: 3,
        backoffMultiplier: 2.0,
      );
      expect(policy.maxAttempts, 3);
      expect(policy.delayForAttempt(0), const Duration(milliseconds: 500));

      expect(
        () => GeminiLiveReconnectPolicy(maxAttempts: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GeminiLiveReconnectPolicy(backoffMultiplier: 0.5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('GeminiLiveAudioBuffer pause, resume, and toPcmBytes', () async {
      final buffer = GeminiLiveAudioBuffer();
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      buffer.add(bytes);
      expect(buffer.toPcmBytes(), equals(bytes));

      final streamCtrl = StreamController<Uint8List>();
      final chunker = GeminiLivePcmChunker(chunkSizeInBytes: 4);
      final chunkStream = chunker.bind(streamCtrl.stream);
      final sub = chunkStream.listen((_) {});
      sub.pause();
      sub.resume();
      await sub.cancel();
      await streamCtrl.close();
    });

    test('LiveService handles empty modalities, error messages, and logs', () async {
      // 1. empty modalities fallback in buildSetupMessage
      final setupMsg = LiveService.buildSetupMessage(
        LiveConnectParameters(
          model: 'models/gemini-2.0-flash-exp',
          callbacks: LiveCallbacks(),
          config: GenerationConfig(responseModalities: []),
        ),
      );
      expect(setupMsg.setup?.generationConfig?.responseModalities, [Modality.AUDIO]);

      // 2. handleWebSocketData with error message
      final logs = <String>[];
      final service = LiveService(
        apiKey: 'key',
        logger: (msg) => logs.add(msg),
      );

      Object? caughtError;
      service.handleWebSocketDataForTesting(
        jsonEncode({
          'error': {
            'code': 403,
            'status': 'PERMISSION_DENIED',
            'message': 'Quota exceeded',
          },
        }),
        LiveCallbacks(
          onError: (err, st) {
            caughtError = err;
          },
        ),
      );

      expect(caughtError, isNotNull);
      expect(caughtError.toString(), contains('Quota exceeded'));
      expect(logs.any((l) => l.contains('Live Server returned error')), isTrue);

      // 3. connect with ephemeral token and non-v1alpha apiVersion warns via logger
      final channel = _TestWebSocketChannel();
      final ephemeralService = LiveService(
        apiKey: 'auth_tokens/test_ephemeral',
        apiVersion: 'v1beta',
        logger: (msg) => logs.add(msg),
        connector: (uri, headers) async {
          unawaited(
            Future<void>.delayed(
              Duration.zero,
              () => channel.emit('{"setupComplete":{}}'),
            ),
          );
          return channel;
        },
      );

      final session = await ephemeralService.connect(
        LiveConnectParameters(
          model: 'models/gemini-2.0-flash-exp',
          callbacks: LiveCallbacks(),
        ),
      );

      expect(logs.any((l) => l.contains('Ephemeral token support is only available on v1alpha')), isTrue);

      // Close session and verify onDone log
      await session.close();
      expect(logs.any((l) => l.contains('WebSocket connection closed')), isTrue);
    });
  });
}
