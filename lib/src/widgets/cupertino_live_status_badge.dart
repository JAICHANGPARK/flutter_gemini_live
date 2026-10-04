import 'package:flutter/cupertino.dart';

import 'live_status_badge.dart';

export 'live_status_badge.dart' show GeminiLiveSessionState;

/// An iOS / Cupertino-styled status badge displaying the current Gemini Live
/// session status and activity state.
///
/// Designed with Apple Human Interface Guidelines in mind:
/// - iOS translucent material background styling
/// - Cupertino Dynamic System Colors ([CupertinoColors])
/// - Subtle typography and pulsing indicator dot
class CupertinoGeminiLiveStatusBadge extends StatelessWidget {
  /// The current state of the session.
  final GeminiLiveSessionState state;

  /// Whether to show a text label alongside the status indicator dot.
  final bool showLabel;

  /// Optional custom label to display instead of the default text.
  final String? customLabel;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional text color override.
  final Color? textColor;

  /// Border radius of the status capsule. Defaults to 20.0.
  final double borderRadius;

  /// Padding around the badge content.
  final EdgeInsetsGeometry padding;

  /// Creates a Cupertino status badge with the given [state].
  const CupertinoGeminiLiveStatusBadge({
    super.key,
    required this.state,
    this.showLabel = true,
    this.customLabel,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
  });

  /// Creates a status badge determining [state] from boolean connection flags.
  factory CupertinoGeminiLiveStatusBadge.fromFlags({
    Key? key,
    required bool isConnected,
    bool isConnecting = false,
    bool isInProgress = false,
    bool showLabel = true,
    String? customLabel,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 20.0,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
  }) {
    final state = !isConnected
        ? (isConnecting
            ? GeminiLiveSessionState.connecting
            : GeminiLiveSessionState.disconnected)
        : (isInProgress
            ? GeminiLiveSessionState.inProgress
            : GeminiLiveSessionState.connected);
    return CupertinoGeminiLiveStatusBadge(
      key: key,
      state: state,
      showLabel: showLabel,
      customLabel: customLabel,
      backgroundColor: backgroundColor,
      textColor: textColor,
      borderRadius: borderRadius,
      padding: padding,
    );
  }

  Color _getStatusColor(BuildContext context) {
    switch (state) {
      case GeminiLiveSessionState.connected:
        return CupertinoColors.systemGreen.resolveFrom(context);
      case GeminiLiveSessionState.connecting:
        return CupertinoColors.systemOrange.resolveFrom(context);
      case GeminiLiveSessionState.inProgress:
        return CupertinoColors.systemBlue.resolveFrom(context);
      case GeminiLiveSessionState.disconnected:
        return CupertinoColors.systemGrey.resolveFrom(context);
    }
  }

  String _getStatusText() {
    if (customLabel != null) return customLabel!;

    switch (state) {
      case GeminiLiveSessionState.connected:
        return 'Ready';
      case GeminiLiveSessionState.connecting:
        return 'Connecting...';
      case GeminiLiveSessionState.inProgress:
        return 'Speaking...';
      case GeminiLiveSessionState.disconnected:
        return 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final isAnimated = state == GeminiLiveSessionState.connecting ||
        state == GeminiLiveSessionState.inProgress;

    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    final defaultBg = backgroundColor ??
        (isDark
            ? CupertinoColors.systemGrey6.darkColor.withValues(alpha: 0.6)
            : CupertinoColors.systemGrey6.color.withValues(alpha: 0.8));

    final effectiveTextColor = textColor ??
        CupertinoColors.label.resolveFrom(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withValues(alpha: 0.12)
              : CupertinoColors.black.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CupertinoPulseDot(
            color: statusColor,
            isPulsing: isAnimated,
          ),
          if (showLabel) ...[
            const SizedBox(width: 7.0),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                color: effectiveTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CupertinoPulseDot extends StatefulWidget {
  final Color color;
  final bool isPulsing;

  const _CupertinoPulseDot({required this.color, required this.isPulsing});

  @override
  State<_CupertinoPulseDot> createState() => _CupertinoPulseDotState();
}

class _CupertinoPulseDotState extends State<_CupertinoPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_CupertinoPulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
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
    if (!widget.isPulsing) {
      return Container(
        width: 7.0,
        height: 7.0,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final haloScale = 1.0 + (_controller.value * 0.9);
        final haloOpacity = (1.0 - _controller.value).clamp(0.0, 0.45);

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: haloScale,
              child: Container(
                width: 7.0,
                height: 7.0,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: haloOpacity),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 7.0,
        height: 7.0,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
