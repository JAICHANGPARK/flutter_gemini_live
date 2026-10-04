import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A floating caption and subtitle bubble widget for Gemini Live conversations.
///
/// Designed with a sleek, non-intrusive native overlay aesthetic (frosted glass,
/// subtle borders, refined typography) suitable for live streaming subtitles,
/// meeting dictations, and voice assistants without an artificial or tacky look.
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

  /// Whether to display the subtle speaker/role pill header. Defaults to `true`.
  final bool showSpeakerTag;

  /// Whether to enable native frosted glass backdrop blur. Defaults to `true`.
  final bool enableBlur;

  /// Duration after which the bubble automatically fades out when idle.
  /// Set to `null` to keep the bubble visible indefinitely.
  final Duration? autoDismissDuration;

  /// Maximum width of the caption bubble. Defaults to 480.0.
  final double maxWidth;

  /// Background color of the caption container.
  final Color? backgroundColor;

  /// Text color.
  final Color? textColor;

  /// Corner radius of the bubble. Defaults to 16.0.
  final double borderRadius;

  /// Padding inside the bubble. Defaults to horizontal 16.0, vertical 10.0.
  final EdgeInsetsGeometry padding;

  /// Callback when the bubble automatically dismisses after [autoDismissDuration].
  final VoidCallback? onDismissed;

  /// Creates a floating caption bubble displaying [text].
  const GeminiLiveCaptionBubble({
    super.key,
    required this.text,
    this.role = 'model',
    this.speaker,
    this.style,
    this.isStreaming = false,
    this.showSpeakerTag = true,
    this.enableBlur = true,
    this.autoDismissDuration = const Duration(seconds: 6),
    this.maxWidth = 480.0,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
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
    Brightness? brightness;
    try {
      brightness = Theme.of(context).brightness;
    } catch (_) {
      brightness = CupertinoTheme.maybeBrightnessOf(context);
    }
    final isDark = brightness == Brightness.dark;

    final defaultBg = widget.backgroundColor ??
        (isDark
            ? const Color(0xE01C1C1E) // iOS style system dark surface
            : const Color(0xF2F2F2F7)); // iOS style system light surface

    final effectiveTextColor = widget.textColor ??
        (isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1C1C1E));

    Widget content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 18.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showSpeakerTag) ...[
            // Refined, subtle header tag (no tacky neon colors)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7.0,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    widget.speaker ?? (isModel ? 'Gemini' : 'You'),
                    style: TextStyle(
                      color: effectiveTextColor.withValues(alpha: 0.8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (widget.style != null) ...[
                  const SizedBox(width: 6.0),
                  Text(
                    '• ${widget.style}',
                    style: TextStyle(
                      color: effectiveTextColor.withValues(alpha: 0.5),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                if (widget.isStreaming) ...[
                  const SizedBox(width: 8.0),
                  _PulsingDot(
                    color: effectiveTextColor.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6.0),
          ],
          // Subtitle text with clean native typography
          Text(
            widget.text,
            style: TextStyle(
              color: effectiveTextColor,
              fontSize: 14.5,
              height: 1.4,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );

    if (widget.enableBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: content,
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: content,
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
      duration: const Duration(milliseconds: 900),
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
