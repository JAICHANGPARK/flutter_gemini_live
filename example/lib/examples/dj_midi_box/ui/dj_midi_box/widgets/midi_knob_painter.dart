import 'dart:math' as math;

import 'package:flutter/material.dart';

// ============================================================================
// Custom Knob Painter
// ============================================================================

class MidiKnobPainter extends CustomPainter {
  final double weight;
  final Color color;
  final bool isActive;
  final double pulse;

  MidiKnobPainter({
    required this.weight,
    required this.color,
    required this.isActive,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Outer Circular Glow Halo when active
    if (isActive) {
      final glowPaint = Paint()
        ..color = color.withAlpha((180 + pulse * 75).toInt().clamp(0, 255))
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + pulse * 8);

      canvas.drawCircle(center, radius * 0.95, glowPaint);

      // Solid color halo ring behind the knob
      final haloSolidPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.88, haloSolidPaint);
    } else {
      // Inactive dark outer well with subtle bevel
      final wellPaint = Paint()
        ..color = Colors.black.withAlpha(130)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.88, wellPaint);

      final wellBorderPaint = Paint()
        ..color = Colors.white.withAlpha(20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius * 0.88, wellBorderPaint);
    }

    // 2. Arc Indicator Track (clockwise from 7 o'clock = 135 deg to 5 o'clock = 405 deg)
    // Total sweep angle = 270 degrees (3 * pi / 2)
    const startAngle = 135.0 * (math.pi / 180.0);
    const totalSweep = 270.0 * (math.pi / 180.0);
    final sweepAngle = totalSweep * weight.clamp(0.0, 1.0);

    if (isActive) {
      // White clean active arc
      final arcPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.68),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // 3. Knob Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(180)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(center.translate(0, 3), radius * 0.54, shadowPaint);

    // 4. White/Silver 3D Physical Knob Cap
    final knobRect = Rect.fromCircle(center: center, radius: radius * 0.54);
    final knobGradient = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      radius: 0.85,
      colors: const [
        Color(0xFFFFFFFF), // Highlight pure white
        Color(0xFFF1F5F9), // Light silver
        Color(0xFFE2E8F0), // Base white/grey
        Color(0xFFCBD5E1), // Bevel shadow edge
      ],
      stops: const [0.0, 0.45, 0.85, 1.0],
    );

    final knobPaint = Paint()..shader = knobGradient.createShader(knobRect);
    canvas.drawCircle(center, radius * 0.54, knobPaint);

    // Subtle edge rim border
    final rimPaint = Paint()
      ..color = const Color(0xFF94A3B8).withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.54, rimPaint);

    // 5. Min Reference Dot at 7 o'clock position (outside knob)
    final minDotOffset = Offset(
      center.dx + radius * 0.74 * math.cos(startAngle),
      center.dy + radius * 0.74 * math.sin(startAngle),
    );
    final minDotPaint = Paint()
      ..color = Colors.white.withAlpha(isActive ? 120 : 60)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(minDotOffset, 1.8, minDotPaint);

    // 6. Knob Position Dot Indicator (black dot on the knob cap)
    final currentAngle = startAngle + sweepAngle;
    final dotDist = radius * 0.36;
    final dotOffset = Offset(
      center.dx + dotDist * math.cos(currentAngle),
      center.dy + dotDist * math.sin(currentAngle),
    );

    final dotPaint = Paint()
      ..color =
          const Color(0xFF0F172A) // Dark slate black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotOffset, 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant MidiKnobPainter oldDelegate) {
    return oldDelegate.weight != weight ||
        oldDelegate.isActive != isActive ||
        oldDelegate.pulse != pulse;
  }
}
