import 'package:camera/camera.dart';
import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../math_tutor_i18n.dart';
import '../view_models/math_tutor_view_model.dart';
import 'camera_control_bar.dart';

/// Full-bleed camera preview with the scan-frame overlay, spoken subtitle bar
/// and the bottom HUD controls.
class CameraPane extends StatelessWidget {
  const CameraPane({
    super.key,
    required this.viewModel,
    this.bottomPadding = 0,
  });

  final MathTutorViewModel viewModel;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = MathTutorI18n(lang);
    final controller = vm.cameraController;
    final isInitialized = controller != null && controller.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isInitialized)
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: Center(
              child: vm.isCameraInitializing
                  ? const CircularProgressIndicator()
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_rounded,
                          size: 48,
                          color: Colors.white24,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '카메라를 불러오는 중입니다...',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
            ),
          ),

        // Math Document Target Box Overlay (문제 스캔 가이드 영역)
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = (constraints.maxWidth * 0.88).clamp(
                240.0,
                480.0,
              );
              final boxHeight = (constraints.maxHeight * 0.65).clamp(
                160.0,
                380.0,
              );

              return ValueListenableBuilder<InteractionStatus>(
                valueListenable: vm.interactionStatusNotifier,
                builder: (context, status, _) {
                  final isThinking = status == InteractionStatus.IN_PROGRESS;
                  return Container(
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isThinking
                            ? Colors.amberAccent
                            : Colors.white.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              i18n.cameraGuide,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        if (isThinking)
                          LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            color: Colors.amberAccent.withValues(alpha: 0.8),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Spoken subtitle floating bar (Reactive ValueListenableBuilder)
        ValueListenableBuilder<String>(
          valueListenable: vm.liveSubtitleNotifier,
          builder: (context, subtitle, _) {
            if (subtitle.isEmpty) return const SizedBox.shrink();
            final isUserSpeaking = subtitle.startsWith('🎤');
            return Positioned(
              left: 12,
              right: 12,
              bottom: bottomPadding + 64,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isUserSpeaking
                      ? const Color(0xDD042F2E)
                      : const Color(0xCC0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUserSpeaking
                        ? Colors.cyanAccent.withValues(alpha: 0.6)
                        : Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUserSpeaking
                          ? Icons.mic_rounded
                          : Icons.volume_up_rounded,
                      color: isUserSpeaking
                          ? Colors.cyanAccent
                          : Colors.amberAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUserSpeaking
                              ? const Color(0xFFE0F2FE)
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: isUserSpeaking
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Camera Bottom HUD Controls
        Positioned(
          left: 8,
          right: 8,
          bottom: bottomPadding + 10,
          child: CameraControlBar(viewModel: vm),
        ),
      ],
    );
  }
}
