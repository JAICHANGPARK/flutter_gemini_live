/// An individual speech turn in the live audio timeline.
class LiveSpeechTurn {
  final String speakerText;
  final String? translatedText;
  final DateTime timestamp;

  LiveSpeechTurn({
    required this.speakerText,
    this.translatedText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String formatTime() {
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$m:$s';
  }
}
