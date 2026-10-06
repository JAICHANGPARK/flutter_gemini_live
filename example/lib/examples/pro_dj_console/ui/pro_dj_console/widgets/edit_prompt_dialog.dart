import 'package:flutter/material.dart';

/// Edit dialog for a deck's steerable prompt. Resolves to the trimmed new
/// prompt when APPLY is pressed, or null when cancelled / dismissed.
Future<String?> showEditPromptDialog(
  BuildContext context, {
  required bool isDeckA,
  required String initialText,
}) {
  final controller = TextEditingController(text: initialText);

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        title: Text(
          isDeckA ? 'Edit Deck 1 (A) Prompt' : 'Edit Deck 2 (B) Prompt',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter musical style, instruments, or vibe...',
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Color(0xFF222838),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('APPLY'),
          ),
        ],
      );
    },
  );
}
