import 'package:example/app_translations.dart';
import 'package:example/scrollable_app_bar_actions.dart';
import 'package:flutter/material.dart';

import '../math_tutor_i18n.dart';
import '../view_models/math_tutor_view_model.dart';
import 'thinking_status_pill.dart';

/// Screen app bar: title (with ellipsis), thinking pill, system instruction,
/// mic device picker and settings. Actions scroll instead of overflowing.
class MathTutorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MathTutorAppBar({
    super.key,
    required this.viewModel,
    required this.pulse,
    required this.onShowSystemInstruction,
    required this.onOpenSettings,
  });

  final MathTutorViewModel viewModel;
  final Animation<double> pulse;
  final VoidCallback onShowSystemInstruction;
  final VoidCallback onOpenSettings;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final t = AppLanguageController.instance.t;
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = MathTutorI18n(lang);
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i18n.appTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  i18n.modelSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.amber.shade200),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ScrollableAppBarActions(
          children: [
            // Extended Thinking status indicator
            ThinkingStatusPill(viewModel: vm, pulse: pulse, i18n: i18n),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: i18n.systemInstructionTitle,
              onPressed: onShowSystemInstruction,
            ),
            // Audio Input Device selector
            PopupMenuButton<String>(
              tooltip: vm.selectedAudioDevice?.label.isNotEmpty == true
                  ? vm.selectedAudioDevice!.label
                  : '마이크 디바이스 선택',
              icon: Icon(
                vm.selectedAudioDevice != null
                    ? Icons.mic_external_on_rounded
                    : Icons.mic_rounded,
                color: Colors.white70,
                size: 20,
              ),
              onOpened: vm.loadAudioDevices,
              onSelected: (deviceId) {
                vm.selectAudioDeviceById(
                  deviceId == '__default__' ? null : deviceId,
                );
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem<String>(
                    value: '__default__',
                    child: Row(
                      children: [
                        Icon(
                          vm.selectedAudioDevice == null
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: vm.selectedAudioDevice == null
                              ? Colors.amberAccent
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '기본 마이크',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  ...vm.availableAudioDevices.map((dev) {
                    final isSelected = vm.selectedAudioDevice?.id == dev.id;
                    return PopupMenuItem<String>(
                      value: dev.id,
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: isSelected
                                ? Colors.amberAccent
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dev.label.isNotEmpty ? dev.label : dev.id,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ];
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: t.settingsTooltip,
              onPressed: onOpenSettings,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ],
    );
  }
}
