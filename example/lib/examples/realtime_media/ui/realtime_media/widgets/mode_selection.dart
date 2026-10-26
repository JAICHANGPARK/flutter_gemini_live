import 'package:flutter/material.dart';

import '../realtime_media_i18n.dart';
import '../view_models/realtime_media_view_model.dart';

/// Automatic / manual activity detection selector.
class ModeSelection extends StatelessWidget {
  final RealtimeMediaViewModel viewModel;

  const ModeSelection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final t = RealtimeMediaI18n.current;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.modeSelectionTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(t.modeAutomatic),
                icon: const Icon(Icons.auto_mode),
              ),
              ButtonSegment(
                value: true,
                label: Text(t.modeManual),
                icon: const Icon(Icons.touch_app),
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
            viewModel.manualActivityMode ? t.modeManualDesc : t.modeAutoDesc,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
