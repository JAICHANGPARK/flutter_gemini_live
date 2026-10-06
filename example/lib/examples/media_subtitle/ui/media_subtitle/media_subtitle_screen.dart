import 'package:example/app_settings_dialog.dart';
import 'package:example/foldable_utils.dart';
import 'package:flutter/material.dart';

import 'view_models/media_subtitle_notice.dart';
import 'view_models/media_subtitle_view_model.dart';
import 'widgets/live_control_bar.dart';
import 'widgets/media_subtitle_app_bar.dart';
import 'widgets/media_subtitle_snack_bar.dart';
import 'widgets/mobile_tab_bar.dart';
import 'widgets/play_quick_bar.dart';
import 'widgets/transcript_panel.dart';
import 'widgets/video_and_player_section.dart';
import 'widgets/video_player_with_hud.dart';

/// Live Media Subtitles: translates the audio of a YouTube video (captured via
/// a system audio input such as BlackHole) into real-time subtitles.
///
/// This is the view: it owns only UI-bound objects (animation, text and scroll
/// controllers), builds the layout from [MediaSubtitleViewModel] state and
/// shows snackbars / dialogs on the view model's behalf.
class LiveMediaSubtitlePage extends StatefulWidget {
  const LiveMediaSubtitlePage({super.key});

  @override
  State<LiveMediaSubtitlePage> createState() => _LiveMediaSubtitlePageState();
}

class _LiveMediaSubtitlePageState extends State<LiveMediaSubtitlePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();
  late final MediaSubtitleViewModel _viewModel;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _viewModel = MediaSubtitleViewModel()
      ..onNotice = _showNotice
      ..requestApiKeySetup = _requestApiKeySetup
      ..onScrollToEnd = _scrollToEnd
      ..getUrlText = (() => _urlController.text)
      ..setUrlText = ((text) => _urlController.text = text);

    _urlController.text = _viewModel.initialUrlText;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _viewModel.init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _viewModel.dispose();
    _urlController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _showNotice(MediaSubtitleNotice notice) {
    if (!mounted) return;
    showMediaSubtitleSnackBar(context, notice);
  }

  Future<bool?> _requestApiKeySetup() {
    return AppSettingsDialog.show(context);
  }

  void _scrollToEnd(Duration duration) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: duration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final foldableInfo = FoldableLayoutInfo.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;

        Widget videoAndPlayerSection() => VideoAndPlayerSection(
          viewModel: vm,
          urlController: _urlController,
          pulse: _pulseController,
        );

        Widget transcriptPanel() => TranscriptPanel(
          viewModel: vm,
          scrollController: _logScrollController,
        );

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: MediaSubtitleAppBar(
            viewModel: vm,
            foldableInfo: foldableInfo,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Tabletop / Flex mode: Top screen video player, bottom screen controls & transcript
              if (foldableInfo.isTabletop) {
                return Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            VideoPlayerWithHud(
                              viewModel: vm,
                              pulse: _pulseController,
                            ),
                            const SizedBox(height: 8),
                            PlayQuickBar(onPlay: vm.playVideo),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 3,
                      color: Colors.cyanAccent.withValues(alpha: 0.6),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: LiveControlBar(viewModel: vm),
                          ),
                          Expanded(child: transcriptPanel()),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Dual-Screen (Book mode) or Foldable unfolded or Wide screen
              final isTwoPane =
                  (foldableInfo.hasHinge && foldableInfo.isBookMode) ||
                  foldableInfo.isFoldableOrWide ||
                  constraints.maxWidth >= 800;

              if (isTwoPane) {
                return Row(
                  children: [
                    Expanded(flex: 6, child: videoAndPlayerSection()),
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
                    Expanded(flex: 4, child: transcriptPanel()),
                  ],
                );
              }
              // Mobile/Compact view with tab switcher to prevent vertical overflows
              return Column(
                children: [
                  MobileTabBar(viewModel: vm),
                  Expanded(
                    child: vm.activeViewTab == 0
                        ? videoAndPlayerSection()
                        : transcriptPanel(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
