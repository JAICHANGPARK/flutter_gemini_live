import 'models/midi_knob_data.dart';

/// Builds the "active blend" summary string shown in the visualizer header.
String buildMixSummary({
  required List<MidiKnobData> knobs,
  String? customPromptText,
  double? customPromptWeight,
}) {
  final activeKnobs = knobs.where((k) => k.weight > 0.01).toList();
  final double customW =
      (customPromptText != null &&
          customPromptText.isNotEmpty &&
          (customPromptWeight ?? 0) > 0.01)
      ? (customPromptWeight ?? 0)
      : 0.0;

  final totalWeight =
      activeKnobs.fold<double>(0.0, (acc, k) => acc + k.weight) + customW;

  final List<String> blendParts = [];
  if (customW > 0.0) {
    final pct = ((customW / (totalWeight > 0 ? totalWeight : 1.0)) * 100)
        .round();
    final preview = customPromptText!.length > 14
        ? '${customPromptText.substring(0, 12)}..'
        : customPromptText;
    blendParts.add('✍️ "$preview" $pct%');
  }

  for (final k in activeKnobs) {
    final pct = ((k.weight / (totalWeight > 0 ? totalWeight : 1.0)) * 100)
        .round();
    blendParts.add('${k.title} $pct%');
  }

  final String mixSummary = blendParts.isEmpty
      ? 'Ambient Synth (100%)'
      : blendParts.join(' + ');
  return mixSummary;
}
