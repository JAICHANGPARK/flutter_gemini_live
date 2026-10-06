/// Fields extracted from a model solution markdown.
class ParsedSolution {
  final String problemLevel;
  final String examinerIntent;
  final String finalAnswer;
  final String summary;

  const ParsedSolution({
    required this.problemLevel,
    required this.examinerIntent,
    required this.finalAnswer,
    required this.summary,
  });
}

/// Pure functions that pull structured sections out of the tutor's markdown.
class SolutionParser {
  const SolutionParser._();

  static ParsedSolution parse(String solution) {
    // Extract problem level if present (supports Korean & English headers, with or without emojis)
    String problemLevel = '';
    final levelMatch = RegExp(
      r'###\s*(?:📊\s*)?\[?(?:(?:과목\s*(?:및|&)\s*)?문제\s*수준|Subject(?:\s*(?:및|&)\s*Problem)?\s*Level|교과목|Subject)(?:\s*(?:및|&)\s*(?:난이도|Difficulty))?\]?\s*\n+([^#]+)',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(solution);
    if (levelMatch != null && levelMatch.groupCount >= 1) {
      problemLevel = levelMatch.group(1)?.trim() ?? '';
    }

    // Extract examiner intent if present
    String examinerIntent = '';
    final intentMatch = RegExp(
      r'###\s*(?:🎯\s*)?\[?(?:출제자의?\s*의도(?:\s*(?:및|&)\s*평가\s*요소)?|Examiner(?:\x27s)?\s*Intent(?:\s*&\s*Assessment\s*Objective)?)\]?\s*\n+([^#]+)',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(solution);
    if (intentMatch != null && intentMatch.groupCount >= 1) {
      examinerIntent = intentMatch.group(1)?.trim() ?? '';
    }

    // Extract final answer if present (e.g. "정답: ...", "Answer: ...")
    String finalAnswer = '';
    final answerMatch = RegExp(
      r'(?:정답|Answer)\s*:\s*([^\n\r]+)',
      caseSensitive: false,
    ).firstMatch(solution);
    if (answerMatch != null && answerMatch.groupCount >= 1) {
      finalAnswer =
          answerMatch
              .group(1)
              ?.replaceAll('*', '')
              .replaceAll('>', '')
              .trim() ??
          '';
    } else {
      // Fallback: spoken form, e.g. "정답은 3번입니다" / "the answer is 42"
      final spokenMatch = RegExp(
        r'(?:정답은|최종\s*정답은|답은)\s*([^\n.。!?]{1,40}?)\s*(?:입니다|이에요|예요|이야|입니다만|[.。!?\n]|$)|(?:the\s+(?:final\s+)?answer\s+is)\s+([^\n.!?]{1,40})',
        caseSensitive: false,
      ).firstMatch(solution);
      if (spokenMatch != null) {
        finalAnswer = (spokenMatch.group(1) ?? spokenMatch.group(2) ?? '')
            .replaceAll('*', '')
            .trim();
      }
      // Fallback: look for 🏁 or 🎯 block
      final blockMatch = RegExp(
        r'[🏁🎯]\s*\[?(?:최종\s*정답|Final\s*Answer)\]?[^\n]*\n+>?\s*([^\n\r]+)',
        caseSensitive: false,
      ).firstMatch(solution);
      if (blockMatch != null && blockMatch.groupCount >= 1) {
        finalAnswer =
            blockMatch
                .group(1)
                ?.replaceAll('*', '')
                .replaceAll('>', '')
                .trim() ??
            '';
      }
    }

    return ParsedSolution(
      problemLevel: problemLevel,
      examinerIntent: examinerIntent,
      finalAnswer: finalAnswer,
      summary: extractSummary(solution),
    );
  }

  static String extractSummary(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    for (final line in lines) {
      if (!line.startsWith('#') && !line.startsWith('>')) {
        return line.trim().length > 60
            ? '${line.trim().substring(0, 60)}...'
            : line.trim();
      }
    }
    return '시험 문제 풀이 및 심층 해설';
  }
}
