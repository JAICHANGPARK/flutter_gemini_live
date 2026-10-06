import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../domain/models/music_studio_status.dart';
import '../view_models/music_studio_view_model.dart';

/// Model picker, connect / disconnect button, status line and stream metrics.
class ConnectionCard extends StatelessWidget {
  const ConnectionCard({super.key, required this.viewModel});

  final MusicStudioViewModel viewModel;

  static Color statusColor(MusicStudioStatus status) {
    switch (status) {
      case MusicStudioStatus.disconnected:
        return Colors.grey;
      case MusicStudioStatus.connecting:
        return Colors.orange;
      case MusicStudioStatus.connected:
        return Colors.teal;
      case MusicStudioStatus.failed:
        return Colors.red;
      case MusicStudioStatus.streaming:
        return Colors.greenAccent.shade700;
      case MusicStudioStatus.paused:
        return Colors.amber;
      case MusicStudioStatus.stopped:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = viewModel.isConnected;
    final isConnecting = viewModel.isConnecting;
    final color = statusColor(viewModel.status);
    return Card(
      color: const Color(0xFF1C2029),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: viewModel.selectedModel,
                    dropdownColor: const Color(0xFF242936),
                    decoration: const InputDecoration(
                      labelText: 'Lyria Live Model',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: LiveMusicModels.lyriaRealtimeExp,
                        child: Text(
                          'lyria-realtime-exp (Standard)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    onChanged: isConnected
                        ? null
                        : (val) {
                            if (val != null) {
                              viewModel.selectModel(val);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: isConnecting
                      ? null
                      : isConnected
                      ? viewModel.disconnect
                      : viewModel.connect,
                  icon: isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isConnected ? Icons.link_off : Icons.link),
                  label: Text(isConnected ? 'Disconnect' : 'Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected
                        ? Colors.red.shade700
                        : Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  viewModel.status.text,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  'Chunks: ${viewModel.receivedChunksCount} · ${(viewModel.totalBytesReceived / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
