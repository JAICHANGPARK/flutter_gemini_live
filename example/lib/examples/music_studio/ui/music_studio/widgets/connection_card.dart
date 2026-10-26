import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../domain/models/music_studio_status.dart';
import '../music_studio_i18n.dart';
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
    final i18n = MusicStudioI18n.current;
    final isConnected = viewModel.isConnected;
    final isConnecting = viewModel.isConnecting;
    final color = statusColor(viewModel.status);
    return Card(
      color: const Color(0xFF1C2029),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 320;
            final dropdown = DropdownButtonFormField<String>(
              initialValue: viewModel.selectedModel,
              isExpanded: true,
              dropdownColor: const Color(0xFF242936),
              decoration: InputDecoration(
                labelText: i18n.modelLabel,
                labelStyle: const TextStyle(color: Colors.white70),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: LiveMusicModels.lyriaRealtimeExp,
                  child: Text(
                    i18n.modelStandardOption,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
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
            );
            final connectBtn = ElevatedButton.icon(
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
              label: Text(
                isConnected ? i18n.disconnectButton : i18n.connectButton,
              ),
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
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCompact) ...[
                  dropdown,
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: connectBtn),
                ] else
                  Row(
                    children: [
                      Expanded(child: dropdown),
                      const SizedBox(width: 12),
                      connectBtn,
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
                    Expanded(
                      child: Text(
                        i18n.statusText(viewModel.status),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        i18n.streamMetrics(
                          viewModel.receivedChunksCount,
                          (viewModel.totalBytesReceived / 1024).toStringAsFixed(
                            1,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
