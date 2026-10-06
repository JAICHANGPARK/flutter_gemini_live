import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../math_tutor_i18n.dart';
import '../view_models/math_tutor_view_model.dart';

/// App-bar pill showing "thinking" vs "idle" plus the thoughts token count.
class ThinkingStatusPill extends StatelessWidget {
  const ThinkingStatusPill({
    super.key,
    required this.viewModel,
    required this.pulse,
    required this.i18n,
  });

  final MathTutorViewModel viewModel;
  final Animation<double> pulse;
  final MathTutorI18n i18n;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InteractionStatus>(
      valueListenable: viewModel.interactionStatusNotifier,
      builder: (context, status, _) {
        final isThinking = status == InteractionStatus.IN_PROGRESS;

        return ValueListenableBuilder<int>(
          valueListenable: viewModel.thoughtsTokenNotifier,
          builder: (context, tokenCount, _) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isThinking
                    ? Colors.amber.shade900.withValues(alpha: 0.8)
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isThinking ? Colors.amberAccent : Colors.white24,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isThinking)
                    FadeTransition(
                      opacity: pulse,
                      child: const Icon(
                        Icons.psychology_rounded,
                        size: 15,
                        color: Colors.amberAccent,
                      ),
                    )
                  else
                    const Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: Colors.greenAccent,
                    ),
                  const SizedBox(width: 5),
                  Text(
                    isThinking ? i18n.statusThinking : i18n.statusIdle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isThinking ? Colors.amberAccent : Colors.white70,
                    ),
                  ),
                  if (tokenCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '($tokenCount tok)',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
