import 'package:flutter/material.dart';

import 'view_models/function_calling_view_model.dart';
import 'widgets/function_info_card.dart';
import 'widgets/input_area.dart';
import 'widgets/message_bubble.dart';

/// Demo page for function calling (tool calling) feature
class FunctionCallingDemoPage extends StatefulWidget {
  const FunctionCallingDemoPage({super.key});

  @override
  State<FunctionCallingDemoPage> createState() =>
      _FunctionCallingDemoPageState();
}

class _FunctionCallingDemoPageState extends State<FunctionCallingDemoPage> {
  late final FunctionCallingViewModel _viewModel;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = FunctionCallingViewModel();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _submitInput() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _viewModel.sendText(text);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Function Calling Demo'),
            actions: [
              if (vm.pendingFunctionCalls.isNotEmpty)
                Badge(
                  label: Text('${vm.pendingFunctionCalls.length}'),
                  child: const Icon(Icons.pending_actions),
                ),
            ],
          ),
          body: Column(
            children: [
              // Info card
              const FunctionInfoCard(),

              // Connection button
              if (!vm.isConnected)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: vm.isConnecting ? null : vm.connect,
                    icon: vm.isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.connect_without_contact),
                    label: Text(vm.isConnecting ? 'Connecting...' : 'Connect'),
                  ),
                ),

              // Message list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: vm.messages.length,
                  itemBuilder: (context, index) {
                    final msg = vm.messages[index];
                    return MessageBubble(msg: msg);
                  },
                ),
              ),

              // Input area
              if (vm.isConnected)
                InputArea(
                  controller: _inputController,
                  onSubmit: _submitInput,
                  onQuickPrompt: vm.sendText,
                ),
            ],
          ),
        );
      },
    );
  }
}
