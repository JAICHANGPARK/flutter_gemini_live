import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/models.dart';
import '../utils/live_session_controller.dart';

/// Builder signature for customizing the label text or widget inside [GeminiLiveToolActivityChip].
typedef GeminiLiveToolLabelBuilder =
    Widget Function(BuildContext context, List<FunctionCall> activeCalls);

/// A restrained, native system-styled status pill that displays in-flight function
/// calls (`toolCall`) or grounding lookups during a Gemini Live session.
///
/// Designed to feel like a native iOS/macOS system status pill rather than a flashy
/// AI indicator. Supports direct binding to [GeminiLiveSessionController.activeToolCalls]
/// or standalone usage via [isExecuting] and [label].
class GeminiLiveToolActivityChip extends StatelessWidget {
  /// Whether a tool or function call is currently executing.
  final bool isExecuting;

  /// Optional list of active [FunctionCall]s when wired to a session.
  final List<FunctionCall> activeCalls;

  /// Optional explicit label override. When null, derives a human-readable
  /// label from [activeCalls] (e.g., `'Running get_weather…'`) or defaults to
  /// `'Working…'`.
  final String? label;

  /// Optional custom widget to replace the default compact progress indicator
  /// while [isExecuting] is `true`.
  final Widget? leadingIcon;

  /// Optional custom widget shown when [isExecuting] is `false` and [hideWhenIdle] is `false`.
  final Widget? completedIcon;

  /// Optional builder for completely customizing the label widget from [activeCalls].
  final GeminiLiveToolLabelBuilder? labelBuilder;

  /// Whether to collapse (`SizedBox.shrink()`) when [isExecuting] is `false`.
  /// Defaults to `true`.
  final bool hideWhenIdle;

  /// Optional tap callback (e.g., to inspect tool call arguments).
  final VoidCallback? onTap;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional text and icon color override.
  final Color? foregroundColor;

  /// Padding inside the capsule.
  final EdgeInsetsGeometry padding;

  /// Corner radius of the capsule. Defaults to `18.0`.
  final double borderRadius;

  /// Creates a native system-styled tool execution status chip.
  const GeminiLiveToolActivityChip({
    super.key,
    required this.isExecuting,
    this.activeCalls = const [],
    this.label,
    this.leadingIcon,
    this.completedIcon,
    this.labelBuilder,
    this.hideWhenIdle = true,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 11.0, vertical: 5.5),
    this.borderRadius = 18.0,
  });

  /// Creates a [GeminiLiveToolActivityChip] directly from a [GeminiLiveSessionController].
  factory GeminiLiveToolActivityChip.fromController({
    Key? key,
    required GeminiLiveSessionController controller,
    String? label,
    Widget? leadingIcon,
    Widget? completedIcon,
    GeminiLiveToolLabelBuilder? labelBuilder,
    bool hideWhenIdle = true,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 11.0,
      vertical: 5.5,
    ),
    double borderRadius = 18.0,
  }) {
    final calls = controller.activeToolCalls;
    return GeminiLiveToolActivityChip(
      key: key,
      isExecuting: calls.isNotEmpty,
      activeCalls: calls,
      label: label,
      leadingIcon: leadingIcon,
      completedIcon: completedIcon,
      labelBuilder: labelBuilder,
      hideWhenIdle: hideWhenIdle,
      onTap: onTap,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  String _resolveLabel() {
    if (label != null && label!.isNotEmpty) return label!;
    if (!isExecuting) return 'Completed';
    if (activeCalls.isEmpty) return 'Working…';
    final firstName = activeCalls.first.name ?? 'tool';
    if (activeCalls.length == 1) {
      return 'Running $firstName…';
    }
    return 'Running $firstName +${activeCalls.length - 1}…';
  }

  @override
  Widget build(BuildContext context) {
    if (!isExecuting && hideWhenIdle) {
      return const SizedBox.shrink();
    }

    Brightness? brightness;
    try {
      brightness = Theme.of(context).brightness;
    } catch (_) {
      brightness = CupertinoTheme.maybeBrightnessOf(context);
    }
    final isDark = brightness == Brightness.dark;

    final effectiveBg =
        backgroundColor ??
        (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5));
    final effectiveFg =
        foregroundColor ??
        (isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A));
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    final Widget leading;
    if (isExecuting) {
      leading =
          leadingIcon ??
          SizedBox(
            width: 12.0,
            height: 12.0,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              valueColor: AlwaysStoppedAnimation<Color>(
                effectiveFg.withValues(alpha: 0.8),
              ),
            ),
          );
    } else {
      leading =
          completedIcon ??
          Icon(
            Icons.check_circle_outline_rounded,
            size: 13.5,
            color: effectiveFg.withValues(alpha: 0.75),
          );
    }

    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 7.5),
          Flexible(
            child:
                labelBuilder?.call(context, activeCalls) ??
                Text(
                  _resolveLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveFg,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
