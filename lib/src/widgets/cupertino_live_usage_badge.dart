import 'package:flutter/cupertino.dart';

import '../utils/token_usage_tracker.dart';
import 'live_usage_badge.dart';

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

  /// Optional explicit language code (`'en'`, `'ko'`, `'ja'`, `'zh'`).
  final String? languageCode;

  /// Creates a Cupertino token usage badge wired to [tracker].
  const CupertinoGeminiLiveUsageBadge({
    super.key,
    required this.tracker,
    this.compact = false,
    this.showIcon = true,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
    this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        tracker,
        GeminiLiveUsageBadge.languageNotifier,
      ]),
      builder: (context, _) {
        final isDark =
            CupertinoTheme.of(context).brightness == Brightness.dark;
        final lang = GeminiLiveUsageBadge.resolveLanguageCode(
          context,
          explicitCode: languageCode,
          fallback: 'en',
        );

        final bg = backgroundColor ??
            (isDark
                ? CupertinoColors.systemGrey6.darkColor.withValues(alpha: 0.6)
                : CupertinoColors.systemGrey6.color.withValues(alpha: 0.8));
        final fg = foregroundColor ??
            CupertinoColors.label.resolveFrom(context);

        final tokenText = tracker.formatTokens();
        final costText = tracker.formatCostForLanguage(lang);

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
      builder: (context) => CupertinoGeminiLiveUsageDetailsDialog(
        tracker: tracker,
        languageCode: languageCode,
      ),
    );
  }
}

/// An iOS / Cupertino-styled modal dialog presenting token usage breakdowns.
class CupertinoGeminiLiveUsageDetailsDialog extends StatelessWidget {
  /// The usage tracker providing real-time metrics.
  final GeminiTokenUsageTracker tracker;

  /// Optional explicit language code (`'en'`, `'ko'`, `'ja'`, `'zh'`).
  final String? languageCode;

  /// Creates a Cupertino dialog displaying detailed token metrics from [tracker].
  const CupertinoGeminiLiveUsageDetailsDialog({
    super.key,
    required this.tracker,
    this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        tracker,
        GeminiLiveUsageBadge.languageNotifier,
      ]),
      builder: (context, _) {
        final isDark =
            CupertinoTheme.of(context).brightness == Brightness.dark;
        final lang = GeminiLiveUsageBadge.resolveLanguageCode(
          context,
          explicitCode: languageCode,
          fallback: 'en',
        );

        final titleText = switch (lang) {
          'ko' => 'Gemini Live 사용량',
          'ja' => 'Gemini Live 使用量',
          'zh' => 'Gemini Live 用量',
          _ => 'Gemini Live Usage',
        };
        final totalLabel = switch (lang) {
          'ko' => '총 토큰',
          'ja' => '総トークン数',
          'zh' => '总 Token 数',
          _ => 'Total Tokens',
        };
        final estimatedPrefix = switch (lang) {
          'ko' => '예상 비용',
          'ja' => '推定コスト',
          'zh' => '预估费用',
          _ => 'Estimated',
        };
        final promptLabel = switch (lang) {
          'ko' => '입력 프롬프트 토큰',
          'ja' => '入力プロンプトトークン',
          'zh' => '输入提示词 Token',
          _ => 'Prompt Tokens',
        };
        final responseLabel = switch (lang) {
          'ko' => '응답 생성 토큰',
          'ja' => '応答生成トークン',
          'zh' => '响应生成 Token',
          _ => 'Response Tokens',
        };
        final cachedLabel = switch (lang) {
          'ko' => '캐시된 토큰',
          'ja' => 'キャッシュ済みトークン',
          'zh' => '已缓存 Token',
          _ => 'Cached Tokens',
        };
        final resetLabel = switch (lang) {
          'ko' => '초기화',
          'ja' => 'リセット',
          'zh' => '重置',
          _ => 'Reset',
        };
        final doneLabel = switch (lang) {
          'ko' => '완료',
          'ja' => '完了',
          'zh' => '完成',
          _ => 'Done',
        };

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
                Flexible(
                  child: Text(
                    titleText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                      totalLabel,
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
                      '$estimatedPrefix: ${tracker.formatCostForLanguage(lang)}',
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
                promptLabel,
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
                responseLabel,
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
                  cachedLabel,
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
              child: Text(resetLabel),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              isDefaultAction: true,
              child: Text(doneLabel),
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
