import 'package:flutter/material.dart';

import '../utils/token_usage_tracker.dart';

/// A sleek status badge displaying real-time token usage and estimated cost
/// for Gemini Live sessions.
///
/// Automatically rebuilds when [tracker] notifies listeners of new usage events.
/// Tapping the badge opens [GeminiLiveUsageDetailsDialog] with full breakdowns.
class GeminiLiveUsageBadge extends StatelessWidget {
  /// The usage tracker providing real-time metrics.
  final GeminiTokenUsageTracker tracker;

  /// Whether to show a compact version without cost details.
  final bool compact;

  /// Whether to show the token coin icon.
  final bool showIcon;

  /// Custom tap callback. If null, displays [GeminiLiveUsageDetailsDialog].
  final VoidCallback? onTap;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional text/icon color override.
  final Color? foregroundColor;

  /// Padding around badge content.
  final EdgeInsetsGeometry padding;

  /// Creates a Material 3 token usage badge wired to [tracker].
  const GeminiLiveUsageBadge({
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
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final bg = backgroundColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05));
        final fg = foregroundColor ?? (isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1F2937));

        final tokenText = tracker.formatTokens();
        final costText = tracker.formatCost();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => _showDetailsDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
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
                  if (showIcon) ...[
                    Icon(
                      Icons.toll_rounded,
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
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GeminiLiveUsageDetailsDialog(tracker: tracker),
    );
  }
}

/// A detailed modal dialog displaying full token metrics, modality breakdowns,
/// and pricing explanations.
class GeminiLiveUsageDetailsDialog extends StatelessWidget {
  /// The usage tracker providing real-time metrics.
  final GeminiTokenUsageTracker tracker;

  /// Creates a Material 3 dialog displaying detailed token metrics from [tracker].
  const GeminiLiveUsageDetailsDialog({
    super.key,
    required this.tracker,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tracker,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 0.5,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.all(12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Gemini Live 사용량 및 비용',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                // Main Highlight Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '총 사용 토큰',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tracker.formatTokens(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF18181B),
                        ),
                      ),
                      Divider(height: 20, color: isDark ? Colors.white12 : Colors.black12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCostItem(
                            label: '종량제 예상 비용',
                            value: tracker.formatCost(),
                            isDark: isDark,
                          ),
                          _buildCostItem(
                            label: 'Free Tier (무료)',
                            value: '\$0.00 (무료)',
                            isDark: isDark,
                            highlightColor: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Detailed breakdown table
                const Text(
                  '세부 모달리티 사용 내역',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF202023) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildMetricRow(
                        label: '입력 프롬프트 토큰 (Prompt)',
                        count: tracker.promptTokens,
                        isDark: isDark,
                      ),
                      if (tracker.audioInputTokens > 0)
                        _buildSubMetricRow('└ 오디오 입력 (Audio In)', tracker.audioInputTokens, isDark),
                      if (tracker.videoInputTokens > 0)
                        _buildSubMetricRow('└ 실시간 영상 입력 (Video In)', tracker.videoInputTokens, isDark),
                      if (tracker.imageInputTokens > 0)
                        _buildSubMetricRow('└ 이미지 입력 (Image In)', tracker.imageInputTokens, isDark),
                      if (tracker.textInputTokens > 0)
                        _buildSubMetricRow('└ 텍스트/시스템 입력 (Text In)', tracker.textInputTokens, isDark),
                      Divider(height: 14, color: isDark ? Colors.white10 : Colors.black12),
                      _buildMetricRow(
                        label: '응답 생성 토큰 (Response)',
                        count: tracker.responseTokens,
                        isDark: isDark,
                      ),
                      if (tracker.audioOutputTokens > 0)
                        _buildSubMetricRow('└ 오디오 출력 (Audio Out)', tracker.audioOutputTokens, isDark),
                      if (tracker.textOutputTokens > 0)
                        _buildSubMetricRow('└ 텍스트 출력 (Text Out)', tracker.textOutputTokens, isDark),
                      if (tracker.cachedTokens > 0) ...[
                        Divider(height: 14, color: isDark ? Colors.white10 : Colors.black12),
                        _buildMetricRow(
                          label: '캐시된 토큰 (Cached)',
                          count: tracker.cachedTokens,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Pricing footnote
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: isDark ? Colors.white60 : Colors.black45),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '현재 모델: ${tracker.model}\n'
                          '• 오디오 입력: \$${tracker.pricingRates.audioInputPerM.toStringAsFixed(2)} / 1M\n'
                          '• 오디오 출력: \$${tracker.pricingRates.audioOutputPerM.toStringAsFixed(2)} / 1M\n'
                          '• 영상/비디오 입력: \$${tracker.pricingRates.videoInputPerM.toStringAsFixed(2)} / 1M\n'
                          '• 텍스트 입력: \$${tracker.pricingRates.textInputPerM.toStringAsFixed(2)} / 1M\n'
                          '• Free Tier 사용 시 비용 청구 \$0.00\n'
                          '• 환율: 1 USD = ${tracker.usdToKrwRate.round()} KRW 적용',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                tracker.reset();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('통계 초기화'),
              style: TextButton.styleFrom(foregroundColor: Colors.white60),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCostItem({
    required String label,
    required String value,
    required bool isDark,
    Color? highlightColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: highlightColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow({
    required String label,
    required int count,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSubMetricRow(String label, int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
