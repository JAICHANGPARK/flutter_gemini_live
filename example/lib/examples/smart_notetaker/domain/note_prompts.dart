import '../ui/smart_notetaker/smart_notetaker_i18n.dart';

/// System instruction for the note-taker session.
String buildNoteSystemPrompt(String targetLang) {
  return '''
You are an expert real-time AI lecture and meeting note-taker.
Your mission:
1. Listen to the continuous live audio stream.
2. In real-time, translate any foreign speech into $targetLang.
3. Automatically structure clear, well-organized lecture/meeting notes in Markdown.
4. When important insights appear, mark them with "[KEY] insight".
5. When tasks, action items, or decisions occur, mark them with "[ACTION] task description".
6. When important terms or concepts are defined, mark them with "[TERM] concept: definition".
7. Deliver concise, high-value professional notes without small talk or filler text.
''';
}

/// Prompt sent when the user asks for the final wrap-up summary.
String get kWrapUpSummaryPrompt => SmartNotetakerI18n.current.wrapUpSummaryPrompt;

/// Writes the initial guide into the raw notes buffer.
void writeInitialNoteGuide(StringBuffer buffer) {
  buffer.write(SmartNotetakerI18n.current.initialNoteGuide);
}
