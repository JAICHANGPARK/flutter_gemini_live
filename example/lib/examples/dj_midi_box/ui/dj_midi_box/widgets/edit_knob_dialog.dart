import 'package:flutter/material.dart';

import '../../../domain/models/midi_knob_data.dart';
import '../dj_midi_box_i18n.dart';
import '../view_models/dj_midi_box_view_model.dart';

/// Long-press editor for a dial's label and prompt.
void showEditKnobDialog(
  BuildContext context,
  DjMidiBoxViewModel viewModel,
  MidiKnobData knob,
) {
  final i18n = DjMidiBoxI18n.current;
  final titleController = TextEditingController(text: knob.title);
  final promptController = TextEditingController(text: knob.prompt);

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1438),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          i18n.editKnobTitle(knob.title),
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
              decoration: InputDecoration(
                labelText: i18n.labelBadgeTitleField,
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2D1F50),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: promptController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: i18n.musicalPromptField,
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2D1F50),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              i18n.cancelButton,
              style: const TextStyle(color: Colors.white54),
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
            child: Text(i18n.saveButton),
          ),
        ],
      );
    },
  );
}
