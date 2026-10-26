import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Drag-to-turn hardware rotary EQ potentiometer knob with silk-screened dB ticks.
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
    final norm = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontFamily: 'monospace',
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        GestureDetector(
          onDoubleTap: () {
            onChanged(min + (max - min) * 0.5);
          },
          onVerticalDragUpdate: (details) {
            final delta = -details.primaryDelta! / 100.0;
            final newVal = (value + delta * (max - min)).clamp(min, max);
            onChanged(newVal);
          },
          child: SizedBox(
            width: 50,
            height: 50,
            child: CustomPaint(
              painter: _HardwareEqKnobPainter(norm: norm, color: color),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0D14),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF1E2636)),
          ),
          child: Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _HardwareEqKnobPainter extends CustomPainter {
  final double norm;
  final Color color;

  const _HardwareEqKnobPainter({required this.norm, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    const startAngle = 135.0 * (math.pi / 180.0);
    const totalSweep = 270.0 * (math.pi / 180.0);
    final sweepAngle = totalSweep * norm;

    // 1. Outer Silk-Screened Scale Ticks (11 ticks, center detent at i == 5)
    const tickCount = 11;
    for (var i = 0; i < tickCount; i++) {
      final t = i / (tickCount - 1);
      final angle = startAngle + totalSweep * t;
      final isCenterDetent = i == 5;
      final isMajor = i == 0 || isCenterDetent || i == tickCount - 1;
      final isLit = t <= norm + 0.01;

      final r1 = radius * (isMajor ? 0.76 : 0.80);
      final r2 = radius * 0.92;

      final p1 = Offset(
        center.dx + r1 * math.cos(angle),
        center.dy + r1 * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + r2 * math.cos(angle),
        center.dy + r2 * math.sin(angle),
      );

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = isLit
              ? color
              : (isCenterDetent
                    ? Colors.white.withAlpha(150)
                    : Colors.white.withAlpha(isMajor ? 90 : 40))
          ..strokeWidth = isMajor ? 1.6 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // 2. Active Arc Ring
    final arcRadius = radius * 0.68;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      startAngle,
      totalSweep,
      false,
      Paint()
        ..color = const Color(0xFF1A202E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // 3. Drop shadow & Knurled Cap Body
    final capRadius = radius * 0.56;
    canvas.drawCircle(
      center.translate(0, 2),
      capRadius,
      Paint()
        ..color = Colors.black87
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final capRect = Rect.fromCircle(center: center, radius: capRadius);
    canvas.drawCircle(
      center,
      capRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [Color(0xFF384152), Color(0xFF1F2633), Color(0xFF11151E)],
        ).createShader(capRect),
    );

    canvas.drawCircle(
      center,
      capRadius,
      Paint()
        ..color = color.withAlpha(110)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 4. Center Indicator Notch Line
    final currentAngle = startAngle + sweepAngle;
    final pStart = Offset(
      center.dx + (capRadius * 0.22) * math.cos(currentAngle),
      center.dy + (capRadius * 0.22) * math.sin(currentAngle),
    );
    final pEnd = Offset(
      center.dx + (capRadius * 0.88) * math.cos(currentAngle),
      center.dy + (capRadius * 0.88) * math.sin(currentAngle),
    );

    canvas.drawLine(
      pStart,
      pEnd,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HardwareEqKnobPainter oldDelegate) {
    return oldDelegate.norm != norm || oldDelegate.color != color;
  }
}
