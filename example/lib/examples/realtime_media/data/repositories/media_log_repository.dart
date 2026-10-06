import '../../domain/models/media_log.dart';

/// In-memory log of the demo session, newest entry first.
class MediaLogRepository {
  final List<MediaLog> _logs = [];

  List<MediaLog> get logs => _logs;

  void add(String type, String message) {
    _logs.insert(
      0,
      MediaLog(timestamp: DateTime.now(), type: type, message: message),
    );
  }
}
