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
  });

  group('GeminiLiveVoiceIndicator', () {
    testWidgets('renders correct number of bars', (tester) async {
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

      expect(find.byType(GeminiLiveVoiceIndicator), findsOneWidget);
    });
  });
}
