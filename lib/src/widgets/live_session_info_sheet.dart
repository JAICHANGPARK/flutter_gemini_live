import 'package:flutter/material.dart';

import '../model/models.dart';
import '../utils/live_session_controller.dart';
import 'live_adaptive_layout.dart';

/// Signature for building a custom diagnostic key-value row in [GeminiLiveSessionInfoSheet].
typedef GeminiLiveSessionInfoRowBuilder = Widget Function(
  BuildContext context,
  String label,
  String value,
);

/// A compact pill badge displaying the active Gemini Live `sessionId` (or
/// connection status) that opens [GeminiLiveSessionInfoSheet] when tapped.
class GeminiLiveSessionInfoBadge extends StatelessWidget {
  /// Controller to observe for session metadata.
  final GeminiLiveSessionController controller;

  /// Optional custom label override.
  final String? label;

  /// Optional tap override. When `null`, tapping opens [GeminiLiveSessionInfoSheet.show].
  final VoidCallback? onTap;

  /// Optional HTTP transport options to display in the inspector sheet.
  final HttpOptions? httpOptions;

  /// Optional metadata labels to display in the inspector sheet.
  final Map<String, String>? labels;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional foreground text/icon color override.
  final Color? foregroundColor;

  /// Creates a [GeminiLiveSessionInfoBadge].
  const GeminiLiveSessionInfoBadge({
    super.key,
    required this.controller,
    this.label,
    this.onTap,
    this.httpOptions,
    this.labels,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final sessionId = controller.sessionId;
        final shortId = sessionId != null && sessionId.length > 10
            ? '${sessionId.substring(0, 10)}…'
            : (sessionId ?? controller.state.name);
        final displayText = label ?? 'ID: $shortId';

        final bg =
            backgroundColor ??
            (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5));
        final fg =
            foregroundColor ??
            (isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A));

        return InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap:
              onTap ??
              () {
                GeminiLiveSessionInfoSheet.show(
                  context,
                  controller: controller,
                  httpOptions: httpOptions,
                  labels: labels,
                );
              },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 5.0,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14.0,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 5.0),
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A diagnostic bottom sheet inspecting the active [GeminiLiveSessionController]
/// state (`sessionId`, `sessionResumption` handle, active tools, `HttpOptions`,
/// `labels`, and real-time token/cost metrics).
class GeminiLiveSessionInfoSheet extends StatelessWidget {
  /// Controller providing live session diagnostics.
  final GeminiLiveSessionController controller;

  /// Optional HTTP/WebSocket transport options to display.
  final HttpOptions? httpOptions;

  /// Optional metadata labels to display.
  final Map<String, String>? labels;

  /// Optional custom row builder for each diagnostic entry.
  final GeminiLiveSessionInfoRowBuilder? rowBuilder;

  /// Sheet title text. Defaults to `'Live Session Inspector'`.
  final String title;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Creates a [GeminiLiveSessionInfoSheet].
  const GeminiLiveSessionInfoSheet({
    super.key,
    required this.controller,
    this.httpOptions,
    this.labels,
    this.rowBuilder,
    this.title = 'Live Session Inspector',
    this.backgroundColor,
  });

  /// Displays [GeminiLiveSessionInfoSheet] as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required GeminiLiveSessionController controller,
    HttpOptions? httpOptions,
    Map<String, String>? labels,
    GeminiLiveSessionInfoRowBuilder? rowBuilder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GeminiLiveSessionInfoSheet(
        controller: controller,
        httpOptions: httpOptions,
        labels: labels,
        rowBuilder: rowBuilder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final bg =
            backgroundColor ??
            (isDark ? const Color(0xFF18181B) : Colors.white);
        final tracker = controller.tokenTracker;
        final metrics = controller.connectionMetrics;
        final effectiveHttp =
            httpOptions ?? controller.liveService.httpOptions;

        final entries = <MapEntry<String, String>>[
          MapEntry('Connection State', controller.state.name),
          MapEntry('Session ID', controller.sessionId ?? 'Not assigned'),
          MapEntry('Stability Score', metrics.formatStabilitySummary()),
          MapEntry('Setup Latency', metrics.formatSetupLatency()),
          MapEntry('TTFA Latency', metrics.formatTtfaLatency()),
          MapEntry(
            'Session Resumable',
            controller.isSessionResumable ||
                    controller.latestSessionHandle != null
                ? 'Yes (${controller.latestSessionHandle ?? "active"})'
                : 'No',
          ),
          if (metrics.reconnectAttempts > 0 || metrics.abnormalDisconnects > 0)
            MapEntry(
              'Recovery (SRR / MTTR)',
              '${(metrics.recoverySuccessRate * 100).toStringAsFixed(0)}% / ${metrics.mttrMs.round()} ms',
            ),
          MapEntry('Active Tools', '${controller.activeTools.length}'),
          MapEntry(
            'In-Flight Tool Calls',
            '${controller.activeToolCalls.length}',
          ),
          MapEntry(
            'API Version',
            effectiveHttp?.apiVersion ?? controller.liveService.apiVersion,
          ),
          if (effectiveHttp?.baseUrl != null)
            MapEntry('Custom Base URL', effectiveHttp!.baseUrl!),
          if (effectiveHttp?.headers != null &&
              effectiveHttp!.headers!.isNotEmpty)
            MapEntry(
              'Custom Header Keys',
              effectiveHttp.headers!.keys.join(', '),
            ),
          if (labels != null && labels!.isNotEmpty)
            MapEntry(
              'Labels',
              labels!.entries.map((e) => '${e.key}=${e.value}').join(', '),
            ),
          MapEntry('Total Tokens', '${tracker.totalTokens}'),
          MapEntry(
            'Estimated Cost (USD)',
            '\$${tracker.estimatedCostUsd.toStringAsFixed(5)}',
          ),
        ];

        return GeminiLiveAdaptiveSheetContainer(
          backgroundColor: bg,
          padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 28.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Center(
                child: Container(
                  width: 36.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 14.0),
              Row(
                children: [
                  Icon(
                    Icons.troubleshoot_rounded,
                    color: theme.colorScheme.primary,
                    size: 22.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              for (final entry in entries)
                rowBuilder != null
                    ? rowBuilder!(context, entry.key, entry.value)
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                entry.value,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
