import 'package:flutter/material.dart';

import '../../../domain/music_presets.dart';
import '../view_models/music_studio_view_model.dart';
import 'crossfader_panel.dart';
import 'preset_chip.dart';
import 'prompt_row.dart';
import 'prompt_tag_bank.dart';

/// Steerable weighted prompts: presets, crossfader, tag bank, prompt rows.
class PromptsSection extends StatelessWidget {
  const PromptsSection({super.key, required this.viewModel});

  final MusicStudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C2029),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎛️ Steerable Weighted Prompts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => viewModel.addPrompt('', 0.5),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Prompt'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purpleAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Presets matching official Google Lyria guide
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < kMusicPresets.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    PresetChip(
                      preset: kMusicPresets[i],
                      onPressed: () => viewModel.applyPreset(kMusicPresets[i]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Prompt DJ Crossfader (A <-> B)
            if (viewModel.promptControllers.length >= 2) ...[
              CrossfaderPanel(viewModel: viewModel),
              const SizedBox(height: 12),
            ],

            // Prompt DJ Tag Bank (Keyword Palette)
            PromptTagBank(onTag: viewModel.addTagToPrompt),
            const SizedBox(height: 8),

            // Dynamic Prompt Rows
            ...List.generate(viewModel.promptControllers.length, (index) {
              return PromptRow(viewModel: viewModel, index: index);
            }),

            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: viewModel.isConnected
                    ? viewModel.sendWeightedPrompts
                    : null,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Update Steerable Prompts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
