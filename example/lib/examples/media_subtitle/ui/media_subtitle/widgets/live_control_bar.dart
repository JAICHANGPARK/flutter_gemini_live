import 'package:flutter/material.dart';

import '../view_models/media_subtitle_view_model.dart';
import 'audio_device_selector_button.dart';

/// Connection toggle, mic level meter, device selector and HUD options.
class LiveControlBar extends StatelessWidget {
  const LiveControlBar({super.key, required this.viewModel});

  final MediaSubtitleViewModel viewModel;

  Widget _volumeMeter(MediaSubtitleViewModel vm) {
    return ValueListenableBuilder<double>(
      valueListenable: vm.audioVolume,
      builder: (context, audioVolume, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: audioVolume,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              audioVolume > 0.6
                  ? Colors.redAccent
                  : (audioVolume > 0.3
                        ? Colors.yellowAccent
                        : Colors.cyanAccent),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isNarrow) ...[
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: vm.isAudioStreaming
                            ? Colors.cyanAccent.withValues(alpha: 0.15)
                            : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        vm.isAudioStreaming ? Icons.mic : Icons.mic_off,
                        color: vm.isAudioStreaming
                            ? Colors.cyanAccent
                            : Colors.white38,
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
                                ? (vm.isAudioStreaming
                                      ? '초저지연 번역 스트리밍 중'
                                      : '연결됨 (오디오 대기 중)')
                                : 'Live Translate (gemini-3.5) 자막기 오프라인',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _volumeMeter(vm),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: vm.isConnected
                          ? Colors.red.shade600
                          : Colors.cyanAccent.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: vm.isConnecting ? null : vm.toggleConnection,
                    icon: vm.isConnecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            vm.isConnected
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                          ),
                    label: Text(
                      vm.isConnected ? '자막 정지' : '실시간 자막 시작',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: vm.isAudioStreaming
                            ? Colors.cyanAccent.withValues(alpha: 0.15)
                            : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        vm.isAudioStreaming ? Icons.mic : Icons.mic_off,
                        color: vm.isAudioStreaming
                            ? Colors.cyanAccent
                            : Colors.white38,
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
                                ? (vm.isAudioStreaming
                                      ? '오디오 수음 및 초저지연 번역 스트리밍 중'
                                      : '연결됨 (오디오 대기 중)')
                                : 'Live Translate (gemini-3.5) 자막기 오프라인',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _volumeMeter(vm),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: vm.isConnected
                            ? Colors.red.shade600
                            : Colors.cyanAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: vm.isConnecting ? null : vm.toggleConnection,
                      icon: vm.isConnecting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              vm.isConnected
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                      label: Text(
                        vm.isConnected ? '자막 정지' : '실시간 자막 시작',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.settings_voice_rounded,
                        size: 16,
                        color: Colors.cyanAccent,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '오디오 입력 장치:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  AudioDeviceSelectorButton(viewModel: vm, isCompact: false),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'HUD 옵션:',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('원문 함께 보기'),
                        selected: vm.showOriginalText,
                        backgroundColor: const Color(0xFF0F172A),
                        selectedColor: Colors.cyanAccent.shade700,
                        labelStyle: TextStyle(
                          color: vm.showOriginalText
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 11,
                        ),
                        onSelected: vm.setShowOriginalText,
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('플로팅 자막'),
                        selected: vm.showFloatingHud,
                        backgroundColor: const Color(0xFF0F172A),
                        selectedColor: Colors.cyanAccent.shade700,
                        labelStyle: TextStyle(
                          color: vm.showFloatingHud
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 11,
                        ),
                        onSelected: vm.setShowFloatingHud,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.text_decrease,
                          color: Colors.white70,
                          size: 18,
                        ),
                        tooltip: '글자 크기 축소',
                        onPressed: vm.subtitleFontSize > 14
                            ? vm.decreaseFontSize
                            : null,
                      ),
                      Text(
                        '${vm.subtitleFontSize.toInt()}pt',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.text_increase,
                          color: Colors.white70,
                          size: 18,
                        ),
                        tooltip: '글자 크기 확대',
                        onPressed: vm.subtitleFontSize < 28
                            ? vm.increaseFontSize
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
