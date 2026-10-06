import 'package:flutter/material.dart';

import '../view_models/smart_notetaker_view_model.dart';
import 'audio_device_selector_button.dart';

/// Recording status, timer, mic level and start / stop button.
class SessionStatusBar extends StatelessWidget {
  const SessionStatusBar({
    super.key,
    required this.viewModel,
    required this.pulse,
  });

  final SmartNotetakerViewModel viewModel;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final isConnected = viewModel.isConnected;
    final isConnecting = viewModel.isConnecting;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF131B2E),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 680;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (isConnected)
                      FadeTransition(
                        opacity: pulse,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.radio_button_unchecked,
                        size: 10,
                        color: Colors.grey,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isConnected
                            ? 'RECORDING & TRANSLATING'
                            : 'READY TO RECORD',
                        style: TextStyle(
                          color: isConnected
                              ? Colors.redAccent
                              : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: Colors.amberAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            viewModel.formatElapsedTime(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _VolumeBar(viewModel: viewModel)),
                    const SizedBox(width: 8),
                    AudioDeviceSelectorButton(
                      viewModel: viewModel,
                      isCompact: true,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isConnected
                            ? Colors.red.shade600
                            : Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isConnecting ? null : viewModel.toggleSession,
                      icon: isConnecting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isConnected
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              size: 18,
                            ),
                      label: Text(
                        isConnected ? '종료' : '녹음 시작',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              // Recording Pulse Indicator
              if (isConnected)
                FadeTransition(
                  opacity: pulse,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.radio_button_unchecked,
                  size: 12,
                  color: Colors.grey,
                ),
              const SizedBox(width: 10),
              Text(
                isConnected ? 'RECORDING & TRANSLATING' : 'READY TO RECORD',
                style: TextStyle(
                  color: isConnected ? Colors.redAccent : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 16),
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      viewModel.formatElapsedTime(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Audio level indicator
              Expanded(child: _VolumeBar(viewModel: viewModel)),
              const SizedBox(width: 16),
              AudioDeviceSelectorButton(viewModel: viewModel, isCompact: false),
              const SizedBox(width: 16),
              // Start / Stop Session Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isConnected
                      ? Colors.red.shade600
                      : Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isConnecting ? null : viewModel.toggleSession,
                icon: isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isConnected ? Icons.stop_rounded : Icons.mic_rounded,
                      ),
                label: Text(
                  isConnected ? '세션 종료' : '노트 녹음 시작',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Mic level bar driven by the high-frequency volume notifier.
class _VolumeBar extends StatelessWidget {
  const _VolumeBar({required this.viewModel});

  final SmartNotetakerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: viewModel.audioVolumeNotifier,
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
                        ? Colors.amberAccent
                        : Colors.greenAccent),
            ),
          ),
        );
      },
    );
  }
}
