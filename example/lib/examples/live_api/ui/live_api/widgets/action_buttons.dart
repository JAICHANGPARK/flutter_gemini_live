import 'package:flutter/material.dart';

import '../live_api_i18n.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    required this.onSendText,
    required this.onSendClientContent,
    required this.onSendRealtimeInput,
    required this.onToggleActivity,
    this.onSendContextUpdate,
  });

  final VoidCallback onSendText;
  final VoidCallback onSendClientContent;
  final VoidCallback onSendRealtimeInput;
  final void Function(bool isStart) onToggleActivity;
  final VoidCallback? onSendContextUpdate;

  @override
  Widget build(BuildContext context) {
    final t = LiveApiI18n.current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ElevatedButton(
              onPressed: () => onSendText(),
              child: Text(t.sendTextBtn),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSendClientContent,
              child: Text(t.multiTurnBtn),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSendRealtimeInput,
              child: Text(t.realtimeInputBtn),
            ),
            const SizedBox(width: 8),
            if (onSendContextUpdate != null) ...[
              ElevatedButton(
                onPressed: onSendContextUpdate,
                child: Text(t.contextUpdateBtn),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton(
              onPressed: () => onToggleActivity(true),
              child: Text(t.activityStartBtn),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => onToggleActivity(false),
              child: Text(t.activityEndBtn),
            ),
          ],
        ),
      ),
    );
  }
}
