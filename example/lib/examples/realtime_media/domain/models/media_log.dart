/// One entry in the realtime media demo's live log.
class MediaLog {
  final DateTime timestamp;
  final String type;
  final String message;

  MediaLog({
    required this.timestamp,
    required this.type,
    required this.message,
  });
}
