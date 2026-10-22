import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/live_session_controller.dart';

/// Builder signature for customizing the header label inside [GeminiLiveThinkingIndicator].
typedef GeminiLiveThinkingLabelBuilder =
    Widget Function(BuildContext context, bool isThinking, String? thoughtText);

/// An expandable, system-styled Extended Thinking indicator for Gemini 3.8 Live.
///
/// Displays a compact status pill while the model streams internal reasoning parts
/// (`Part(thought: true)`) and optionally lets the user expand a collapsible
/// drawer to inspect the live or completed chain-of-thought summary.
///
/// Can be bound directly to a [GeminiLiveSessionController] via
/// [GeminiLiveThinkingIndicator.fromController] or configured with explicit
/// [isThinking] and [thoughtText] values.
class GeminiLiveThinkingIndicator extends StatefulWidget {
  /// Whether the model is actively streaming thought parts.
  final bool isThinking;

  /// Latest reasoning/thought text emitted by the model, if any.
  final String? thoughtText;

  /// Optional explicit header label override.
  /// Defaults to `'Thinking…'` while [isThinking] is `true`, or `'Thought process'`
  /// when idle with a recorded [thoughtText].
  final String? label;

  /// Optional custom leading widget shown while [isThinking] is `true`.
  final Widget? thinkingIcon;

  /// Optional custom leading widget shown when [isThinking] is `false`.
  final Widget? completedIcon;

  /// Optional builder for customizing the header label widget.
  final GeminiLiveThinkingLabelBuilder? labelBuilder;

  /// Whether tapping the pill expands/collapses the reasoning text drawer
  /// when [thoughtText] is non-empty. Defaults to `true`.
  final bool expandable;

  /// Whether the reasoning text drawer starts expanded. Defaults to `false`.
  final bool initiallyExpanded;

  /// Whether to collapse (`SizedBox.shrink()`) when [isThinking] is `false`
  /// and [thoughtText] is null or empty. Defaults to `true`.
  final bool hideWhenIdle;

  /// Optional tap callback invoked when the header pill is tapped.
  final VoidCallback? onTap;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional text and icon color override.
  final Color? foregroundColor;

  /// Optional accent color for the thinking icon and border highlight.
  final Color? accentColor;

  /// Maximum height of the expanded thought text area before scrolling.
  /// Defaults to `140.0`.
  final double maxExpandedHeight;

  /// Padding inside the header capsule.
  final EdgeInsetsGeometry padding;

  /// Corner radius of the indicator container. Defaults to `16.0`.
  final double borderRadius;

  /// Creates an Extended Thinking status pill and collapsible reasoning drawer.
  const GeminiLiveThinkingIndicator({
    super.key,
    required this.isThinking,
    this.thoughtText,
    this.label,
    this.thinkingIcon,
    this.completedIcon,
    this.labelBuilder,
    this.expandable = true,
    this.initiallyExpanded = false,
    this.hideWhenIdle = true,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.accentColor,
    this.maxExpandedHeight = 140.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.5),
    this.borderRadius = 16.0,
  });

  /// Creates a [GeminiLiveThinkingIndicator] wired directly to a
  /// [GeminiLiveSessionController].
  factory GeminiLiveThinkingIndicator.fromController({
    Key? key,
    required GeminiLiveSessionController controller,
    String? label,
    Widget? thinkingIcon,
    Widget? completedIcon,
    GeminiLiveThinkingLabelBuilder? labelBuilder,
    bool expandable = true,
    bool initiallyExpanded = false,
    bool hideWhenIdle = true,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? accentColor,
    double maxExpandedHeight = 140.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 12.0,
      vertical: 6.5,
    ),
    double borderRadius = 16.0,
  }) {
    return GeminiLiveThinkingIndicator(
      key: key,
      isThinking: controller.isThinking,
      thoughtText: controller.latestThought,
      label: label,
      thinkingIcon: thinkingIcon,
      completedIcon: completedIcon,
      labelBuilder: labelBuilder,
      expandable: expandable,
      initiallyExpanded: initiallyExpanded,
      hideWhenIdle: hideWhenIdle,
      onTap: onTap,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      accentColor: accentColor,
      maxExpandedHeight: maxExpandedHeight,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  @override
  State<GeminiLiveThinkingIndicator> createState() =>
      _GeminiLiveThinkingIndicatorState();
}

class _GeminiLiveThinkingIndicatorState
    extends State<GeminiLiveThinkingIndicator> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  bool get _hasThoughtText =>
      widget.thoughtText != null && widget.thoughtText!.trim().isNotEmpty;

  String _resolveLabel() {
    if (widget.label != null && widget.label!.isNotEmpty) {
      return widget.label!;
    }
    if (widget.isThinking) {
      return 'Thinking…';
    }
    return 'Thought process';
  }

  void _handleTap() {
    widget.onTap?.call();
    if (widget.expandable && _hasThoughtText) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isThinking && widget.hideWhenIdle && !_hasThoughtText) {
      return const SizedBox.shrink();
    }

    Brightness? brightness;
    try {
      brightness = Theme.of(context).brightness;
    } catch (_) {
      brightness = CupertinoTheme.maybeBrightnessOf(context);
    }
    final isDark = brightness == Brightness.dark;

    final effectiveAccent =
        widget.accentColor ??
        (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED));
    final effectiveBg =
        widget.backgroundColor ??
        (isDark ? const Color(0xFF1E1B2E) : const Color(0xFFF5F3FF));
    final effectiveFg =
        widget.foregroundColor ??
        (isDark ? const Color(0xFFEDE9FE) : const Color(0xFF3B0764));
    final borderColor = widget.isThinking
        ? effectiveAccent.withValues(alpha: isDark ? 0.45 : 0.35)
        : (isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08));

    final Widget leading;
    if (widget.isThinking) {
      leading =
          widget.thinkingIcon ??
          Icon(
            Icons.psychology_rounded,
            size: 15.0,
            color: effectiveAccent,
          );
    } else {
      leading =
          widget.completedIcon ??
          Icon(
            Icons.auto_awesome_rounded,
            size: 14.0,
            color: effectiveAccent.withValues(alpha: 0.85),
          );
    }

    final canExpand = widget.expandable && _hasThoughtText;

    final headerRow = Padding(
      padding: widget.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 7.5),
          Flexible(
            child:
                widget.labelBuilder?.call(
                  context,
                  widget.isThinking,
                  widget.thoughtText,
                ) ??
                Text(
                  _resolveLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveFg,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
          ),
          if (canExpand) ...[
            const SizedBox(width: 4.0),
            Icon(
              _isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16.0,
              color: effectiveFg.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerRow,
        if (canExpand && _isExpanded) ...[
          Divider(
            height: 1.0,
            thickness: 0.5,
            color: borderColor,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxExpandedHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 10.0),
              child: Text(
                widget.thoughtText!.trim(),
                style: TextStyle(
                  color: effectiveFg.withValues(alpha: 0.85),
                  fontSize: 11.5,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    final decorated = Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: body,
    );

    if (canExpand || widget.onTap != null) {
      return Semantics(
        button: true,
        toggled: canExpand ? _isExpanded : null,
        label: _resolveLabel(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          child: decorated,
        ),
      );
    }

    return Semantics(
      label: _resolveLabel(),
      child: decorated,
    );
  }
}
