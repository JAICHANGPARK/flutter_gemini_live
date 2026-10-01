import 'dart:async';
import 'package:flutter/material.dart';

/// A floating caption and subtitle bubble widget for Gemini Live conversations.
///
/// Designed to render real-time streaming speech-to-text transcripts from
/// user input or synthesized model responses with animated transitions,
/// role badges, and optional auto-dismiss timers.
class GeminiLiveCaptionBubble extends StatefulWidget {
  /// The transcript or subtitle text to display.
  final String text;

  /// Role of the speaker, typically `'user'` or `'model'`.
  final String role;

  /// Optional speaker name (e.g. for multi-speaker setups or custom voices).
  final String? speaker;

  /// Optional vocal style description (e.g. "whispering", "excited").
  final String? style;

  /// Whether the current turn is still actively streaming text.
  final bool isStreaming;

  /// Duration after which the bubble automatically fades out when idle.
  /// Set to `null` to keep the bubble visible indefinitely.
  final Duration? autoDismissDuration;

  /// Maximum width of the caption bubble. Defaults to 480.0.
  final double maxWidth;

  /// Background color of the caption container.
  final Color? backgroundColor;

  /// Text color. Defaults to white / high-contrast on dark backgrounds.
  final Color? textColor;

  /// Corner radius of the bubble. Defaults to 16.0.
  final double borderRadius;

  /// Padding inside the bubble. Defaults to horizontal 16.0, vertical 10.0.
  final EdgeInsetsGeometry padding;

  /// Callback when the bubble automatically dismisses after [autoDismissDuration].
  final VoidCallback? onDismissed;

  const GeminiLiveCaptionBubble({
    super.key,
    required this.text,
    this.role = 'model',
    this.speaker,
    this.style,
    this.isStreaming = false,
    this.autoDismissDuration = const Duration(seconds: 6),
    this.maxWidth = 480.0,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    this.onDismissed,
  });

  @override
  State<GeminiLiveCaptionBubble> createState() =>
      _GeminiLiveCaptionBubbleState();
}

class _GeminiLiveCaptionBubbleState extends State<GeminiLiveCaptionBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    if (widget.text.trim().isNotEmpty) {
      _animController.forward();
      _resetDismissTimer();
    }
  }

  @override
  void didUpdateWidget(GeminiLiveCaptionBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      if (widget.text.trim().isNotEmpty) {
        if (!_animController.isCompleted) {
          _animController.forward();
        }
        _resetDismissTimer();
      } else {
        _animController.reverse();
      }
    } else if (widget.isStreaming != oldWidget.isStreaming) {
      _resetDismissTimer();
    }
  }

  void _resetDismissTimer() {
    _dismissTimer?.cancel();
    if (widget.isStreaming || widget.autoDismissDuration == null) {
      return;
    }
    _dismissTimer = Timer(widget.autoDismissDuration!, () {
      if (mounted) {
        _animController.reverse().then((_) {
          widget.onDismissed?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.trim().isEmpty && _animController.isDismissed) {
      return const SizedBox.shrink();
    }

    final isModel = widget.role.toLowerCase() == 'model';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = widget.backgroundColor ??
        (isDark
            ? Colors.black.withValues(alpha: 0.75)
            : Colors.grey.shade900.withValues(alpha: 0.85));

    final effectiveTextColor = widget.textColor ?? Colors.white;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: defaultBg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tag: role / speaker / style
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: isModel
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.purple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      widget.speaker ?? (isModel ? 'Gemini' : 'You'),
                      style: TextStyle(
                        color: isModel ? Colors.blue.shade200 : Colors.purple.shade200,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (widget.style != null) ...[
                    const SizedBox(width: 6.0),
                    Text(
                      '• ${widget.style}',
                      style: TextStyle(
                        color: effectiveTextColor.withValues(alpha: 0.6),
                        fontSize: 10.0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (widget.isStreaming) ...[
                    const SizedBox(width: 8.0),
                    _PulsingDot(color: isModel ? Colors.blue.shade300 : Colors.purple.shade300),
                  ],
                ],
              ),
              const SizedBox(height: 6.0),
              // Body text
              Text(
                widget.text,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 14.0,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      child: Container(
        width: 6.0,
        height: 6.0,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
