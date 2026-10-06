/// A real-time conversation or system event log entry for the Live Dialog Log tab.
class LiveTranscriptEntry {
  final String role; // 'user' | 'model' | 'system'
  String text;
  final DateTime timestamp;
  final bool isInterrupted;

  LiveTranscriptEntry({
    required this.role,
    required this.text,
    required this.timestamp,
    this.isInterrupted = false,
  });
}
