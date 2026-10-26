import 'package:example/app_translations.dart';
import 'package:example/scrollable_app_bar_actions.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../translation_i18n.dart';
import '../view_models/translation_view_model.dart';
import 'translation_foldable_badge.dart';

/// Screen app bar: title (with ellipsis) and scrollable action buttons.
class TranslationAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TranslationAppBar({
    super.key,
    required this.viewModel,
    required this.onOpenSettings,
  });

  final TranslationViewModel viewModel;
  final VoidCallback onOpenSettings;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final i18n = TranslationI18n.current;
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.translate_rounded, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              i18n.appBarTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        ScrollableAppBarActions(
          children: [
            const LanguageSelectorButton(compact: true),
            // Real-time token usage and cost badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GeminiLiveUsageBadge(tracker: vm.usageTracker),
            ),
            // Voice Output Toggle Button (번역 음성 스피커 출력 ON/OFF)
            IconButton(
              icon: Icon(
                vm.isAudioOutputEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: vm.isAudioOutputEnabled
                    ? Colors.greenAccent
                    : Colors.white54,
              ),
              tooltip: vm.isAudioOutputEnabled
                  ? i18n.voiceOutputOnTooltip
                  : i18n.voiceOutputOffTooltip,
              onPressed: vm.toggleAudioOutput,
            ),
            // Echo Loop Prevention Toggle Button
            IconButton(
              icon: Icon(
                vm.preventEchoLoop
                    ? Icons.hearing_rounded
                    : Icons.hearing_disabled_rounded,
                color: vm.preventEchoLoop ? Colors.blueAccent : Colors.white54,
              ),
              tooltip: vm.preventEchoLoop
                  ? i18n.echoPreventOnTooltip
                  : i18n.echoPreventOffTooltip,
              onPressed: vm.togglePreventEchoLoop,
            ),
            // Dual Flip Mode Toggle Button
            IconButton(
              icon: Icon(
                vm.isDualFlipMode
                    ? Icons.splitscreen_rounded
                    : Icons.chat_bubble_outline_rounded,
                color: vm.isDualFlipMode ? Colors.amber : null,
              ),
              tooltip: vm.isDualFlipMode
                  ? i18n.switchToSingleChatTooltip
                  : i18n.switchToDualFlipTooltip,
              onPressed: vm.toggleDualFlipMode,
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: i18n.settingsTooltip,
              onPressed: onOpenSettings,
            ),
            const TranslationFoldableBadge(),
          ],
        ),
      ],
    );
  }
}
