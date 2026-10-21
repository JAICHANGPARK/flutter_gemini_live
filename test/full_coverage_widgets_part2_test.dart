import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class FakeSink implements WebSocketSink {
  final List<Object?> sentMessages = [];

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

class FakeChannel implements WebSocketChannel {
  final StreamController<Object?> _incoming = StreamController<Object?>.broadcast();
  final FakeSink _sink = FakeSink();

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

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GeminiLiveSessionController createMockController({
  FakeChannel? fakeChannel,
  bool autoSetup = true,
}) {
  final channel = fakeChannel ?? FakeChannel();
  final service = LiveService(
    apiKey: 'mock-key',
    connector: (uri, headers) async {
      if (autoSetup) {
        unawaited(
          Future<void>.delayed(Duration.zero, () {
            channel.emitServerJson({
              'setupComplete': {'sessionId': 'mock-session-123'},
            });
          }),
        );
      }
      return channel;
    },
    setupTimeout: const Duration(seconds: 2),
  );
  return GeminiLiveSessionController(liveService: service);
}

void main() {
  group('GeminiLiveWaveform line 164 decay coverage', () {
    testWidgets('decays targetAmplitude when diff <= 0.002 and targetAmplitude > 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveWaveform(
              amplitude: 0.001,
            ),
          ),
        ),
      );
      // Wait for ticker frames
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('GeminiLiveTranslateSplitView Full Coverage', () {
    testWidgets('internal controller creation and autoConnect true and false', (tester) async {
      // 1. autoConnect: false, owns controller
      await tester.pumpWidget(
        const MaterialApp(
          home: GeminiLiveTranslateSplitView(
            apiKey: 'dummy-api-key',
            autoConnect: false,
          ),
        ),
      );
      expect(find.byType(GeminiLiveTranslateSplitView), findsOneWidget);

      // 2. autoConnect: true (triggers _connectTranslateSession in post-frame callback)
      await tester.pumpWidget(
        const MaterialApp(
          home: GeminiLiveTranslateSplitView(
            apiKey: 'dummy-api-key',
            autoConnect: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('didUpdateWidget updates language properties and swaps controller', (tester) async {
      final ctrl1 = createMockController();
      final ctrl2 = createMockController();

      var faceToFace = false;
      var srcCode = 'ko-KR';
      var srcLabel = '한국어';
      var tgtCode = 'en-US';
      var tgtLabel = 'English';
      GeminiLiveSessionController? currentCtrl = ctrl1;

      late StateSetter stateSetter;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              stateSetter = setState;
              return GeminiLiveTranslateSplitView(
                apiKey: 'dummy-key',
                controller: currentCtrl,
                faceToFaceMode: faceToFace,
                sourceLanguageCode: srcCode,
                sourceLanguageLabel: srcLabel,
                targetLanguageCode: tgtCode,
                targetLanguageLabel: tgtLabel,
                autoConnect: false,
              );
            },
          ),
        ),
      );

      // Verify initial texts
      expect(find.text('한국어'), findsNWidgets(2));
      expect(find.text('English'), findsNWidgets(2));

      // Update properties
      stateSetter(() {
        faceToFace = true;
        srcCode = 'ja-JP';
        srcLabel = '日本語';
        tgtCode = 'fr-FR';
        tgtLabel = 'Français';
        currentCtrl = ctrl2;
      });
      await tester.pump();

      expect(find.text('日本語'), findsNWidgets(2));
      expect(find.text('Français'), findsNWidgets(2));

      // Swap to null (owns controller)
      stateSetter(() {
        currentCtrl = null;
      });
      await tester.pump();

      // Swap from null back to ctrl1 (disposes owned controller)
      stateSetter(() {
        currentCtrl = ctrl1;
      });
      await tester.pump();

      ctrl1.dispose();
      ctrl2.dispose();
    });

    testWidgets('custom slot builders: header, topPane, bottomPane, languageBar, controls', (tester) async {
      final controller = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveTranslateSplitView(
            controller: controller,
            autoConnect: false,
            headerBuilder: (context, ctrl) => AppBar(title: const Text('Custom Header Slot')),
            topPaneBuilder: (context, code, label, latest, items, isActive) =>
                Container(key: const ValueKey('custom_top_pane'), child: Text('Top: $label ($code)')),
            bottomPaneBuilder: (context, code, label, latest, items, isActive) =>
                Container(key: const ValueKey('custom_bottom_pane'), child: Text('Bottom: $label ($code)')),
            languageBarBuilder: (context, src, tgt, onSwap) =>
                Container(key: const ValueKey('custom_lang_bar'), child: const Text('LangBar')),
            controlsBuilder: (context, ctrl, isRec, onToggle) =>
                ElevatedButton(key: const ValueKey('custom_controls'), onPressed: onToggle, child: const Text('Custom Mic')),
          ),
        ),
      );

      expect(find.text('Custom Header Slot'), findsOneWidget);
      expect(find.byKey(const ValueKey('custom_top_pane')), findsOneWidget);
      expect(find.byKey(const ValueKey('custom_bottom_pane')), findsOneWidget);
      expect(find.byKey(const ValueKey('custom_lang_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('custom_controls')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('custom_controls')));
      await tester.pump();

      controller.dispose();
    });

    testWidgets('microphone toggle with and without onMicPressed', (tester) async {
      final controller = createMockController();
      bool micPressedCallbackCalled = false;

      // 1. With onMicPressed
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveTranslateSplitView(
            controller: controller,
            autoConnect: false,
            onMicPressed: () {
              micPressedCallbackCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(GeminiLiveMicButton));
      await tester.pump();
      expect(micPressedCallbackCalled, isTrue);

      // 2. Without onMicPressed (internal recording toggling)
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveTranslateSplitView(
            controller: controller,
            autoConnect: false,
            onMicPressed: null,
          ),
        ),
      );

      // Tap once -> _internalRecording = true
      await tester.tap(find.byType(GeminiLiveMicButton));
      await tester.pump();

      // Tap again -> _internalRecording = false, calls controller.stopUserSpeaking()
      await tester.tap(find.byType(GeminiLiveMicButton));
      await tester.pump();

      controller.dispose();
    });

    testWidgets('face to face toggle and swap languages callbacks and dark theme', (tester) async {
      final controller = createMockController();
      bool? faceToFaceResult;
      bool swapLanguagesCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: GeminiLiveTranslateSplitView(
            controller: controller,
            autoConnect: false,
            faceToFaceMode: false,
            onFaceToFaceModeChanged: (val) {
              faceToFaceResult = val;
            },
            onSwapLanguages: () {
              swapLanguagesCalled = true;
            },
          ),
        ),
      );

      // Toggle face to face mode
      await tester.tap(find.byIcon(Icons.screen_rotation_alt_rounded));
      await tester.pump();
      expect(faceToFaceResult, isTrue);

      // Swap languages
      await tester.tap(find.byIcon(Icons.swap_vert_rounded));
      await tester.pump();
      expect(swapLanguagesCalled, isTrue);

      controller.dispose();
    });

    testWidgets('default pane renders transcripts and active waveforms', (tester) async {
      final fakeChannel = FakeChannel();
      final controller = createMockController(fakeChannel: fakeChannel);

      await controller.connect(
        LiveConnectParameters(model: 'test', callbacks: LiveCallbacks()),
      );

      // Inject user and model transcripts
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [Part(text: 'Model translated sentence')],
            ),
          ),
        ),
      );
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            inputTranscription: Transcription(
              text: 'User original utterance',
            ),
          ),
        ),
      );

      // Trigger user speaking via sending audio
      controller.sendRealtimeAudio(Uint8List.fromList([1, 2, 3, 4]));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: GeminiLiveTranslateSplitView(
            controller: controller,
            autoConnect: false,
            isRecording: true,
          ),
        ),
      );

      expect(find.text('Model translated sentence'), findsOneWidget);
      expect(find.text('User original utterance'), findsOneWidget);

      // Verify active waveforms inside panes
      expect(find.byType(GeminiLiveWaveform), findsWidgets);

      controller.dispose();
    });

    testWidgets('app bar status state mapping for disconnected, connecting, and inProgress', (tester) async {
      final fakeChannel = FakeChannel();
      final controller = createMockController(fakeChannel: fakeChannel, autoSetup: false);

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveTranslateSplitView(
            controller: controller,
            autoConnect: false,
          ),
        ),
      );

      // 1. Disconnected
      expect(find.byType(GeminiLiveStatusBadge), findsOneWidget);

      // 2. Connecting
      final connectFuture = controller.connect(
        LiveConnectParameters(
          model: 'test',
          callbacks: LiveCallbacks(),
        ),
      );
      await tester.pump();
      expect(controller.state, LiveSessionState.connecting);

      // Complete setup to become connected
      fakeChannel.emitServerJson({
        'setupComplete': {'sessionId': 'session-123'},
      });
      await connectFuture;
      await tester.pump();
      expect(controller.isConnected, isTrue);

      // 3. In Progress (user speaking)
      controller.sendRealtimeAudio(Uint8List.fromList([1, 2, 3, 4]));
      await tester.pump();

      controller.dispose();
    });
  });

  group('GeminiLiveChatView Full Coverage', () {
    testWidgets('internal controller creation with different loggers and debugLogging', (tester) async {
      // 1. With GeminiLiveLogger
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            apiKey: 'test-api-key',
            logger: const GeminiLiveLogger(),
            autoConnect: false,
          ),
        ),
      );
      expect(find.byType(GeminiLiveChatView), findsOneWidget);

      // 2. With void Function(String)
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            apiKey: 'test-api-key',
            logger: (String msg) {},
            autoConnect: false,
          ),
        ),
      );
      expect(find.byType(GeminiLiveChatView), findsOneWidget);

      // 3. With debugLogging = true
      await tester.pumpWidget(
        const MaterialApp(
          home: GeminiLiveChatView(
            apiKey: 'test-api-key',
            debugLogging: true,
            autoConnect: false,
          ),
        ),
      );
      expect(find.byType(GeminiLiveChatView), findsOneWidget);
    });

    testWidgets('autoConnect: true invokes _connectSession with different systemInstruction formats', (tester) async {
      // 1. String systemInstruction
      await tester.pumpWidget(
        const MaterialApp(
          home: GeminiLiveChatView(
            apiKey: 'test-api-key',
            systemInstruction: 'Custom instruction string',
            autoConnect: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Content systemInstruction
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            apiKey: 'test-api-key',
            systemInstruction: Content(
              role: 'system',
              parts: [Part(text: 'Structured prompt')],
            ),
            autoConnect: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Default fallback systemInstruction
      await tester.pumpWidget(
        const MaterialApp(
          home: GeminiLiveChatView(
            apiKey: 'test-api-key',
            systemInstruction: null,
            autoConnect: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('didUpdateWidget swaps controllers and disposes owned controller', (tester) async {
      final ctrl1 = createMockController();
      final ctrl2 = createMockController();
      GeminiLiveSessionController? currentCtrl = ctrl1;

      late StateSetter stateSetter;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              stateSetter = setState;
              return GeminiLiveChatView(
                apiKey: 'test-api-key',
                controller: currentCtrl,
                autoConnect: false,
              );
            },
          ),
        ),
      );

      // Swap to ctrl2
      stateSetter(() {
        currentCtrl = ctrl2;
      });
      await tester.pump();

      // Swap to null (owns internal controller)
      stateSetter(() {
        currentCtrl = null;
      });
      await tester.pump();

      // Swap from null back to ctrl1 (disposes owned internal controller)
      stateSetter(() {
        currentCtrl = ctrl1;
      });
      await tester.pump();

      ctrl1.dispose();
      ctrl2.dispose();
    });

    testWidgets('attachImage, thumbnail chip preview, and clearAttachedImage', (tester) async {
      final controller = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
          ),
        ),
      );

      final dynamic state = tester.state(find.byType(GeminiLiveChatView));
      final testBytes = Uint8List.fromList([1, 2, 3, 4]);

      // Attach image
      state.attachImage(testBytes, mimeType: 'image/png');
      await tester.pump();

      // Verify close icon in thumbnail chip
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap close icon to clear attached image
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Attach again and use clearAttachedImage method directly
      state.attachImage(testBytes);
      await tester.pump();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      state.clearAttachedImage();
      await tester.pump();
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      controller.dispose();
    });

    testWidgets('sending message with image and text, image only, empty text, and onSubmitted', (tester) async {
      final fakeChannel = FakeChannel();
      final controller = createMockController(fakeChannel: fakeChannel);

      // Connect session so sendRealtimeTurn / sendRealtimeText work
      await controller.connect(
        LiveConnectParameters(model: 'test', callbacks: LiveCallbacks()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
          ),
        ),
      );

      final dynamic state = tester.state(find.byType(GeminiLiveChatView));
      final testBytes = Uint8List.fromList([1, 2, 3, 4]);

      // 1. Send with image and text
      state.attachImage(testBytes);
      await tester.enterText(find.byType(TextField), 'Image description');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // 2. Send with image only (empty text)
      state.attachImage(testBytes);
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // 3. Send with empty text and no image (early return)
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // 4. Send via TextField onSubmitted
      await tester.enterText(find.byType(TextField), 'Submitted via keyboard');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      controller.dispose();
    });

    testWidgets('connection toggle button connects and disconnects with callbacks', (tester) async {
      final fakeChannel = FakeChannel();
      final controller = createMockController(fakeChannel: fakeChannel, autoSetup: false);

      bool connectPressed = false;
      bool disconnectPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            onConnectPressed: () => connectPressed = true,
            onDisconnectPressed: () => disconnectPressed = true,
          ),
        ),
      );

      // 1. Tap connect button
      expect(find.byIcon(Icons.phone_in_talk_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.phone_in_talk_rounded));
      await tester.pump();
      expect(connectPressed, isTrue);

      // Finish connecting
      fakeChannel.emitServerJson({
        'setupComplete': {'sessionId': 'session-123'},
      });
      await tester.pumpAndSettle();
      expect(controller.isConnected, isTrue);

      // 2. Tap disconnect button
      expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.call_end_rounded));
      await tester.pump();
      expect(disconnectPressed, isTrue);
      expect(controller.isConnected, isFalse);

      controller.dispose();
    });

    testWidgets('connectSession onError triggers SnackBar', (tester) async {
      final fakeChannel = FakeChannel();
      final controller = createMockController(fakeChannel: fakeChannel, autoSetup: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveChatView(
              controller: controller,
              autoConnect: false,
            ),
          ),
        ),
      );

      // Tap phone button to initiate connect with LiveCallbacks(onError: ...)
      await tester.tap(find.byIcon(Icons.phone_in_talk_rounded));
      await tester.pump();

      // Emit error through fakeChannel to trigger callbacks.onError
      fakeChannel.emitError('Mock connection failed');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Gemini Live error:'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('waveform bar displays model speaking, user speaking, ready, and custom waveformBuilder', (tester) async {
      final fakeChannel = FakeChannel();
      final controller = createMockController(fakeChannel: fakeChannel);

      await controller.connect(
        LiveConnectParameters(model: 'test', callbacks: LiveCallbacks()),
      );

      // 1. Default waveform bar in dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            showWaveform: true,
          ),
        ),
      );

      expect(find.text('Live session ready'), findsOneWidget);

      // Model speaking
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [
                Part(
                  inlineData: Blob(mimeType: 'audio/pcm', data: 'AAAA'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Gemini speaking...'), findsOneWidget);

      // Stop model speaking and start user speaking
      controller.stopModelSpeaking();
      controller.sendRealtimeAudio(Uint8List.fromList([1, 2, 3, 4]));
      await tester.pump();
      expect(find.text('Listening...'), findsOneWidget);

      // 2. Custom waveformBuilder
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            showWaveform: true,
            waveformBuilder: (context, ctrl) => const Text('Custom Waveform Bar'),
          ),
        ),
      );
      expect(find.text('Custom Waveform Bar'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('tool activity chip and custom toolActivityBuilder', (tester) async {
      final controller = createMockController();

      // Inject tool call
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          toolCall: LiveServerToolCall(
            functionCalls: [
              FunctionCall(id: 'call_1', name: 'search_weather', args: {'loc': 'Seoul'}),
            ],
          ),
        ),
      );

      // 1. Default tool activity chip
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            showToolActivity: true,
          ),
        ),
      );
      expect(find.byType(GeminiLiveToolActivityChip), findsOneWidget);

      // 2. Custom toolActivityBuilder
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            showToolActivity: true,
            toolActivityBuilder: (context, calls) =>
                Text('Active tool: ${calls.first.name}'),
          ),
        ),
      );
      expect(find.text('Active tool: search_weather'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('custom streamingIndicatorBuilder and headerBuilder', (tester) async {
      final controller = createMockController();

      // Model speaking
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [
                Part(
                  inlineData: Blob(mimeType: 'audio/pcm', data: 'AAAA'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            headerBuilder: (context, ctrl) => AppBar(title: const Text('Custom Chat Header')),
            streamingIndicatorBuilder: (context, isSpeaking) =>
                Text('Custom Streaming: $isSpeaking'),
          ),
        ),
      );

      expect(find.text('Custom Chat Header'), findsOneWidget);
      expect(find.text('Custom Streaming: true'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('unified bubbleBuilder and userBubbleBuilder and default bubble with image and streaming', (tester) async {
      final fakeChannel = FakeChannel();
      final controller = createMockController(fakeChannel: fakeChannel);

      await controller.connect(
        LiveConnectParameters(model: 'test', callbacks: LiveCallbacks()),
      );

      // Inject model message
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [Part(text: 'Model bubble response')],
            ),
          ),
        ),
      );

      // Send user turn with image and streaming true
      final testBytes = Uint8List.fromList([1, 2, 3, 4]);
      controller.sendRealtimeTurn(
        text: 'User prompt text',
        imageBytes: testBytes,
        turnComplete: false,
      );

      // 1. Default bubble rendering in dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
          ),
        ),
      );

      expect(find.text('Model bubble response'), findsOneWidget);
      expect(find.text('User prompt text'), findsOneWidget);

      // 2. Unified bubbleBuilder
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            bubbleBuilder: (context, item, isUser) => Text('Unified: ${item.text}'),
          ),
        ),
      );
      expect(find.text('Unified: Model bubble response'), findsOneWidget);
      expect(find.text('Unified: User prompt text'), findsOneWidget);

      // 3. Specialized userBubbleBuilder
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            userBubbleBuilder: (context, item, isUser) => Text('CustomUser: ${item.text}'),
          ),
        ),
      );
      expect(find.text('CustomUser: User prompt text'), findsOneWidget);
      expect(find.text('Model bubble response'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('default input bar mic toggle button and dark mode input fill color', (tester) async {
      final controller = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
          ),
        ),
      );

      // Tap mic toggle button in input bar to start recording
      await tester.tap(find.byType(GeminiLiveMicButton));
      await tester.pump();

      // Tap again to stop recording (calls controller.stopUserSpeaking())
      await tester.tap(find.byType(GeminiLiveMicButton));
      await tester.pump();

      controller.dispose();
    });

    testWidgets('message list scroll to bottom animation when list has clients', (tester) async {
      final controller = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveChatView(
              controller: controller,
              autoConnect: false,
            ),
          ),
        ),
      );

      // Add multiple messages to make list scrollable
      for (int i = 0; i < 20; i++) {
        controller.handleServerMessageForTesting(
          LiveServerMessage(
            serverContent: LiveServerContent(
              modelTurn: Content(
                parts: [Part(text: 'Long message item number $i with plenty of text to expand vertical height')],
              ),
            ),
          ),
        );
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      controller.dispose();
    });
  });
}
