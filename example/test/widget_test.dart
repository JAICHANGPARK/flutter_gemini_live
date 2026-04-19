import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('home screen shows demo entries', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Gemini Live API Examples'), findsOneWidget);
    expect(find.text('Chat Interface'), findsOneWidget);
    expect(find.text('Live API Features'), findsOneWidget);
    expect(find.text('Function Calling'), findsOneWidget);
    expect(find.text('Realtime Media'), findsOneWidget);
  });
}
