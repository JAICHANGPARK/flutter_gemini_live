import 'package:flutter/material.dart';

import '../view_models/music_studio_view_model.dart';

/// Collapsible stream log viewer.
class DiagnosticsPanel extends StatelessWidget {
  const DiagnosticsPanel({super.key, required this.viewModel});

  final MusicStudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final logs = viewModel.logs;
    return Card(
      color: const Color(0xFF14171F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: const Text(
          '📜 Diagnostics & Stream Logs',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet. Connect to start streaming.',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text(
                          logs[index],
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
