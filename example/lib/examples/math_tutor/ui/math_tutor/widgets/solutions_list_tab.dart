import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

import '../math_tutor_i18n.dart';
import '../view_models/math_tutor_view_model.dart';
import 'math_markdown.dart';
import 'solution_card.dart';

/// "Solution Notes" tab: the in-progress solution followed by saved cards.
class SolutionsListTab extends StatelessWidget {
  const SolutionsListTab({
    super.key,
    required this.viewModel,
    required this.pulse,
    this.scrollController,
  });

  final MathTutorViewModel viewModel;
  final Animation<double> pulse;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = MathTutorI18n(lang);

    return ValueListenableBuilder<String>(
      valueListenable: vm.liveSolutionNotifier,
      builder: (context, liveSolutionText, _) {
        final hasLiveSolution = liveSolutionText.isNotEmpty;
        final hasHistory = vm.solutionHistory.isNotEmpty;

        if (!hasLiveSolution && !hasHistory) {
          return SingleChildScrollView(
            controller: scrollController ?? vm.solutionScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    i18n.emptyTitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n.emptyDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final totalCount =
            (hasLiveSolution ? 1 : 0) + vm.solutionHistory.length;

        return ListView.builder(
          controller: scrollController ?? vm.solutionScrollController,
          padding: const EdgeInsets.all(12),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (hasLiveSolution && index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amberAccent, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FadeTransition(
                          opacity: pulse,
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.amberAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            i18n.writingSolution,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MathMarkdown(liveSolutionText),
                  ],
                ),
              );
            }

            final historyIndex = hasLiveSolution ? index - 1 : index;
            final item = vm.solutionHistory[historyIndex];
            return SolutionCard(
              item: item,
              number: vm.solutionHistory.length - historyIndex,
              onCopied: vm.notifyCopied,
            );
          },
        );
      },
    );
  }
}
