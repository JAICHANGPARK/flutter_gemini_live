import 'dart:math' as math;

import 'package:flutter/material.dart';

// ============================================================================
// Hardware Audio Mixer Potentiometer Knob Painter
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
    final radius = math.min(size.width, size.height) / 2;

    const startAngle = 135.0 * (math.pi / 180.0);
    const totalSweep = 270.0 * (math.pi / 180.0);
    final clampedWeight = weight.clamp(0.0, 1.0);
    final sweepAngle = totalSweep * clampedWeight;

    // 1. Recessed Metallic Potentiometer Well
    final wellRadius = radius * 0.86;
    final wellRect = Rect.fromCircle(center: center, radius: wellRadius);
    final wellPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF07090E), Color(0xFF161B26)],
      ).createShader(wellRect);
    canvas.drawCircle(center, wellRadius, wellPaint);

    final wellBevelPaint = Paint()
      ..color = isActive
          ? color.withAlpha((100 + pulse * 80).toInt().clamp(0, 255))
          : const Color(0xFF283142)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, wellRadius, wellBevelPaint);

    // 2. Silk-Screened Scale Ticks & Segmented LED Collar (11 ticks from 7 o'clock to 5 o'clock)
    const tickCount = 11;
    for (var i = 0; i < tickCount; i++) {
      final t = i / (tickCount - 1);
      final angle = startAngle + totalSweep * t;
      final isMajor = i == 0 || i == 5 || i == 8 || i == tickCount - 1;
      final isLit = isActive && t <= clampedWeight + 0.02;

      final innerTickR = radius * (isMajor ? 0.72 : 0.75);
      final outerTickR = radius * 0.83;

      final p1 = Offset(
        center.dx + innerTickR * math.cos(angle),
        center.dy + innerTickR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerTickR * math.cos(angle),
        center.dy + outerTickR * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = isLit
            ? (i >= 9 ? const Color(0xFFEF4444) : color)
            : Colors.white.withAlpha(isMajor ? 95 : 45)
        ..strokeWidth = isMajor ? 1.8 : 1.1
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);
    }

    // 3. Illuminated LED Arc Collar inside the well
    final arcRadius = radius * 0.67;
    final trackPaint = Paint()
      ..color = const Color(0xFF1E2533)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    if (isActive && clampedWeight > 0.01) {
      final glowArcPaint = Paint()
        ..color = color.withAlpha((130 + pulse * 90).toInt().clamp(0, 255))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle,
        sweepAngle,
        false,
        glowArcPaint,
      );

      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // 4. Potentiometer Cap Drop Shadow
    final capRadius = radius * 0.56;
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(210)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(center.translate(0, 2.5), capRadius, shadowPaint);

    // 5. Knurled Outer Skirt (Machined Aluminum Grip Ring)
    final skirtPaint = Paint()
      ..color = const Color(0xFF11151E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, capRadius, skirtPaint);

    const knurlCount = 20;
    final knurlPaint = Paint()
      ..color = Colors.white.withAlpha(32)
      ..strokeWidth = 1.0;
    for (var i = 0; i < knurlCount; i++) {
      final kAngle = (2 * math.pi * i) / knurlCount;
      final k1 = Offset(
        center.dx + capRadius * 0.86 * math.cos(kAngle),
        center.dy + capRadius * 0.86 * math.sin(kAngle),
      );
      final k2 = Offset(
        center.dx + capRadius * 0.98 * math.cos(kAngle),
        center.dy + capRadius * 0.98 * math.sin(kAngle),
      );
      canvas.drawLine(k1, k2, knurlPaint);
    }

    // 6. Anodized Metallic Top Cap
    final topCapRadius = capRadius * 0.84;
    final knobRect = Rect.fromCircle(center: center, radius: topCapRadius);
    final knobGradient = RadialGradient(
      center: const Alignment(-0.28, -0.32),
      radius: 0.95,
      colors: const [
        Color(0xFF3B4457), // Top-left specular highlight
        Color(0xFF252C3B), // Brushed gunmetal body
        Color(0xFF171C26), // Deep anodized shadow
        Color(0xFF0E1118), // Bevel edge
      ],
      stops: const [0.0, 0.42, 0.82, 1.0],
    );
    canvas.drawCircle(
      center,
      topCapRadius,
      Paint()..shader = knobGradient.createShader(knobRect),
    );

    // Subtle metallic rim on top cap
    canvas.drawCircle(
      center,
      topCapRadius,
      Paint()
        ..color = isActive ? color.withAlpha(110) : Colors.white.withAlpha(38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 7. Recessed Inner Cap Dish
    final dishRadius = topCapRadius * 0.56;
    canvas.drawCircle(
      center,
      dishRadius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12161F), Color(0xFF232A38)],
        ).createShader(Rect.fromCircle(center: center, radius: dishRadius)),
    );

    // 8. High-Visibility Pointer Notch Line on Knob Cap
    final currentAngle = startAngle + sweepAngle;
    final lineStart = Offset(
      center.dx + (dishRadius * 0.35) * math.cos(currentAngle),
      center.dy + (dishRadius * 0.35) * math.sin(currentAngle),
    );
    final lineEnd = Offset(
      center.dx + (topCapRadius * 0.90) * math.cos(currentAngle),
      center.dy + (topCapRadius * 0.90) * math.sin(currentAngle),
    );

    if (isActive) {
      canvas.drawLine(
        lineStart,
        lineEnd,
        Paint()
          ..color = color.withAlpha(160)
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    canvas.drawLine(
      lineStart,
      lineEnd,
      Paint()
        ..color = isActive ? Colors.white : const Color(0xFF94A3B8)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant MidiKnobPainter oldDelegate) {
    return oldDelegate.weight != weight ||
        oldDelegate.color != color ||
        oldDelegate.isActive != isActive ||
        oldDelegate.pulse != pulse;
  }
}
