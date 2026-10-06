import 'package:example/app_settings_dialog.dart';
import 'package:example/foldable_utils.dart';
import 'package:flutter/material.dart';

import 'view_models/music_studio_notice.dart';
import 'view_models/music_studio_view_model.dart';
import 'widgets/connection_card.dart';
import 'widgets/diagnostics_panel.dart';
import 'widgets/generation_config_section.dart';
import 'widgets/music_studio_app_bar.dart';
import 'widgets/prompts_section.dart';
import 'widgets/transport_controls.dart';
import 'widgets/visualizer_card.dart';

/// Interactive Real-time Music Studio powered by Google's Lyria Live models.
///
/// Demonstrates:
/// - Real-time bidirectional WebSocket music streaming (`BidiGenerateMusic`)
/// - Dynamic prompt steering via [WeightedPrompt]
/// - Real-time generation parameters ([LiveMusicGenerationConfig]: BPM, Scale, Density, Brightness, Mute Bass/Drums)
/// - Playback transport control: Play, Pause, Stop, Reset Context
/// - Real-time low-latency linear PCM playback & audio visualization
///
/// This is the view: it owns only the visualizer [AnimationController] and
/// builds the layout from [MusicStudioViewModel] state.
class LiveMusicStudioPage extends StatefulWidget {
  const LiveMusicStudioPage({super.key});

  @override
  State<LiveMusicStudioPage> createState() => _LiveMusicStudioPageState();
}

class _LiveMusicStudioPageState extends State<LiveMusicStudioPage>
    with SingleTickerProviderStateMixin {
  late final MusicStudioViewModel _viewModel;
  late final AnimationController _visualizerAnim;

  @override
  void initState() {
    super.initState();
    _viewModel = MusicStudioViewModel()
      ..onNotice = _showNotice
      ..requestApiKeySetup = _requestApiKeySetup
      ..onVisualizerStart = (() => _visualizerAnim.repeat(reverse: true))
      ..onVisualizerStop = (() => _visualizerAnim.stop());
    _viewModel.init();

    _visualizerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_viewModel.tickVisualizer);

    // Initial default prompts from official Google Prompt DJ guide
    _viewModel.addInitialPrompts();
  }

  @override
  void dispose() {
    _visualizerAnim.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showNotice(MusicStudioNotice notice) {
    ScaffoldMessenger.of(context).showSnackBar(
      notice.duration == null
          ? SnackBar(content: Text(notice.message))
          : SnackBar(
              content: Text(notice.message),
              duration: notice.duration!,
            ),
    );
  }

  Future<bool?> _requestApiKeySetup() {
    return AppSettingsDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final darkSurface = const Color(0xFF13151A);
    final foldableInfo = FoldableLayoutInfo.of(context);

    return Scaffold(
      backgroundColor: darkSurface,
      appBar: MusicStudioAppBar(foldableInfo: foldableInfo),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final vm = _viewModel;
            // 1. Tabletop / Flex mode (Foldable resting on flat surface)
            // Top Screen (Upright): Connection Card & Realtime Visualizer HUD
            // Bottom Screen (Flat): Transport Controls, Steerable Prompts, Config, Diagnostics
            if (foldableInfo.isTabletop) {
              return Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        ConnectionCard(viewModel: vm),
                        const SizedBox(height: 12),
                        VisualizerCard(viewModel: vm),
                      ],
                    ),
                  ),
                  Container(
                    height: 3,
                    color: Colors.purpleAccent.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    flex: 1,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        TransportControls(viewModel: vm),
                        const SizedBox(height: 12),
                        PromptsSection(viewModel: vm),
                        const SizedBox(height: 12),
                        GenerationConfigSection(viewModel: vm),
                        const SizedBox(height: 12),
                        DiagnosticsPanel(viewModel: vm),
                      ],
                    ),
                  ),
                ],
              );
            }

            // 2. Dual-Screen Book Mode (Surface Duo) or Foldable Unfolded or Wide Screen
            final isTwoPane =
                (foldableInfo.hasHinge && foldableInfo.isBookMode) ||
                foldableInfo.isFoldableOrWide ||
                constraints.maxWidth >= 850;

            if (isTwoPane) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left pane: Monitor, Visualizer, Transport, Diagnostics
                  Expanded(
                    flex: 5,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ConnectionCard(viewModel: vm),
                        const SizedBox(height: 16),
                        VisualizerCard(viewModel: vm),
                        const SizedBox(height: 16),
                        TransportControls(viewModel: vm),
                        const SizedBox(height: 16),
                        DiagnosticsPanel(viewModel: vm),
                      ],
                    ),
                  ),
                  if (foldableInfo.isDualScreen)
                    SizedBox(
                      width: (foldableInfo.hingeBounds?.width ?? 16).clamp(
                        8.0,
                        36.0,
                      ),
                      child: Container(color: Colors.black),
                    )
                  else
                    const VerticalDivider(color: Colors.white12, width: 1),
                  // Right pane: Prompts & Music Config
                  Expanded(
                    flex: 5,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        PromptsSection(viewModel: vm),
                        const SizedBox(height: 16),
                        GenerationConfigSection(viewModel: vm),
                      ],
                    ),
                  ),
                ],
              );
            }

            // 3. Default single-screen mobile portrait
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ConnectionCard(viewModel: vm),
                const SizedBox(height: 16),
                VisualizerCard(viewModel: vm),
                const SizedBox(height: 16),
                TransportControls(viewModel: vm),
                const SizedBox(height: 16),
                PromptsSection(viewModel: vm),
                const SizedBox(height: 16),
                GenerationConfigSection(viewModel: vm),
                const SizedBox(height: 16),
                DiagnosticsPanel(viewModel: vm),
              ],
            );
          },
        ),
      ),
    );
  }
}
