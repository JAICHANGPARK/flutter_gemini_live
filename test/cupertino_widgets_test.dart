import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  group('Cupertino Gemini Live Widgets', () {
    testWidgets('CupertinoGeminiLiveStatusBadge renders correctly in CupertinoApp',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: CupertinoGeminiLiveStatusBadge.fromFlags(
                isConnected: true,
                isInProgress: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoGeminiLiveStatusBadge), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
    });

    testWidgets('CupertinoGeminiLiveMicButton renders and handles tap and haptics',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: CupertinoGeminiLiveMicButton(
                isRecording: false,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoGeminiLiveMicButton), findsOneWidget);
      await tester.tap(find.byType(CupertinoGeminiLiveMicButton));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('CupertinoGeminiLiveUsageBadge renders and opens Cupertino dialog',
        (tester) async {
      final tracker = GeminiTokenUsageTracker();
      tracker.recordUsage(
        UsageMetadata(
          totalTokenCount: 1500,
          promptTokenCount: 500,
          responseTokenCount: 1000,
        ),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: CupertinoGeminiLiveUsageBadge(tracker: tracker),
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoGeminiLiveUsageBadge), findsOneWidget);
      expect(find.textContaining('1,500 tokens'), findsOneWidget);

      // Tap to open Cupertino dialog
      await tester.tap(find.byType(CupertinoGeminiLiveUsageBadge));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.text('Gemini Live Usage'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });

    testWidgets('GeminiLiveCaptionBubble & Waveform work inside CupertinoApp',
        (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: Column(
              children: [
                GeminiLiveWaveform(amplitude: 0.5),
                GeminiLiveCaptionBubble(
                  text: 'Hello from Cupertino',
                  role: 'model',
                ),
                GeminiLiveVoiceIndicator(isSpeaking: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hello from Cupertino'), findsOneWidget);
      expect(find.byType(GeminiLiveWaveform), findsOneWidget);
      expect(find.byType(GeminiLiveVoiceIndicator), findsOneWidget);
    });
  });
}
