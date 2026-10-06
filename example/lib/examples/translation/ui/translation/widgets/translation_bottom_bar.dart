import 'package:flutter/material.dart';

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
          listenable: Listenable.merge([vm, vm.micVolumeNotifier]),
          builder: (context, _) {
            final micVolume = vm.micVolume;
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.isConnected
                            ? (vm.isAiCurrentlySpeaking
                                  ? '🔊 번역 음성 출력 중 (에코 방지 대기)'
                                  : (vm.isMicActive
                                        ? '실시간 동시통역 중 (말씀하시면 즉시 번역됩니다)'
                                        : '마이크 일시 정지됨'))
                            : (vm.isConnecting
                                  ? 'Live Translate 서버 연결 중...'
                                  : '준비 완료 (통역 시작을 누르세요)'),
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
                const SizedBox(width: 12),
                if (vm.isConnected) ...[
                  IconButton.filledTonal(
                    onPressed: vm.toggleMicStreaming,
                    icon: Icon(
                      vm.isMicActive
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    tooltip: vm.isMicActive ? '마이크 일시중지' : '마이크 재개',
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: vm.disconnect,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('종료'),
                  ),
                ] else ...[
                  FilledButton.icon(
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
                        : const Icon(Icons.translate_rounded),
                    label: Text(vm.isConnecting ? '연결 중...' : '통역 시작'),
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
