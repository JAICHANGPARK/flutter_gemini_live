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
  });
}
