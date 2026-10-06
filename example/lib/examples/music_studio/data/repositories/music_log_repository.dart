/// In-memory stream log (newest first, capped at 100 entries).
class MusicLogRepository {
  final List<String> _logs = [];

  List<String> get logs => _logs;

  void add(String message) {
    _logs.insert(
      0,
      '[${DateTime.now().toIso8601String().substring(11, 19)}] $message',
    );
    if (_logs.length > 100) _logs.removeLast();
  }
}
