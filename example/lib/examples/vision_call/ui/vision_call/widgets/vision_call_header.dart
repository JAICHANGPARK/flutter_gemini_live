import 'package:example/api_key_store.dart';
import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../domain/models/audio_activity.dart';
import '../view_models/vision_call_view_model.dart';
import '../vision_call_i18n.dart';
import 'mic_device_menu.dart';

/// Top header: logo, title, connection status and header actions.
class VisionCallHeader extends StatelessWidget {
  const VisionCallHeader({
    super.key,
    required this.viewModel,
    required this.i18n,
    required this.agentTitle,
    required this.onOpenSettings,
  });

  final VisionCallViewModel viewModel;
  final VisionCallI18n i18n;
  final String? agentTitle;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Circular green logo with eco/sprout icon
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF1B6A42),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agentTitle ?? i18n.defaultTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              ValueListenableBuilder<AudioActivity>(
                valueListenable: vm.audioActivity,
                builder: (context, act, _) {
                  final isAiSpeaking = act.isAiResponding;
                  final isUserSpeaking = act.isUserSpeaking;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: vm.isConnected
                              ? (isAiSpeaking
                                    ? Colors.greenAccent
                                    : (isUserSpeaking
                                          ? Colors.amberAccent
                                          : Colors.green))
                              : (vm.isConnecting
                                    ? Colors.orangeAccent
                                    : Colors.redAccent),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vm.isConnected
                            ? (isAiSpeaking
                                  ? i18n.aiSpeaking
                                  : (isUserSpeaking
                                        ? i18n.listening
                                        : i18n.liveStatus(
                                            ApiKeyStore.liveModel,
                                          )))
                            : (vm.isConnecting
                                  ? i18n.connecting
                                  : i18n.disconnected),
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          // Real-time token usage and cost badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GeminiLiveUsageBadge(
              tracker: vm.usageTracker,
              backgroundColor: Colors.white.withAlpha(25),
              foregroundColor: Colors.white,
            ),
          ),
          // Language switcher dropdown
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.0),
            child: LanguageSelectorButton(compact: true),
          ),
          // Audio Input Device selector
          MicDeviceMenu(viewModel: vm, i18n: i18n),
          // Flip Camera Toggle button (좌우 반전 / 거울 모드)
          ValueListenableBuilder<bool>(
            valueListenable: vm.isCameraFlippedNotifier,
            builder: (context, isFlipped, _) {
              return IconButton(
                onPressed: vm.toggleCameraFlip,
                icon: Icon(
                  isFlipped ? Icons.flip_rounded : Icons.swap_horiz_rounded,
                  color: isFlipped ? Colors.greenAccent : Colors.white70,
                  size: 22,
                ),
                tooltip: isFlipped ? i18n.flipOn : i18n.flipOff,
              );
            },
          ),
          // Camera Switch button in header
          if (vm.availableCameras.length > 1)
            IconButton(
              onPressed: vm.toggleCameraDirection,
              icon: const Icon(
                Icons.flip_camera_ios_outlined,
                color: Colors.white70,
                size: 22,
              ),
              tooltip: i18n.switchCameraTooltip,
            ),
          // Settings button (API Key & Model)
          IconButton(
            onPressed: onOpenSettings,
            icon: const Icon(
              Icons.tune_rounded,
              color: Colors.white70,
              size: 22,
            ),
            tooltip: i18n.settingsTooltip,
          ),
        ],
      ),
    );
  }
}
