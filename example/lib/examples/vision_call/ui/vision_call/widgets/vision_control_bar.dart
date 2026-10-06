import 'package:flutter/material.dart';

import '../vision_call_i18n.dart';
import '../view_models/vision_call_view_model.dart';
import 'circle_action_button.dart';
import 'dot_waveform.dart';

/// Bottom control bar (5 buttons: chat, camera, waveform, mic, end call).
class VisionControlBar extends StatelessWidget {
  const VisionControlBar({
    super.key,
    required this.viewModel,
    required this.i18n,
    required this.dotsAnimation,
    required this.onOpenChat,
    required this.onEndCall,
  });

  final VisionCallViewModel viewModel;
  final VisionCallI18n i18n;
  final AnimationController dotsAnimation;
  final VoidCallback onOpenChat;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Chat button (Dark semi-transparent circle)
          CircleActionButton(
            backgroundColor: const Color(0xFF173827),
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: Colors.white,
            onTap: onOpenChat,
            tooltip: i18n.liveTranscriptTitle,
          ),

          // 2. Camera Toggle button (White circle)
          ValueListenableBuilder<bool>(
            valueListenable: viewModel.isVideoPausedNotifier,
            builder: (context, isPaused, _) {
              return CircleActionButton(
                backgroundColor: Colors.white,
                icon: isPaused
                    ? Icons.videocam_off_rounded
                    : Icons.videocam_rounded,
                iconColor: isPaused ? Colors.black54 : const Color(0xFF0F2D1E),
                onTap: viewModel.toggleVideoPause,
                tooltip: i18n.cameraToggleTooltip,
              );
            },
          ),

          // 3. Central Dot Waveform Visualizer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: DotWaveform(
                  animation: dotsAnimation,
                  audioActivity: viewModel.audioActivity,
                ),
              ),
            ),
          ),

          // 4. Microphone Toggle button (White circle)
          ValueListenableBuilder<bool>(
            valueListenable: viewModel.isMicMutedNotifier,
            builder: (context, isMuted, _) {
              return CircleActionButton(
                backgroundColor: Colors.white,
                icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                iconColor: isMuted ? Colors.redAccent : const Color(0xFF0F2D1E),
                onTap: viewModel.toggleMicMute,
                tooltip: i18n.micToggleTooltip,
              );
            },
          ),

          // 5. End Call button (Red circle)
          CircleActionButton(
            backgroundColor: const Color(0xFFD32F2F),
            icon: Icons.call_end_rounded,
            iconColor: Colors.white,
            onTap: onEndCall,
            tooltip: i18n.endSessionTooltip,
          ),
        ],
      ),
    );
  }
}
