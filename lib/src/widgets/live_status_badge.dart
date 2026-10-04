import 'package:flutter/material.dart';

import '../model/models.dart';

/// Connection and activity state of a Gemini Live session.
enum GeminiLiveSessionState {
  /// WebSocket is closed or not yet connected.
  disconnected,

  /// Connecting to the Live API WebSocket.
  connecting,

  /// Connected and ready for user input (idle).
  connected,

  /// Model is actively streaming responses or processing tools (in progress).
  inProgress,
}

/// A compact status badge displaying the current Gemini Live session status
/// and activity state.
///
/// Automatically formats colors and icons according to [GeminiLiveSessionState]
/// and [InteractionStatus].
class GeminiLiveStatusBadge extends StatelessWidget {
  /// The current state of the session.
  final GeminiLiveSessionState state;

  /// Optional specific interaction status reported by the Live server.
  final InteractionStatus? interactionStatus;

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

  const GeminiLiveStatusBadge({
    super.key,
    required this.state,
    this.interactionStatus,
    this.showLabel = true,
    this.customLabel,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
  });

  /// Creates a status badge determining [state] from boolean connection flags
  /// and optional [interactionStatus].
  factory GeminiLiveStatusBadge.fromFlags({
    Key? key,
    required bool isConnected,
    bool isConnecting = false,
    InteractionStatus? interactionStatus,
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
        : (interactionStatus == InteractionStatus.IN_PROGRESS
            ? GeminiLiveSessionState.inProgress
            : GeminiLiveSessionState.connected);
    return GeminiLiveStatusBadge(
      key: key,
      state: state,
      interactionStatus: interactionStatus,
      showLabel: showLabel,
      customLabel: customLabel,
      backgroundColor: backgroundColor,
      textColor: textColor,
      borderRadius: borderRadius,
      padding: padding,
    );
  }

  Color _getStatusColor(BuildContext context) {
    if (interactionStatus == InteractionStatus.IN_PROGRESS ||
        state == GeminiLiveSessionState.inProgress) {
      return const Color(0xFF3B82F6); // Refined calm electric blue
    }

    switch (state) {
      case GeminiLiveSessionState.connected:
        return const Color(0xFF10B981); // Emerald green
      case GeminiLiveSessionState.connecting:
        return const Color(0xFFF59E0B); // Amber
      case GeminiLiveSessionState.inProgress:
        return const Color(0xFF3B82F6); // Electric blue
      case GeminiLiveSessionState.disconnected:
        return const Color(0xFF9CA3AF); // Muted neutral slate
    }
  }

  String _getStatusText() {
    if (customLabel != null) return customLabel!;

    if (interactionStatus == InteractionStatus.IN_PROGRESS ||
        state == GeminiLiveSessionState.inProgress) {
      return 'Thinking / Speaking';
    }

    switch (state) {
      case GeminiLiveSessionState.connected:
        return 'Ready (Idle)';
      case GeminiLiveSessionState.connecting:
        return 'Connecting...';
      case GeminiLiveSessionState.inProgress:
        return 'In Progress';
      case GeminiLiveSessionState.disconnected:
        return 'Disconnected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final isAnimated = state == GeminiLiveSessionState.connecting ||
        state == GeminiLiveSessionState.inProgress ||
        interactionStatus == InteractionStatus.IN_PROGRESS;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05));

    final effectiveTextColor = textColor ??
        (isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1F2937));

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(
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

class _PulseDot extends StatefulWidget {
  final Color color;
  final bool isPulsing;

  const _PulseDot({required this.color, required this.isPulsing});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
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
  void didUpdateWidget(_PulseDot oldWidget) {
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
