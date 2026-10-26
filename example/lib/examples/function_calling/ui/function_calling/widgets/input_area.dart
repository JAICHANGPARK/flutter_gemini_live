import 'package:flutter/material.dart';

import '../function_calling_i18n.dart';

class InputArea extends StatelessWidget {
  const InputArea({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.onQuickPrompt,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final void Function(String prompt) onQuickPrompt;

  @override
  Widget build(BuildContext context) {
    final t = FunctionCallingI18n.current;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickPrompt(t.quickPromptWeather),
                const SizedBox(width: 6),
                _buildQuickPrompt(t.quickPromptCurrency),
                const SizedBox(width: 6),
                _buildQuickPrompt(t.quickPromptPlaces),
                const SizedBox(width: 6),
                _buildQuickPrompt(t.quickPromptReminder),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: t.inputHint,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onSubmit,
                tooltip: t.sendTooltip,
                icon: const Icon(Icons.send),
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompt(String prompt) {
    return ActionChip(
      label: Text(prompt, style: const TextStyle(fontSize: 12)),
      onPressed: () => onQuickPrompt(prompt),
    );
  }
}
