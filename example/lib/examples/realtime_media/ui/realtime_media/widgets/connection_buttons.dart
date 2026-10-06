import 'package:flutter/material.dart';

import '../view_models/realtime_media_view_model.dart';

/// Connect / Disconnect buttons.
class ConnectionButtons extends StatelessWidget {
  final RealtimeMediaViewModel viewModel;

  const ConnectionButtons({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isConnected = viewModel.isConnected;
    final isConnecting = viewModel.isConnecting;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: isConnected ? null : viewModel.connect,
            icon: isConnecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isConnected
                        ? Icons.check_circle
                        : Icons.connect_without_contact,
                  ),
            label: Text(
              isConnecting
                  ? 'Connecting...'
                  : isConnected
                  ? 'Connected'
                  : 'Connect',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? Colors.green : null,
              foregroundColor: isConnected ? Colors.white : null,
              minimumSize: const Size(200, 48),
            ),
          ),
          OutlinedButton.icon(
            onPressed: isConnected ? viewModel.disconnect : null,
            icon: const Icon(Icons.link_off),
            label: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
