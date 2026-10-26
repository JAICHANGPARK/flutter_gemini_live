import 'package:flutter/material.dart';

import '../live_api_i18n.dart';

class ConnectionButton extends StatelessWidget {
  const ConnectionButton({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.onConnect,
  });

  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final t = LiveApiI18n.current;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: isConnected ? null : onConnect,
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
              ? t.connecting
              : isConnected
              ? t.connected
              : t.connectToLiveApi,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? Colors.green : null,
          foregroundColor: isConnected ? Colors.white : null,
        ),
      ),
    );
  }
}
