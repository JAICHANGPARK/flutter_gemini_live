import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import 'view_models/live_api_view_model.dart';
import 'widgets/action_buttons.dart';
import 'widgets/connection_button.dart';
import 'widgets/feature_toggles.dart';
import 'widgets/log_list.dart';
import 'widgets/text_input_dialog.dart';

/// A comprehensive demo page showcasing all new Gemini Live API features
class LiveAPIDemoPage extends StatefulWidget {
  const LiveAPIDemoPage({super.key});

  @override
  State<LiveAPIDemoPage> createState() => _LiveAPIDemoPageState();
}

class _LiveAPIDemoPageState extends State<LiveAPIDemoPage> {
  late final LiveApiViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LiveApiViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Live API Features Demo'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GeminiLiveStatusBadge.fromFlags(
                  isConnected: vm.isConnected,
                  isConnecting: vm.isConnecting,
                  interactionStatus: vm.interactionStatus,
                ),
              ),
              if (vm.isConnected)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: vm.closeConnection,
                  tooltip: 'Close connection',
                ),
            ],
          ),
          body: Column(
            children: [
              // Feature toggles
              FeatureToggles(viewModel: vm),
              const Divider(),
              // Connection button
              ConnectionButton(
                isConnected: vm.isConnected,
                isConnecting: vm.isConnecting,
                onConnect: vm.connect,
              ),
              const Divider(),
              // Action buttons
              if (vm.isConnected)
                ActionButtons(
                  onSendText: _showTextInputDialog,
                  onSendClientContent: vm.sendClientContent,
                  onSendRealtimeInput: vm.sendRealtimeInput,
                  onToggleActivity: vm.toggleActivity,
                ),
              const Divider(),
              // Logs
              Expanded(child: LogList(logs: vm.logs)),
            ],
          ),
        );
      },
    );
  }

  void _showTextInputDialog() {
    showTextInputDialog(context, _viewModel.sendText);
  }
}
