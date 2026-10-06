import 'package:flutter/material.dart';

import '../../../domain/models/default_system_instruction.dart';
import '../math_tutor_i18n.dart';

/// Lets the user edit the system prompt. Resolves with the edited text when
/// saved, or `null` when cancelled.
Future<String?> showSystemInstructionDialog(
  BuildContext context, {
  required MathTutorI18n i18n,
  required String initialText,
}) async {
  final textController = TextEditingController(text: initialText);

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Row(
        children: [
          const Icon(Icons.tune_rounded, color: Colors.amberAccent, size: 22),
          const SizedBox(width: 8),
          Text(
            i18n.systemInstructionTitle,
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                i18n.systemInstructionDesc,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: textController,
                  maxLines: 15,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                    hintText: 'System instruction text in English...',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            textController.text = defaultMathTutorSystemInstruction;
          },
          child: const Text(
            '기본값 복원',
            style: TextStyle(color: Colors.amberAccent),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소', style: TextStyle(color: Colors.white60)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade700),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('저장 및 적용'),
        ),
      ],
    ),
  );

  // The controller is intentionally not disposed here: the TextField is still
  // mounted during the dialog's exit animation.
  return saved == true ? textController.text : null;
}
