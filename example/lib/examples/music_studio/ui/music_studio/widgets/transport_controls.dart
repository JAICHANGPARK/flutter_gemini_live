import 'package:flutter/material.dart';

import '../view_models/music_studio_view_model.dart';

/// Play / Pause / Stop / Reset Context transport row.
class TransportControls extends StatelessWidget {
  const TransportControls({super.key, required this.viewModel});

  final MusicStudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isConnected = viewModel.isConnected;
    final isPlaying = viewModel.isPlaying;
    return Card(
      color: const Color(0xFF1E222D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Play
            IconButton.filled(
              iconSize: 28,
              onPressed: isConnected && !isPlaying ? viewModel.play : null,
              icon: const Icon(Icons.play_arrow_rounded),
              tooltip: 'Start / Resume Generation',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                disabledBackgroundColor: Colors.white10,
              ),
            ),
            // Pause
            IconButton.filled(
              iconSize: 28,
              onPressed: isConnected && isPlaying ? viewModel.pause : null,
              icon: const Icon(Icons.pause_rounded),
              tooltip: 'Pause Stream',
              style: IconButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                disabledBackgroundColor: Colors.white10,
              ),
            ),
            // Stop
            IconButton.filled(
              iconSize: 28,
              onPressed: isConnected ? viewModel.stop : null,
              icon: const Icon(Icons.stop_rounded),
              tooltip: 'Stop & Reset Context',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                disabledBackgroundColor: Colors.white10,
              ),
            ),
            // Reset Context (Seamless)
            OutlinedButton.icon(
              onPressed: isConnected ? viewModel.resetContext : null,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Context'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
                side: BorderSide(
                  color: isConnected ? Colors.cyanAccent : Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
