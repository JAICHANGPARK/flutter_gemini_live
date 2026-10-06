import 'package:example/scrollable_app_bar_actions.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../domain/models/connection_status.dart';
import '../../../domain/models/response_mode.dart';
import '../view_models/chat_view_model.dart';

/// Screen app bar: title, chat mode menu, settings, usage and status badges.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    required this.viewModel,
    required this.onOpenSettings,
  });

  final ChatViewModel viewModel;
  final VoidCallback onOpenSettings;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return AppBar(
      title: const Text('Gemini Live API'),
      actions: [
        ScrollableAppBarActions(
          children: [
            PopupMenuButton<ResponseMode>(
              tooltip: 'Chat mode',
              onSelected: vm.selectMode,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: ResponseMode.text,
                  child: Text('Text Mode'),
                ),
                PopupMenuItem(
                  value: ResponseMode.audio,
                  child: Text('Voice Mode'),
                ),
              ],
              icon: Icon(
                vm.voiceModeEnabled ? Icons.graphic_eq : Icons.text_fields,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'API Key & Model Settings',
              onPressed: onOpenSettings,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GeminiLiveUsageBadge(tracker: vm.usageTracker),
            ),
            // A visual indicator for the connection status.
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GeminiLiveStatusBadge.fromFlags(
                isConnected: vm.connectionStatus == ConnectionStatus.connected,
                isConnecting:
                    vm.connectionStatus == ConnectionStatus.connecting,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
