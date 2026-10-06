import 'package:flutter/material.dart';

import '../../../domain/models/midi_knob_data.dart';
import '../view_models/dj_midi_box_view_model.dart';

/// Long-press editor for a dial's label and prompt.
void showEditKnobDialog(
  BuildContext context,
  DjMidiBoxViewModel viewModel,
  MidiKnobData knob,
) {
  final titleController = TextEditingController(text: knob.title);
  final promptController = TextEditingController(text: knob.prompt);

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1438),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Knob: ${knob.title}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Label Badge Title',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF2D1F50),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: promptController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Musical Description Prompt',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF2D1F50),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: knob.color,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              viewModel.saveKnobEdit(
                knob,
                titleController.text.trim(),
                promptController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      );
    },
  );
}
