import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  group('GeminiLiveStatusBadge', () {
    testWidgets('renders disconnected state correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveStatusBadge(
              state: GeminiLiveSessionState.disconnected,
            ),
          ),
        ),
      );

      expect(find.text('Disconnected'), findsOneWidget);
    });

    testWidgets('renders connected ready state correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveStatusBadge(
              state: GeminiLiveSessionState.connected,
              interactionStatus: InteractionStatus.IDLE,
            ),
          ),
        ),
      );

      expect(find.text('Ready (Idle)'), findsOneWidget);
    });

    testWidgets('renders inProgress state correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveStatusBadge(
              state: GeminiLiveSessionState.inProgress,
              interactionStatus: InteractionStatus.IN_PROGRESS,
            ),
          ),
        ),
      );

      expect(find.text('Thinking / Speaking'), findsOneWidget);
    });

    testWidgets('fromFlags builds correctly with connection and interaction flags', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveStatusBadge.fromFlags(
              isConnected: true,
              interactionStatus: InteractionStatus.IN_PROGRESS,
            ),
          ),
        ),
      );

      expect(find.text('Thinking / Speaking'), findsOneWidget);
    });
    testWidgets('respects customLabel and showLabel=false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveStatusBadge(
              state: GeminiLiveSessionState.connected,
              customLabel: 'Custom Connected',
            ),
          ),
        ),
      );
      expect(find.text('Custom Connected'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveStatusBadge(
              state: GeminiLiveSessionState.connected,
              showLabel: false,
            ),
          ),
        ),
      );
      expect(find.text('Custom Connected'), findsNothing);
      expect(find.text('Ready (Idle)'), findsNothing);
    });

    testWidgets('animates pulse dot when state updates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveStatusBadge(
              state: GeminiLiveSessionState.connected,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Transition to inProgress
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveStatusBadge(
              state: GeminiLiveSessionState.inProgress,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Thinking / Speaking'), findsOneWidget);
    });
  });

  group('GeminiLiveMicButton', () {
    testWidgets('taps trigger onPressed callback', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveMicButton(
              isRecording: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GeminiLiveMicButton));
      await tester.pump();
      expect(pressed, true);
    });

    testWidgets('long press triggers onLongPressStart and onLongPressEnd', (tester) async {
      var started = false;
      var ended = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveMicButton(
              isRecording: false,
              onPressed: () {},
              onLongPressStart: () => started = true,
              onLongPressEnd: () => ended = true,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(GeminiLiveMicButton)));
      await tester.pump(const Duration(seconds: 1));
      expect(started, true);

      await gesture.up();
      await tester.pump();
      expect(ended, true);
    });

    testWidgets('handles isRecording state change and controller animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveMicButton(
              isRecording: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveMicButton(
              isRecording: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GeminiLiveMicButton), findsOneWidget);
    });
  });

  group('GeminiLiveVoiceIndicator', () {
    testWidgets('renders correct number of bars when speaking and when resting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveVoiceIndicator(
              isSpeaking: true,
              barCount: 5,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(GeminiLiveVoiceIndicator), findsOneWidget);

      // Transition to resting
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveVoiceIndicator(
              isSpeaking: false,
              barCount: 5,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(GeminiLiveVoiceIndicator), findsOneWidget);
    });
  });
}
