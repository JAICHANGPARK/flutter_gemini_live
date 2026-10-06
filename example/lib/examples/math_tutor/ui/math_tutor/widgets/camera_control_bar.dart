import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

import '../math_tutor_i18n.dart';
import '../view_models/math_tutor_view_model.dart';

/// Pill-shaped HUD under the camera: flash, gallery, snap, auto-scan, mic,
/// switch camera, expand and notes toggles.
class CameraControlBar extends StatelessWidget {
  const CameraControlBar({super.key, required this.viewModel});

  final MathTutorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final i18n = MathTutorI18n(AppLanguageController.instance.currentLanguage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flash toggle
            IconButton(
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              icon: Icon(
                vm.isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: vm.isFlashOn ? Colors.amberAccent : Colors.white70,
              ),
              tooltip: 'Flash',
              onPressed: vm.toggleFlash,
            ),
            const SizedBox(width: 4),

            // Gallery Image Picker Button
            IconButton(
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.photo_library_rounded,
                color: Colors.amberAccent,
              ),
              tooltip: 'Gallery',
              onPressed: vm.pickAndSendImage,
            ),
            const SizedBox(width: 4),

            // Manual Snap & Solve Shutter
            ElevatedButton.icon(
              onPressed: () => vm.captureAndSendFrame(isManualSnap: true),
              icon: const Icon(Icons.camera_alt_rounded, size: 16),
              label: Text(
                '📸 ${i18n.btnScanSolve}',
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Auto stream toggle
            IconButton(
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              icon: Icon(
                vm.isAutoScanEnabled
                    ? Icons.motion_photos_on_rounded
                    : Icons.motion_photos_off_rounded,
                color: vm.isAutoScanEnabled
                    ? Colors.greenAccent
                    : Colors.white38,
              ),
              tooltip: i18n.btnAutoScan,
              onPressed: vm.toggleAutoScan,
            ),
            const SizedBox(width: 4),

            // Mic toggle with real-time volume level meter
            InkWell(
              onTap: vm.toggleMic,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: vm.isMicMuted
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: vm.isMicMuted ? Colors.redAccent : Colors.white24,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vm.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      size: 16,
                      color: vm.isMicMuted
                          ? Colors.redAccent
                          : Colors.cyanAccent,
                    ),
                    const SizedBox(width: 4),
                    // Live volume bar meter
                    ValueListenableBuilder<double>(
                      valueListenable: vm.liveMicVolumeNotifier,
                      builder: (context, vol, _) {
                        return Row(
                          children: List.generate(4, (index) {
                            final threshold = (index + 1) * 0.18;
                            final active = !vm.isMicMuted && vol >= threshold;
                            return Container(
                              width: 2.5,
                              height: 4 + (index * 2.5),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 0.8,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.greenAccent
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Switch Camera
            IconButton(
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.flip_camera_ios_rounded,
                color: Colors.white70,
              ),
              tooltip: 'Switch Camera',
              onPressed: vm.toggleCamera,
            ),
            const SizedBox(width: 4),

            // Camera Size Toggle (확대/원래대로)
            IconButton(
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              icon: Icon(
                vm.isCameraExpanded
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                color: vm.isCameraExpanded
                    ? Colors.amberAccent
                    : Colors.white70,
              ),
              tooltip: vm.isCameraExpanded ? '축소' : '카메라 확대',
              onPressed: vm.toggleCameraExpanded,
            ),
            const SizedBox(width: 4),

            // Bottom sheet toggle (풀이 노트 보기/숨기기)
            IconButton(
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              icon: Icon(
                vm.isBottomSheetVisible
                    ? Icons.vertical_align_bottom_rounded
                    : Icons.vertical_align_top_rounded,
                color: vm.isBottomSheetVisible
                    ? Colors.amberAccent
                    : Colors.white70,
              ),
              tooltip: vm.isBottomSheetVisible ? '노트 접기/숨기기' : '풀이 노트 열기',
              onPressed: vm.toggleBottomSheet,
            ),
          ],
        ),
      ),
    );
  }
}
