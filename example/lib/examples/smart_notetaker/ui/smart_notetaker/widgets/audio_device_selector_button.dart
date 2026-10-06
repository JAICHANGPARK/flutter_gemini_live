import 'package:flutter/material.dart';

import '../view_models/smart_notetaker_view_model.dart';

/// Popup button to choose the audio input device (BlackHole / microphone).
class AudioDeviceSelectorButton extends StatelessWidget {
  const AudioDeviceSelectorButton({
    super.key,
    required this.viewModel,
    this.isCompact = false,
  });

  final SmartNotetakerViewModel viewModel;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final selectedAudioDevice = viewModel.selectedAudioDevice;
    final hasDevice = selectedAudioDevice != null;
    final isBlackHole =
        selectedAudioDevice?.label.toLowerCase().contains('blackhole') ?? false;
    final label = hasDevice
        ? (selectedAudioDevice.label.isNotEmpty
              ? selectedAudioDevice.label
              : '입력 장치 (${selectedAudioDevice.id})')
        : '기본 마이크 (System Default)';

    return PopupMenuButton<String>(
      tooltip: '오디오 입력 장치 선택 (BlackHole / 마이크)',
      onOpened: viewModel.loadAudioDevices,
      onSelected: viewModel.selectAudioDeviceById,
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            value: '__default__',
            child: Row(
              children: [
                Icon(
                  viewModel.selectedAudioDevice == null
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: viewModel.selectedAudioDevice == null
                      ? Colors.amberAccent
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text('기본 마이크 (System Default)'),
              ],
            ),
          ),
          ...viewModel.availableAudioDevices.map((dev) {
            final isSelected = viewModel.selectedAudioDevice?.id == dev.id;
            final isBh = dev.label.toLowerCase().contains('blackhole');
            return PopupMenuItem<String>(
              value: dev.id,
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isSelected ? Colors.amberAccent : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isBh ? '🔈 ${dev.label} (시스템 오디오)' : dev.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isBh ? Colors.amberAccent : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ];
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: isBlackHole
              ? Colors.amber.withValues(alpha: 0.15)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isBlackHole
                ? Colors.amberAccent.withValues(alpha: 0.6)
                : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBlackHole
                  ? Icons.surround_sound_rounded
                  : (hasDevice ? Icons.mic_external_on : Icons.mic),
              size: isCompact ? 14 : 16,
              color: isBlackHole ? Colors.amberAccent : Colors.cyanAccent,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isCompact ? 130 : 200),
              child: Text(
                isBlackHole ? '🔈 $label' : label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isBlackHole ? Colors.amberAccent : Colors.white,
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
