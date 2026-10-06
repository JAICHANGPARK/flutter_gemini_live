import 'package:flutter/material.dart';

class DjVisualizerPainter extends CustomPainter {
  final List<double> fftValues;
  final List<double> peakCaps;
  final List<double> waveform;
  final bool isPlaying;

  DjVisualizerPainter({
    required this.fftValues,
    required this.peakCaps,
    required this.waveform,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Draw subtle background grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, height * 0.25),
      Offset(width, height * 0.25),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, height * 0.5),
      Offset(width, height * 0.5),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, height * 0.75),
      Offset(width, height * 0.75),
      gridPaint,
    );

    // 2. Draw 32 FFT Frequency Bars
    final barCount = fftValues.length;
    const barSpacing = 2.0;
    final barWidth = (width - (barCount - 1) * barSpacing) / barCount;

    for (var i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      final mag = isPlaying ? fftValues[i].clamp(0.02, 1.0) : 0.02;
      final barHeight = mag * (height - 6);
      final y = height - barHeight;

      // Color transition: Bass (Cyan/Blue) -> Mid (Amber/Orange) -> High (Rose/Magenta)
      final norm = i / barCount;
      final barColor = norm < 0.35
          ? Color.lerp(
              const Color(0xFF06B6D4),
              const Color(0xFF3B82F6),
              norm / 0.35,
            )!
          : norm < 0.7
          ? Color.lerp(
              const Color(0xFFF59E0B),
              const Color(0xFFEC4899),
              (norm - 0.35) / 0.35,
            )!
          : Color.lerp(
              const Color(0xFFEC4899),
              const Color(0xFFF43F5E),
              (norm - 0.7) / 0.3,
            )!;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(2),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [barColor.withAlpha(120), barColor],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(barRect, barPaint);

      // Draw Peak Cap
      if (isPlaying) {
        final peakMag = peakCaps[i].clamp(0.0, 1.0);
        final peakY = height - (peakMag * (height - 6)) - 2;
        final capPaint = Paint()
          ..color = Colors.white.withAlpha(220)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, peakY, barWidth, 2),
            const Radius.circular(1),
          ),
          capPaint,
        );
      }
    }

    // 3. Draw Oscilloscope Waveform overlay across center
    if (isPlaying && waveform.isNotEmpty) {
      final wavePath = Path();
      final waveStep = width / (waveform.length - 1);
      final centerY = height * 0.5;

      for (var i = 0; i < waveform.length; i++) {
        final x = i * waveStep;
        final y = centerY - (waveform[i] * (height * 0.42));
        if (i == 0) {
          wavePath.moveTo(x, y);
        } else {
          wavePath.lineTo(x, y);
        }
      }

      final waveGlowPaint = Paint()
        ..color = const Color(0xFF38BDF8).withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(wavePath, waveGlowPaint);

      final waveLinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(wavePath, waveLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant DjVisualizerPainter oldDelegate) {
    return isPlaying || oldDelegate.isPlaying != isPlaying;
  }
}
