import 'package:flutter/material.dart';

import '../../../domain/models/midi_knob_data.dart';
import 'midi_knob_painter.dart';

// ============================================================================
// Tactile Rotary Dial Knob Widget
// ============================================================================

class MidiKnobWidget extends StatelessWidget {
  final MidiKnobData data;
  final double rmsLevel;
  final ValueChanged<double> onChanged;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MidiKnobWidget({
    super.key,
    required this.data,
    required this.rmsLevel,
    required this.onChanged,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = data.weight > 0.02;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onVerticalDragUpdate: (details) {
        final delta = -details.primaryDelta! / 80.0;
        final nextWeight = (data.weight + delta).clamp(0.0, 1.0);
        onChanged(nextWeight);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rotary Dial with Glow Halo and Arc
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: CustomPaint(
                  painter: MidiKnobPainter(
                    weight: data.weight,
                    color: data.color,
                    isActive: isActive,
                    pulse: isActive ? rmsLevel : 0.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Label Badge underneath knob
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(220),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? data.color.withAlpha(120) : Colors.white10,
                width: 1,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: data.color.withAlpha(60),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
