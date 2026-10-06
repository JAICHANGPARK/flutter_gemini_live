import 'package:flutter/material.dart';

import '../view_models/live_api_view_model.dart';

class FeatureToggles extends StatelessWidget {
  const FeatureToggles({super.key, required this.viewModel});

  final LiveApiViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildToggle(
            'Realtime Config',
            viewModel.enableRealtimeConfig,
            (v) => viewModel.enableRealtimeConfig = v,
          ),
          _buildToggle(
            'Transcription',
            viewModel.enableTranscription,
            (v) => viewModel.enableTranscription = v,
          ),
          if (viewModel.enableTranscription)
            _buildToggle(
              'Smart Mode',
              viewModel.useSmartTranscription,
              (v) => viewModel.useSmartTranscription = v,
            ),
          _buildToggle(
            'Session Resume',
            viewModel.enableSessionResumption,
            (v) => viewModel.enableSessionResumption = v,
          ),
          _buildToggle(
            'Context Compression',
            viewModel.enableContextCompression,
            (v) => viewModel.enableContextCompression = v,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: viewModel.isConnected ? null : onChanged,
    );
  }
}
