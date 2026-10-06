import 'package:flutter/material.dart';

/// Master transport: connect toggle, play / pause, stop / cue, hard drop.
class MasterTransportBar extends StatelessWidget {
  final bool isConnecting;
  final bool isConnected;
  final bool isPlaying;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final VoidCallback onResetContext;

  const MasterTransportBar({
    super.key,
    required this.isConnecting,
    required this.isConnected,
    required this.isPlaying,
    required this.onConnect,
    required this.onDisconnect,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
    required this.onResetContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF242C3C)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          // Connection Toggle Button
          ElevatedButton.icon(
            onPressed: isConnecting
                ? null
                : (isConnected ? onDisconnect : onConnect),
            icon: Icon(
              isConnected ? Icons.link_off : Icons.power_settings_new,
              size: 18,
            ),
            label: Text(
              isConnecting
                  ? 'CONNECTING...'
                  : (isConnected ? 'DISCONNECT' : 'CONNECT CONSOLE'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected
                  ? Colors.red.shade800
                  : Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          // Master Play / Pause / Drop Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: isConnected ? (isPlaying ? onPause : onPlay) : null,
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 20,
                ),
                label: Text(isPlaying ? 'PAUSE' : 'PLAY MASTER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: isConnected ? onStop : null,
                icon: const Icon(Icons.stop, size: 20),
                label: const Text('STOP / CUE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: isConnected ? onResetContext : null,
                icon: const Icon(Icons.bolt, size: 20),
                label: const Text('HARD DROP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
