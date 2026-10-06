import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

import '../math_tutor_i18n.dart';
import '../view_models/math_tutor_view_model.dart';

/// "Thinking Process" tab: live Extended Thinking scratchpad stream.
class ThinkingScratchpadTab extends StatelessWidget {
  const ThinkingScratchpadTab({
    super.key,
    required this.viewModel,
    this.scrollController,
  });

  final MathTutorViewModel viewModel;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = MathTutorI18n(lang);

    return SingleChildScrollView(
      controller: scrollController ?? vm.thoughtsScrollController,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_alt_rounded,
                color: Colors.cyanAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  i18n.thinkingScratchpadTitle,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: vm.thoughtsTokenNotifier,
                builder: (context, tokenCount, _) {
                  if (tokenCount <= 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade900.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent),
                    ),
                    child: Text(
                      '$tokenCount tokens',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            i18n.thinkingScratchpadDesc,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: vm.liveThoughtsNotifier,
              builder: (context, liveThoughts, _) {
                final displayThoughts = liveThoughts.isNotEmpty
                    ? liveThoughts
                    : (vm.solutionHistory.isNotEmpty &&
                              vm.solutionHistory.first.thinkingLog.isNotEmpty
                          ? vm.solutionHistory.first.thinkingLog
                          : i18n.thinkingScratchpadWaiting);
                return SelectableText(
                  displayThoughts,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    color: Colors.cyanAccent,
                    height: 1.5,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
