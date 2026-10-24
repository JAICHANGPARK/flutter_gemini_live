import 'package:flutter/material.dart';

import '../model/models.dart';
import '../utils/live_session_controller.dart';

/// Signature for building custom content inside [GeminiLiveReconnectBanner].
typedef GeminiLiveReconnectContentBuilder = Widget Function(
  BuildContext context,
  bool isReconnecting,
  int reconnectAttempt,
  LiveServerGoAway? goAway,
  bool isSessionResumable,
);

/// An animated status and action banner for `GoAway` server notices
/// ([LiveServerGoAway]) and automatic session resumption / reconnection
/// ([GeminiLiveReconnectPolicy]).
///
/// Use [GeminiLiveReconnectBanner.fromController] to bind directly to a
/// [GeminiLiveSessionController] with zero boilerplate, or construct
/// [GeminiLiveReconnectBanner] directly with custom state and callbacks.
class GeminiLiveReconnectBanner extends StatelessWidget {
  /// Optional controller to listen to automatically.
  final GeminiLiveSessionController? controller;

  /// Whether a reconnection attempt is currently in progress.
  final bool isReconnecting;

  /// Current reconnection attempt index (1-based when displayed).
  final int reconnectAttempt;

  /// Optional maximum reconnection attempts configured on the policy.
  final int? maxAttempts;

  /// Optional `GoAway` notice received from the server.
  final LiveServerGoAway? goAway;

  /// Whether the session has a valid resumption handle (`sessionResumptionUpdate.resumable`).
  final bool isSessionResumable;

  /// Callback invoked when the user taps the manual reconnect / retry action button.
  final VoidCallback? onReconnectNow;

  /// Callback invoked when the user taps the cancel reconnect button.
  final VoidCallback? onCancel;

  /// Optional custom content builder for full layout control.
  final GeminiLiveReconnectContentBuilder? contentBuilder;

  /// Optional custom trailing action widget builder.
  final WidgetBuilder? actionBuilder;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional foreground text/icon color override.
  final Color? foregroundColor;

  /// Border radius of the banner. Defaults to `14.0`.
  final BorderRadiusGeometry borderRadius;

  /// Inner padding of the banner.
  final EdgeInsetsGeometry padding;

  /// Creates a [GeminiLiveReconnectBanner].
  const GeminiLiveReconnectBanner({
    super.key,
    this.controller,
    this.isReconnecting = false,
    this.reconnectAttempt = 0,
    this.maxAttempts,
    this.goAway,
    this.isSessionResumable = false,
    this.onReconnectNow,
    this.onCancel,
    this.contentBuilder,
    this.actionBuilder,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(14.0)),
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
  });

  /// Creates a reactive [GeminiLiveReconnectBanner] bound to [controller].
  factory GeminiLiveReconnectBanner.fromController({
    Key? key,
    required GeminiLiveSessionController controller,
    VoidCallback? onReconnectNow,
    VoidCallback? onCancel,
    GeminiLiveReconnectContentBuilder? contentBuilder,
    WidgetBuilder? actionBuilder,
    Color? backgroundColor,
    Color? foregroundColor,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(14.0),
    ),
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 14.0,
      vertical: 10.0,
    ),
  }) {
    return GeminiLiveReconnectBanner(
      key: key,
      controller: controller,
      onReconnectNow: onReconnectNow,
      onCancel: onCancel ?? controller.disconnect,
      contentBuilder: contentBuilder,
      actionBuilder: actionBuilder,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      borderRadius: borderRadius,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return ListenableBuilder(
        listenable: controller!,
        builder: (context, _) {
          return _buildBanner(
            context,
            effectiveReconnecting: controller!.isReconnecting,
            effectiveAttempt: controller!.reconnectAttempt,
            effectiveMaxAttempts: controller!.reconnectPolicy?.maxAttempts,
            effectiveGoAway: controller!.lastGoAway,
            effectiveResumable:
                controller!.isSessionResumable ||
                controller!.latestSessionHandle != null,
          );
        },
      );
    }

    return _buildBanner(
      context,
      effectiveReconnecting: isReconnecting,
      effectiveAttempt: reconnectAttempt,
      effectiveMaxAttempts: maxAttempts,
      effectiveGoAway: goAway,
      effectiveResumable: isSessionResumable,
    );
  }

  Widget _buildBanner(
    BuildContext context, {
    required bool effectiveReconnecting,
    required int effectiveAttempt,
    required int? effectiveMaxAttempts,
    required LiveServerGoAway? effectiveGoAway,
    required bool effectiveResumable,
  }) {
    if (!effectiveReconnecting && effectiveGoAway == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ??
        (isDark ? const Color(0xFF422006) : const Color(0xFFFEF3C7));
    final fg =
        foregroundColor ??
        (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E));

    if (contentBuilder != null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(color: bg, borderRadius: borderRadius),
        child: contentBuilder!(
          context,
          effectiveReconnecting,
          effectiveAttempt,
          effectiveGoAway,
          effectiveResumable,
        ),
      );
    }

    final attemptSuffix = effectiveMaxAttempts != null
        ? ' ($effectiveAttempt/$effectiveMaxAttempts)'
        : (effectiveAttempt > 0 ? ' (attempt $effectiveAttempt)' : '');
    final headline = effectiveReconnecting
        ? 'Reconnecting session$attemptSuffix…'
        : 'Server connection closing soon (${effectiveGoAway?.timeLeft ?? "GoAway"})';
    final subtext = effectiveResumable
        ? 'Session handle saved — conversation context will resume automatically.'
        : 'Attempting to re-establish WebSocket connection.';

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
        border: Border.all(
          color: fg.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          if (effectiveReconnecting)
            SizedBox(
              width: 16.0,
              height: 16.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            )
          else
            Icon(Icons.schedule_rounded, size: 18.0, color: fg),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 11.0,
                    color: fg.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (actionBuilder != null)
            actionBuilder!(context)
          else ...[
            if (onReconnectNow != null)
              TextButton(
                onPressed: onReconnectNow,
                child: Text(
                  'Reconnect',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            if (effectiveReconnecting && onCancel != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Cancel Reconnect',
                onPressed: onCancel,
                icon: Icon(Icons.close_rounded, size: 16.0, color: fg),
              ),
          ],
        ],
      ),
    );
  }
}
