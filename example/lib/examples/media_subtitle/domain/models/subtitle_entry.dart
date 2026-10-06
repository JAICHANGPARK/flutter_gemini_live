/// Subtitle entry in the timeline log.
class SubtitleEntry {
  final String originalText;
  final String translatedText;
  final DateTime timestamp;

  SubtitleEntry({
    required this.originalText,
    required this.translatedText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String formatTime() {
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$m:$s';
  }
}
