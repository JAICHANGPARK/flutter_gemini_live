import 'package:flutter/material.dart';

import '../realtime_media_i18n.dart';
import '../view_models/realtime_media_view_model.dart';
import 'log_list.dart';
import 'section_divider.dart';

/// "Live Logs" header with entry count, followed by the log list.
class LogSection extends StatelessWidget {
  final RealtimeMediaViewModel viewModel;

  const LogSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final t = RealtimeMediaI18n.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.liveLogsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Chip(
                label: Text(t.entriesCount(viewModel.logs.length)),
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
