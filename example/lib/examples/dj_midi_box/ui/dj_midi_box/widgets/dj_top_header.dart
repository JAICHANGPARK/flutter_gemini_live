import 'package:example/app_settings_dialog.dart';
import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../dj_midi_box_i18n.dart';
import '../view_models/dj_midi_box_view_model.dart';
import 'dj_console_sheet.dart';

class DjTopHeader extends StatelessWidget {
  final DjMidiBoxViewModel viewModel;
  final ScrollController logScrollController;

  const DjTopHeader({
    super.key,
    required this.viewModel,
    required this.logScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = DjMidiBoxI18n.current;
    final vm = viewModel;
    final isNarrow = MediaQuery.sizeOf(context).width < 480;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 8 : 16,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: i18n.backTooltip,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    i18n.headerTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isNarrow ? 14 : 16,
                      letterSpacing: isNarrow ? 1.0 : 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status & BPM Pill (scales down cleanly on narrow 320px viewports so all controls stay visible)
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hardware Mixer Desk vs 4x4 Pad Matrix Toggle Pill
                  InkWell(
                    onTap: vm.toggleMixerDeskView,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: vm.isMixerDeskView
                            ? const Color(0xFF0084D6).withAlpha(60)
                            : Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: vm.isMixerDeskView
                              ? const Color(0xFF0095FF)
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            vm.isMixerDeskView
                                ? Icons.tune_rounded
                                : Icons.grid_view_rounded,
                            color: vm.isMixerDeskView
                                ? const Color(0xFF38BDF8)
                                : Colors.white70,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vm.isMixerDeskView ? '16-CH MIXER' : '4x4 PAD',
                            style: TextStyle(
                              color: vm.isMixerDeskView
                                  ? const Color(0xFF38BDF8)
                                  : Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // BPM Indicator (Tap to cycle tempo)
                  InkWell(
                    onTap: vm.cycleBpm,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.speed,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${vm.bpm} BPM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Connection status
                  InkWell(
                    onTap: vm.isConnected ? vm.closeSession : vm.connect,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: vm.isConnected
                            ? const Color(0xFF10B981).withAlpha(40)
                            : Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: vm.isConnected
                              ? const Color(0xFF10B981)
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: vm.isConnected
                                ? const Color(0xFF10B981)
                                : Colors.white54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vm.isConnecting
                                ? i18n.connectingPill
                                : (vm.isConnected
                                      ? i18n.onlinePill
                                      : i18n.connectPill),
                            style: TextStyle(
                              color: vm.isConnected
                                  ? const Color(0xFF10B981)
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Real-time token usage & cost badge
                  GeminiLiveUsageBadge(
                    tracker: vm.usageTracker,
                    compact: true,
                    backgroundColor: Colors.white.withAlpha(20),
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(width: 4),

                  const LanguageSelectorButton(compact: true),

                  const SizedBox(width: 4),

                  // Console Split-View Toggle Button
                  IconButton(
                    icon: Icon(
                      vm.showSidePanel
                          ? Icons.space_dashboard
                          : Icons.space_dashboard_outlined,
                      color: vm.showSidePanel
                          ? const Color(0xFFA855F7)
                          : Colors.white70,
                      size: 20,
                    ),
                    onPressed: () {
                      final width = MediaQuery.of(context).size.width;
                      if (width < 860) {
                        showDjMobileConsoleSheet(
                          context,
                          vm,
                          logScrollController,
                        );
                      } else {
                        vm.toggleSidePanel();
                      }
                    },
                    tooltip: vm.showSidePanel
                        ? i18n.hideConsoleTooltip
                        : i18n.showConsoleTooltip,
                  ),

                  const SizedBox(width: 4),

                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => AppSettingsDialog.show(context),
                    tooltip: i18n.settingsTooltip,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
