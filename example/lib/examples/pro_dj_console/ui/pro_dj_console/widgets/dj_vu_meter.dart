import 'package:flutter/material.dart';

/// Club Mixer 12-Segment LED VU Meter with OVER indicator and dB scale ticks.
class DjVuMeter extends StatelessWidget {
  final double level;
  final String channelLabel;

  const DjVuMeter({super.key, required this.level, required this.channelLabel});

  @override
  Widget build(BuildContext context) {
    const totalBars = 12;
    final activeCount = (level.clamp(0.0, 1.0) * totalBars).round();
    final isOver = level > 0.90;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          channelLabel,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontFamily: 'monospace',
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        // Top OVER / CLIP Red LED Lamp
        Container(
          width: 24,
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          decoration: BoxDecoration(
            color: isOver ? const Color(0xFFEF4444) : const Color(0xFF1A1014),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isOver ? Colors.redAccent : const Color(0xFF331C22),
              width: 0.8,
            ),
          ),
          child: Text(
            'OVER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isOver ? Colors.white : const Color(0xFF643B43),
              fontFamily: 'monospace',
              fontSize: 6.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          height: 108,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF080A0F),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF222938)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 12-Segment LED Column
              SizedBox(
                width: 11,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(totalBars, (index) {
                    final barIndex = totalBars - 1 - index;
                    final isActive = barIndex < activeCount;
                    final Color color;
                    if (barIndex >= 10) {
                      color = const Color(0xFFEF4444); // +6..+9 dB Red
                    } else if (barIndex >= 7) {
                      color = const Color(0xFFF59E0B); // 0..+3 dB Amber
                    } else {
                      color = const Color(0xFF10B981); // -24..-3 dB Green
                    }

                    return Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? color : color.withAlpha(32),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color.withAlpha(170),
                                  blurRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 3),
              // Silk-Screened dB Scale Markings
              const Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DbScaleText('+6', Color(0xFFEF4444)),
                  _DbScaleText(' 0', Color(0xFFF59E0B)),
                  _DbScaleText('-6', Color(0xFF64748B)),
                  _DbScaleText('-12', Color(0xFF64748B)),
                  _DbScaleText('-24', Color(0xFF475569)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DbScaleText extends StatelessWidget {
  final String label;
  final Color color;

  const _DbScaleText(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontFamily: 'monospace',
        fontSize: 6.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
