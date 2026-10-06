import 'dart:ui' show Color;

/// One rotary dial pad (style / instrument prompt + steering weight).
class MidiKnobData {
  String title;
  String prompt;
  final Color color;
  double weight;

  MidiKnobData({
    required this.title,
    required this.prompt,
    required this.color,
    required this.weight,
  });
}
