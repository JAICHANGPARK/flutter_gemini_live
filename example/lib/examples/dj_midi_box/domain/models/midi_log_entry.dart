import 'dart:ui' show Color;

/// Real-time DJ log entry.
class MidiLogEntry {
  final DateTime time;
  final String text;
  final Color color;

  MidiLogEntry(this.text, {Color? color})
    : time = DateTime.now(),
      color = color ?? const Color(0xFF94A3B8);

  String get timeFormatted {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
