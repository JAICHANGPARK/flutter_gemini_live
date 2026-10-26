import 'package:flutter/material.dart';

import '../translation_i18n.dart';
import '../view_models/translation_view_model.dart';
import 'translation_language_dropdown.dart';
import 'translation_toggle_pill.dart';

/// Language & configuration bar: language pickers, swap button, mode badge and
/// the voice output / echo prevention pills.
class TranslationLanguageBar extends StatelessWidget {
  const TranslationLanguageBar({super.key, required this.viewModel});

  final TranslationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final i18n = TranslationI18n.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 내 언어 선택기
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  i18n.myLanguageLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 4),
                TranslationLanguageDropdown(
                  value: vm.myLanguageCode,
                  onChanged: vm.isConnected
                      ? null
                      : (val) {
                          if (val != null) {
                            vm.setMyLanguage(val);
                          }
                        },
                ),
              ],
            ),
            const SizedBox(width: 6),
            // 언어 맞바꾸기(Swap) 버튼
            IconButton(
              icon: const Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: Colors.blueAccent,
              ),
              tooltip: i18n.swapLanguagesTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: vm.isConnected ? null : vm.swapLanguages,
            ),
            const SizedBox(width: 6),
            // 상대방 언어 선택기
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  i18n.partnerLanguageLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 4),
                TranslationLanguageDropdown(
                  value: vm.targetLanguageCode,
                  onChanged: vm.isConnected
                      ? null
                      : (val) {
                          if (val != null) {
                            vm.setTargetLanguage(val);
                          }
                        },
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Mode badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: vm.isDualFlipMode
                    ? Colors.amber.withValues(alpha: 0.15)
                    : Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    vm.isDualFlipMode
                        ? Icons.screen_rotation_rounded
                        : Icons.chat_rounded,
                    size: 14,
                    color: vm.isDualFlipMode
                        ? Colors.amber.shade900
                        : Colors.blueAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vm.isDualFlipMode
                        ? i18n.tabletopFaceToFaceMode
                        : i18n.standardChatMode,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: vm.isDualFlipMode
                          ? Colors.amber.shade900
                          : Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Voice output toggle pill (클릭하여 켜기/끄기)
            TranslationTogglePill(
              onTap: vm.toggleAudioOutput,
              backgroundColor: vm.isAudioOutputEnabled
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.15),
              borderColor: vm.isAudioOutputEnabled
                  ? Colors.greenAccent.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.3),
              icon: vm.isAudioOutputEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              contentColor: vm.isAudioOutputEnabled
                  ? Colors.greenAccent
                  : Colors.grey,
              label: vm.isAudioOutputEnabled
                  ? i18n.voiceOutputOn
                  : i18n.voiceOutputOff,
            ),
            const SizedBox(width: 8),
            // Echo loop prevention pill (클릭하여 켜기/끄기)
            TranslationTogglePill(
              onTap: vm.togglePreventEchoLoop,
              backgroundColor: vm.preventEchoLoop
                  ? Colors.blue.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              borderColor: vm.preventEchoLoop
                  ? Colors.blueAccent.withValues(alpha: 0.5)
                  : Colors.orangeAccent.withValues(alpha: 0.3),
              icon: vm.preventEchoLoop
                  ? Icons.hearing_rounded
                  : Icons.hearing_disabled_rounded,
              contentColor: vm.preventEchoLoop
                  ? Colors.blueAccent
                  : Colors.orangeAccent,
              label: vm.preventEchoLoop
                  ? i18n.echoPreventionOn
                  : i18n.echoPreventionOff,
            ),
          ],
        ),
      ),
    );
  }
}
