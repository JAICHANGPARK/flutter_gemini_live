import 'dart:ui' show Color;

/// One hardware mixer channel strip / rotary dial pad (style / instrument prompt + steering parameters).
class MidiKnobData {
  String title;
  String prompt;
  final Color color;
  double weight;

  // Per-channel MG-series hardware mixer strip potentiometer states (0.0 .. 1.0)
  double gain;
  double comp;
  double high;
  double mid;
  double low;
  double aux1;
  double aux2;
  double pan;
  bool groupAssigned;
  bool stAssigned;
  bool pflActive;

  MidiKnobData({
    required this.title,
    required this.prompt,
    required this.color,
    required this.weight,
    this.gain = 0.65,
    this.comp = 0.40,
    this.high = 0.50,
    this.mid = 0.50,
    this.low = 0.50,
    this.aux1 = 0.35,
    this.aux2 = 0.25,
    this.pan = 0.50,
    this.groupAssigned = false,
    this.stAssigned = true,
    this.pflActive = false,
  });
}
