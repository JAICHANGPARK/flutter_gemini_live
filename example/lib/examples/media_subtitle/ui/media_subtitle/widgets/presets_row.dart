import 'package:flutter/material.dart';

import '../../../domain/models/youtube_preset.dart';
import '../media_subtitle_i18n.dart';

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
    final i18n = MediaSubtitleI18n.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.recommendedVideoPresets,
          style: const TextStyle(
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
              label: Text(
                i18n.presetTitle(preset.videoId, preset.title),
                overflow: TextOverflow.ellipsis,
              ),
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
