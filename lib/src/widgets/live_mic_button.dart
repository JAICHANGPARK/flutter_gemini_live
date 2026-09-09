import 'package:flutter/material.dart';

/// An interactive microphone button designed for Gemini Live voice input.
///
/// Supports tap-to-toggle or press-and-hold gestures, with animated glow/ripple
/// effects when active or listening.
class GeminiLiveMicButton extends StatefulWidget {
  /// Whether the microphone is currently active (recording / listening).
  final bool isRecording;

  /// Callback when user taps or begins speaking.
  final VoidCallback? onPressed;

  /// Optional callback when long press starts (for Push-to-Talk mode).
  final VoidCallback? onLongPressStart;

  /// Optional callback when long press ends (for Push-to-Talk mode).
  final VoidCallback? onLongPressEnd;

  /// Size of the button.
  final double size;

  /// Icon size.
  final double iconSize;

  /// Custom color when microphone is active.
  final Color? activeColor;

  /// Custom color when microphone is inactive.
  final Color? inactiveColor;

  /// Tooltip message.
  final String? tooltip;

  const GeminiLiveMicButton({
    super.key,
    required this.isRecording,
    this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.size = 56.0,
    this.iconSize = 28.0,
    this.activeColor,
    this.inactiveColor,
    this.tooltip,
  });

  @override
  State<GeminiLiveMicButton> createState() => _GeminiLiveMicButtonState();
}

class _GeminiLiveMicButtonState extends State<GeminiLiveMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GeminiLiveMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeBg = widget.activeColor ?? theme.colorScheme.error;
    final inactiveBg = widget.inactiveColor ?? theme.colorScheme.primary;

    return Tooltip(
      message: widget.tooltip ?? (widget.isRecording ? 'Stop listening' : 'Start speaking'),
      child: GestureDetector(
        onLongPressStart: widget.onLongPressStart != null ? (_) => widget.onLongPressStart!() : null,
        onLongPressEnd: widget.onLongPressEnd != null ? (_) => widget.onLongPressEnd!() : null,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final glowRadius = widget.isRecording ? 6.0 + (_pulseController.value * 10.0) : 0.0;
            final glowOpacity = widget.isRecording ? 0.3 + (_pulseController.value * 0.3) : 0.0;

            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording ? activeBg : inactiveBg,
                boxShadow: [
                  if (widget.isRecording)
                    BoxShadow(
                      color: activeBg.withValues(alpha: glowOpacity),
                      blurRadius: glowRadius,
                      spreadRadius: glowRadius / 2,
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onPressed,
                  child: Center(
                    child: Icon(
                      widget.isRecording ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: widget.iconSize,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
