import 'package:flutter/material.dart';

import '../../../domain/models/music_preset.dart';

/// One quick-preset chip.
class PresetChip extends StatelessWidget {
  const PresetChip({super.key, required this.preset, required this.onPressed});

  final MusicPreset preset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: const Color(0xFF2B3242),
      label: Text(
        preset.label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      onPressed: onPressed,
    );
  }
}
