import 'package:flutter/cupertino.dart';

import '../utils/token_usage_tracker.dart';

/// An iOS / Cupertino-styled token usage badge displaying real-time token metrics
/// and estimated cost for Gemini Live sessions.
///
/// Tapping the badge opens [CupertinoGeminiLiveUsageDetailsDialog] with full breakdowns
/// using iOS modal presentation.
class CupertinoGeminiLiveUsageBadge extends StatelessWidget {
  /// The usage tracker providing real-time metrics.
  final GeminiTokenUsageTracker tracker;

  /// Whether to show a compact version without cost details.
  final bool compact;

  /// Whether to show the token icon.
  final bool showIcon;

  /// Custom tap callback. If null, displays [CupertinoGeminiLiveUsageDetailsDialog].
  final VoidCallback? onTap;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional text/icon color override.
  final Color? foregroundColor;

  /// Padding around badge content.
  final EdgeInsetsGeometry padding;

  const CupertinoGeminiLiveUsageBadge({
    super.key,
    required this.tracker,
    this.compact = false,
    this.showIcon = true,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tracker,
      builder: (context, _) {
        final isDark =
            CupertinoTheme.of(context).brightness == Brightness.dark;

        final bg = backgroundColor ??
            (isDark
                ? CupertinoColors.systemGrey6.darkColor.withValues(alpha: 0.6)
                : CupertinoColors.systemGrey6.color.withValues(alpha: 0.8));
        final fg = foregroundColor ??
            CupertinoColors.label.resolveFrom(context);

        final tokenText = tracker.formatTokens();
        final costText = tracker.formatCost();

        return GestureDetector(
          onTap: onTap ?? () => _showDetailsDialog(context),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
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
                if (showIcon) ...[
                  Icon(
                    CupertinoIcons.chart_bar_alt_fill,
                    size: 13,
                    color: fg.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  tokenText,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                if (!compact && tracker.totalTokens > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    costText,
                    style: TextStyle(
                      color: isDark
                          ? CupertinoColors.systemGreen.darkColor
                          : CupertinoColors.systemGreen.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) =>
          CupertinoGeminiLiveUsageDetailsDialog(tracker: tracker),
    );
  }
}

/// An iOS / Cupertino-styled modal dialog presenting token usage breakdowns.
class CupertinoGeminiLiveUsageDetailsDialog extends StatelessWidget {
  final GeminiTokenUsageTracker tracker;

  const CupertinoGeminiLiveUsageDetailsDialog({
    super.key,
    required this.tracker,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tracker,
      builder: (context, _) {
        final isDark =
            CupertinoTheme.of(context).brightness == Brightness.dark;

        return CupertinoAlertDialog(
          title: Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.waveform_circle_fill,
                  size: 20,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'Gemini Live Usage',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary box
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.systemGrey5.darkColor
                      : CupertinoColors.systemGrey5.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Tokens',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.secondaryLabel
                            .resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tracker.formatTokens(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Estimated: ${tracker.formatCost(showKrw: false)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.secondaryLabel
                            .resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _buildMetricRow(
                'Prompt Tokens',
                '${tracker.promptTokens}',
                context,
              ),
              if (tracker.audioInputTokens > 0)
                _buildSubMetricRow('Audio In', '${tracker.audioInputTokens}', context),
              if (tracker.videoInputTokens > 0)
                _buildSubMetricRow('Video In', '${tracker.videoInputTokens}', context),
              if (tracker.textInputTokens > 0)
                _buildSubMetricRow('Text In', '${tracker.textInputTokens}', context),
              const SizedBox(height: 4),
              _buildMetricRow(
                'Response Tokens',
                '${tracker.responseTokens}',
                context,
              ),
              if (tracker.audioOutputTokens > 0)
                _buildSubMetricRow('Audio Out', '${tracker.audioOutputTokens}', context),
              if (tracker.textOutputTokens > 0)
                _buildSubMetricRow('Text Out', '${tracker.textOutputTokens}', context),
              if (tracker.cachedTokens > 0) ...[
                const SizedBox(height: 4),
                _buildMetricRow(
                  'Cached Tokens',
                  '${tracker.cachedTokens}',
                  context,
                ),
              ],
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => tracker.reset(),
              isDestructiveAction: true,
              child: const Text('Reset'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              isDefaultAction: true,
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetricRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 1.0, bottom: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '• $label',
            style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
