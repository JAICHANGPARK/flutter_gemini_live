import 'package:flutter/material.dart';

/// Stereo LED VU Meter
class DjVuMeter extends StatelessWidget {
  final double level;
  final String channelLabel;

  const DjVuMeter({super.key, required this.level, required this.channelLabel});

  @override
  Widget build(BuildContext context) {
    const totalBars = 10;
    final activeCount = (level * totalBars).round();

    return Column(
      children: [
        Text(
          channelLabel,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 14,
          height: 100,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E14),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF202634)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(totalBars, (index) {
              final barIndex = totalBars - 1 - index;
              final isActive = barIndex < activeCount;
              Color color;
              if (barIndex >= 8) {
                color = Colors.redAccent;
              } else if (barIndex >= 6) {
                color = Colors.amberAccent;
              } else {
                color = Colors.greenAccent;
              }

              return Container(
                height: 7,
                margin: const EdgeInsets.symmetric(vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? color : color.withAlpha(40),
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: isActive
                      ? [BoxShadow(color: color.withAlpha(180), blurRadius: 3)]
                      : null,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
