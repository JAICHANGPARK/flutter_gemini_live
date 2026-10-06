import 'package:example/app_settings_dialog.dart';
import 'package:flutter/material.dart';

import '../../domain/models/connection_status.dart';
import 'view_models/chat_view_model.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_message_list.dart';

/// The main chat page widget.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatPage> {
  late final ChatViewModel _viewModel;
  final TextEditingController _textController =
      TextEditingController(); // Controller for the text input field.

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel()
      ..onNotice = _showNotice
      ..onClearInput = _textController.clear;
    // Start the connection process and subscribe to the recorder state.
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _textController.dispose(); // Dispose of the text controller.
    super.dispose();
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openApiKeySettings() async {
    final changed = await AppSettingsDialog.show(context);
    if (changed == true && mounted) {
      _viewModel.connectToLiveAPI();
    }
  }

  // --- UI Widget Builder ---
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        return Scaffold(
          appBar: ChatAppBar(
            viewModel: vm,
            onOpenSettings: _openApiKeySettings,
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // The main chat area.
                Expanded(child: ChatMessageList(viewModel: vm)),
                // Show a progress bar while the model is replying.
                if (vm.isReplying) const LinearProgressIndicator(),
                const Divider(height: 1.0),
                // If disconnected, show a button to reconnect.
                if (vm.connectionStatus == ConnectionStatus.disconnected)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reconnect"),
                      onPressed: vm.connectToLiveAPI,
                    ),
                  ),
                // If connected, show the message input composer.
                if (vm.connectionStatus == ConnectionStatus.connected)
                  ChatComposer(
                    viewModel: vm,
                    textController: _textController,
                    onSend: () => vm.sendMessage(_textController.text),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
