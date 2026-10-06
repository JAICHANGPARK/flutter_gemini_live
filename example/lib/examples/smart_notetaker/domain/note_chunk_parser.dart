import 'models/note_action_item.dart';

/// Parses structured `[KEY]`, `[ACTION]` and `[TERM]` tags out of a note chunk,
/// appending de-duplicated results to the given lists.
void parseNoteChunkTags(
  String chunk, {
  required List<String> keyTakeaways,
  required List<NoteActionItem> actionItems,
  required List<String> glossaryTerms,
}) {
  final lines = chunk.split('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('[KEY]') || trimmed.contains('[KEY]')) {
      final text = trimmed.replaceAll(RegExp(r'.*?\[KEY\]'), '').trim();
      if (text.isNotEmpty && !keyTakeaways.contains(text)) {
        keyTakeaways.add(text);
      }
    } else if (trimmed.startsWith('[ACTION]') || trimmed.contains('[ACTION]')) {
      final text = trimmed.replaceAll(RegExp(r'.*?\[ACTION\]'), '').trim();
      if (text.isNotEmpty && !actionItems.any((a) => a.title == text)) {
        actionItems.add(NoteActionItem(title: text));
      }
    } else if (trimmed.startsWith('[TERM]') || trimmed.contains('[TERM]')) {
      final text = trimmed.replaceAll(RegExp(r'.*?\[TERM\]'), '').trim();
      if (text.isNotEmpty && !glossaryTerms.contains(text)) {
        glossaryTerms.add(text);
      }
    }
  }
}
