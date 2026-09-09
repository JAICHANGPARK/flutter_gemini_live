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

  /// Padding around the badge content.
  final EdgeInsetsGeometry padding;

  const GeminiLiveStatusBadge({
    super.key,
    required this.state,
    this.interactionStatus,
    this.showLabel = true,
    this.customLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
  });

  /// Convenient factory constructor determining [state] from boolean connection flags
  /// and optional [interactionStatus].
  factory GeminiLiveStatusBadge.fromFlags({
    Key? key,
    required bool isConnected,
    bool isConnecting = false,
    InteractionStatus? interactionStatus,
    bool showLabel = true,
    String? customLabel,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
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
      padding: padding,
    );
  }

  Color _getStatusColor(BuildContext context) {
    if (interactionStatus == InteractionStatus.IN_PROGRESS ||
        state == GeminiLiveSessionState.inProgress) {
      return Colors.blueAccent;
    }

    switch (state) {
      case GeminiLiveSessionState.connected:
        return Colors.green;
      case GeminiLiveSessionState.connecting:
        return Colors.amber.shade700;
      case GeminiLiveSessionState.inProgress:
        return Colors.blueAccent;
      case GeminiLiveSessionState.disconnected:
        return Colors.grey;
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

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: statusColor.withAlpha(30),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: statusColor.withAlpha(100),
          width: 1.0,
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
            const SizedBox(width: 6.0),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: statusColor,
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isPulsing ? 0.8 + (_controller.value * 0.4) : 1.0;
        final opacity =
            widget.isPulsing ? 0.5 + (_controller.value * 0.5) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: Container(
        width: 8.0,
        height: 8.0,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
