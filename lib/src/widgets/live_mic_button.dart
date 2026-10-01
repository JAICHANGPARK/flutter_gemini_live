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
    final isDark = theme.brightness == Brightness.dark;

    final activeBg = widget.activeColor ??
        (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)); // Clean recording red
    final inactiveBg = widget.inactiveColor ??
        (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5)); // Clean neutral surface

    final activeFg = Colors.white;
    final inactiveFg = isDark ? Colors.white : const Color(0xFF18181B);

    return Tooltip(
      message: widget.tooltip ?? (widget.isRecording ? 'Stop listening' : 'Start speaking'),
      child: GestureDetector(
        onLongPressStart: widget.onLongPressStart != null ? (_) => widget.onLongPressStart!() : null,
        onLongPressEnd: widget.onLongPressEnd != null ? (_) => widget.onLongPressEnd!() : null,
        child: SizedBox(
          width: widget.size * 1.4,
          height: widget.size * 1.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Clean acoustic expanding ring (native audio ripple)
              if (widget.isRecording)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final rippleScale = 1.0 + (_pulseController.value * 0.35);
                    final rippleOpacity = (1.0 - _pulseController.value).clamp(0.0, 0.4);

                    return Transform.scale(
                      scale: rippleScale,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeBg.withValues(alpha: rippleOpacity),
                            width: 2.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Main button core
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isRecording ? activeBg : inactiveBg,
                  border: Border.all(
                    color: widget.isRecording
                        ? Colors.transparent
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08)),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 10.0,
                      offset: const Offset(0, 3),
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
                        color: widget.isRecording ? activeFg : inactiveFg,
                        size: widget.iconSize,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
