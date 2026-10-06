import 'package:flutter/material.dart';

import '../view_models/realtime_media_view_model.dart';
import 'log_list.dart';
import 'section_divider.dart';

/// "Live Logs" header with entry count, followed by the log list.
class LogSection extends StatelessWidget {
  final RealtimeMediaViewModel viewModel;

  const LogSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Live Logs',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Chip(
                label: Text('${viewModel.logs.length} entries'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const SectionDivider(),
        Expanded(child: LogList(viewModel: viewModel)),
      ],
    );
  }
}
