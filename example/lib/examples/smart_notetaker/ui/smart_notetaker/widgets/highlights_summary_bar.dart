import 'package:flutter/material.dart';

import '../view_models/smart_notetaker_view_model.dart';
import 'action_items_panel.dart';

/// Summary of detected key points / action items with a checklist shortcut.
class HighlightsSummaryBar extends StatelessWidget {
  const HighlightsSummaryBar({super.key, required this.viewModel});

  final SmartNotetakerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Colors.amberAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '핵심 요약 ${viewModel.keyTakeaways.length}건 · 액션 아이템 ${viewModel.actionItems.length}건 감지됨',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (viewModel.actionItems.isNotEmpty)
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: Colors.cyanAccent,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF131B2E),
                  builder: (_) => ActionItemsPanel(viewModel: viewModel),
                );
              },
              child: const Text('할 일 목록 보기 ➔', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
