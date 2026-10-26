import 'package:flutter/material.dart';

import '../live_api_i18n.dart';

/// Shows the "Send Message" dialog; [onSend] is called with non-empty text
/// before the dialog is popped.
void showTextInputDialog(BuildContext context, void Function(String) onSend) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) {
      final t = LiveApiI18n.current;
      return AlertDialog(
        title: Text(t.sendMessageTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: t.enterYourMessageHint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancelBtn),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSend(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(t.sendBtn),
          ),
        ],
      );
    },
  );
}
