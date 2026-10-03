// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/compat/firebase_ai.dart';
import 'package:gemini_live/gemini_live.dart' as core;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'compat/firebase_ai_portable_sample.dart';

class _FakeSink implements WebSocketSink {
  _FakeSink(this.channel);

  final _FakeChannel channel;
  final List<Map<String, dynamic>> sent = [];

  @override
  void add(dynamic data) {
    if (channel.closeCode != null) return;
    sent.add(jsonDecode(data as String) as Map<String, dynamic>);
    if (sent.length == 1) {
      scheduleMicrotask(() => channel.serverSend({'setupComplete': {}}));
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    channel.closeCode ??= closeCode ?? 1000;
    await channel.incoming.close();
  }

  @override
  Future<void> get done => Future.value();
}

class _FakeChannel implements WebSocketChannel {
  _FakeChannel() {
    _sink = _FakeSink(this);
  }

  final incoming = StreamController<dynamic>();
  late final _FakeSink _sink;

  @override
  int? closeCode;

  List<Map<String, dynamic>> get sent => _sink.sent;

  void serverSend(Map<String, dynamic> json) => incoming.add(jsonEncode(json));

  Future<void> serverClose() async {
    closeCode = 1000;
    await incoming.close();
  }

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake server that hands out a new channel per connection.
class _FakeServer {
  final channels = <_FakeChannel>[];

  _FakeChannel get current => channels.last;

  FirebaseAI ai() => FirebaseAI.forTesting(
        core.LiveService(
          apiKey: 'test-key',
          connector: (uri, headers) async {
            final channel = _FakeChannel();
            channels.add(channel);
            return channel;
          },
        ),
      );
}

Map<String, dynamic> _setupOf(_FakeChannel channel) =>
    channel.sent.first['setup'] as Map<String, dynamic>;

void main() {
  group('FirebaseAI entry point', () {
    test('requires an API key', () {
      FirebaseAI.initialize(apiKey: '');
      expect(() => FirebaseAI.googleAI(), throwsStateError);
      expect(FirebaseAI.googleAI(apiKey: 'k'), isA<FirebaseAI>());
      FirebaseAI.initialize(apiKey: 'k');
      expect(FirebaseAI.googleAI(), isA<FirebaseAI>());
    });
  });

  group('Content and Part', () {
    test('match firebase_ai factories and json', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(Content.text('hi').toJson(), {
        'role': 'user',
        'parts': [
          {'text': 'hi'}
        ],
      });
      expect(Content.system('s').role, 'system');
      expect(Content.multi([TextPart('a')]).role, 'user');
      expect(Content.model([TextPart('a')]).role, 'model');
      expect(Content.functionResponse('f', {'a': 1}, id: 'x').role, 'function');
      expect(Content('user', [InlineDataPart('image/png', bytes)]).toJson(), {
        'role': 'user',
        'parts': [
          {
            'inlineData': {'data': base64Encode(bytes), 'mimeType': 'image/png'}
          }
        ],
      });
      expect(
        FunctionDeclaration('f', 'd',
            parameters: {'x': Schema.string(), 'y': Schema.integer()},
            optionalParameters: ['y']).toJson(),
        {
          'name': 'f',
          'description': 'd',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'x': {'type': 'STRING'},
              'y': {'type': 'INTEGER'},
            },
            'required': ['x'],
          },
        },
      );
    });
  });

  group('LiveSession over the core engine', () {
    late _FakeServer server;
    late LiveSession session;

    setUp(() async {
      server = _FakeServer();
      session = await buildSampleModel(server.ai()).connect(
        sessionResumption: SessionResumptionConfig(),
      );
    });

    tearDown(() => session.close());

    test('connect() sends the full setup', () {
      final setup = _setupOf(server.current);
      expect(setup['model'], 'models/gemini-2.5-flash-native-audio-preview-12-2025');

      final generation = setup['generation_config'] as Map<String, dynamic>;
      expect(generation['response_modalities'], ['AUDIO']);
      expect(generation['temperature'], 0.7);
      expect(generation['media_resolution'], 'MEDIA_RESOLUTION_LOW');
      final speech = jsonEncode(generation['speech_config']);
      expect(speech, contains('Puck'));
      expect(speech, contains('ko-KR'));
      expect(generation.containsKey('audio_transcription_config'), isFalse);

      expect(setup['system_instruction']['parts'][0]['text'], 'Answer briefly.');
      expect(setup.containsKey('input_audio_transcription'), isTrue);
      expect(setup.containsKey('output_audio_transcription'), isTrue);
      expect(setup['session_resumption'], isA<Map>());

      final tools = jsonEncode(setup['tools']);
      expect(tools, contains('getWeather'));
      expect(tools, contains('"required":["city"]'));
      expect(tools, contains('google_search'));

      final realtime = jsonEncode(setup['realtime_input_config']);
      expect(realtime, contains('START_SENSITIVITY_HIGH'));
      expect(realtime, contains('START_OF_ACTIVITY_INTERRUPTS'));
      expect(realtime, contains('TURN_INCLUDES_ONLY_ACTIVITY'));
      expect(jsonEncode(setup['context_window_compression']), contains('1000'));
    });

    test('send methods use the realtime audio/video/text fields', () async {
      final mic = Stream.fromIterable([
        Uint8List.fromList([9, 9])
      ]);
      await sendSampleInput(session, mic);

      final sent = server.current.sent.skip(1).toList();
      expect(sent[0]['realtimeInput']['audio']['mimeType'],
          'audio/pcm;rate=16000');
      expect(sent[1]['realtimeInput']['video']['mimeType'], 'image/jpeg');
      expect(sent[2]['realtimeInput']['text'], 'hello');
      expect(sent[3]['realtimeInput']['audio']['data'],
          base64Encode([9, 9]));
      expect(sent[3]['realtimeInput'].containsKey('mediaChunks'), isFalse);
      expect(sent[4]['clientContent']['turns'][0]['parts'][0]['text'],
          'What is Flutter?');
      expect(sent[4]['clientContent']['turnComplete'], isTrue);
    });

    test('send() defaults turnComplete to false like firebase_ai', () async {
      await session.send(input: Content.text('part 1'));
      expect(server.current.sent.last['clientContent']['turnComplete'], isFalse);
    });

    test('receive() maps every server message type', () async {
      final turnFuture = handleSampleTurn(session);
      final audio = Uint8List.fromList([7, 8, 9]);
      final channel = server.current
        ..serverSend({
          'toolCall': {
            'functionCalls': [
              {
                'id': 'call-1',
                'name': 'getWeather',
                'args': {'city': 'Seoul'}
              }
            ]
          }
        })
        ..serverSend({
          'toolCallCancellation': {
            'ids': ['call-0']
          }
        })
        ..serverSend({
          'sessionResumptionUpdate': {'newHandle': 'h1', 'resumable': true}
        })
        ..serverSend({
          'goAway': {'timeLeft': '10s'}
        })
        ..serverSend({
          'serverContent': {
            'modelTurn': {
              'parts': [
                {'text': 'Sunny'},
                {
                  'inlineData': {
                    'mimeType': 'audio/pcm;rate=24000',
                    'data': base64Encode(audio)
                  }
                },
              ]
            },
            'outputTranscription': {'text': 'Sunny'},
            'interrupted': true,
          },
          'usageMetadata': {
            'promptTokenCount': 15,
            'responseTokenCount': 25,
            'totalTokenCount': 40
          },
        })
        ..serverSend({
          'serverContent': {'turnComplete': true}
        });

      final turn = await turnFuture;
      expect(turn.toolCalls, ['getWeather(Seoul)']);
      expect(turn.cancelledCalls, ['call-0']);
      expect(turn.resumeHandle, 'h1');
      expect(turn.goAwayTimeLeft, '10s');
      expect(turn.text.toString(), 'Sunny');
      expect(turn.audioBytes, 3);
      expect(turn.captions, ['Sunny']);
      expect(turn.interrupted, isTrue);

      final toolResponse = channel.sent.last['toolResponse'];
      expect(toolResponse['functionResponses'][0]['id'], 'call-1');
      expect(toolResponse['functionResponses'][0]['response'], {'tempC': 21});

      // gemini_live-only extras.
      expect(session.tokenTracker.totalTokens, 40);
      expect(session.rawSession, isA<core.LiveSession>());
    });

    test('messages that arrive before receive() are not dropped', () async {
      server.current.serverSend({
        'serverContent': {
          'modelTurn': {
            'parts': [
              {'text': 'early'}
            ]
          },
          'turnComplete': true,
        }
      });
      await pumpEventQueue();

      final turn = await handleSampleTurn(session);
      expect(turn.text.toString(), 'early');
    });

    test('rawMessage exposes fields firebase_ai drops', () async {
      final first = session
          .receive()
          .firstWhere((r) => r.message is LiveServerContent);
      server.current.serverSend({
        'serverContent': {'turnComplete': true},
        'usageMetadata': {'totalTokenCount': 5},
      });
      final response = await first;
      expect(response.rawMessage?.usageMetadata?.totalTokenCount, 5);
    });

    test('receive() completes when the server closes', () async {
      final done = session.receive().toList();
      await server.current.serverClose();
      await expectLater(done, completes);
      expect(() => session.send(input: Content.text('x')),
          throwsA(isA<Exception>()));
    });

    test('resumeSession() reconnects and keeps the receive stream', () async {
      final texts = <String>[];
      final sub = session.receive().listen((r) {
        final m = r.message;
        if (m is LiveServerContent) {
          texts.addAll(m.modelTurn?.parts.whereType<TextPart>().map((p) => p.text) ?? []);
        }
      });

      final first = server.current;
      await session.resumeSession(
          sessionResumption: SessionResumptionConfig.resume('h1'));
      expect(server.channels.length, 2);
      expect(first.closeCode, isNotNull);
      expect(_setupOf(server.current)['session_resumption']['handle'], 'h1');

      server.current.serverSend({
        'serverContent': {
          'modelTurn': {
            'parts': [
              {'text': 'resumed'}
            ]
          }
        }
      });
      await pumpEventQueue();
      expect(texts, ['resumed']);
      await sub.cancel();
    });

    test('close() ends receive() and rejects further sends', () async {
      final done = session.receive().toList();
      await session.close();
      await expectLater(done, completes);
      expect(() => session.sendTextRealtime('x'),
          throwsA(isA<Exception>()));
    });
  });
}
