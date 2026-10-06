import 'package:flutter/material.dart';

import '../../../domain/models/youtube_preset.dart';

/// Wrap of preset video chips.
class PresetsRow extends StatelessWidget {
  const PresetsRow({
    super.key,
    required this.currentVideoId,
    required this.onSelect,
  });

  final String currentVideoId;
  final void Function(YouTubePreset preset) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 비디오 프리셋:',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: kYouTubePresets.map((preset) {
            final isSelected = currentVideoId == preset.videoId;
            return ChoiceChip(
              label: Text(preset.title),
              selected: isSelected,
              selectedColor: Colors.cyanAccent.shade700,
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => onSelect(preset),
            );
          }).toList(),
        ),
      ],
    );
  }
}
