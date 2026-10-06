import 'package:flutter/material.dart';

import '../view_models/realtime_media_view_model.dart';

/// Automatic / manual activity detection selector.
class ModeSelection extends StatelessWidget {
  final RealtimeMediaViewModel viewModel;

  const ModeSelection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Detection Mode:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Automatic'),
                icon: Icon(Icons.auto_mode),
              ),
              ButtonSegment(
                value: true,
                label: Text('Manual'),
                icon: Icon(Icons.touch_app),
              ),
            ],
            selected: {viewModel.manualActivityMode},
            onSelectionChanged: viewModel.isConnected
                ? null
                : (selected) {
                    viewModel.manualActivityMode = selected.first;
                  },
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.manualActivityMode
                ? 'Manual mode: live camera + voice starts an activity automatically, and you can still end it yourself.'
                : 'Auto mode: microphone audio streams continuously, and camera frames upload only while speech is detected.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
