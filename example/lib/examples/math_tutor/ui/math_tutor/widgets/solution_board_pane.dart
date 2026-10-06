import 'package:flutter/material.dart';

import '../view_models/math_tutor_view_model.dart';
import 'board_tab_header.dart';
import 'solutions_list_tab.dart';
import 'thinking_scratchpad_tab.dart';
import 'transcript_log_tab.dart';

/// The notes board: optional drag handle, tab header and the active tab body.
/// Used as a side pane on wide layouts and inside the bottom sheet on phones.
class SolutionBoardPane extends StatelessWidget {
  const SolutionBoardPane({
    super.key,
    required this.viewModel,
    required this.pulse,
    required this.onClearHistory,
    this.scrollController,
    this.showDragHandle = false,
    this.onCloseSheet,
  });

  final MathTutorViewModel viewModel;
  final Animation<double> pulse;
  final VoidCallback onClearHistory;
  final ScrollController? scrollController;
  final bool showDragHandle;
  final VoidCallback? onCloseSheet;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Drag handle for bottom sheet mode
          if (showDragHandle)
            Container(
              width: double.infinity,
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

          // Tab Header (해설 노트 vs 실시간 대화 로그 vs AI 심층 생각 노트)
          BoardTabHeader(
            viewModel: viewModel,
            onClearHistory: onClearHistory,
            onCloseSheet: onCloseSheet,
          ),

          // Tab Content
          Expanded(
            child: switch (viewModel.activeTabIndex) {
              0 => SolutionsListTab(
                viewModel: viewModel,
                pulse: pulse,
                scrollController: scrollController,
              ),
              1 => TranscriptLogTab(
                viewModel: viewModel,
                scrollController: scrollController,
              ),
              _ => ThinkingScratchpadTab(
                viewModel: viewModel,
                scrollController: scrollController,
              ),
            },
          ),
        ],
      ),
    );
  }
}
