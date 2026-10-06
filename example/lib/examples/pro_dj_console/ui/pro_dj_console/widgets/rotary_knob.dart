import 'package:flutter/material.dart';

/// Drag-to-turn rotary EQ knob.
class RotaryKnob extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const RotaryKnob({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final norm = (value - min) / (max - min);
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final delta = -details.primaryDelta! / 100.0;
            final newVal = (value + delta * (max - min)).clamp(min, max);
            onChanged(newVal);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1F2533),
              border: Border.all(color: color.withAlpha(120), width: 2),
            ),
            child: Transform.rotate(
              angle: (norm - 0.5) * 4.5,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
