import 'package:flutter/material.dart';

import '../view_models/media_subtitle_view_model.dart';
import 'live_control_bar.dart';
import 'play_quick_bar.dart';
import 'presets_row.dart';
import 'url_bar.dart';
import 'video_player_with_hud.dart';

/// URL bar, presets, video player, play bar and live controls in a scroller.
class VideoAndPlayerSection extends StatelessWidget {
  const VideoAndPlayerSection({
    super.key,
    required this.viewModel,
    required this.urlController,
    required this.pulse,
  });

  final MediaSubtitleViewModel viewModel;
  final TextEditingController urlController;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UrlBar(controller: urlController, onLoad: vm.loadVideoFromInput),
          const SizedBox(height: 12),
          PresetsRow(
            currentVideoId: vm.currentVideoId,
            onSelect: vm.selectPreset,
          ),
          const SizedBox(height: 16),
          VideoPlayerWithHud(viewModel: vm, pulse: pulse),
          const SizedBox(height: 12),
          PlayQuickBar(onPlay: vm.playVideo),
          const SizedBox(height: 16),
          LiveControlBar(viewModel: vm),
        ],
      ),
    );
  }
}
