import 'package:flutter/material.dart';

import '../media_subtitle_i18n.dart';
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
    final i18n = MediaSubtitleI18n.current;
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
                                      ? i18n.statusStreamingNarrow
                                      : i18n.statusConnectedWaiting)
                                : i18n.statusOffline,
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
                      vm.isConnected
                          ? i18n.stopSubtitles
                          : i18n.startLiveSubtitles,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                                      ? i18n.statusStreamingWide
                                      : i18n.statusConnectedWaiting)
                                : i18n.statusOffline,
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
                        vm.isConnected
                            ? i18n.stopSubtitles
                            : i18n.startLiveSubtitles,
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
                    children: [
                      const Icon(
                        Icons.settings_voice_rounded,
                        size: 16,
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          i18n.audioInputDeviceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Text(
                        i18n.hudOptionsLabel,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      FilterChip(
                        label: Text(i18n.showOriginalTextChip),
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
                      FilterChip(
                        label: Text(i18n.floatingSubtitleChip),
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
                        tooltip: i18n.decreaseFontSizeTooltip,
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
                        tooltip: i18n.increaseFontSizeTooltip,
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
