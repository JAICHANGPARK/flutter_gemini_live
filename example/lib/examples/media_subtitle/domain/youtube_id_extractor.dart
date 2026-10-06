String extractYouTubeId(String input) {
  final trimmed = input.trim();
  if (trimmed.length == 11 && !trimmed.contains('/')) {
    return trimmed;
  }
  // Match watch?v=ID or youtu.be/ID or embed/ID
  final regExp = RegExp(
    r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
  );
  final match = regExp.firstMatch(trimmed);
  return match?.group(1) ?? trimmed;
}
