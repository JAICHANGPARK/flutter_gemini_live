import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// An iOS / Cupertino-styled microphone button designed for Gemini Live voice input.
///
/// Follows Apple Human Interface Guidelines:
/// - iOS smooth spring tap interaction with scale feedback
/// - Haptic feedback support on tap and long-press ([HapticFeedback])
/// - Subtle concentric ripple/glow when active
class CupertinoGeminiLiveMicButton extends StatefulWidget {
  /// Whether the microphone is currently active (recording / listening).
  final bool isRecording;

  /// Callback when user taps the button.
  final VoidCallback? onPressed;

  /// Optional callback when long press starts (for Push-to-Talk mode).
  final VoidCallback? onLongPressStart;

  /// Optional callback when long press ends (for Push-to-Talk mode).
  final VoidCallback? onLongPressEnd;

  /// Diameter of the button core. Defaults to 56.0.
  final double size;

  /// Icon size. Defaults to 26.0.
  final double iconSize;

  /// Custom color when microphone is active. Defaults to [CupertinoColors.systemRed].
  final Color? activeColor;

  /// Custom color when microphone is inactive.
  final Color? inactiveColor;

  /// Whether to trigger iOS haptic feedback on gestures. Defaults to `true`.
  final bool enableHaptics;

  const CupertinoGeminiLiveMicButton({
    super.key,
    required this.isRecording,
    this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.size = 56.0,
    this.iconSize = 26.0,
    this.activeColor,
    this.inactiveColor,
    this.enableHaptics = true,
  });

  @override
  State<CupertinoGeminiLiveMicButton> createState() =>
      _CupertinoGeminiLiveMicButtonState();
}

class _CupertinoGeminiLiveMicButtonState
    extends State<CupertinoGeminiLiveMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isPressed = false;

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
  void didUpdateWidget(CupertinoGeminiLiveMicButton oldWidget) {
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

  void _handleTapDown(_) {
    setState(() => _isPressed = true);
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(_) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    final activeBg = widget.activeColor ??
        CupertinoColors.systemRed.resolveFrom(context);

    final inactiveBg = widget.inactiveColor ??
        (isDark
            ? CupertinoColors.systemGrey5.darkColor
            : CupertinoColors.systemGrey5.color);

    final activeFg = CupertinoColors.white;
    final inactiveFg = CupertinoColors.label.resolveFrom(context);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      onLongPressStart: widget.onLongPressStart != null
          ? (_) {
              if (widget.enableHaptics) HapticFeedback.mediumImpact();
              widget.onLongPressStart!();
            }
          : null,
      onLongPressEnd: widget.onLongPressEnd != null
          ? (_) {
              if (widget.enableHaptics) HapticFeedback.lightImpact();
              widget.onLongPressEnd!();
            }
          : null,
      child: SizedBox(
        width: widget.size * 1.4,
        height: widget.size * 1.4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // iOS translucent ripple aura when active
            if (widget.isRecording)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final rippleScale = 1.0 + (_pulseController.value * 0.35);
                  final rippleOpacity =
                      (1.0 - _pulseController.value).clamp(0.0, 0.4);

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
            // Button core with iOS scale down effect on press
            AnimatedScale(
              scale: _isPressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isRecording ? activeBg : inactiveBg,
                  border: Border.all(
                    color: widget.isRecording
                        ? CupertinoColors.transparent
                        : (isDark
                            ? CupertinoColors.white.withValues(alpha: 0.12)
                            : CupertinoColors.black.withValues(alpha: 0.08)),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black
                          .withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.isRecording
                        ? CupertinoIcons.mic_fill
                        : CupertinoIcons.mic,
                    color: widget.isRecording ? activeFg : inactiveFg,
                    size: widget.iconSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
