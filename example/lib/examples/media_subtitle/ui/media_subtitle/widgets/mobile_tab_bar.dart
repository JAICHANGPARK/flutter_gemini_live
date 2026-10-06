import 'package:flutter/material.dart';

import '../view_models/media_subtitle_view_model.dart';

/// Compact-layout tab switcher (video & controls / subtitle timeline).
class MobileTabBar extends StatelessWidget {
  const MobileTabBar({super.key, required this.viewModel});

  final MediaSubtitleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ValueListenableBuilder<int>(
        valueListenable: vm.subtitleRevision,
        builder: (context, _, _) {
          return SegmentedButton<int>(
            segments: [
              const ButtonSegment(
                value: 0,
                icon: Icon(Icons.smart_display_rounded, size: 16),
                label: Text('영상 & 컨트롤'),
              ),
              ButtonSegment(
                value: 1,
                icon: const Icon(Icons.subtitles_rounded, size: 16),
                label: Text('자막 타임라인 (${vm.subtitleHistory.length})'),
              ),
            ],
            selected: {vm.activeViewTab},
            onSelectionChanged: (set) {
              vm.activeViewTab = set.first;
            },
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          );
        },
      ),
    );
  }
}
