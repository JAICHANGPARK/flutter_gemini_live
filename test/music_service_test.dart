import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeWebSocketSink implements WebSocketSink {
  final List<String> sentMessages = [];
  bool isClosed = false;

  @override
  void add(dynamic data) {
    sentMessages.add(data as String);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream stream) async {}

  @override
  Future close([int? closeCode, String? closeReason]) async {
    isClosed = true;
  }

  @override
  Future get done => Future.value();
}

class _FakeWebSocketChannel implements WebSocketChannel {
  final _FakeWebSocketSink _sink = _FakeWebSocketSink();
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();

  @override
  Stream get stream => _controller.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  int? closeCode;

  @override
  String? closeReason;

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('LiveMusic Models serialization', () {
    test('Scale enum serializes correctly', () {
      expect(Scale.C_MAJOR_A_MINOR.name, 'C_MAJOR_A_MINOR');
      expect(Scale.G_MAJOR_E_MINOR.name, 'G_MAJOR_E_MINOR');
    });

    test('MusicGenerationMode and LiveMusicPlaybackControl serialize correctly', () {
      expect(MusicGenerationMode.QUALITY.name, 'QUALITY');
      expect(LiveMusicPlaybackControl.PLAY.name, 'PLAY');
      expect(LiveMusicPlaybackControl.PAUSE.name, 'PAUSE');
      expect(LiveMusicPlaybackControl.STOP.name, 'STOP');
      expect(LiveMusicPlaybackControl.RESET_CONTEXT.name, 'RESET_CONTEXT');
    });

    test('WeightedPrompt and LiveMusicGenerationConfig round-trip', () {
      final prompt = WeightedPrompt(text: 'cyberpunk synthwave', weight: 1.5);
      final json = prompt.toJson();
      expect(json['text'], 'cyberpunk synthwave');
      expect(json['weight'], 1.5);

      final decoded = WeightedPrompt.fromJson(json);
      expect(decoded.text, 'cyberpunk synthwave');
      expect(decoded.weight, 1.5);

      final config = LiveMusicGenerationConfig(
        bpm: 128,
        temperature: 1.2,
        density: 0.8,
        brightness: 0.5,
        scale: Scale.C_MAJOR_A_MINOR,
        muteBass: false,
        muteDrums: false,
        musicGenerationMode: MusicGenerationMode.QUALITY,
      );
      final configJson = config.toJson();
      expect(configJson['bpm'], 128);
      expect(configJson['temperature'], 1.2);
      expect(configJson['scale'], 'C_MAJOR_A_MINOR');
      expect(configJson['musicGenerationMode'], 'QUALITY');

      final decodedConfig = LiveMusicGenerationConfig.fromJson(configJson);
      expect(decodedConfig.bpm, 128);
      expect(decodedConfig.scale, Scale.C_MAJOR_A_MINOR);
    });

    test('LiveMusicServerMessage audioChunk and audioBytes helpers', () {
      final rawBytes = Uint8List.fromList([1, 2, 3, 4]);
      final base64Str = base64Encode(rawBytes);

      final msg = LiveMusicServerMessage(
        serverContent: LiveMusicServerContent(
          audioChunks: [
            AudioChunk(
              data: base64Str,
              mimeType: 'audio/pcm',
              sourceMetadata: LiveMusicSourceMetadata(
                clientContent: LiveMusicClientContent(
                  weightedPrompts: [
                    WeightedPrompt(text: 'jazz', weight: 1.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

      expect(msg.audioChunk?.mimeType, 'audio/pcm');
      expect(msg.audioBytes, rawBytes);
    });
  });

  group('LiveMusicService & LiveMusicSession', () {
    late _FakeWebSocketChannel fakeChannel;
    late LiveMusicService musicService;

    setUp(() {
      fakeChannel = _FakeWebSocketChannel();
      musicService = LiveMusicService(
        apiKey: 'test-api-key',
        connector: (uri, headers) async {
          expect(uri.host, 'generativelanguage.googleapis.com');
          expect(uri.path, contains('BidiGenerateMusic'));
          expect(uri.queryParameters['key'], 'test-api-key');
          expect(headers['x-goog-api-key'], 'test-api-key');
          return fakeChannel;
        },
      );
    });

    test('connect sends setup message and resolves after setupComplete', () async {
      final receivedMessages = <LiveMusicServerMessage>[];
      var opened = false;

      final connectFuture = musicService.connect(
        LiveMusicConnectParameters(
          model: 'lyria-realtime-exp',
          callbacks: LiveMusicCallbacks(
            onOpen: () => opened = true,
            onMessage: (msg) => receivedMessages.add(msg),
          ),
        ),
      );

      // Allow async connector to run and send setup message
      await pumpEventQueue();

      // Verify setup message was sent
      expect(fakeChannel._sink.sentMessages.length, 1);
      final setupMsg = jsonDecode(fakeChannel._sink.sentMessages.first);
      expect(setupMsg['setup']['model'], 'models/lyria-realtime-exp');
      expect(opened, isTrue);

      // Simulate server sending setupComplete
      fakeChannel._controller.add(
        jsonEncode({'setupComplete': {}}),
      );

      final session = await connectFuture;
      expect(session.setupComplete, isNotNull);

      // Send weighted prompts
      session.setWeightedPrompts([
        WeightedPrompt(text: 'ambient piano', weight: 1.0),
      ]);
      expect(fakeChannel._sink.sentMessages.length, 2);
      final promptsMsg = jsonDecode(fakeChannel._sink.sentMessages[1]);
      expect(
        promptsMsg['clientContent']['weightedPrompts'][0]['text'],
        'ambient piano',
      );

      // Send config
      session.setMusicGenerationConfig(
        LiveMusicGenerationConfig(bpm: 90),
      );
      expect(fakeChannel._sink.sentMessages.length, 3);
      final configMsg = jsonDecode(fakeChannel._sink.sentMessages[2]);
      expect(configMsg['musicGenerationConfig']['bpm'], 90);

      // Playback controls
      session.play();
      session.pause();
      session.stop();
      session.resetContext();

      expect(
        jsonDecode(fakeChannel._sink.sentMessages[3])['playbackControl'],
        'PLAY',
      );
      expect(
        jsonDecode(fakeChannel._sink.sentMessages[4])['playbackControl'],
        'PAUSE',
      );
      expect(
        jsonDecode(fakeChannel._sink.sentMessages[5])['playbackControl'],
        'STOP',
      );
      expect(
        jsonDecode(fakeChannel._sink.sentMessages[6])['playbackControl'],
        'RESET_CONTEXT',
      );

      // Server sends audio chunk
      final pcmBytes = Uint8List.fromList([10, 20, 30]);
      fakeChannel._controller.add(
        jsonEncode({
          'serverContent': {
            'audioChunks': [
              {
                'data': base64Encode(pcmBytes),
                'mimeType': 'audio/pcm',
              }
            ]
          }
        }),
      );

      await pumpEventQueue();
      expect(receivedMessages.length, 2); // setupComplete + serverContent
      expect(receivedMessages.last.audioBytes, pcmBytes);

      await session.close();
      expect(fakeChannel._sink.isClosed, isTrue);
    });

    test('GoogleGenAI exposes live.music', () {
      final ai = GoogleGenAI(apiKey: 'key');
      expect(ai.live.music, isNotNull);
      expect(ai.live.music.apiKey, 'key');
    });
  });
}
