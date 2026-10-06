import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

import '../math_tutor_i18n.dart';
import '../view_models/math_tutor_view_model.dart';

/// The three-tab header (notes / dialog log / thinking) with the clear-history
/// and hide-sheet actions.
class BoardTabHeader extends StatelessWidget {
  const BoardTabHeader({
    super.key,
    required this.viewModel,
    required this.onClearHistory,
    this.onCloseSheet,
  });

  final MathTutorViewModel viewModel;
  final VoidCallback onClearHistory;
  final VoidCallback? onCloseSheet;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final i18n = MathTutorI18n(AppLanguageController.instance.currentLanguage);
    final activeTabIndex = vm.activeTabIndex;

    return Container(
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          // Tab 0: Solution Notes
          Expanded(
            child: InkWell(
              onTap: () => vm.activeTabIndex = 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 2,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: activeTabIndex == 0
                          ? Colors.amberAccent
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_rounded,
                      size: 15,
                      color: activeTabIndex == 0
                          ? Colors.amberAccent
                          : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${i18n.tabSolutions} (${vm.solutionHistory.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: activeTabIndex == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: activeTabIndex == 0
                              ? Colors.amberAccent
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab 1: Live Dialog & Transcript Log
          Expanded(
            child: InkWell(
              onTap: () => vm.activeTabIndex = 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 2,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: activeTabIndex == 1
                          ? Colors.greenAccent
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum_rounded,
                      size: 15,
                      color: activeTabIndex == 1
                          ? Colors.greenAccent
                          : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: ValueListenableBuilder<int>(
                        valueListenable: vm.transcriptUpdateNotifier,
                        builder: (context, _, _) {
                          return Text(
                            '${i18n.tabTranscript} (${vm.transcriptEntries.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: activeTabIndex == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: activeTabIndex == 1
                                  ? Colors.greenAccent
                                  : Colors.white70,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab 2: AI Extended Thinking Process
          Expanded(
            child: InkWell(
              onTap: () => vm.activeTabIndex = 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 2,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: activeTabIndex == 2
                          ? Colors.cyanAccent
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_rounded,
                      size: 15,
                      color: activeTabIndex == 2
                          ? Colors.cyanAccent
                          : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        i18n.tabThinking,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: activeTabIndex == 2
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: activeTabIndex == 2
                              ? Colors.cyanAccent
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (vm.solutionHistory.isNotEmpty)
            IconButton(
              iconSize: 18,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.white54,
              ),
              tooltip: i18n.clearHistoryTitle,
              onPressed: onClearHistory,
            ),
          if (onCloseSheet != null)
            IconButton(
              iconSize: 20,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white70,
              ),
              tooltip: i18n.btnHideSheet,
              onPressed: onCloseSheet,
            ),
        ],
      ),
    );
  }
}
