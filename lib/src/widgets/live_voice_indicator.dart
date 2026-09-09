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
    final barColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final phase = (index / widget.barCount) * 2 * math.pi;
              final t = widget.isSpeaking
                  ? (math.sin((_controller.value * 2 * math.pi) + phase) + 1) / 2
                  : 0.15;

              final minHeight = widget.height * 0.2;
              final currentHeight =
                  minHeight + (widget.height - minHeight) * t;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                width: 3.5,
                height: currentHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
