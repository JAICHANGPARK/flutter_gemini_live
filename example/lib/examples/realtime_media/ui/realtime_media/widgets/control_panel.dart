import 'package:flutter/material.dart';

import '../view_models/realtime_media_view_model.dart';
import 'connection_buttons.dart';
import 'media_controls.dart';
import 'mode_selection.dart';
import 'section_divider.dart';

/// Left/top panel: mode selection, connect buttons and (once connected) the
/// media controls.
class ControlPanel extends StatelessWidget {
  final RealtimeMediaViewModel viewModel;
  final bool compact;

  const ControlPanel({
    super.key,
    required this.viewModel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModeSelection(viewModel: viewModel),
        const SectionDivider(),
        ConnectionButtons(viewModel: viewModel),
        if (viewModel.isConnected) ...[
          const SectionDivider(),
          MediaControls(viewModel: viewModel, compact: compact),
        ],
      ],
    );
  }
}
