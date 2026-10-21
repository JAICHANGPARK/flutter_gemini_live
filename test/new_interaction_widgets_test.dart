import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  group('New Gemini Live Interaction Widgets', () {
    testWidgets('GeminiLiveBargeInBanner renders and animates when isInterrupted is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GeminiLiveBargeInBanner(
                isInterrupted: true,
                message: 'Listening to you...',
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(GeminiLiveBargeInBanner), findsOneWidget);
      expect(find.text('Listening to you...'), findsOneWidget);
      expect(find.byIcon(Icons.hearing_rounded), findsOneWidget);
    });

    testWidgets('GeminiLiveControlBar renders buttons and responds to callbacks',
        (tester) async {
      bool micToggled = false;
      bool videoToggled = false;
      bool cameraFlipped = false;
      bool callEnded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GeminiLiveControlBar(
                isMicActive: true,
                isVideoActive: true,
                onToggleMic: () => micToggled = true,
                onToggleVideo: () => videoToggled = true,
                onFlipCamera: () => cameraFlipped = true,
                onEndCall: () => callEnded = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GeminiLiveControlBar), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_ios_rounded), findsOneWidget);
      expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.mic));
      expect(micToggled, isTrue);

      await tester.tap(find.byIcon(Icons.videocam));
      expect(videoToggled, isTrue);

      await tester.tap(find.byIcon(Icons.flip_camera_ios_rounded));
      expect(cameraFlipped, isTrue);

      await tester.tap(find.byIcon(Icons.call_end_rounded));
      expect(callEnded, isTrue);
    });

    testWidgets('GeminiLiveVoiceSelectorSheet renders and selects voice',
        (tester) async {
      String? selectedVoice;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    selectedVoice = await GeminiLiveVoiceSelectorSheet.show(
                      context,
                      currentVoice: 'Puck',
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(GeminiLiveVoiceSelectorSheet), findsOneWidget);
      expect(find.text('Puck'), findsOneWidget);
      expect(find.text('Aoede'), findsOneWidget);

      // Tap 'Aoede'
      await tester.tap(find.text('Aoede'));
      await tester.pumpAndSettle();

      expect(selectedVoice, equals('Aoede'));
      expect(find.byType(GeminiLiveVoiceSelectorSheet), findsNothing);
    });

    testWidgets('GeminiLiveVisionOverlay renders HUD reticles and analyzing badge',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 240,
                child: GeminiLiveVisionOverlay(
                  isAnalyzing: true,
                  enableScanAnimation: true,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GeminiLiveVisionOverlay), findsOneWidget);
      expect(find.text('AI Analyzing...'), findsOneWidget);
    });

    testWidgets('GeminiLiveBargeInBanner auto-dismisses after displayDuration and supports custom icon',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GeminiLiveBargeInBanner(
                isInterrupted: true,
                displayDuration: Duration(milliseconds: 500),
                icon: Icon(Icons.graphic_eq_rounded),
              ),
            ),
          ),
        ),
      );

      final bannerFade = find.descendant(
        of: find.byType(GeminiLiveBargeInBanner),
        matching: find.byType(FadeTransition),
      );

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      expect(tester.widget<FadeTransition>(bannerFade).opacity.value, 1.0);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(tester.widget<FadeTransition>(bannerFade).opacity.value, 0.0);
    });

    testWidgets('GeminiLiveMicButton and CupertinoGeminiLiveMicButton render custom activeIcon/inactiveIcon',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GeminiLiveMicButton(
                  isRecording: true,
                  activeIcon: Icon(Icons.stop_circle_outlined),
                  inactiveIcon: Icon(Icons.play_arrow),
                ),
                CupertinoGeminiLiveMicButton(
                  isRecording: false,
                  activeIcon: Icon(Icons.stop),
                  inactiveIcon: Icon(Icons.keyboard_voice),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_voice), findsOneWidget);
    });

    testWidgets('GeminiLiveChatView supports custom slot builders and controller swapping in didUpdateWidget',
        (tester) async {
      final genAI = GoogleGenAI(apiKey: 'test-key');
      final controller1 = GeminiLiveSessionController(liveService: genAI.live);
      final controller2 = GeminiLiveSessionController(liveService: genAI.live);

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller1,
            autoConnect: false,
            headerBuilder: (context, ctrl) => AppBar(
              title: const Text('Custom Header'),
            ),
            emptyBuilder: (context, ctrl) => Text(
              identical(ctrl, controller1) ? 'Controller 1 Slot' : 'Controller 2 Slot',
            ),
            inputBuilder: (context, ctrl, textCtrl, onSend) =>
                const Text('Custom Input Slot'),
          ),
        ),
      );

      expect(find.text('Custom Header'), findsOneWidget);
      expect(find.text('Controller 1 Slot'), findsOneWidget);
      expect(find.text('Custom Input Slot'), findsOneWidget);

      // Swap controller via didUpdateWidget
      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller2,
            autoConnect: false,
            emptyBuilder: (context, ctrl) => Text(
              identical(ctrl, controller2) ? 'Controller 2 Active' : 'Old Controller',
            ),
          ),
        ),
      );

      expect(find.text('Controller 2 Active'), findsOneWidget);

      controller1.dispose();
      controller2.dispose();
    });

    test('Transcription WordInfo and RealtimeInputConfig interimTranscriptTimestampEnabled serialize properly', () {
      final roundTrip = Transcription.fromJson({
        'text': 'hello world',
        'finished': true,
        'speakerLabel': 'Speaker 1',
        'startOffset': '0.1s',
        'endOffset': '1.2s',
        'words': [
          {'word': 'hello', 'startOffset': '0.1s', 'endOffset': '0.5s'},
          {'word': 'world', 'startOffset': '0.6s', 'endOffset': '1.2s'},
        ],
      });
      expect(roundTrip.speakerLabel, 'Speaker 1');
      expect(roundTrip.words?.length, 2);
      expect(roundTrip.words?.first.word, 'hello');
      expect(roundTrip.words?.first.startOffset, '0.1s');

      final config = RealtimeInputConfig(
        interimTranscriptTimestampEnabled: true,
      );
      final configJson = config.toJson();
      expect(configJson['interim_transcript_timestamp_enabled'], isTrue);
      expect(
        RealtimeInputConfig.fromJson(configJson).interimTranscriptTimestampEnabled,
        isTrue,
      );
    });

    test('GeminiLivePcmChunker chunks irregular PCM streams with 16-bit alignment', () async {
      final chunker = GeminiLivePcmChunker.fromDuration(
        duration: const Duration(milliseconds: 20), // 640 bytes at 16kHz 16-bit mono
        sampleRate: 16000,
      );
      expect(chunker.chunkSizeInBytes, 640);

      final source = Stream<Uint8List>.fromIterable([
        Uint8List(300),
        Uint8List(400),
        Uint8List(600),
      ]);

      final emitted = await source.transform(chunker).toList();
      // Total 1300 bytes -> 640 + 640 + trailing 20 bytes flushed
      expect(emitted.length, 3);
      expect(emitted[0].length, 640);
      expect(emitted[1].length, 640);
      expect(emitted[2].length, 20);
    });

    test('GeminiLiveAudioBuffer accumulates PCM, calculates duration, and exports WAV', () {
      final buffer = GeminiLiveAudioBuffer(
        sampleRate: 24000,
        numChannels: 1,
        bitsPerSample: 16,
      );

      // 48,000 bytes = 1 second of 24kHz 16-bit mono audio
      buffer.add(Uint8List(24000));
      buffer.add(Uint8List(24000));

      expect(buffer.lengthInBytes, 48000);
      expect(buffer.duration, const Duration(seconds: 1));

      final wav = buffer.toWavBytes();
      expect(wav.length, 48044);
      // Verify 'RIFF' and 'WAVE' magic headers
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');

      buffer.clear();
      expect(buffer.isEmpty, isTrue);
    });

    test('GeminiLiveReconnectPolicy computes exponential backoff delays and controller tracks tool calls & WAV export', () {
      const policy = GeminiLiveReconnectPolicy(
        maxAttempts: 4,
        initialDelay: Duration(milliseconds: 500),
        maxDelay: Duration(milliseconds: 3000),
        backoffMultiplier: 2.0,
      );

      expect(policy.delayForAttempt(0), const Duration(milliseconds: 500));
      expect(policy.delayForAttempt(1), const Duration(milliseconds: 1000));
      expect(policy.delayForAttempt(2), const Duration(milliseconds: 2000));
      expect(policy.delayForAttempt(3), const Duration(milliseconds: 3000));

      final genAI = GoogleGenAI(apiKey: 'test-key');
      final controller = GeminiLiveSessionController(
        liveService: genAI.live,
        reconnectPolicy: policy,
      );

      // Session resumption update
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          sessionResumptionUpdate: LiveServerSessionResumptionUpdate(
            newHandle: 'resume-token-123',
            resumable: true,
          ),
        ),
      );
      expect(controller.latestSessionHandle, 'resume-token-123');
      expect(controller.isSessionResumable, isTrue);

      // Tool call tracking
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          toolCall: LiveServerToolCall(
            functionCalls: [
              FunctionCall(id: 'call-1', name: 'get_weather', args: {'city': 'Seoul'}),
            ],
          ),
        ),
      );
      expect(controller.isExecutingTool, isTrue);
      expect(controller.activeToolCalls.first.name, 'get_weather');

      controller.sendToolResponses([
        FunctionResponse(id: 'call-1', name: 'get_weather', response: {'temp': 22}),
      ]);
      expect(controller.isExecutingTool, isFalse);

      // Audio turn accumulation and WAV export
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [
                Part(
                  inlineData: Blob(
                    mimeType: 'audio/pcm;rate=24000',
                    data: base64Encode(Uint8List(480)),
                  ),
                ),
              ],
            ),
            turnComplete: true,
          ),
        ),
      );

      final exportedWav = controller.exportLastTurnWav();
      expect(exportedWav, isNotNull);
      expect(exportedWav!.length, 480 + 44);

      controller.dispose();
    });

    testWidgets('GeminiLiveToolActivityChip renders active tool call and custom labelBuilder',
        (tester) async {
      final genAI = GoogleGenAI(apiKey: 'test-key');
      final controller = GeminiLiveSessionController(liveService: genAI.live);

      controller.handleServerMessageForTesting(
        LiveServerMessage(
          toolCall: LiveServerToolCall(
            functionCalls: [
              FunctionCall(id: 'c1', name: 'search_calendar'),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GeminiLiveToolActivityChip.fromController(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Running search_calendar…'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('GeminiLiveAudioRouteButton cycles 2 routes and opens picker for 3+ routes',
        (tester) async {
      GeminiLiveAudioRoute route = GeminiLiveAudioRoute.speaker;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: GeminiLiveAudioRouteButton(
                    currentRoute: route,
                    onRouteChanged: (next) => setState(() => route = next),
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      await tester.tap(find.byType(GeminiLiveAudioRouteButton));
      await tester.pumpAndSettle();
      expect(route, GeminiLiveAudioRoute.earpiece);
      expect(find.byIcon(Icons.phone_in_talk_rounded), findsOneWidget);
    });

    testWidgets('GeminiLiveTranslateSplitView renders dual panes, swaps languages, and toggles faceToFaceMode',
        (tester) async {
      final genAI = GoogleGenAI(apiKey: 'test-key');
      final controller = GeminiLiveSessionController(liveService: genAI.live);

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveTranslateSplitView(
            controller: controller,
            sourceLanguageCode: 'ko-KR',
            sourceLanguageLabel: '한국어',
            targetLanguageCode: 'en-US',
            targetLanguageLabel: 'English',
          ),
        ),
      );

      expect(find.text('한국어'), findsWidgets);
      expect(find.text('English'), findsWidgets);

      // Tap swap languages icon
      await tester.tap(find.byIcon(Icons.swap_vert_rounded));
      await tester.pump();

      // Tap face-to-face rotation button
      await tester.tap(find.byIcon(Icons.screen_rotation_alt_rounded));
      await tester.pump();
      expect(find.byType(RotatedBox), findsOneWidget);

      controller.dispose();
    });
  });

  group('Upstream v2.30.0 / v2.31.0 Parity Tests', () {
    test('GoogleSearch supports SearchTypes (webSearch & imageSearch)', () {
      const search = GoogleSearch(
        excludeDomains: ['example.com'],
        searchTypes: SearchTypes(
          webSearch: WebSearch(),
          imageSearch: ImageSearch(),
        ),
      );
      final json = search.toJson();
      expect(json['search_types'], isA<Map<String, dynamic>>());
      final restored = GoogleSearch.fromJson(json);
      expect(restored.searchTypes?.webSearch, isNotNull);
      expect(restored.searchTypes?.imageSearch, isNotNull);
    });

    test('GoogleMaps supports authConfig and enableWidget', () {
      final maps = GoogleMaps(
        groundingTypes: ['PLACE_SEARCH'],
        authConfig: const AuthConfig(apiKey: 'maps-key', authType: 'API_KEY'),
        enableWidget: true,
      );
      final json = maps.toJson();
      expect(json['enable_widget'], isTrue);
      expect((json['auth_config'] as Map)['api_key'], 'maps-key');

      final restored = GoogleMaps.fromJson(json);
      expect(restored.enableWidget, isTrue);
      expect(restored.authConfig?.apiKey, 'maps-key');
    });

    test('Tool.fromMcpServers and typedMcpServers round-trip', () {
      final tool = Tool.fromMcpServers([
        const McpServer(
          name: 'weather-mcp',
          streamableHttpTransport: StreamableHttpTransport(
            url: 'https://mcp.example.com/sse',
            headers: {'Authorization': 'Bearer token'},
            timeout: '10s',
            sseReadTimeout: '30s',
            terminateOnClose: true,
          ),
        ),
      ]);
      final servers = tool.typedMcpServers;
      expect(servers, isNotNull);
      expect(servers!.first.name, 'weather-mcp');
      expect(
        servers.first.streamableHttpTransport?.url,
        'https://mcp.example.com/sse',
      );
      expect(servers.first.streamableHttpTransport?.terminateOnClose, isTrue);
    });

    test('LiveConnectConstraints supports full Live setup fields', () {
      final constraints = LiveConnectConstraints(
        model: 'models/gemini-2.5-flash-native-audio-preview-12-2025',
        config: GenerationConfig(temperature: 0.6),
        systemInstruction: Content(parts: [Part(text: 'Stay concise.')]),
        inputAudioTranscription: AudioTranscriptionConfig(),
        outputAudioTranscription: AudioTranscriptionConfig(),
        sessionResumption: SessionResumptionConfig(handle: 'res-123'),
        proactivity: ProactivityConfig(proactiveAudio: true),
        translationConfig: TranslationConfig(
          targetLanguageCode: 'en-US',
          echoTargetLanguage: true,
        ),
      );
      final json = constraints.toJson();
      expect(json['system_instruction'], isNotNull);
      expect(json['session_resumption'], isNotNull);
      expect(json['proactivity'], isNotNull);
      expect(json['translation_config'], isNotNull);

      final restored = LiveConnectConstraints.fromJson({
        'model': constraints.model,
        'system_instruction': constraints.systemInstruction!.toJson(),
        'session_resumption': constraints.sessionResumption!.toJson(),
        'proactivity': constraints.proactivity!.toJson(),
        'translation_config': constraints.translationConfig!.toJson(),
      });
      expect(restored.sessionResumption?.handle, 'res-123');
      expect(restored.proactivity?.proactiveAudio, isTrue);
      expect(restored.translationConfig?.targetLanguageCode, 'en-US');
    });

    test('VoiceActivity and UsageMetadata support wire-format fallback keys', () {
      final vaFromWire = VoiceActivity.fromJson({
        'type': 'ACTIVITY_START',
        'audioOffset': '1.2s',
      });
      expect(vaFromWire.voiceActivityType, VoiceActivityType.ACTIVITY_START);
      expect(vaFromWire.audioOffset, '1.2s');

      final usage = UsageMetadata.fromJson({
        'initialPromptTokenCount': 42,
        'promptTokenCount': 100,
        'candidatesTokenCount': 55,
        'toolUsePromptTokenCount': 18,
        'totalTokenCount': 173,
      });
      expect(usage.initialPromptTokenCount, 42);
      expect(usage.responseTokenCount, 55);
      expect(usage.toolUsePromptTokenCount, 18);

      final tracker = GeminiTokenUsageTracker();
      tracker.recordUsage(usage);
      expect(tracker.initialPromptTokens, 42);
      expect(tracker.toolUsePromptTokens, 18);
      expect(tracker.responseTokens, 55);
      tracker.reset();
      expect(tracker.initialPromptTokens, 0);
      expect(tracker.toolUsePromptTokens, 0);
    });

    test('LiveClientContextUpdate supports systemInstruction, tool updates, and clearing tools', () {
      // 1. Update systemInstruction via String
      final sysUpdate = LiveClientContextUpdate(
        systemInstruction: 'You are a helpful assistant.',
      );
      final sysMsg = LiveClientMessage(contextUpdate: sysUpdate).toJson();
      final ctxJson = (sysMsg['contextUpdate'] as LiveClientContextUpdate).toJson();
      expect(ctxJson['systemInstruction']['role'], 'user');
      expect(
        (ctxJson['systemInstruction']['parts'] as List).first.text,
        'You are a helpful assistant.',
      );

      // 2. Clear tools via empty list []
      final clearUpdate = LiveClientContextUpdate(tools: const <Tool>[]);
      final clearJson = clearUpdate.toJson();
      expect(clearJson['tools'], {'tools': []});

      // 3. Update tools with function declaration & round-trip fromJson
      final toolUpdate = LiveClientContextUpdate(
        systemInstruction: 'Updated instruction.',
        tools: LiveClientContextUpdateTools(
          tools: [
            Tool(
              functionDeclarations: [
                FunctionDeclaration(
                  name: 'get_current_weather',
                  description: 'Gets the weather for a location.',
                ),
              ],
            ),
          ],
        ),
      );
      final restored = LiveClientContextUpdate.fromJson(toolUpdate.toJson());
      expect(
        restored.systemInstruction?.parts?.first.text,
        'Updated instruction.',
      );
      expect(
        restored.tools?.tools?.first.functionDeclarations?.first.name,
        'get_current_weather',
      );
    });

    test('PromptedVoice and CreateVoiceRequest.prompted support baseVoice', () {
      final req = CreateVoiceRequest.prompted(
        prompt: 'Make the voice slightly warmer and slower.',
        baseVoice: 'Puck',
        displayName: 'Warm Puck',
      );
      final json = req.toJson();
      expect((json['prompted'] as Map)['base_voice'], 'Puck');
      expect(
        (json['prompted'] as Map)['input'],
        'Make the voice slightly warmer and slower.',
      );

      final restored = CreateVoiceRequest.fromJson(json);
      expect(restored.prompted?.baseVoice, 'Puck');
      expect(
        restored.prompted?.input,
        'Make the voice slightly warmer and slower.',
      );
    });
  });
}
