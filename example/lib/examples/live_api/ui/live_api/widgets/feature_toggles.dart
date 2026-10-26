import 'package:flutter/material.dart';

import '../live_api_i18n.dart';
import '../view_models/live_api_view_model.dart';

class FeatureToggles extends StatelessWidget {
  const FeatureToggles({super.key, required this.viewModel});

  final LiveApiViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final t = LiveApiI18n.current;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildToggle(
            t.toggleRealtimeConfig,
            viewModel.enableRealtimeConfig,
            (v) => viewModel.enableRealtimeConfig = v,
          ),
          _buildToggle(
            t.toggleTranscription,
            viewModel.enableTranscription,
            (v) => viewModel.enableTranscription = v,
          ),
          if (viewModel.enableTranscription)
            _buildToggle(
              t.toggleSmartMode,
              viewModel.useSmartTranscription,
              (v) => viewModel.useSmartTranscription = v,
            ),
          _buildToggle(
            t.toggleSessionResume,
            viewModel.enableSessionResumption,
            (v) => viewModel.enableSessionResumption = v,
          ),
          _buildToggle(
            t.toggleContextCompression,
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
