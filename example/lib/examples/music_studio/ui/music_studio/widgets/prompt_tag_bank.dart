import 'package:flutter/material.dart';

/// Expandable keyword palette (official Lyria guide vocabularies).
class PromptTagBank extends StatelessWidget {
  const PromptTagBank({super.key, required this.onTag});

  final ValueChanged<String> onTag;

  Widget _tagChip(String label, Color color) {
    return ActionChip(
      backgroundColor: color.withAlpha(50),
      side: BorderSide(color: color.withAlpha(120)),
      avatar: Icon(Icons.add, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: () => onTag(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: const Row(
        children: [
          Icon(Icons.library_music_rounded, color: Colors.cyanAccent, size: 16),
          SizedBox(width: 6),
          Text(
            'Prompt DJ Tag Bank (Official Guide Vocabularies)',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Genres
            _tagChip('Minimal Techno', Colors.indigo),
            _tagChip('Deep House', Colors.indigo),
            _tagChip('Synthpop', Colors.indigo),
            _tagChip('Lo-Fi Hip Hop', Colors.indigo),
            _tagChip('Afrobeat', Colors.indigo),
            _tagChip('Bossa Nova', Colors.indigo),
            _tagChip('Acid Jazz', Colors.indigo),
            _tagChip('Drum & Bass', Colors.indigo),
            // Synths & Keys
            _tagChip('Moog Oscillations', Colors.deepPurple),
            _tagChip('303 Acid Bass', Colors.deepPurple),
            _tagChip('Rhodes Piano', Colors.deepPurple),
            _tagChip('Mellotron', Colors.deepPurple),
            _tagChip('Synth Pads', Colors.deepPurple),
            _tagChip('Dirty Synths', Colors.deepPurple),
            // Drums & Bass
            _tagChip('TR-909 Drum Machine', Colors.teal),
            _tagChip('808 Hip Hop Beat', Colors.teal),
            _tagChip('Funk Drums', Colors.teal),
            _tagChip('Boomy Bass', Colors.teal),
            _tagChip('Tabla', Colors.teal),
            // Acoustic & Textures
            _tagChip('Alto Saxophone', Colors.orange),
            _tagChip('Warm Acoustic Guitar', Colors.orange),
            _tagChip('Cello', Colors.orange),
            _tagChip('Harmonica', Colors.orange),
            _tagChip('Dusty vinyl crackle', Colors.blueGrey),
            _tagChip('Distorted 303 bassline', Colors.blueGrey),
            _tagChip('Atmospheric synths', Colors.blueGrey),
            _tagChip('Subtle sub bass', Colors.blueGrey),
          ],
        ),
      ],
    );
  }
}
