import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  group('GeminiLiveChatView Widget Tests', () {
    testWidgets('renders default layout when supplied with mock controller',
        (tester) async {
      final genAI = GoogleGenAI(apiKey: 'dummy_api_key');
      final controller =
          GeminiLiveSessionController(liveService: genAI.live);

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            title: 'Test Live Chat',
          ),
        ),
      );

      // Verify title and default empty state
      expect(find.text('Test Live Chat'), findsOneWidget);
      expect(find.text('Gemini Live Ready'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(GeminiLiveMicButton), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      controller.dispose();
    });

    testWidgets('renders custom slot builders for bubbles and input',
        (tester) async {
      final genAI = GoogleGenAI(apiKey: 'dummy_api_key');
      final controller =
          GeminiLiveSessionController(liveService: genAI.live);

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            emptyBuilder: (context, _) =>
                const Text('Custom Empty Placeholder'),
            inputBuilder: (context, ctrl, textCtrl, onSend) => Container(
              key: const ValueKey('custom_input_bar'),
              child: const Text('Custom Input Slot'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Empty Placeholder'), findsOneWidget);
      expect(find.byKey(const ValueKey('custom_input_bar')), findsOneWidget);
      expect(find.text('Custom Input Slot'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('renders custom user and model bubble builders when messages exist',
        (tester) async {
      final genAI = GoogleGenAI(apiKey: 'dummy_api_key');
      final controller =
          GeminiLiveSessionController(liveService: genAI.live);

      // Inject test messages using testing helper
      controller.handleServerMessageForTesting(
        LiveServerMessage(
          serverContent: LiveServerContent(
            modelTurn: Content(
              parts: [Part(text: 'Hello, this is Gemini Live AI!')],
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
            modelBubbleBuilder: (context, item, isUser) => Container(
              key: const ValueKey('custom_ai_bubble'),
              child: Text('AI: ${item.text}'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('custom_ai_bubble')), findsOneWidget);
      expect(find.text('AI: Hello, this is Gemini Live AI!'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('typing and pressing send triggers sendRealtimeText',
        (tester) async {
      final genAI = GoogleGenAI(apiKey: 'dummy_api_key');
      final controller =
          GeminiLiveSessionController(liveService: genAI.live);

      await tester.pumpWidget(
        MaterialApp(
          home: GeminiLiveChatView(
            controller: controller,
            autoConnect: false,
          ),
        ),
      );

      // Enter text into the default input
      await tester.enterText(find.byType(TextField), 'Testing message send');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Text field should be cleared
      expect(find.text('Testing message send'), findsNothing);

      controller.dispose();
    });
  });
}
