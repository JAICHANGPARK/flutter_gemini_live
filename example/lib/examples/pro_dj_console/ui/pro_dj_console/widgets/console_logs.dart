import 'package:flutter/material.dart';

/// Expandable diagnostics terminal showing the latest console log lines.
class ConsoleLogs extends StatelessWidget {
  final List<String> consoleLogs;

  const ConsoleLogs({super.key, required this.consoleLogs});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF10131A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          '🎛️ DJ CONSOLE DIAGNOSTIC TERMINAL',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            color: Colors.black45,
            child: ListView.builder(
              reverse: true,
              itemCount: consoleLogs.length,
              itemBuilder: (context, idx) {
                return Text(
                  consoleLogs[idx],
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontFamily: 'monospace',
                    fontSize: 11,
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
