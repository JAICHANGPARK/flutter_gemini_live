String summarizeTextForLog(String text) {
  final singleLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (singleLine.isEmpty) return '(empty)';
  if (singleLine.length <= 80) return singleLine;
  return '${singleLine.substring(0, 77)}...';
}
