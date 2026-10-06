import 'dart:math' as math;

import 'package:example/app_settings_dialog.dart';
import 'package:example/foldable_utils.dart';
import 'package:flutter/material.dart';

import '../../domain/dj_defaults.dart';
import 'view_models/dj_midi_box_notice.dart';
import 'view_models/dj_midi_box_view_model.dart';
import 'widgets/dj_bottom_controls.dart';
import 'widgets/dj_console_panel.dart';
import 'widgets/dj_knob_grid.dart';
import 'widgets/dj_midi_box_snack_bar.dart';
import 'widgets/dj_tabletop_orb.dart';
import 'widgets/dj_top_header.dart';

/// Interactive Prompt DJ MIDI Box inspired by Google AI Studio's Prompt DJ.
///
/// Features:
/// - 4x4 16-pad tactile rotary dial grid with neon halo rings and arc indicators
/// - Real-time continuous prompt steering via Google Gemini Lyria RealTime WebSocket
/// - Tactile touch interaction: drag to turn dials, tap to toggle on/off, long-press to edit prompt
/// - Audio reactive pulse syncing glowing rings to the live stream beat
/// - Responsive layout adapting smoothly to desktop web and mobile screens
class DjMidiBoxPage extends StatefulWidget {
  const DjMidiBoxPage({super.key});

  @override
  State<DjMidiBoxPage> createState() => _DjMidiBoxPageState();
}

class _DjMidiBoxPageState extends State<DjMidiBoxPage>
    with SingleTickerProviderStateMixin {
  late final DjMidiBoxViewModel _viewModel;
  final TextEditingController _customPromptController = TextEditingController(
    text: djDefaultCustomPrompt,
  );
  final ScrollController _logScrollController = ScrollController();
  late final AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _viewModel =
        DjMidiBoxViewModel(customPromptController: _customPromptController)
          ..onNotice = _showNotice
          ..requestApiKeySetup = _requestApiKeySetup
          ..onLogAppended = _scrollLogsToEnd;
    _viewModel.init();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _viewModel.cancelKnobDebounce();
    _customPromptController.dispose();
    _logScrollController.dispose();
    _pulseAnim.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showNotice(DjMidiBoxNotice notice) {
    if (!mounted) return;
    showDjMidiBoxSnackBar(context, notice);
  }

  Future<bool?> _requestApiKeySetup() {
    return AppSettingsDialog.show(context);
  }

  void _scrollLogsToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.jumpTo(
          _logScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  // ==========================================================================
  // Build UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Rich cosmic dark purple gradient matching reference design
          gradient: RadialGradient(
            center: Alignment(0.4, -0.2),
            radius: 1.3,
            colors: [
              Color(0xFF381566), // Glowing cosmic violet
              Color(0xFF210E40), // Mid purple
              Color(0xFF110724), // Dark deep purple
              Color(0xFF090414), // Near black purple
            ],
            stops: [0.0, 0.45, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => LayoutBuilder(
              builder: (context, constraints) {
                final vm = _viewModel;
                final width = constraints.maxWidth;
                final foldableInfo = FoldableLayoutInfo.of(context);

                Widget header() => DjTopHeader(
                  viewModel: vm,
                  logScrollController: _logScrollController,
                );
                Widget grid({
                  required List<int> knobIndices,
                  required int crossAxisCount,
                  double maxWidth = 680,
                }) => DjKnobGrid(
                  viewModel: vm,
                  knobIndices: knobIndices,
                  crossAxisCount: crossAxisCount,
                  maxWidth: maxWidth,
                );
                Widget bottomControls() => DjBottomControls(viewModel: vm);

                // 1. Tabletop / Flex Mode (Foldable device half-opened on a table)
                if (foldableInfo.isTabletop) {
                  return Column(
                    children: [
                      // Upright Top Screen: Header + Glowing Audio Reactive Visualizer
                      header(),
                      Expanded(
                        flex: 4,
                        child: DjTabletopOrb(viewModel: vm, pulse: _pulseAnim),
                      ),

                      // Physical Hinge Crease
                      Container(height: 4, color: Colors.white10),

                      // Flat Bottom Screen: 4x4 Grid + Bottom Transport Controls
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              grid(
                                knobIndices: List.generate(
                                  vm.knobs.length,
                                  (i) => i,
                                ),
                                crossAxisCount: 4,
                                maxWidth: 680,
                              ),
                              bottomControls(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // 2. Dual-Screen Book Mode (Surface Duo / 2 physical screens)
                if (foldableInfo.hasHinge && foldableInfo.isBookMode) {
                  return Column(
                    children: [
                      header(),
                      Expanded(
                        child: Row(
                          children: [
                            // Left Screen: Pads 1-8
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(top: 8),
                                child: grid(
                                  knobIndices: List.generate(8, (i) => i),
                                  crossAxisCount: 2,
                                  maxWidth: 360,
                                ),
                              ),
                            ),

                            // Hinge Spine Spacer
                            SizedBox(
                              width: (foldableInfo.hingeBounds?.width ?? 16)
                                  .clamp(8.0, 36.0),
                              child: Center(
                                child: Container(
                                  width: 2,
                                  color: Colors.white24,
                                ),
                              ),
                            ),

                            // Right Screen: Pads 9-16 + Controls
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  children: [
                                    grid(
                                      knobIndices: List.generate(
                                        8,
                                        (i) => i + 8,
                                      ),
                                      crossAxisCount: 2,
                                      maxWidth: 360,
                                    ),
                                    bottomControls(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // 3. Desktop / Wide Screen Split View Layout
                if (width >= 860) {
                  final leftPanelWidth = math
                      .min(width * 0.35, 420.0)
                      .clamp(320.0, 420.0);
                  return Row(
                    children: [
                      if (vm.showSidePanel)
                        SizedBox(
                          width: leftPanelWidth,
                          child: DjConsolePanel(
                            viewModel: vm,
                            logScrollController: _logScrollController,
                          ),
                        ),
                      if (vm.showSidePanel)
                        Container(width: 1.5, color: Colors.white12),
                      Expanded(
                        child: Column(
                          children: [
                            header(),
                            Expanded(
                              child: Center(
                                child: grid(
                                  knobIndices: List.generate(
                                    vm.knobs.length,
                                    (i) => i,
                                  ),
                                  crossAxisCount: 4,
                                  maxWidth: 680,
                                ),
                              ),
                            ),
                            bottomControls(),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // 4. Standard Compact & Mobile Layout
                final crossAxisCount = width < 420 ? 2 : (width < 600 ? 3 : 4);

                return Column(
                  children: [
                    header(),
                    Expanded(
                      child: Center(
                        child: grid(
                          knobIndices: List.generate(vm.knobs.length, (i) => i),
                          crossAxisCount: crossAxisCount,
                          maxWidth: 680,
                        ),
                      ),
                    ),
                    bottomControls(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
