import 'package:example/app_settings_dialog.dart';
import 'package:example/foldable_utils.dart';
import 'package:flutter/material.dart';

import 'view_models/smart_notetaker_view_model.dart';
import 'widgets/action_items_panel.dart';
import 'widgets/live_timeline_panel.dart';
import 'widgets/mobile_tab_bar.dart';
import 'widgets/session_status_bar.dart';
import 'widgets/smart_notes_board.dart';
import 'widgets/smart_notetaker_app_bar.dart';

/// Live Smart NoteTaker: real-time meeting / lecture transcription,
/// translation and structured note generation.
///
/// This is the view: it owns only UI-bound objects (the pulse animation),
/// builds the layout from [SmartNotetakerViewModel] state and shows snackbars
/// and dialogs on the view model's behalf.
class LiveSmartNotePage extends StatefulWidget {
  const LiveSmartNotePage({super.key});

  @override
  State<LiveSmartNotePage> createState() => _LiveSmartNotePageState();
}

class _LiveSmartNotePageState extends State<LiveSmartNotePage>
    with SingleTickerProviderStateMixin {
  late final SmartNotetakerViewModel _viewModel;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _viewModel = SmartNotetakerViewModel()
      ..onNotice = _showNotice
      ..requestApiKeySetup = _requestApiKeySetup;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _viewModel.init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> _requestApiKeySetup() {
    return AppSettingsDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        final foldableInfo = FoldableLayoutInfo.of(context);

        return Scaffold(
          backgroundColor: const Color(0xFF090D16),
          appBar: SmartNotetakerAppBar(
            viewModel: vm,
            foldableInfo: foldableInfo,
          ),
          body: Column(
            children: [
              SessionStatusBar(viewModel: vm, pulse: _pulseController),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Tabletop / Flex mode: Top half timeline, bottom half notes board
                    if (foldableInfo.isTabletop) {
                      return Column(
                        children: [
                          Expanded(
                            flex: 1,
                            child: LiveTimelinePanel(viewModel: vm),
                          ),
                          Container(
                            height: 3,
                            color: Colors.amberAccent.withValues(alpha: 0.6),
                          ),
                          Expanded(
                            flex: 1,
                            child: SmartNotesBoard(viewModel: vm),
                          ),
                        ],
                      );
                    }

                    // Dual-Screen (Book mode) or Foldable unfolded or Wide screen
                    final isTwoPane =
                        (foldableInfo.hasHinge && foldableInfo.isBookMode) ||
                        foldableInfo.isFoldableOrWide ||
                        constraints.maxWidth >= 780;

                    if (isTwoPane) {
                      return Row(
                        children: [
                          // Left: Live Speech Stream & Audio Waveform (40%)
                          Expanded(
                            flex: 4,
                            child: LiveTimelinePanel(viewModel: vm),
                          ),
                          if (foldableInfo.isDualScreen)
                            SizedBox(
                              width: (foldableInfo.hingeBounds?.width ?? 16)
                                  .clamp(8.0, 36.0),
                              child: Container(color: Colors.black),
                            )
                          else
                            const VerticalDivider(
                              color: Colors.white12,
                              width: 1,
                            ),
                          // Right: Smart Note Board & Markdown Canvas (60%)
                          Expanded(
                            flex: 6,
                            child: SmartNotesBoard(viewModel: vm),
                          ),
                        ],
                      );
                    }

                    // Mobile view with tab switcher
                    return Column(
                      children: [
                        MobileTabBar(viewModel: vm),
                        Expanded(
                          child: vm.activeViewTab == 0
                              ? LiveTimelinePanel(viewModel: vm)
                              : vm.activeViewTab == 1
                              ? SmartNotesBoard(viewModel: vm)
                              : ActionItemsPanel(viewModel: vm),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
