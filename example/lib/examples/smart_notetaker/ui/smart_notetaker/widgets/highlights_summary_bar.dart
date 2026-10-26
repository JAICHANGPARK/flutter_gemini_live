import 'package:flutter/material.dart';

import '../smart_notetaker_i18n.dart';
import '../view_models/smart_notetaker_view_model.dart';
import 'action_items_panel.dart';

/// Summary of detected key points / action items with a checklist shortcut.
class HighlightsSummaryBar extends StatelessWidget {
  const HighlightsSummaryBar({super.key, required this.viewModel});

  final SmartNotetakerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final i18n = SmartNotetakerI18n.current;
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
          Expanded(
            child: Text(
              i18n.highlightsSummary(
                viewModel.keyTakeaways.length,
                viewModel.actionItems.length,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (viewModel.actionItems.isNotEmpty) ...[
            const SizedBox(width: 8),
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
              child: Text(
                i18n.viewTasksButton,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
