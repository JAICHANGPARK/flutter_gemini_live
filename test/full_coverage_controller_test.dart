import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

  void emitError(Object error) {
    _incoming.addError(error);
  }

  void emitDone() {
    _incoming.close();
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

void main() {
  group('GeminiLiveSessionController Full Coverage', () {
    test('LiveTranscriptItem.copyWith covers all optional fields', () {
      final item = LiveTranscriptItem(
        role: 'user',
        text: 'hello',
        speaker: 'speaker1',
        style: 'whisper',
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageMimeType: 'image/jpeg',
        timestamp: DateTime(2026, 1, 1),
        isStreaming: true,
      );

      final copySame = item.copyWith();
      expect(copySame.role, 'user');
      expect(copySame.text, 'hello');
      expect(copySame.speaker, 'speaker1');
      expect(copySame.style, 'whisper');
      expect(copySame.imageBytes, Uint8List.fromList([1, 2, 3]));
      expect(copySame.imageMimeType, 'image/jpeg');
      expect(copySame.timestamp, DateTime(2026, 1, 1));
      expect(copySame.isStreaming, isTrue);

      final copyDiff = item.copyWith(
        role: 'model',
        text: 'hi',
        speaker: 'model_voice',
        style: 'normal',
        imageBytes: Uint8List.fromList([4, 5]),
        imageMimeType: 'image/png',
        timestamp: DateTime(2026, 2, 2),
        isStreaming: false,
      );
      expect(copyDiff.role, 'model');
      expect(copyDiff.text, 'hi');
      expect(copyDiff.speaker, 'model_voice');
      expect(copyDiff.style, 'normal');
      expect(copyDiff.imageBytes, Uint8List.fromList([4, 5]));
      expect(copyDiff.imageMimeType, 'image/png');
      expect(copyDiff.timestamp, DateTime(2026, 2, 2));
      expect(copyDiff.isStreaming, isFalse);
    });

    test('getters, exportLastTurnWav, and initial states', () {
      final channel = FakeChannel();
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async => channel,
      );
      final controller = GeminiLiveSessionController(liveService: service);

      expect(controller.isReconnecting, isFalse);
      expect(controller.reconnectAttempt, 0);
      expect(controller.sessionId, isNull);
      expect(controller.latestSessionHandle, isNull);
      expect(controller.isSessionResumable, isFalse);
      expect(controller.lastGoAway, isNull);
      expect(controller.activeToolCalls, isEmpty);
      expect(controller.isExecutingTool, isFalse);
      expect(controller.currentTurnAudioBuffer.isEmpty, isTrue);
      expect(controller.exportLastTurnWav(), isNull);
      expect(controller.lastError, isNull);
      expect(controller.lastStackTrace, isNull);
      expect(controller.session, isNull);

      // Accumulate some pcm into currentTurnAudioBuffer to test exportLastTurnWav
      controller.currentTurnAudioBuffer.add(Uint8List.fromList([0, 0, 10, 0]));
      final wavBytes = controller.exportLastTurnWav();
      expect(wavBytes, isNotNull);
      expect(wavBytes!.length, greaterThan(44));

      controller.dispose();
    });

    test('connect early returns if already connecting or connected', () async {
      final channel = FakeChannel();
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async => channel,
      );
      final controller = GeminiLiveSessionController(liveService: service);

      final params = LiveConnectParameters(
        model: 'models/gemini-2.0-flash-exp',
        callbacks: LiveCallbacks(),
      );

      final connectFut = controller.connect(params);
      expect(controller.state, LiveSessionState.connecting);

      // Simulate server setup complete
      await pumpEventQueue();
      channel.emitServerJson({'setupComplete': {'sessionId': 'sess_1'}});
      await connectFut;
      expect(controller.state, LiveSessionState.connected);

      // Second connect call while connected does nothing
      await controller.connect(params);
      expect(controller.state, LiveSessionState.connected);

      controller.dispose();
    });

    test('connect failure updates state, lastError, and rethrows', () async {
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async {
          throw StateError('Failed to connect');
        },
      );
      final controller = GeminiLiveSessionController(liveService: service);

      final params = LiveConnectParameters(
        model: 'models/gemini-2.0-flash-exp',
        callbacks: LiveCallbacks(),
      );

      await expectLater(() => controller.connect(params), throwsStateError);
      expect(controller.state, LiveSessionState.error);
      expect(controller.lastError, isNotNull);
      expect(controller.lastStackTrace, isNotNull);

      controller.dispose();
    });

    test('callbacks forwarding: onOpen, onError, onClose, and onMessage', () async {
      final channel = FakeChannel();
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async => channel,
      );
      final controller = GeminiLiveSessionController(liveService: service);

      bool openCalled = false;
      Object? errorReceived;
      int? closeCodeReceived;

      final params = LiveConnectParameters(
        model: 'models/gemini-20-flash-exp',
        callbacks: LiveCallbacks(
          onOpen: () => openCalled = true,
          onError: (err, st) => errorReceived = err,
          onClose: (code, [reason]) => closeCodeReceived = code,
          onMessage: (_) {},
        ),
      );

      final connFut = controller.connect(params);
      await pumpEventQueue();
      channel.emitServerJson({'setupComplete': {'sessionId': 's-123'}});
      await connFut;

      expect(openCalled, isTrue);
      expect(controller.sessionId, 's-123');

      // Test onMessage forwarding
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          sessionResumptionUpdate: LiveServerSessionResumptionUpdate(newHandle: 'h1'),
        ),
      );
      expect(controller.latestSessionHandle, 'h1');

      // Test onError
      channel.emitError(Exception('stream err'));
      await pumpEventQueue();
      expect(errorReceived, isNotNull);
      expect(controller.state, LiveSessionState.error);

      controller.dispose();

      // Test onClose on fresh connection
      final closeChannel = FakeChannel();
      final closeService = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async => closeChannel,
      );
      final closeController = GeminiLiveSessionController(liveService: closeService);
      final closeFut = closeController.connect(
        LiveConnectParameters(
          model: 'models/gemini-2.0-flash-exp',
          callbacks: LiveCallbacks(
            onClose: (code, [reason]) => closeCodeReceived = code,
          ),
        ),
      );
      await pumpEventQueue();
      closeChannel.emitServerJson({'setupComplete': {'sessionId': 's-456'}});
      await closeFut;

      closeChannel._closeCode = 1000;
      closeChannel.emitDone();
      await pumpEventQueue();
      expect(closeCodeReceived, 1000);
      expect(closeController.state, LiveSessionState.disconnected);

      closeController.dispose();
    });

    test('resumption handle update, goAway, and tool call cancellation', () async {
      final channel = FakeChannel();
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async => channel,
      );
      final controller = GeminiLiveSessionController(
        liveService: service,
        reconnectPolicy: GeminiLiveReconnectPolicy(
          reconnectOnGoAway: true,
          reconnectOnAbnormalClose: true,
          initialDelay: const Duration(milliseconds: 1),
          maxAttempts: 2,
        ),
      );

      final connFut = controller.connect(
        LiveConnectParameters(
          model: 'models/gemini-2.0-flash-exp',
          callbacks: LiveCallbacks(),
        ),
      );
      await pumpEventQueue();
      channel.emitServerJson({'setupComplete': {'sessionId': 's-1'}});
      await connFut;

      // 1. Session resumption update
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          sessionResumptionUpdate: LiveServerSessionResumptionUpdate(
            newHandle: 'handle-xyz',
            resumable: true,
          ),
        ),
      );
      expect(controller.latestSessionHandle, 'handle-xyz');
      expect(controller.isSessionResumable, isTrue);

      // 2. Tool calls and cancellations
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          toolCall: LiveServerToolCall(
            functionCalls: [
              FunctionCall(id: 'call-1', name: 'search', args: {}),
              FunctionCall(id: 'call-2', name: 'calc', args: {}),
            ],
          ),
        ),
      );
      expect(controller.activeToolCalls.length, 2);
      expect(controller.isExecutingTool, isTrue);

      // Cancel call-1
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          toolCallCancellation: LiveServerToolCallCancellation(ids: ['call-1']),
        ),
      );
      expect(controller.activeToolCalls.length, 1);
      expect(controller.activeToolCalls.first.id, 'call-2');

      // 3. GoAway triggers reconnection
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          goAway: LiveServerGoAway(timeLeft: '10s'),
        ),
      );
      expect(controller.lastGoAway?.timeLeft, '10s');
      expect(controller.isReconnecting, isTrue);

      // Let reconnection timer fire
      await Future<void>.delayed(const Duration(milliseconds: 20));

      controller.dispose();
    });

    test('speech transcription, interactionComplete, and turn WAV export', () async {
      final channel = FakeChannel();
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async => channel,
      );
      final controller = GeminiLiveSessionController(liveService: service);

      final connFut = controller.connect(
        LiveConnectParameters(
          model: 'models/gemini-2.0-flash-exp',
          callbacks: LiveCallbacks(),
        ),
      );
      await pumpEventQueue();
      channel.emitServerJson({'setupComplete': {'sessionId': 's-1'}});
      await connFut;

      // 1. Input transcription (streaming then final)
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            inputTranscription: Transcription(
              text: 'hello world',
              speakerLabel: 'user_1',
              finished: false,
            ),
          ),
        ),
      );
      expect(controller.transcripts.length, 1);
      expect(controller.transcripts.first.text, 'hello world');
      expect(controller.transcripts.first.isStreaming, isTrue);

      // Append text
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            inputTranscription: Transcription(
              text: ' more',
              speakerLabel: 'user_1',
              finished: true,
            ),
          ),
        ),
      );
      expect(controller.transcripts.first.text, 'hello world more');
      expect(controller.transcripts.first.isStreaming, isFalse);

      // 2. Output transcription
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            outputTranscription: Transcription(
              text: 'Hi there!',
              speakerLabel: 'model_voice',
              finished: false,
            ),
            modelTurn: Content(
              parts: [
                Part(
                  inlineData: Blob(
                    mimeType: 'audio/pcm;rate=24000',
                    data: base64Encode([0, 0, 10, 0]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(controller.isModelSpeaking, isTrue);
      expect(controller.transcripts.length, 2);

      // 3. Interaction complete (triggers WAV finalization)
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            turnComplete: true,
          ),
        ),
      );
      expect(controller.isModelSpeaking, isFalse);
      expect(controller.exportLastTurnWav(), isNotNull);

      // 4. stopModelSpeaking
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [
                Part(
                  inlineData: Blob(
                    mimeType: 'audio/pcm;rate=24000',
                    data: base64Encode([0, 0, 10, 0]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(controller.isModelSpeaking, isTrue);
      controller.stopModelSpeaking();
      expect(controller.isModelSpeaking, isFalse);
      expect(controller.isInterrupted, isTrue);

      controller.dispose();
    });

    test('sendRealtimeTurn, sendRealtimeText, sendRealtimeImage, and sendToolResponses', () async {
      final channel = FakeChannel();
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async => channel,
      );
      final controller = GeminiLiveSessionController(liveService: service);

      // While disconnected, all send methods return early without error
      controller.sendRealtimeText('ignored');
      controller.sendRealtimeTurn(text: 'ignored');
      controller.sendRealtimeImage(Uint8List.fromList([1, 2]));
      controller.sendToolResponses([FunctionResponse(name: 'fn', response: {})]);
      expect(channel.sentMessages, isEmpty);

      final connFut = controller.connect(
        LiveConnectParameters(
          model: 'models/gemini-2.0-flash-exp',
          callbacks: LiveCallbacks(),
        ),
      );
      await pumpEventQueue();
      channel.emitServerJson({'setupComplete': {'sessionId': 's-1'}});
      await connFut;
      channel.sentMessages.clear();

      // sendRealtimeTurn with image, text, and additionalParts
      controller.sendRealtimeTurn(
        text: 'look at this',
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageMimeType: 'image/png',
        additionalParts: [Part(text: 'extra')],
        turnComplete: false,
      );
      expect(channel.sentMessages.length, 1);

      // sendRealtimeTurn with empty parts returns early
      controller.sendRealtimeTurn();
      expect(channel.sentMessages.length, 1);

      // sendRealtimeImage
      controller.sendRealtimeImage(Uint8List.fromList([4, 5, 6]), mimeType: 'image/jpeg');
      expect(channel.sentMessages.length, 2);

      // sendToolResponses with id matching
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          toolCall: LiveServerToolCall(
            functionCalls: [
              FunctionCall(id: 'call_id_1', name: 'search', args: {}),
              FunctionCall(id: 'call_id_2', name: 'calc', args: {}),
            ],
          ),
        ),
      );
      expect(controller.activeToolCalls.length, 2);

      controller.sendToolResponses([
        FunctionResponse(name: 'search', response: {'res': 1}, id: 'call_id_1'),
        FunctionResponse(name: 'calc', response: {'res': 2}, id: 'call_id_2'),
      ]);
      expect(controller.activeToolCalls, isEmpty);
      expect(channel.sentMessages.length, 3);

      controller.dispose();
    });

    test('reconnect lifecycle on abnormal close, maxAttempts, and manual disconnect', () async {
      var channel = FakeChannel();
      var failOnConnect = false;
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async {
          if (failOnConnect) throw StateError('Reconnect fail');
          return channel;
        },
      );
      final controller = GeminiLiveSessionController(
        liveService: service,
        reconnectPolicy: GeminiLiveReconnectPolicy(
          reconnectOnAbnormalClose: true,
          initialDelay: const Duration(milliseconds: 5),
          maxAttempts: 1,
        ),
      );

      final connFut = controller.connect(
        LiveConnectParameters(
          model: 'models/gemini-2.0-flash-exp',
          callbacks: LiveCallbacks(),
        ),
      );
      await pumpEventQueue();
      channel.emitServerJson({'setupComplete': {'sessionId': 's-1'}});
      await connFut;

      // Trigger abnormal close
      channel._closeCode = 1006;
      failOnConnect = true;
      channel.emitDone();
      await pumpEventQueue();

      expect(controller.isReconnecting, isTrue);
      expect(controller.reconnectAttempt, 1);

      // Wait for reconnect attempt to fail and hit maxAttempts
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(controller.isReconnecting, isFalse);

      // Test disconnect when _session is null
      await controller.disconnect();
      expect(controller.state, LiveSessionState.disconnected);

      controller.dispose();
    });

    test('audio streaming, barge-in, interim transcription, and history clearing', () async {
      final channel = FakeChannel();
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async => channel,
      );
      final controller = GeminiLiveSessionController(liveService: service);

      expect(controller.isUserSpeaking, isFalse);
      expect(controller.incomingAudioStream, isNotNull);
      expect(controller.outgoingAudioStream, isNotNull);
      expect(controller.latestTranscript, isNull);
      expect(controller.latestTranscriptRole, isNull);

      final connFut = controller.connect(
        LiveConnectParameters(
          model: 'models/gemini-2.0-flash-exp',
          callbacks: LiveCallbacks(),
        ),
      );
      await pumpEventQueue();
      channel.emitServerJson({'setupComplete': {'sessionId': 's-1'}});
      await connFut;

      // 1. sendRealtimeAudio and stopUserSpeaking
      controller.sendRealtimeAudio(Uint8List.fromList([10, 20]));
      expect(controller.isUserSpeaking, isTrue);
      controller.stopUserSpeaking();
      expect(controller.isUserSpeaking, isFalse);

      // 2. sendRealtimeText
      controller.sendRealtimeText('hello realtime text');
      expect(controller.latestTranscript, 'hello realtime text');
      expect(controller.latestTranscriptRole, 'user');

      // 3. interim transcription
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            interimInputTranscription: Transcription(
              text: 'interim input',
              speakerLabel: 'user_1',
            ),
          ),
        ),
      );
      expect(controller.latestTranscript, 'interim input');

      // Append another streaming chunk with null speakerLabel to hit speaker ?? last.speaker
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            inputTranscription: Transcription(
              text: ' continuation',
              finished: false,
            ),
          ),
        ),
      );
      expect(controller.transcripts.last.speaker, 'user_1');

      // 4. Model text part with speechMetadata
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [
                Part(
                  text: 'Model speech text',
                  speechMetadata: SpeechMetadata(speaker: 'spk_a', style: 'cheerful'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(controller.latestTranscript, 'Model speech text');
      expect(controller.latestTranscriptRole, 'model');

      // 5. Barge-in interruption
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(interrupted: true),
        ),
      );
      expect(controller.isInterrupted, isTrue);

      // 6. Tool call with null id (matched by name)
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          toolCall: LiveServerToolCall(
            functionCalls: [
              FunctionCall(name: 'unidentified_call', args: {}),
            ],
          ),
        ),
      );
      expect(controller.activeToolCalls.length, 1);
      controller.sendToolResponses([
        FunctionResponse(name: 'unidentified_call', response: {'ok': true}, id: 'assigned_id'),
      ]);
      expect(controller.activeToolCalls, isEmpty);

      // 7. Clear history
      controller.clearHistory();
      expect(controller.transcripts, isEmpty);
      expect(controller.latestTranscript, isNull);
      expect(controller.latestTranscriptRole, isNull);

      // 8. Disconnect while connected
      await controller.disconnect();
      expect(controller.state, LiveSessionState.disconnected);

      controller.dispose();
    });

    test('reconnect retry loop reaching maxAttempts > 1', () async {
      var channel = FakeChannel();
      var failOnConnect = false;
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async {
          if (failOnConnect) throw StateError('reconnect fail');
          return channel;
        },
      );
      final controller = GeminiLiveSessionController(
        liveService: service,
        reconnectPolicy: GeminiLiveReconnectPolicy(
          reconnectOnAbnormalClose: true,
          initialDelay: const Duration(milliseconds: 2),
          maxAttempts: 2,
        ),
      );

      final connFut = controller.connect(
        LiveConnectParameters(
          model: 'models/gemini-2.0-flash-exp',
          callbacks: LiveCallbacks(),
        ),
      );
      await pumpEventQueue();
      channel.emitServerJson({'setupComplete': {'sessionId': 's-1'}});
      await connFut;

      // Fail next reconnects
      failOnConnect = true;

      // Trigger abnormal close to start reconnect loop with maxAttempts: 2
      channel._closeCode = 1006;
      channel.emitDone();
      await pumpEventQueue();

      expect(controller.isReconnecting, isTrue);

      // Wait for 2 retries to exhaust
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.isReconnecting, isFalse);

      controller.dispose();
    });

    test('reconnect with maxAttempts 0 hits immediate bail out', () async {
      final channel = FakeChannel();
      final service = LiveService(
        apiKey: 'key',
        connector: (uri, headers) async => channel,
      );
      final controller = GeminiLiveSessionController(
        liveService: service,
        reconnectPolicy: GeminiLiveReconnectPolicy(
          reconnectOnAbnormalClose: true,
          maxAttempts: 0,
        ),
      );
      final connFut = controller.connect(
        LiveConnectParameters(
          model: 'models/gemini-2.0-flash-exp',
          callbacks: LiveCallbacks(),
        ),
      );
      await pumpEventQueue();
      channel.emitServerJson({'setupComplete': {'sessionId': 's-1'}});
      await connFut;

      channel._closeCode = 1006;
      channel.emitDone();
      await pumpEventQueue();
      expect(controller.isReconnecting, isFalse);

      controller.dispose();
    });
  });
}
