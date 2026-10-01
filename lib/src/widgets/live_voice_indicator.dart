import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An animated audio visualizer indicator for Gemini Live sessions.
///
/// Displays smooth, rhythmic bar waves or pulsing rings to visualize
/// outgoing user voice input or incoming model speech.
class GeminiLiveVoiceIndicator extends StatefulWidget {
  /// Whether voice/audio is actively being processed or played.
  final bool isSpeaking;

  /// Number of waveform bars. Defaults to 4.
  final int barCount;

  /// Height of the visualizer. Defaults to 24.0.
  final double height;

  /// Color of the visualizer bars.
  final Color? color;

  const GeminiLiveVoiceIndicator({
    super.key,
    required this.isSpeaking,
    this.barCount = 4,
    this.height = 24.0,
    this.color,
  });

  @override
  State<GeminiLiveVoiceIndicator> createState() =>
      _GeminiLiveVoiceIndicatorState();
}

class _GeminiLiveVoiceIndicatorState extends State<GeminiLiveVoiceIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.isSpeaking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(GeminiLiveVoiceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isSpeaking && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor = widget.color ??
        (isDark
            ? Colors.white.withValues(alpha: 0.9)
            : theme.colorScheme.onSurface.withValues(alpha: 0.85));

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final half = widget.barCount / 2.0;

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              // Bell envelope from center
              final distFromCenter = (index + 0.5 - half).abs() / half;
              final bellWeight = (1.0 - 0.35 * distFromCenter).clamp(0.4, 1.0);

              // Organic dual-harmonic audio motion
              final phase1 = (index / widget.barCount) * 2 * math.pi;
              final phase2 = (index / widget.barCount) * 4 * math.pi;
              final wave = (math.sin((_controller.value * 2 * math.pi) + phase1) * 0.7) +
                  (math.cos((_controller.value * 2 * math.pi) + phase2) * 0.3);

              final t = widget.isSpeaking
                  ? (((wave + 1) / 2) * bellWeight).clamp(0.12, 1.0)
                  : 0.18;

              final minHeight = widget.height * 0.18;
              final currentHeight =
                  minHeight + (widget.height - minHeight) * t;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                width: 3.5,
                height: currentHeight,
                decoration: BoxDecoration(
                  color: barColor.withValues(
                    alpha: widget.isSpeaking ? 1.0 : 0.45,
                  ),
                  borderRadius: BorderRadius.circular(1.75), // Smooth pill capsule
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
