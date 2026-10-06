import 'package:flutter/material.dart';

import '../view_models/vision_call_view_model.dart';
import '../vision_call_i18n.dart';

/// Audio input device selector popup in the header.
class MicDeviceMenu extends StatelessWidget {
  const MicDeviceMenu({super.key, required this.viewModel, required this.i18n});

  final VisionCallViewModel viewModel;
  final VisionCallI18n i18n;

  @override
  Widget build(BuildContext context) {
    final selectedAudioDevice = viewModel.selectedAudioDevice;
    return PopupMenuButton<String>(
      tooltip: i18n.micSelectorTooltip(
        selectedAudioDevice?.label.isNotEmpty == true
            ? selectedAudioDevice!.label
            : i18n.defaultMic,
      ),
      icon: Icon(
        selectedAudioDevice != null
            ? Icons.mic_external_on_rounded
            : Icons.mic_rounded,
        color: Colors.white70,
        size: 22,
      ),
      onOpened: viewModel.loadAudioDevices,
      onSelected: (deviceId) {
        if (deviceId == '__default__') {
          viewModel.switchAudioDevice(null);
        } else {
          final dev = viewModel.availableAudioDevices
              .where((d) => d.id == deviceId)
              .firstOrNull;
          viewModel.switchAudioDevice(dev);
        }
      },
      itemBuilder: (context) {
        final selectedAudioDevice = viewModel.selectedAudioDevice;
        return [
          PopupMenuItem<String>(
            value: '__default__',
            child: Row(
              children: [
                Icon(
                  selectedAudioDevice == null
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: selectedAudioDevice == null
                      ? Colors.blueAccent
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(i18n.defaultMic),
              ],
            ),
          ),
          ...viewModel.availableAudioDevices.map((dev) {
            final isSelected = selectedAudioDevice?.id == dev.id;
            return PopupMenuItem<String>(
              value: dev.id,
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isSelected ? Colors.blueAccent : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dev.label.isNotEmpty ? dev.label : '마이크 (${dev.id})',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ];
      },
    );
  }
}
