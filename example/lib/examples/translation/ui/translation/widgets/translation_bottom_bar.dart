import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

import '../translation_i18n.dart';
import '../view_models/translation_view_model.dart';

/// Waveform & controls bottom bar: mic / AI playback indicator, status text,
/// level meter and the connect / pause / stop buttons.
class TranslationBottomBar extends StatelessWidget {
  const TranslationBottomBar({super.key, required this.viewModel});

  final TranslationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        // Mic level changes for every audio chunk; rebuild only this subtree.
        child: ListenableBuilder(
          listenable: Listenable.merge([
            vm,
            vm.micVolumeNotifier,
            AppLanguageController.instance,
          ]),
          builder: (context, _) {
            final micVolume = vm.micVolume;
            final i18n = TranslationI18n.current;
            return Row(
              children: [
                // Mic amplitude meter / AI playback indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: vm.isAiCurrentlySpeaking
                        ? Colors.amber.withValues(alpha: 0.2)
                        : (vm.isMicActive
                              ? Colors.redAccent.withValues(
                                  alpha: 0.15 + (micVolume * 0.8),
                                )
                              : Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Icon(
                    vm.isAiCurrentlySpeaking
                        ? Icons.volume_up_rounded
                        : (vm.isMicActive ? Icons.mic : Icons.mic_off),
                    color: vm.isAiCurrentlySpeaking
                        ? Colors.amber.shade800
                        : (vm.isMicActive ? Colors.redAccent : Colors.grey),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.isConnected
                            ? (vm.isAiCurrentlySpeaking
                                  ? i18n.statusSpeaking
                                  : (vm.isMicActive
                                        ? i18n.statusTranslating
                                        : i18n.statusMicPaused))
                            : (vm.isConnecting
                                  ? i18n.statusConnecting
                                  : i18n.statusReady),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: vm.isConnected
                              ? (vm.isAiCurrentlySpeaking
                                    ? Colors.amber.shade900
                                    : Colors.green.shade700)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: vm.isAiCurrentlySpeaking
                              ? null
                              : (vm.isMicActive
                                    ? (micVolume * 2.5).clamp(0.0, 1.0)
                                    : 0.0),
                          minHeight: 4,
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            vm.isAiCurrentlySpeaking
                                ? Colors.amber
                                : (micVolume > 0.05
                                      ? Colors.greenAccent.shade700
                                      : Colors.blueAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (vm.isConnected) ...[
                  IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    onPressed: vm.toggleMicStreaming,
                    icon: Icon(
                      vm.isMicActive
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    tooltip: vm.isMicActive
                        ? i18n.pauseMicTooltip
                        : i18n.resumeMicTooltip,
                  ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: vm.disconnect,
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: Text(
                      i18n.stopTranslation,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ] else ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: vm.isConnecting ? null : vm.connect,
                    icon: vm.isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.translate_rounded, size: 18),
                    label: Text(
                      vm.isConnecting
                          ? i18n.connectingLabel
                          : i18n.startTranslation,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
