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
const String kWrapUpSummaryPrompt =
    '지금까지 청취한 전체 내용을 바탕으로 [최종 결론 요약 (Executive Summary)]'
    '과 [핵심 액션 아이템]을 명확한 마크다운 리포트로 최종 정리해줘.';

/// Writes the initial guide into the raw notes buffer.
void writeInitialNoteGuide(StringBuffer buffer) {
  buffer.writeln('# 🎙️ 실시간 AI 회의 및 강의 노트');
  buffer.writeln(
    '> **Gemini 3.8 Live**가 실시간 오디오를 청취하여 '
    '실시간 통번역 및 핵심 메모를 자동으로 구조화합니다.\n',
  );
  buffer.writeln('### 💡 안내');
  buffer.writeln(
    '- **녹음 시작** 버튼을 누르면 발표자의 발화가 실시간으로 분석됩니다.\n'
    '- 외국어 발화는 선택한 언어로 즉시 번역되며, 주요 논점과 액션 아이템이 자동 추출됩니다.\n',
  );
}
