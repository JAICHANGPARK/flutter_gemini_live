class LogEntry {
  final DateTime timestamp;
  final String type;
  final String message;
  final Map<String, dynamic>? data;

  LogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
    this.data,
  });
}
