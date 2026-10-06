import 'package:flutter/material.dart';

import '../view_models/smart_notetaker_view_model.dart';

/// Tab switcher shown on narrow (mobile) layouts.
class MobileTabBar extends StatelessWidget {
  const MobileTabBar({super.key, required this.viewModel});

  final SmartNotetakerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF131B2E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<int>(
        segments: [
          ButtonSegment(
            value: 0,
            icon: const Icon(Icons.mic, size: 16),
            label: Text('실시간 발화 (${viewModel.speechTurns.length})'),
          ),
          const ButtonSegment(
            value: 1,
            icon: Icon(Icons.description, size: 16),
            label: Text('스마트 노트'),
          ),
          ButtonSegment(
            value: 2,
            icon: const Icon(Icons.checklist_rtl, size: 16),
            label: Text('할일 (${viewModel.actionItems.length})'),
          ),
        ],
        selected: {viewModel.activeViewTab},
        onSelectionChanged: (set) {
          viewModel.activeViewTab = set.first;
        },
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    );
  }
}
