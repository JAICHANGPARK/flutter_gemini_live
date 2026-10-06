import 'package:flutter/material.dart';

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
                _buildQuickPrompt('Weather in Seoul in celsius'),
                const SizedBox(width: 6),
                _buildQuickPrompt('Convert 120 USD to KRW'),
                const SizedBox(width: 6),
                _buildQuickPrompt('Find 3 ramen places in Tokyo'),
                const SizedBox(width: 6),
                _buildQuickPrompt(
                  'Remind me tomorrow 9am Asia/Seoul to submit weekly report',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText:
                        'Ask weather/time/fx conversion/place search/reminder...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
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
