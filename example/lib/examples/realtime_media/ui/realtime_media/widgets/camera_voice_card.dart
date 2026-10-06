import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../domain/camera_text.dart';
import '../view_models/realtime_media_view_model.dart';
import 'camera_preview_view.dart';
import 'stat_chip.dart';

/// Live camera preview, stream controls and stream stats.
class CameraVoiceCard extends StatelessWidget {
  final RealtimeMediaViewModel viewModel;
  final bool compact;

  const CameraVoiceCard({
    super.key,
    required this.viewModel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final previewHeight = compact
                ? (maxWidth * 0.5).clamp(180.0, 240.0).toDouble()
                : (maxWidth / (4 / 3)).clamp(220.0, 360.0).toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.podcasts),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Live Camera + Voice',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Chip(
                      label: Text(
                        vm.isStreamingAudio
                            ? vm.cameraInputActive
                                  ? 'Audio + Video'
                                  : 'Audio Only'
                            : 'Idle',
                      ),
                      backgroundColor:
                          (vm.isStreamingAudio || vm.isStreamingCamera)
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  vm.manualActivityMode
                      ? 'This example keeps a live camera preview on screen, uploads a JPEG snapshot every 1.2 seconds while the activity is active, and streams microphone PCM chunks to the same Live session.'
                      : 'This example keeps a live camera preview on screen, streams microphone PCM chunks continuously, and uploads JPEG snapshots only while speech is being detected.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: previewHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CameraPreviewView(viewModel: vm),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: vm.isCameraInitializing
                          ? null
                          : () => vm.ensureCameraReady(),
                      icon: vm.isCameraInitializing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.videocam),
                      label: Text(
                        vm.cameraReady ? 'Refresh Camera' : 'Initialize Camera',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: vm.availableCameras.length > 1
                          ? vm.switchCamera
                          : null,
                      icon: const Icon(Icons.cameraswitch),
                      label: const Text('Switch Camera'),
                    ),
                    FilledButton.icon(
                      onPressed: (!vm.isConnected || vm.isStreamingAudio)
                          ? null
                          : vm.startLiveMultimodalStream,
                      icon: const Icon(Icons.play_circle_fill),
                      label: const Text('Start Camera + Voice'),
                    ),
                    OutlinedButton.icon(
                      onPressed: (vm.isStreamingAudio || vm.isStreamingCamera)
                          ? vm.stopLiveMultimodalStream
                          : null,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop Stream'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatChip(
                      Icons.mic,
                      vm.isStreamingAudio ? 'Mic on' : 'Mic idle',
                    ),
                    if (vm.isStreamingAudio)
                      GeminiLiveVoiceIndicator(
                        isSpeaking: vm.cameraInputActive,
                        barCount: 5,
                        height: 24,
                        color: Colors.blueAccent,
                      ),
                    StatChip(Icons.image, 'Frames ${vm.videoFramesSent}'),
                    StatChip(
                      Icons.graphic_eq,
                      'Audio chunks ${vm.audioChunksSent}',
                    ),
                    if (vm.availableCameras.isNotEmpty)
                      StatChip(
                        Icons.camera_front,
                        cameraLabel(
                          vm.availableCameras[vm.selectedCameraIndex],
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
