import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  group('GeminiLiveLogger & GeminiLiveLogLevel Tests', () {
    test('filters messages based on severity levels', () {
      final logs = <String>[];
      final logger = GeminiLiveLogger(
        level: GeminiLiveLogLevel.warning,
        output: (msg, lvl) => logs.add('$lvl: $msg'),
      );

      logger.traffic('Packet #1');
      logger.info('Connected');
      logger.warning('Deprecated param');
      logger.error('Socket drop');

      expect(logs.length, 2);
      expect(logs[0], contains('[GeminiLive] ⚠️ WARNING Deprecated param'));
      expect(logs[1], contains('[GeminiLive] ❌ ERROR Socket drop'));
    });

    test('toCallback infers severity correctly from emoji prefixes', () {
      final logs = <GeminiLiveLogLevel>[];
      final logger = GeminiLiveLogger(
        level: GeminiLiveLogLevel.traffic,
        output: (_, lvl) => logs.add(lvl),
      );

      final callback = logger.toCallback();

      callback('📤 Sending: {"turn": 1}');
      callback('⚠️ Warning: Deprecated');
      callback('❌ Error: Failed setup');
      callback('Normal informational line');

      expect(logs, [
        GeminiLiveLogLevel.traffic,
        GeminiLiveLogLevel.warning,
        GeminiLiveLogLevel.error,
        GeminiLiveLogLevel.info,
      ]);
    });

    test('silent logger emits nothing', () {
      final logs = <String>[];
      const logger = GeminiLiveLogger.silent;

      logger.traffic('Test');
      logger.error('Error');

      expect(logs, isEmpty);
    });
  });
}
