import 'package:flutter/material.dart';

import '../view_models/realtime_media_view_model.dart';
import 'camera_voice_card.dart';

/// Camera + voice card, realtime text field, activity toggle and the manual
/// send buttons (shown only while connected).
class MediaControls extends StatelessWidget {
  final RealtimeMediaViewModel viewModel;
  final bool compact;

  const MediaControls({
    super.key,
    required this.viewModel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final isActivityActive = viewModel.isActivityActive;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          CameraVoiceCard(viewModel: viewModel, compact: compact),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Send realtime text...',
                    prefixIcon: Icon(Icons.text_fields),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: viewModel.sendRealtimeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (viewModel.manualActivityMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: viewModel.toggleActivity,
                  icon: Icon(isActivityActive ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    isActivityActive ? 'End Activity' : 'Start Activity',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActivityActive
                        ? Colors.red
                        : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          if (viewModel.manualActivityMode) const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: viewModel.sendAudioStreamEnd,
                icon: const Icon(Icons.stop_circle),
                label: const Text('Audio End'),
              ),
              ElevatedButton.icon(
                onPressed: viewModel.isSendingVideo
                    ? null
                    : viewModel.pickAndSendImage,
                icon: viewModel.isSendingVideo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image),
                label: const Text('Send Image'),
              ),
              ElevatedButton.icon(
                onPressed: viewModel.sendMediaChunks,
                icon: const Icon(Icons.folder_zip),
                label: const Text('Media Chunks'),
              ),
              ElevatedButton.icon(
                onPressed: viewModel.sendCombinedRealtimeInput,
                icon: const Icon(Icons.merge_type),
                label: const Text('Frame + Prompt'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
