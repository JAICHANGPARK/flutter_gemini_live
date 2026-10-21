import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiLiveMicButton coverage', () {
    testWidgets('renders dark theme inactive border and handles didUpdateWidget recording stop', (tester) async {
      bool recording = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return GeminiLiveMicButton(
                  isRecording: recording,
                  onPressed: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(GeminiLiveMicButton), findsOneWidget);

      // Transition to recording: false
      setState(() {
        recording = false;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(GeminiLiveMicButton), findsOneWidget);
    });
  });

  group('GeminiLiveControlBar coverage', () {
    testWidgets('renders in CupertinoApp, dark theme, and with trailing widget', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: Center(
              child: GeminiLiveControlBar(
                isMicActive: true,
                isVideoActive: false,
                onToggleMic: () {},
                onToggleVideo: () {},
                trailing: const Text('Trailing'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Trailing'), findsOneWidget);
    });
  });

  group('GeminiLiveVoiceIndicator coverage', () {
    testWidgets('renders in CupertinoApp, dark mode, and handles didUpdateWidget isSpeaking', (tester) async {
      bool speaking = false;
      late StateSetter setState;

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return GeminiLiveVoiceIndicator(isSpeaking: speaking);
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(GeminiLiveVoiceIndicator), findsOneWidget);

      setState(() {
        speaking = true;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(GeminiLiveVoiceIndicator), findsOneWidget);
    });
  });

  group('GeminiLiveStatusBadge coverage', () {
    testWidgets('renders dark theme and handles didUpdateWidget pulse stop', (tester) async {
      GeminiLiveSessionState state = GeminiLiveSessionState.connecting;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return GeminiLiveStatusBadge(state: state);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      setState(() {
        state = GeminiLiveSessionState.disconnected;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(GeminiLiveStatusBadge), findsOneWidget);
    });
  });

  group('GeminiLiveVoiceSelectorSheet coverage', () {
    testWidgets('renders in CupertinoApp with dark theme to cover catch branch', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: Material(
              child: GeminiLiveVoiceSelectorSheet(
                currentVoice: 'Aoede',
                onVoiceSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(GeminiLiveVoiceSelectorSheet), findsOneWidget);
    });

    testWidgets('showLiveVoice opens modal in MaterialApp, resolves voice, and handles selection', (tester) async {
      GeminiLiveVoice? selectedLiveVoice;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedLiveVoice = await GeminiLiveVoiceSelectorSheet.showLiveVoice(
                    context,
                    currentVoice: GeminiLiveVoice.aoede,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Gemini Live Voice Persona'), findsOneWidget);
      await tester.tap(find.text('Kore').first);
      await tester.pumpAndSettle();

      expect(selectedLiveVoice, GeminiLiveVoice.kore);
    });

    testWidgets('invokes onLiveVoiceSelected callback in Material dark theme', (tester) async {
      GeminiLiveVoice? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: GeminiLiveVoiceSelectorSheet(
              currentVoice: 'Aoede',
              onVoiceSelected: (_) {},
              onLiveVoiceSelected: (voice) {
                picked = voice;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Fenrir').first);
      await tester.pump();

      expect(picked, GeminiLiveVoice.fenrir);
    });
  });

  group('GeminiLiveToolActivityChip coverage', () {
    testWidgets('covers multi-call label, CupertinoApp, dark theme, idle without custom icon, and onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: Center(
              child: GeminiLiveToolActivityChip(
                isExecuting: true,
                activeCalls: [
                  FunctionCall(name: 'lookupWeather', id: 'c1', args: {}),
                  FunctionCall(name: 'bookFlight', id: 'c2', args: {}),
                ],
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Running lookupWeather +1…'), findsOneWidget);
      await tester.tap(find.byType(GeminiLiveToolActivityChip));
      expect(tapped, isTrue);

      // Also verify idle with completed icon fallback
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Center(
              child: GeminiLiveToolActivityChip(
                isExecuting: false,
                hideWhenIdle: false,
                activeCalls: [],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });
  });

  group('GeminiLiveBargeInBanner coverage', () {
    testWidgets('handles CupertinoApp, dark theme, and didUpdateWidget false->true->false transitions', (tester) async {
      bool interrupted = false;
      late StateSetter setState;

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return GeminiLiveBargeInBanner(isInterrupted: interrupted);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      setState(() {
        interrupted = true;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      setState(() {
        interrupted = false;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GeminiLiveBargeInBanner), findsOneWidget);
    });
  });

  group('GeminiLiveVisionOverlay coverage', () {
    testWidgets('supports isMirrored, didUpdateWidget toggle, and painter shouldRepaint', (tester) async {
      bool scan = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return GeminiLiveVisionOverlay(
                  enableScanAnimation: scan,
                  isMirrored: true,
                  child: const SizedBox(width: 100, height: 100),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Disable scan animation
      setState(() {
        scan = false;
      });
      await tester.pump();

      // Re-enable scan animation
      setState(() {
        scan = true;
      });
      await tester.pump();

      expect(find.byType(GeminiLiveVisionOverlay), findsOneWidget);
    });
  });

  group('GeminiLiveCaptionBubble coverage', () {
    testWidgets('handles CupertinoApp, dark mode, didUpdateWidget text and isStreaming transitions', (tester) async {
      String text = 'Hello';
      bool streaming = true;
      late StateSetter setState;

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return GeminiLiveCaptionBubble(
                  text: text,
                  isStreaming: streaming,
                  role: 'model',
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Change text to another non-empty string
      setState(() {
        text = 'World';
      });
      await tester.pump();

      // Change text to empty
      setState(() {
        text = '';
      });
      await tester.pump();

      // Change streaming flag
      setState(() {
        streaming = false;
      });
      await tester.pump();

      expect(find.byType(GeminiLiveCaptionBubble), findsOneWidget);
    });
  });

  group('GeminiLiveWaveform coverage', () {
    testWidgets('gradient rendering, shouldRepaint, CupertinoApp theme, and didUpdateWidget', (tester) async {
      final ampController = StreamController<double>.broadcast();
      final audioController = StreamController<Uint8List>.broadcast();

      int barCount = 10;
      double? amplitude = 0.5;
      late StateSetter setState;

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(primaryColor: CupertinoColors.systemPurple),
          home: CupertinoPageScaffold(
            child: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return GeminiLiveWaveform(
                  barCount: barCount,
                  amplitude: amplitude,
                  amplitudeStream: ampController.stream,
                  audioStream: audioController.stream,
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.red],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      setState(() {
        barCount = 16;
        amplitude = 0.8;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Simulate tick decay by letting animation run a bit
      await tester.pump(const Duration(milliseconds: 200));

      await ampController.close();
      await audioController.close();
    });
  });

  group('GeminiLiveUsageBadge and CupertinoGeminiLiveUsageBadge coverage', () {
    testWidgets('GeminiLiveUsageBadge renders in dark mode and opens details dialog with all token metrics', (tester) async {
      final tracker = GeminiTokenUsageTracker();
      tracker.recordUsage(
        UsageMetadata(
          promptTokenCount: 150,
          responseTokenCount: 80,
          totalTokenCount: 230,
          cachedContentTokenCount: 25,
          promptTokensDetails: [
            ModalityTokenCount(modality: MediaModality.AUDIO, tokenCount: 40),
            ModalityTokenCount(modality: MediaModality.VIDEO, tokenCount: 30),
            ModalityTokenCount(modality: MediaModality.IMAGE, tokenCount: 20),
            ModalityTokenCount(modality: MediaModality.TEXT, tokenCount: 60),
          ],
          responseTokensDetails: [
            ModalityTokenCount(modality: MediaModality.AUDIO, tokenCount: 50),
            ModalityTokenCount(modality: MediaModality.TEXT, tokenCount: 30),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: GeminiLiveUsageBadge(tracker: tracker),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap to open details dialog
      await tester.tap(find.byType(GeminiLiveUsageBadge));
      await tester.pumpAndSettle();

      expect(find.text('Gemini Live 사용량 및 비용'), findsOneWidget);
      expect(find.text('└ 실시간 영상 입력 (Video In)'), findsOneWidget);
      expect(find.text('└ 이미지 입력 (Image In)'), findsOneWidget);
      expect(find.text('└ 텍스트/시스템 입력 (Text In)'), findsOneWidget);
      expect(find.text('└ 텍스트 출력 (Text Out)'), findsOneWidget);
      expect(find.text('캐시된 토큰 (Cached)'), findsOneWidget);
    });

    testWidgets('CupertinoGeminiLiveUsageBadge renders in dark mode, shows dialog, and handles reset', (tester) async {
      final tracker = GeminiTokenUsageTracker();
      tracker.recordUsage(
        UsageMetadata(
          promptTokenCount: 100,
          responseTokenCount: 50,
          totalTokenCount: 150,
          cachedContentTokenCount: 10,
          promptTokensDetails: [
            ModalityTokenCount(modality: MediaModality.AUDIO, tokenCount: 25),
            ModalityTokenCount(modality: MediaModality.VIDEO, tokenCount: 25),
            ModalityTokenCount(modality: MediaModality.TEXT, tokenCount: 50),
          ],
          responseTokensDetails: [
            ModalityTokenCount(modality: MediaModality.AUDIO, tokenCount: 30),
            ModalityTokenCount(modality: MediaModality.TEXT, tokenCount: 20),
          ],
        ),
      );

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: Center(
              child: CupertinoGeminiLiveUsageBadge(tracker: tracker),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(CupertinoGeminiLiveUsageBadge));
      await tester.pumpAndSettle();

      expect(find.text('Gemini Live Usage'), findsOneWidget);
      expect(find.text('• Video In'), findsOneWidget);
      expect(find.text('• Text Out'), findsOneWidget);
      expect(find.text('Cached Tokens'), findsOneWidget);

      // Tap Reset
      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(tracker.totalTokens, 0);
    });
  });

  group('CupertinoGeminiLiveStatusBadge and CupertinoGeminiLiveMicButton coverage', () {
    testWidgets('CupertinoGeminiLiveStatusBadge renders dark mode and transitions isPulsing', (tester) async {
      GeminiLiveSessionState state = GeminiLiveSessionState.connecting;
      late StateSetter setState;

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return CupertinoGeminiLiveStatusBadge(state: state);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      setState(() {
        state = GeminiLiveSessionState.disconnected;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CupertinoGeminiLiveStatusBadge), findsOneWidget);
    });

    testWidgets('CupertinoGeminiLiveMicButton renders dark mode, taps, long presses, and stops recording', (tester) async {
      bool recording = true;
      bool longPressStarted = false;
      bool longPressEnded = false;
      late StateSetter setState;

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return CupertinoGeminiLiveMicButton(
                  isRecording: recording,
                  enableHaptics: true,
                  onPressed: () {},
                  onLongPressStart: () {
                    longPressStarted = true;
                  },
                  onLongPressEnd: () {
                    longPressEnded = true;
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(tester.getCenter(find.byType(CupertinoGeminiLiveMicButton)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(longPressStarted, isTrue);

      await gesture.up();
      await tester.pump();
      expect(longPressEnded, isTrue);

      // Transition to recording: false
      setState(() {
        recording = false;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CupertinoGeminiLiveMicButton), findsOneWidget);
    });
  });

  group('GeminiLiveAudioRouteButton coverage', () {
    testWidgets('exercises enum methods, custom iconBuilder, 2-route tap, and picker sheet in dark theme', (tester) async {
      expect(GeminiLiveAudioRoute.earpiece.label, 'Phone Earpiece');
      expect(GeminiLiveAudioRoute.headphones.label, 'Headphones');
      expect(GeminiLiveAudioRoute.bluetooth.label, 'Bluetooth Audio');
      expect(GeminiLiveAudioRoute.earpiece.iconData, Icons.phone_in_talk_rounded);
      expect(GeminiLiveAudioRoute.headphones.iconData, Icons.headphones_rounded);
      expect(GeminiLiveAudioRoute.bluetooth.iconData, Icons.bluetooth_audio_rounded);

      GeminiLiveAudioRoute route = GeminiLiveAudioRoute.speaker;
      late StateSetter setState;

      // 2 routes tap toggle
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return GeminiLiveAudioRouteButton(
                  key: const Key('two-route-btn'),
                  currentRoute: route,
                  availableRoutes: const [
                    GeminiLiveAudioRoute.speaker,
                    GeminiLiveAudioRoute.earpiece,
                  ],
                  onRouteChanged: (newRoute) {
                    setState(() {
                      route = newRoute;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('two-route-btn')));
      await tester.pump();
      expect(route, GeminiLiveAudioRoute.earpiece);

      // Now 3 routes in MaterialApp with route picker sheet and iconBuilder
      GeminiLiveAudioRoute selected3Route = GeminiLiveAudioRoute.speaker;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                return Center(
                  child: GeminiLiveAudioRouteButton(
                    key: const Key('three-route-btn'),
                    currentRoute: selected3Route,
                    availableRoutes: const [
                      GeminiLiveAudioRoute.speaker,
                      GeminiLiveAudioRoute.earpiece,
                      GeminiLiveAudioRoute.bluetooth,
                    ],
                    iconBuilder: (context, r, color) => Icon(r.iconData, color: color),
                    onRouteChanged: (newRoute) {
                      setter(() {
                        selected3Route = newRoute;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('three-route-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Bluetooth Audio'), findsOneWidget);
      await tester.tap(find.text('Bluetooth Audio'));
      await tester.pumpAndSettle();

      expect(selected3Route, GeminiLiveAudioRoute.bluetooth);
    });

    testWidgets('opens picker sheet in light theme without iconBuilder', (tester) async {
      GeminiLiveAudioRoute lightRoute = GeminiLiveAudioRoute.speaker;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                return Center(
                  child: GeminiLiveAudioRouteButton(
                    key: const Key('light-route-button'),
                    currentRoute: lightRoute,
                    availableRoutes: const [
                      GeminiLiveAudioRoute.speaker,
                      GeminiLiveAudioRoute.earpiece,
                      GeminiLiveAudioRoute.headphones,
                    ],
                    onRouteChanged: (newRoute) {
                      setter(() {
                        lightRoute = newRoute;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('light-route-button')));
      await tester.pumpAndSettle();
      expect(find.text('Headphones'), findsOneWidget);
      await tester.tap(find.text('Headphones'));
      await tester.pumpAndSettle();
      expect(lightRoute, GeminiLiveAudioRoute.headphones);
    });
  });

  group('Remaining widget edge cases', () {
    testWidgets('CupertinoGeminiLiveStatusBadge inProgress state and pulsing start transition', (tester) async {
      GeminiLiveSessionState state = GeminiLiveSessionState.disconnected;
      late StateSetter setState;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return CupertinoGeminiLiveStatusBadge(state: state);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Transition to inProgress (pumps line 88 and starts pulsing line 193)
      setState(() {
        state = GeminiLiveSessionState.inProgress;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Speaking...'), findsOneWidget);
    });

    testWidgets('CupertinoGeminiLiveMicButton starts recording in didUpdateWidget', (tester) async {
      bool recording = false;
      late StateSetter setState;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return CupertinoGeminiLiveMicButton(isRecording: recording);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      setState(() {
        recording = true;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CupertinoGeminiLiveMicButton), findsOneWidget);
    });

    testWidgets('GeminiLiveVisionOverlay updates scanColor', (tester) async {
      Color color = Colors.cyan;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return GeminiLiveVisionOverlay(
                  scanColor: color,
                  child: const SizedBox(width: 80, height: 80),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      setState(() {
        color = Colors.amber;
      });
      await tester.pump();
      expect(find.byType(GeminiLiveVisionOverlay), findsOneWidget);
    });

    testWidgets('GeminiLiveWaveform stream updates and painter shouldRepaint', (tester) async {
      final s1 = StreamController<double>.broadcast();
      final s2 = StreamController<double>.broadcast();
      var stream = s1.stream;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return GeminiLiveWaveform(amplitudeStream: stream);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      setState(() {
        stream = s2.stream;
      });
      await tester.pump();

      await s1.close();
      await s2.close();
    });
  });
}
