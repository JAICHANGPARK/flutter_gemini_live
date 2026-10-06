import 'package:example/app_settings_dialog.dart';
import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

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
    final vm = viewModel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              const Text(
                'DJ MIDI BOX',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),

          // Status & BPM Pill
          Row(
            children: [
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
                      const Icon(Icons.speed, color: Colors.white70, size: 14),
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
                            ? 'CONNECTING'
                            : (vm.isConnected ? 'ONLINE' : 'CONNECT'),
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
                    showDjMobileConsoleSheet(context, vm, logScrollController);
                  } else {
                    vm.toggleSidePanel();
                  }
                },
                tooltip: vm.showSidePanel
                    ? 'Hide Console'
                    : 'Show Console (Prompt, Settings, Logs)',
              ),

              const SizedBox(width: 4),

              IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => AppSettingsDialog.show(context),
                tooltip: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
