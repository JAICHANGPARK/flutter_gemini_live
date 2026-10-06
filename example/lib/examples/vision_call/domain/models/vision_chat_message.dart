class VisionChatMessage {
  VisionChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
  });

  final bool isUser;
  final String text;
  final DateTime timestamp;
}
