import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('GeminiLiveSessionController', () {
    late FakeChannel fakeChannel;
    late LiveService service;
    late GeminiLiveSessionController controller;

    setUp(() {
      fakeChannel = FakeChannel();
      service = LiveService(
        apiKey: 'test-key',
        connector: (uri, headers) async {
          unawaited(
            Future<void>.delayed(Duration.zero, () {
              fakeChannel.emitServerJson({
                'setupComplete': {'sessionId': 'session-xyz-123'},
              });
            }),
          );
          return fakeChannel;
        },
        setupTimeout: const Duration(seconds: 2),
      );
      controller = GeminiLiveSessionController(liveService: service);
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is disconnected and idle', () {
      expect(controller.state, LiveSessionState.disconnected);
      expect(controller.isConnected, isFalse);
      expect(controller.isModelSpeaking, isFalse);
      expect(controller.isUserSpeaking, isFalse);
      expect(controller.isInterrupted, isFalse);
      expect(controller.sessionId, isNull);
      expect(controller.transcripts, isEmpty);
    });

    test('connect transitions state, assigns sessionId, and processes turns', () async {
      await controller.connect(
        LiveConnectParameters(
          model: LiveModels.gemini38Live,
          callbacks: LiveCallbacks(),
        ),
      );

      expect(controller.state, LiveSessionState.connected);
      expect(controller.isConnected, isTrue);
      expect(controller.sessionId, 'session-xyz-123');

      // Simulate incoming audio chunk and text from model
      final pcmBytes = Uint8List.fromList([1, 2, 3, 4]);
      final base64Audio = base64Encode(pcmBytes);

      final audioChunks = <Uint8List>[];
      final audioSub = controller.incomingAudioStream.listen(audioChunks.add);

      fakeChannel.emitServerJson({
        'serverContent': {
          'modelTurn': {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'audio/pcm;rate=24000',
                  'data': base64Audio,
                },
              },
              {
                'text': 'Greetings human!',
                'speech_metadata': {
                  'speaker': 'Charon',
                  'style': 'friendly',
                },
              },
            ],
          },
        },
      });

      await pumpEventQueue();

      expect(controller.isModelSpeaking, isTrue);
      expect(controller.latestTranscript, 'Greetings human!');
      expect(controller.latestTranscriptRole, 'model');
      expect(controller.transcripts.length, 1);
      expect(controller.transcripts.first.speaker, 'Charon');
      expect(controller.transcripts.first.style, 'friendly');
      expect(audioChunks.length, 1);
      expect(audioChunks.first, pcmBytes);

      // Simulate turn completion
      fakeChannel.emitServerJson({
        'serverContent': {
          'turnComplete': true,
        },
      });

      await pumpEventQueue();
      expect(controller.isModelSpeaking, isFalse);
      expect(controller.transcripts.first.isStreaming, isFalse);

      await audioSub.cancel();
    });

    test('handles user audio, text, images, and tool responses', () async {
      await controller.connect(
        LiveConnectParameters(
          model: LiveModels.gemini38Live,
          callbacks: LiveCallbacks(),
        ),
      );

      final userAudioChunks = <Uint8List>[];
      final userAudioSub = controller.outgoingAudioStream.listen(userAudioChunks.add);

      final micBytes = Uint8List.fromList([10, 20, 30, 40]);
      controller.sendRealtimeAudio(micBytes);
      await pumpEventQueue();
      expect(controller.isUserSpeaking, isTrue);
      expect(userAudioChunks.length, 1);
      expect(userAudioChunks.first, micBytes);

      controller.stopUserSpeaking();
      expect(controller.isUserSpeaking, isFalse);

      controller.sendRealtimeText('What is the weather today?');
      expect(controller.latestTranscript, 'What is the weather today?');
      expect(controller.latestTranscriptRole, 'user');

      controller.sendRealtimeImage(Uint8List.fromList([255, 216, 255]));

      controller.sendToolResponses([
        FunctionResponse(
          id: 'call-1',
          name: 'getWeather',
          response: {'temp': 22},
        ),
      ]);

      expect(fakeChannel.sentMessages.length, greaterThan(3));
      await userAudioSub.cancel();
    });

    test('interruption resets model speaking state and sets isInterrupted', () async {
      await controller.connect(
        LiveConnectParameters(
          model: LiveModels.gemini38Live,
          callbacks: LiveCallbacks(),
        ),
      );

      fakeChannel.emitServerJson({
        'serverContent': {
          'interrupted': true,
        },
      });
      await pumpEventQueue();

      expect(controller.isInterrupted, isTrue);
      expect(controller.isModelSpeaking, isFalse);
    });

    test('disconnect and clearHistory clean up state', () async {
      await controller.connect(
        LiveConnectParameters(
          model: LiveModels.gemini38Live,
          callbacks: LiveCallbacks(),
        ),
      );

      controller.sendRealtimeText('test message');
      expect(controller.transcripts.isNotEmpty, isTrue);

      controller.clearHistory();
      expect(controller.transcripts, isEmpty);
      expect(controller.latestTranscript, isNull);

      await controller.disconnect();
      expect(controller.state, LiveSessionState.disconnected);
      expect(controller.isConnected, isFalse);
    });
  });
}

class FakeChannel implements WebSocketChannel {
  final StreamController<Object?> _incoming = StreamController<Object?>.broadcast();
  final List<Object?> sentMessages = [];
  late final FakeSink _sink = FakeSink(sentMessages);

  @override
  Stream<Object?> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  void emitServerJson(Map<String, dynamic> json) {
    _incoming.add(jsonEncode(json));
  }

  int? _closeCode;

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSink implements WebSocketSink {
  final List<Object?> sentMessages;

  FakeSink(this.sentMessages);

  @override
  void add(dynamic data) {
    sentMessages.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) => Future.value();

  @override
  Future<void> close([int? closeCode, String? closeReason]) => Future.value();

  @override
  Future<void> get done => Future.value();
}

Future<void> pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
