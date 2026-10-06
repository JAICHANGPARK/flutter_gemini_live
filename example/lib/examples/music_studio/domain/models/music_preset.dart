import 'package:gemini_live/gemini_live.dart';

/// A quick preset: weighted prompts plus tempo / scale / mode.
class MusicPreset {
  const MusicPreset({
    required this.label,
    required this.prompts,
    required this.bpm,
    this.scale,
    required this.mode,
  });

  final String label;
  final List<MapEntry<String, double>> prompts;
  final int bpm;
  final Scale? scale;
  final MusicGenerationMode mode;
}
