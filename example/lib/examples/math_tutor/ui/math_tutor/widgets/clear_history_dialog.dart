import 'package:flutter/material.dart';

import '../math_tutor_i18n.dart';

/// Asks the user to confirm wiping the solution history. Resolves `true` if
/// they confirmed.
Future<bool?> showClearHistoryDialog(BuildContext context, MathTutorI18n i18n) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text(
        i18n.clearHistoryTitle,
        style: const TextStyle(color: Colors.white),
      ),
      content: Text(
        i18n.clearHistoryConfirm,
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(i18n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(i18n.delete),
        ),
      ],
    ),
  );
}
