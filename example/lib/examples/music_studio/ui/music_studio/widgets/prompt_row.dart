import 'package:flutter/material.dart';

import '../view_models/music_studio_view_model.dart';

/// One editable prompt: text field, weight slider and remove button.
class PromptRow extends StatelessWidget {
  const PromptRow({super.key, required this.viewModel, required this.index});

  final MusicStudioViewModel viewModel;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: viewModel.promptControllers[index],
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Prompt style, instrument, or vibe...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF262C38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weight: ${viewModel.promptWeights[index].toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: viewModel.promptWeights[index],
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    activeColor: Colors.purpleAccent,
                    onChanged: (val) => viewModel.setPromptWeight(index, val),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
            onPressed: () => viewModel.removePrompt(index),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
