import 'package:flutter/material.dart';

import '../pro_dj_console_i18n.dart';

/// Edit dialog for a deck's steerable prompt. Resolves to the trimmed new
/// prompt when APPLY is pressed, or null when cancelled / dismissed.
Future<String?> showEditPromptDialog(
  BuildContext context, {
  required bool isDeckA,
  required String initialText,
}) {
  final i18n = ProDjConsoleI18n.current;
  final controller = TextEditingController(text: initialText);

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        title: Text(
          i18n.editDeckPromptTitle(isDeckA),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: i18n.editPromptHint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF222838),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(i18n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim());
            },
            child: Text(i18n.applyButton),
          ),
        ],
      );
    },
  );
}
