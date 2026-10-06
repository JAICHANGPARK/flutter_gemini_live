import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    required this.onSendText,
    required this.onSendClientContent,
    required this.onSendRealtimeInput,
    required this.onToggleActivity,
  });

  final VoidCallback onSendText;
  final VoidCallback onSendClientContent;
  final VoidCallback onSendRealtimeInput;
  final void Function(bool isStart) onToggleActivity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ElevatedButton(
              onPressed: () => onSendText(),
              child: const Text('Send Text'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSendClientContent,
              child: const Text('Multi-turn'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSendRealtimeInput,
              child: const Text('Realtime Input'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => onToggleActivity(true),
              child: const Text('Activity Start'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => onToggleActivity(false),
              child: const Text('Activity End'),
            ),
          ],
        ),
      ),
    );
  }
}
