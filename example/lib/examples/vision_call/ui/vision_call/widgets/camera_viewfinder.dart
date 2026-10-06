import 'package:flutter/material.dart';

import '../../../domain/models/audio_activity.dart';
import '../view_models/vision_call_view_model.dart';
import '../vision_call_i18n.dart';
import 'camera_preview_view.dart';

/// Rounded camera viewfinder with status overlays.
class CameraViewfinder extends StatelessWidget {
  const CameraViewfinder({
    super.key,
    required this.viewModel,
    required this.i18n,
  });

  final VisionCallViewModel viewModel;
  final VisionCallI18n i18n;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    const viewfinderRadius = 28.0;

    return ValueListenableBuilder<AudioActivity>(
      valueListenable: vm.audioActivity,
      builder: (context, act, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF04100A),
            borderRadius: BorderRadius.circular(viewfinderRadius),
            border: Border.all(
              color: act.isAiResponding
                  ? Colors.greenAccent.withAlpha(120)
                  : Colors.white.withAlpha(18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(viewfinderRadius - 1.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview or Loading/Error state
            ValueListenableBuilder<bool>(
              valueListenable: vm.isVideoPausedNotifier,
              builder: (context, isPaused, _) {
                if (vm.cameraReady && !isPaused) {
                  return CameraPreviewView(
                    controller: vm.cameraController,
                    isFlipped: vm.isCameraFlippedNotifier,
                  );
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          vm.cameraErrorMessage != null
                              ? Icons.videocam_off_outlined
                              : (isPaused
                                    ? Icons.pause_circle_outline
                                    : Icons.camera_alt_outlined),
                          color: vm.cameraErrorMessage != null
                              ? Colors.redAccent.withAlpha(200)
                              : Colors.white38,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          vm.cameraErrorMessage ??
                              (isPaused
                                  ? i18n.cameraPaused
                                  : (vm.isCameraInitializing
                                        ? i18n.cameraConnecting
                                        : i18n.cameraPreparing)),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (vm.cameraErrorMessage != null) ...[
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: vm.loadCameras,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(i18n.retryCamera),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // Top-left label pill
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.remove_red_eye_outlined,
                      color: Colors.white70,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Gemini Vision',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-right camera flip toggle pill
            Positioned(
              top: 14,
              right: 14,
              child: ValueListenableBuilder<bool>(
                valueListenable: vm.isCameraFlippedNotifier,
                builder: (context, isFlipped, _) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: vm.toggleCameraFlip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isFlipped
                              ? const Color(0xFF104626).withAlpha(220)
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFlipped
                                ? Colors.greenAccent.withAlpha(160)
                                : Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              color: isFlipped
                                  ? Colors.greenAccent
                                  : Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isFlipped
                                  ? i18n.flipToggleTextOn
                                  : i18n.flipToggleTextOff,
                              style: TextStyle(
                                color: isFlipped
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Subtle focus crosshair or corner guides
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(40),
                        Colors.transparent,
                        Colors.black.withAlpha(60),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Indicator pill (Sending frame)
            ValueListenableBuilder<bool>(
              valueListenable: vm.captureInFlightNotifier,
              builder: (context, inFlight, _) {
                if (!inFlight) return const SizedBox.shrink();
                return Positioned(
                  bottom: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.greenAccent,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
