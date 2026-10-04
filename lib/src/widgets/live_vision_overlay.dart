import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A camera viewfinder overlay widget tailored for Gemini Live multimodal vision interactions.
///
/// Wraps any camera viewfinder/preview widget and overlays Project Astra-style real-time
/// computer vision telemetry:
/// - Scanning laser / radar sweep animation across the viewfinder
/// - Corner targeting reticle HUD
/// - Real-time "AI Analyzing" in-flight snapshot pill badge
/// - Mirroring / horizontal flip support for front-facing camera feeds
class GeminiLiveVisionOverlay extends StatefulWidget {
  /// The underlying camera preview or viewfinder widget (e.g. `CameraPreview(controller)`).
  final Widget child;

  /// Whether a frame analysis or snapshot is actively in flight to the Gemini Live server.
  final bool isAnalyzing;

  /// Whether the scanning beam effect is actively animating. Defaults to `true`.
  final bool enableScanAnimation;

  /// Optional custom label on the analyzing badge. Defaults to `'AI Analyzing...'`.
  final String analyzingLabel;

  /// Whether the preview is mirrored (useful for selfie front cameras). Defaults to `false`.
  final bool isMirrored;

  /// Tint color for targeting HUD and scanner beam. Defaults to cyan / electric blue.
  final Color? scanColor;

  /// Corner radius of the rounded viewfinder container. Defaults to 20.0.
  final double borderRadius;

  /// Creates a multimodal vision overlay wrapping [child].
  const GeminiLiveVisionOverlay({
    super.key,
    required this.child,
    this.isAnalyzing = false,
    this.enableScanAnimation = true,
    this.analyzingLabel = 'AI Analyzing...',
    this.isMirrored = false,
    this.scanColor,
    this.borderRadius = 20.0,
  });

  @override
  State<GeminiLiveVisionOverlay> createState() =>
      _GeminiLiveVisionOverlayState();
}

class _GeminiLiveVisionOverlayState extends State<GeminiLiveVisionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    if (widget.enableScanAnimation) {
      _scanController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GeminiLiveVisionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableScanAnimation && !_scanController.isAnimating) {
      _scanController.repeat(reverse: true);
    } else if (!widget.enableScanAnimation && _scanController.isAnimating) {
      _scanController.stop();
      _scanController.reset();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.scanColor ?? const Color(0xFF00E5FF);

    Widget preview = widget.child;
    if (widget.isMirrored) {
      preview = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: preview,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Camera feed preview
          preview,

          // Subtle scanline radar beam
          if (widget.enableScanAnimation)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _VisionScanPainter(
                      progress: _scanController.value,
                      color: effectiveColor,
                    ),
                  );
                },
              ),
            ),

          // Corner HUD targeting reticles
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomPaint(
                  painter: _HudCornersPainter(color: effectiveColor),
                ),
              ),
            ),
          ),

          // Top status pill (AI analyzing badge)
          if (widget.isAnalyzing)
            Positioned(
              top: 14.0,
              left: 14.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: effectiveColor.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.0,
                      height: 7.0,
                      decoration: BoxDecoration(
                        color: effectiveColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      widget.analyzingLabel,
                      style: TextStyle(
                        color: effectiveColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VisionScanPainter extends CustomPainter {
  final double progress;
  final Color color;

  _VisionScanPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromLTWH(0, y - 40, size.width, 40));

    // Draw fading trail above the beam line
    canvas.drawRect(Rect.fromLTWH(0, (y - 40).clamp(0, size.height), size.width, 40), glowPaint);
    // Draw leading laser line
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
  }

  @override
  bool shouldRepaint(_VisionScanPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _HudCornersPainter extends CustomPainter {
  final Color color;

  _HudCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const cornerLength = 16.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(_HudCornersPainter oldDelegate) => oldDelegate.color != color;
}
