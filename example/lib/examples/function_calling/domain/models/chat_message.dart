class ChatMessage {
  final String author;
  final String text;
  final DateTime timestamp;
  final bool isSystem;

  ChatMessage({
    required this.author,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });
}
