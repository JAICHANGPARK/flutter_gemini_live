class LiveTranslationMessage {
  final bool isUser;
  final String text;
  final String? languageCode;
  final DateTime timestamp;

  LiveTranslationMessage({
    required this.isUser,
    required this.text,
    this.languageCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
