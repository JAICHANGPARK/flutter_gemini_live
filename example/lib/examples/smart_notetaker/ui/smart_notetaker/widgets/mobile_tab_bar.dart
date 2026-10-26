import 'package:flutter/material.dart';

import '../smart_notetaker_i18n.dart';
import '../view_models/smart_notetaker_view_model.dart';

/// Tab switcher shown on narrow (mobile) layouts.
class MobileTabBar extends StatelessWidget {
  const MobileTabBar({super.key, required this.viewModel});

  final SmartNotetakerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final i18n = SmartNotetakerI18n.current;
    return Container(
      width: double.infinity,
      color: const Color(0xFF131B2E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: 0,
              icon: const Icon(Icons.mic, size: 16),
              label: Text(i18n.liveSpeechTab(viewModel.speechTurns.length)),
            ),
            ButtonSegment(
              value: 1,
              icon: const Icon(Icons.description, size: 16),
              label: Text(i18n.smartNotesTab),
            ),
            ButtonSegment(
              value: 2,
              icon: const Icon(Icons.checklist_rtl, size: 16),
              label: Text(i18n.tasksTab(viewModel.actionItems.length)),
            ),
          ],
          selected: {viewModel.activeViewTab},
          onSelectionChanged: (set) {
            viewModel.activeViewTab = set.first;
          },
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
      ),
    );
  }
}
