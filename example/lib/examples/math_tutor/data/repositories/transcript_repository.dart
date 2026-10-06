import '../../domain/models/live_transcript_entry.dart';

/// In-memory live dialog log with the merge rules used while streaming
/// speech-to-text fragments.
class TranscriptRepository {
  final List<LiveTranscriptEntry> _entries = [];

  List<LiveTranscriptEntry> get entries => _entries;

  /// Replaces the last user entry if it is < 4s old, otherwise adds one.
  void recordUserUtterance(String text) {
    if (_entries.isNotEmpty &&
        _entries.last.role == 'user' &&
        DateTime.now().difference(_entries.last.timestamp).inSeconds < 4) {
      _entries.last.text = text;
    } else {
      _entries.add(
        LiveTranscriptEntry(
          role: 'user',
          text: text,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Appends to the last model entry if it is < 8s old, otherwise adds one.
  void appendModelText(String text) {
    if (_entries.isNotEmpty &&
        _entries.last.role == 'model' &&
        DateTime.now().difference(_entries.last.timestamp).inSeconds < 8) {
      _entries.last.text += text;
    } else {
      _entries.add(
        LiveTranscriptEntry(
          role: 'model',
          text: text,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void addSystem(String text, {bool isInterrupted = false}) {
    _entries.add(
      LiveTranscriptEntry(
        role: 'system',
        text: text,
        timestamp: DateTime.now(),
        isInterrupted: isInterrupted,
      ),
    );
  }

  void clear() => _entries.clear();
}
