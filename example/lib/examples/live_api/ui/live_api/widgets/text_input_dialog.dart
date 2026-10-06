import 'package:flutter/material.dart';

/// Shows the "Send Message" dialog; [onSend] is called with non-empty text
/// before the dialog is popped.
void showTextInputDialog(BuildContext context, void Function(String) onSend) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Send Message'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Enter your message'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              onSend(controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
}
