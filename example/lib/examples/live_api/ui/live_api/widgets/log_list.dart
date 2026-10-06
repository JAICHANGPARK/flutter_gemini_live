import 'package:flutter/material.dart';

import '../../../domain/models/log_entry.dart';

class LogList extends StatelessWidget {
  const LogList({super.key, required this.logs});

  final List<LogEntry> logs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          dense: true,
          leading: _buildLogIcon(log.type),
          title: Text(
            log.message,
            style: TextStyle(fontSize: 13, color: _getLogColor(log.type)),
          ),
          subtitle: Text(
            '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 11),
          ),
        );
      },
    );
  }

  Widget _buildLogIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'TEXT':
        icon = Icons.chat_bubble;
        color = Colors.blue;
        break;
      case 'AUDIO':
        icon = Icons.audiotrack;
        color = Colors.purple;
        break;
      case 'TRANSCRIPTION':
        icon = Icons.transcribe;
        color = Colors.teal;
        break;
      case 'VAD':
        icon = Icons.mic;
        color = Colors.orange;
        break;
      case 'SESSION':
        icon = Icons.sync;
        color = Colors.indigo;
        break;
      case 'USAGE':
        icon = Icons.analytics;
        color = Colors.grey;
        break;
      case 'ERROR':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'WARNING':
        icon = Icons.warning;
        color = Colors.amber;
        break;
      case 'STATUS':
        icon = Icons.bolt;
        color = Colors.amber.shade700;
        break;
      case 'CONNECTION':
        icon = Icons.link;
        color = Colors.green;
        break;
      case 'SYSTEM':
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.amber.shade800;
      case 'TEXT':
        return Colors.blue.shade800;
      default:
        return Colors.black87;
    }
  }
}
