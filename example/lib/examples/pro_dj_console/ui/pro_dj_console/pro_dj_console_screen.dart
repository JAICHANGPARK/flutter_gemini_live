import 'package:example/app_settings_dialog.dart';
import 'package:example/foldable_utils.dart';
import 'package:flutter/material.dart';

import 'view_models/pro_dj_console_notice.dart';
import 'view_models/pro_dj_console_view_model.dart';
import 'widgets/cdj_deck.dart';
import 'widgets/console_logs.dart';
import 'widgets/djm_center_mixer.dart';
import 'widgets/edit_prompt_dialog.dart';
import 'widgets/master_lcd_display.dart';
import 'widgets/master_transport_bar.dart';
import 'widgets/performance_pads_section.dart';
import 'widgets/pro_dj_console_app_bar.dart';

/// Professional DJ Console for Google Gemini Live (Lyria RealTime)
/// streaming music generation.
///
/// This is the view: it owns only UI-bound objects (the jog wheel
/// animation controller), builds the layouts from [ProDjConsoleViewModel]
/// state and shows dialogs and snackbars on the view model's behalf.
class ProDjConsolePage extends StatefulWidget {
  const ProDjConsolePage({super.key});

  @override
  State<ProDjConsolePage> createState() => _ProDjConsolePageState();
}

class _ProDjConsolePageState extends State<ProDjConsolePage>
    with TickerProviderStateMixin {
  late final ProDjConsoleViewModel _viewModel;
  late final AnimationController _jogAnimController;

  @override
  void initState() {
    super.initState();
    _viewModel = ProDjConsoleViewModel()
      ..onNotice = _showNotice
      ..requestApiKeySetup = _requestApiKeySetup
      ..startJog = (() => _jogAnimController.repeat())
      ..stopJog = (() => _jogAnimController.stop())
      ..disposeJog = (() => _jogAnimController.dispose());

    _jogAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showNotice(ProDjConsoleNotice notice) {
    switch (notice.kind) {
      case ProDjConsoleNoticeKind.connected:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notice.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      case ProDjConsoleNoticeKind.hardDrop:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notice.message),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 1),
          ),
        );
      case ProDjConsoleNoticeKind.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notice.message), backgroundColor: Colors.red),
        );
    }
  }

  Future<bool?> _requestApiKeySetup() {
    return AppSettingsDialog.show(context);
  }

  Future<void> _editPrompt(bool isDeckA) async {
    final text = await showEditPromptDialog(
      context,
      isDeckA: isDeckA,
      initialText: isDeckA ? _viewModel.deckAPrompt : _viewModel.deckBPrompt,
    );
    if (text != null) {
      _viewModel.setDeckPrompt(isDeckA, text);
    }
  }

  // ==========================================================================
  // Build UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        return Scaffold(
          backgroundColor: const Color(0xFF0C0E12),
          appBar: ProDjConsoleAppBar(isPlaying: vm.isPlaying),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final foldableInfo = FoldableLayoutInfo.of(context);

                // 1. Tabletop / Flex Mode (Galaxy Z Fold half-folded at 90° on a desk)
                if (foldableInfo.isTabletop) {
                  return Column(
                    children: [
                      // Top Screen (Upright Master LCD Display & Diagnostics)
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                          child: Column(
                            children: [
                              _buildMasterLcdDisplay(),
                              const SizedBox(height: 6),
                              Expanded(child: _buildConsoleLogs()),
                            ],
                          ),
                        ),
                      ),

                      // Physical Fold Line / Crease Divider
                      Container(height: 4, color: const Color(0xFF1E2638)),

                      // Bottom Screen (Tactile DJ Console flat on desk)
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                          child: Column(
                            children: [
                              _buildHardwareConsoleBody(
                                isWide: constraints.maxWidth >= 600,
                              ),
                              const SizedBox(height: 10),
                              _buildPerformancePadsSection(),
                              const SizedBox(height: 10),
                              _buildMasterTransportBar(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // 2. Dual-Screen Book Mode (Surface Duo / 2 physical screens)
                if (foldableInfo.hasHinge && foldableInfo.isBookMode) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Screen: Master LCD + CDJ Deck A + Pads
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              _buildMasterLcdDisplay(),
                              const SizedBox(height: 12),
                              _buildCdjDeck(isDeckA: true),
                              const SizedBox(height: 12),
                              _buildPerformancePadsSection(),
                            ],
                          ),
                        ),
                      ),

                      // Center Hinge Spacer (Avoids physical hinge gap)
                      SizedBox(
                        width: (foldableInfo.hingeBounds?.width ?? 16).clamp(
                          8.0,
                          36.0,
                        ),
                        child: Center(
                          child: Container(width: 2, color: Colors.white24),
                        ),
                      ),

                      // Right Screen: DJM Mixer + CDJ Deck B + Transport + Logs
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              _buildDjmCenterMixer(),
                              const SizedBox(height: 12),
                              _buildCdjDeck(isDeckA: false),
                              const SizedBox(height: 12),
                              _buildMasterTransportBar(),
                              const SizedBox(height: 12),
                              _buildConsoleLogs(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // 3. Standard & Foldable Wide (Galaxy Z Fold unfolded or tablet/desktop)
                final isWide =
                    constraints.maxWidth >= 720 ||
                    foldableInfo.isFoldableOrWide;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMasterLcdDisplay(),
                      const SizedBox(height: 14),
                      _buildHardwareConsoleBody(isWide: isWide),
                      const SizedBox(height: 14),
                      _buildPerformancePadsSection(),
                      const SizedBox(height: 14),
                      _buildMasterTransportBar(),
                      const SizedBox(height: 14),
                      _buildConsoleLogs(),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHardwareConsoleBody({required bool isWide}) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: CDJ Deck A
          Expanded(flex: 5, child: _buildCdjDeck(isDeckA: true)),
          const SizedBox(width: 12),
          // Center: DJM Mixer Section
          Expanded(flex: 4, child: _buildDjmCenterMixer()),
          const SizedBox(width: 12),
          // Right: CDJ Deck B
          Expanded(flex: 5, child: _buildCdjDeck(isDeckA: false)),
        ],
      );
    } else {
      // Mobile / Narrow Stack Layout
      return Column(
        children: [
          _buildCdjDeck(isDeckA: true),
          const SizedBox(height: 12),
          _buildDjmCenterMixer(),
          const SizedBox(height: 12),
          _buildCdjDeck(isDeckA: false),
        ],
      );
    }
  }

  Widget _buildMasterLcdDisplay() {
    final vm = _viewModel;
    return MasterLcdDisplay(
      elapsed: vm.elapsed,
      bpm: vm.bpm,
      selectedScale: vm.selectedScale,
      isConnected: vm.isConnected,
      isPlaying: vm.isPlaying,
      currentRmsL: vm.currentRmsL,
    );
  }

  Widget _buildCdjDeck({required bool isDeckA}) {
    final vm = _viewModel;
    return CdjDeck(
      isDeckA: isDeckA,
      deckAPrompt: vm.deckAPrompt,
      deckBPrompt: vm.deckBPrompt,
      deckAWeight: vm.deckAWeight,
      deckBWeight: vm.deckBWeight,
      jogAnim: _jogAnimController,
      isPlaying: vm.isPlaying,
      isConnected: vm.isConnected,
      currentRmsL: vm.currentRmsL,
      currentRmsR: vm.currentRmsR,
      bpm: vm.bpm,
      onWeightChanged: (val) => vm.setDeckWeight(isDeckA, val),
      onSync: () => vm.syncDeckWeight(isDeckA),
      onEditPrompt: () => _editPrompt(isDeckA),
      onResetContext: vm.resetContext,
      onPlay: vm.play,
      onPause: vm.pause,
    );
  }

  Widget _buildDjmCenterMixer() {
    final vm = _viewModel;
    return DjmCenterMixer(
      mode: vm.mode,
      temperature: vm.temperature,
      brightness: vm.brightness,
      density: vm.density,
      guidance: vm.guidance,
      currentRmsL: vm.currentRmsL,
      currentRmsR: vm.currentRmsR,
      muteBass: vm.muteBass,
      muteDrums: vm.muteDrums,
      onlyBassAndDrums: vm.onlyBassAndDrums,
      crossfader: vm.crossfader,
      onTemperatureChanged: vm.setTemperature,
      onBrightnessChanged: vm.setBrightness,
      onDensityChanged: vm.setDensity,
      onGuidanceChanged: vm.setGuidance,
      onMuteBassChanged: vm.setMuteBass,
      onMuteDrumsChanged: vm.setMuteDrums,
      onOnlyBassAndDrumsChanged: vm.setOnlyBassAndDrums,
      onCrossfaderChanged: vm.setCrossfader,
    );
  }

  Widget _buildPerformancePadsSection() {
    final vm = _viewModel;
    return PerformancePadsSection(
      hotCuePads: vm.hotCuePads,
      activePadIndex: vm.activePadIndex,
      onPadTap: vm.applyHotCuePad,
    );
  }

  Widget _buildMasterTransportBar() {
    final vm = _viewModel;
    return MasterTransportBar(
      isConnecting: vm.isConnecting,
      isConnected: vm.isConnected,
      isPlaying: vm.isPlaying,
      onConnect: vm.connect,
      onDisconnect: vm.disconnect,
      onPlay: vm.play,
      onPause: vm.pause,
      onStop: vm.stop,
      onResetContext: vm.resetContext,
    );
  }

  Widget _buildConsoleLogs() {
    return ConsoleLogs(consoleLogs: _viewModel.consoleLogs);
  }
}
