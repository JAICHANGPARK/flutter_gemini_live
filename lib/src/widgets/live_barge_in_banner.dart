/// @docImport '../utils/live_session_controller.dart';
library;

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An animated notification pill / banner that visually alerts users when
/// barge-in (interruption) occurs during a Gemini Live conversation.
///
/// When the user starts speaking while the AI is responding, this widget smoothly
/// slides and fades in to reassure the user that the AI has stopped speaking and is
/// now actively listening.
class GeminiLiveBargeInBanner extends StatefulWidget {
  /// Whether an interruption / barge-in is currently active.
  /// Typically wired to [GeminiLiveSessionController.isInterrupted].
  final bool isInterrupted;

  /// Custom banner message. Defaults to `'Listening to you...'`.
  final String message;

  /// Duration for which the banner remains visible after [isInterrupted] turns `true`.
  /// Defaults to 2.5 seconds.
  final Duration displayDuration;

  /// Optional icon to display beside the message. Defaults to [Icons.hearing_rounded].
  final Widget? icon;

  /// Background color override.
  final Color? backgroundColor;

  /// Text and icon color override.
  final Color? foregroundColor;

  /// Padding around the banner.
  final EdgeInsetsGeometry padding;

  /// Corner radius of the banner capsule.
  final double borderRadius;

  const GeminiLiveBargeInBanner({
    super.key,
    required this.isInterrupted,
    this.message = 'Listening to you...',
    this.displayDuration = const Duration(milliseconds: 2500),
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
    this.borderRadius = 24.0,
  });

  @override
  State<GeminiLiveBargeInBanner> createState() =>
      _GeminiLiveBargeInBannerState();
}

class _GeminiLiveBargeInBannerState extends State<GeminiLiveBargeInBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isInterrupted) {
      _show();
    }
  }

  @override
  void didUpdateWidget(GeminiLiveBargeInBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInterrupted && !oldWidget.isInterrupted) {
      _show();
    }
  }

  void _show() {
    _hideTimer?.cancel();
    _controller.forward();
    _hideTimer = Timer(widget.displayDuration, () {
      if (mounted && widget.isInterrupted == false) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Brightness? brightness;
    try {
      brightness = Theme.of(context).brightness;
    } catch (_) {
      brightness = CupertinoTheme.maybeBrightnessOf(context);
    }

    final isDark = brightness == Brightness.dark;

    final defaultBg = widget.backgroundColor ??
        (isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.92)
            : const Color(0xFFF1F5F9).withValues(alpha: 0.96));

    final defaultFg = widget.foregroundColor ??
        (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: defaultBg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: defaultFg.withValues(alpha: 0.25),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 12.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon ??
                  Icon(
                    Icons.hearing_rounded,
                    size: 16.0,
                    color: defaultFg,
                  ),
              const SizedBox(width: 8.0),
              Text(
                widget.message,
                style: TextStyle(
                  color: defaultFg,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
