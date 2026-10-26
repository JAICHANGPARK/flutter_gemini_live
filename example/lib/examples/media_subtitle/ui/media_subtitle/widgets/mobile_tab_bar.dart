import 'package:flutter/material.dart';

import '../media_subtitle_i18n.dart';
import '../view_models/media_subtitle_view_model.dart';

/// Compact-layout tab switcher (video & controls / subtitle timeline).
class MobileTabBar extends StatelessWidget {
  const MobileTabBar({super.key, required this.viewModel});

  final MediaSubtitleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final i18n = MediaSubtitleI18n.current;
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ValueListenableBuilder<int>(
        valueListenable: vm.subtitleRevision,
        builder: (context, _, _) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: const Icon(Icons.smart_display_rounded, size: 15),
                  label: Text(i18n.videoAndControlsTab),
                ),
                ButtonSegment(
                  value: 1,
                  icon: const Icon(Icons.subtitles_rounded, size: 15),
                  label: Text(
                    i18n.subtitleTimelineTab(vm.subtitleHistory.length),
                  ),
                ),
              ],
              selected: {vm.activeViewTab},
              onSelectionChanged: (set) {
                vm.activeViewTab = set.first;
              },
            ),
          );
        },
      ),
    );
  }
}
