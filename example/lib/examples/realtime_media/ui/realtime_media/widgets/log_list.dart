import 'package:flutter/material.dart';

import '../view_models/realtime_media_view_model.dart';

/// Scrolling list of log cards, newest first.
class LogList extends StatelessWidget {
  final RealtimeMediaViewModel viewModel;

  const LogList({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final logs = viewModel.logs;
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: _getLogColor(log.type),
          child: ListTile(
            dense: true,
            leading: Icon(_getLogIcon(log.type), size: 20),
            title: Text(log.message, style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        );
      },
    );
  }

  static IconData _getLogIcon(String type) {
    switch (type) {
      case 'TEXT':
        return Icons.chat;
      case 'TRANSCRIPTION':
        return Icons.transcribe;
      case 'VAD':
        return Icons.mic;
      case 'VIDEO':
        return Icons.video_call;
      case 'MEDIA':
        return Icons.perm_media;
      case 'ACTIVITY':
        return Icons.touch_app;
      case 'AUDIO':
        return Icons.audiotrack;
      case 'ERROR':
        return Icons.error;
      case 'CONNECTION':
        return Icons.link;
      default:
        return Icons.info;
    }
  }

  static Color? _getLogColor(String type) {
    switch (type) {
      case 'TEXT':
        return Colors.blue.shade50;
      case 'TRANSCRIPTION':
        return Colors.teal.shade50;
      case 'VAD':
        return Colors.orange.shade50;
      case 'VIDEO':
        return Colors.purple.shade50;
      case 'ACTIVITY':
        return Colors.green.shade50;
      case 'ERROR':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }
}
