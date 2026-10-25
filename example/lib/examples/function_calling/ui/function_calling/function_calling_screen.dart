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
              if (vm.isConnected)
                IconButton(
                  icon: Icon(
                    vm.toolsEnabled ? Icons.build : Icons.build_circle_outlined,
                  ),
                  tooltip: vm.toolsEnabled
                      ? 'Clear tools in-session (sendContextUpdate)'
                      : 'Restore tools in-session (sendContextUpdate)',
                  onPressed: vm.toggleToolsInSession,
                ),
              if (vm.pendingFunctionCalls.isNotEmpty)
                Badge(
                  label: Text('${vm.pendingFunctionCalls.length}'),
                  child: const Icon(Icons.pending_actions),
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Info card (constrained so it scrolls cleanly on compact/mobile screens)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.65,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FunctionInfoCard(),
                          if (!vm.isConnected)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: vm.isConnecting ? null : vm.connect,
                                icon: vm.isConnecting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.connect_without_contact),
                                label: Text(
                                  vm.isConnecting
                                      ? 'Connecting...'
                                      : 'Connect',
                                ),
                              ),
                            ),
                        ],
                      ),
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
              );
            },
          ),
        );
      },
    );
  }
}
