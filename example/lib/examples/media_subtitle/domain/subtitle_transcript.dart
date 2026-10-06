import 'models/subtitle_entry.dart';

/// Builds the clipboard text for the full subtitle history.
String buildSubtitleTranscript(List<SubtitleEntry> history) {
  final buffer = StringBuffer();
  buffer.writeln('=== Gemini Live Translate 실시간 자막 기록 ===');
  for (final item in history) {
    buffer.writeln('[${item.formatTime()}]');
    if (item.originalText.isNotEmpty) {
      buffer.writeln('원문: ${item.originalText}');
    }
    buffer.writeln('번역: ${item.translatedText}');
    buffer.writeln();
  }
  return buffer.toString();
}
