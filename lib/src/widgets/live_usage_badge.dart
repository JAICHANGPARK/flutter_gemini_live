import 'package:flutter/material.dart';

import '../utils/token_usage_tracker.dart';

/// A sleek status badge displaying real-time token usage and estimated cost
/// for Gemini Live sessions.
///
/// Automatically rebuilds when [tracker] notifies listeners of new usage events.
/// Tapping the badge opens [GeminiLiveUsageDetailsDialog] with full breakdowns.
class GeminiLiveUsageBadge extends StatelessWidget {
  /// Global language notifier (`'en'`, `'ko'`, `'ja'`, `'zh'`) for apps that
  /// switch languages dynamically without `flutter_localizations`.
  static final ValueNotifier<String?> languageNotifier =
      ValueNotifier<String?>(null);

  /// Gets the global default language code (`'en'`, `'ko'`, `'ja'`, `'zh'`).
  static String? get defaultLanguageCode => languageNotifier.value;

  /// Sets the global default language code (`'en'`, `'ko'`, `'ja'`, `'zh'`).
  static set defaultLanguageCode(String? code) {
    languageNotifier.value = code;
  }

  /// Resolves the active language code from [explicitCode], [languageNotifier],
  /// or [Localizations.maybeLocaleOf], falling back to [fallback].
  static String resolveLanguageCode(
    BuildContext context, {
    String? explicitCode,
    String fallback = 'ko',
  }) {
    if (explicitCode != null && explicitCode.isNotEmpty) {
      return explicitCode.toLowerCase();
    }
    final globalCode = languageNotifier.value;
    if (globalCode != null && globalCode.isNotEmpty) {
      return globalCode.toLowerCase();
    }
    final locale = Localizations.maybeLocaleOf(context);
    if (locale != null) {
      final code = locale.languageCode.toLowerCase();
      if (code == 'ja' || code == 'zh' || code == 'ko') {
        return code;
      }
      if (code == 'en' &&
          (locale.countryCode == null || locale.countryCode!.isEmpty)) {
        return 'en';
      }
    }
    return fallback;
  }

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

  /// Optional explicit language code (`'en'`, `'ko'`, `'ja'`, `'zh'`).
  final String? languageCode;

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
    this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([tracker, languageNotifier]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final lang = resolveLanguageCode(
          context,
          explicitCode: languageCode,
          fallback: 'ko',
        );

        final bg = backgroundColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05));
        final fg = foregroundColor ?? (isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1F2937));

        final tokenText = tracker.formatTokens();
        final costText = tracker.formatCostForLanguage(lang);

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
      builder: (context) => GeminiLiveUsageDetailsDialog(
        tracker: tracker,
        languageCode: languageCode,
      ),
    );
  }
}

/// A detailed modal dialog displaying full token metrics, modality breakdowns,
/// and pricing explanations with multi-language support (`en`, `ko`, `ja`, `zh`).
class GeminiLiveUsageDetailsDialog extends StatelessWidget {
  /// The usage tracker providing real-time metrics.
  final GeminiTokenUsageTracker tracker;

  /// Optional explicit language code (`'en'`, `'ko'`, `'ja'`, `'zh'`).
  final String? languageCode;

  /// Creates a Material 3 dialog displaying detailed token metrics from [tracker].
  const GeminiLiveUsageDetailsDialog({
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final lang = GeminiLiveUsageBadge.resolveLanguageCode(
          context,
          explicitCode: languageCode,
          fallback: 'ko',
        );
        final l10n = _UsageDialogStrings.of(lang);

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
              Flexible(
                child: Text(
                  l10n.dialogTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
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
                        l10n.totalTokensLabel,
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
                            label: l10n.paidTierCostLabel,
                            value: tracker.formatCostForLanguage(lang),
                            isDark: isDark,
                          ),
                          _buildCostItem(
                            label: l10n.freeTierLabel,
                            value: l10n.freeTierValue,
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
                Text(
                  l10n.breakdownHeader,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                        label: l10n.promptTokensLabel,
                        count: tracker.promptTokens,
                        isDark: isDark,
                      ),
                      if (tracker.audioInputTokens > 0)
                        _buildSubMetricRow(l10n.audioInSubLabel, tracker.audioInputTokens, isDark),
                      if (tracker.videoInputTokens > 0)
                        _buildSubMetricRow(l10n.videoInSubLabel, tracker.videoInputTokens, isDark),
                      if (tracker.imageInputTokens > 0)
                        _buildSubMetricRow(l10n.imageInSubLabel, tracker.imageInputTokens, isDark),
                      if (tracker.textInputTokens > 0)
                        _buildSubMetricRow(l10n.textInSubLabel, tracker.textInputTokens, isDark),
                      Divider(height: 14, color: isDark ? Colors.white10 : Colors.black12),
                      _buildMetricRow(
                        label: l10n.responseTokensLabel,
                        count: tracker.responseTokens,
                        isDark: isDark,
                      ),
                      if (tracker.audioOutputTokens > 0)
                        _buildSubMetricRow(l10n.audioOutSubLabel, tracker.audioOutputTokens, isDark),
                      if (tracker.textOutputTokens > 0)
                        _buildSubMetricRow(l10n.textOutSubLabel, tracker.textOutputTokens, isDark),
                      if (tracker.cachedTokens > 0) ...[
                        Divider(height: 14, color: isDark ? Colors.white10 : Colors.black12),
                        _buildMetricRow(
                          label: l10n.cachedTokensLabel,
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
                          l10n.pricingFootnote(tracker),
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
              label: Text(l10n.resetButtonLabel),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.closeButtonLabel),
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

class _UsageDialogStrings {
  final String languageCode;

  const _UsageDialogStrings._(this.languageCode);

  factory _UsageDialogStrings.of(String languageCode) {
    return _UsageDialogStrings._(languageCode.toLowerCase());
  }

  String get dialogTitle => switch (languageCode) {
    'en' => 'Gemini Live Usage & Cost',
    'ja' => 'Gemini Live 使用量とコスト',
    'zh' => 'Gemini Live 用量与费用',
    _ => 'Gemini Live 사용량 및 비용',
  };

  String get totalTokensLabel => switch (languageCode) {
    'en' => 'Total Tokens Used',
    'ja' => '総使用トークン数',
    'zh' => '总使用 Token 数',
    _ => '총 사용 토큰',
  };

  String get paidTierCostLabel => switch (languageCode) {
    'en' => 'Estimated Paid Cost',
    'ja' => '従量課金 推定コスト',
    'zh' => '按量计费预估费用',
    _ => '종량제 예상 비용',
  };

  String get freeTierLabel => switch (languageCode) {
    'en' => 'Free Tier',
    'ja' => 'Free Tier (無料枠)',
    'zh' => 'Free Tier (免费额度)',
    _ => 'Free Tier (무료)',
  };

  String get freeTierValue => switch (languageCode) {
    'en' => '\$0.00 (Free)',
    'ja' => '\$0.00 (無料)',
    'zh' => '\$0.00 (免费)',
    _ => '\$0.00 (무료)',
  };

  String get breakdownHeader => switch (languageCode) {
    'en' => 'Modality Usage Breakdown',
    'ja' => 'モダリティ別使用内訳',
    'zh' => '各模态详细用量明细',
    _ => '세부 모달리티 사용 내역',
  };

  String get promptTokensLabel => switch (languageCode) {
    'en' => 'Prompt Input Tokens (Prompt)',
    'ja' => '入力プロンプトトークン (Prompt)',
    'zh' => '输入提示词 Token (Prompt)',
    _ => '입력 프롬프트 토큰 (Prompt)',
  };

  String get audioInSubLabel => switch (languageCode) {
    'en' => '└ Audio Input (Audio In)',
    'ja' => '└ 音声入力 (Audio In)',
    'zh' => '└ 音频输入 (Audio In)',
    _ => '└ 오디오 입력 (Audio In)',
  };

  String get videoInSubLabel => switch (languageCode) {
    'en' => '└ Live Video Input (Video In)',
    'ja' => '└ リアルタイム映像入力 (Video In)',
    'zh' => '└ 实时视频输入 (Video In)',
    _ => '└ 실시간 영상 입력 (Video In)',
  };

  String get imageInSubLabel => switch (languageCode) {
    'en' => '└ Image Input (Image In)',
    'ja' => '└ 画像入力 (Image In)',
    'zh' => '└ 图像输入 (Image In)',
    _ => '└ 이미지 입력 (Image In)',
  };

  String get textInSubLabel => switch (languageCode) {
    'en' => '└ Text / System Input (Text In)',
    'ja' => '└ テキスト/システム入力 (Text In)',
    'zh' => '└ 文本/系统输入 (Text In)',
    _ => '└ 텍스트/시스템 입력 (Text In)',
  };

  String get responseTokensLabel => switch (languageCode) {
    'en' => 'Response Output Tokens (Response)',
    'ja' => '応答生成トークン (Response)',
    'zh' => '响应生成 Token (Response)',
    _ => '응답 생성 토큰 (Response)',
  };

  String get audioOutSubLabel => switch (languageCode) {
    'en' => '└ Audio Output (Audio Out)',
    'ja' => '└ 音声出力 (Audio Out)',
    'zh' => '└ 音频输出 (Audio Out)',
    _ => '└ 오디오 출력 (Audio Out)',
  };

  String get textOutSubLabel => switch (languageCode) {
    'en' => '└ Text Output (Text Out)',
    'ja' => '└ テキスト出力 (Text Out)',
    'zh' => '└ 文本输出 (Text Out)',
    _ => '└ 텍스트 출력 (Text Out)',
  };

  String get cachedTokensLabel => switch (languageCode) {
    'en' => 'Cached Tokens (Cached)',
    'ja' => 'キャッシュ済みトークン (Cached)',
    'zh' => '已缓存 Token (Cached)',
    _ => '캐시된 토큰 (Cached)',
  };

  String pricingFootnote(GeminiTokenUsageTracker tracker) {
    final audioIn = tracker.pricingRates.audioInputPerM.toStringAsFixed(2);
    final audioOut = tracker.pricingRates.audioOutputPerM.toStringAsFixed(2);
    final videoIn = tracker.pricingRates.videoInputPerM.toStringAsFixed(2);
    final textIn = tracker.pricingRates.textInputPerM.toStringAsFixed(2);

    return switch (languageCode) {
      'en' =>
        'Active Model: ${tracker.model}\n'
            '• Audio Input: \$$audioIn / 1M\n'
            '• Audio Output: \$$audioOut / 1M\n'
            '• Video Input: \$$videoIn / 1M\n'
            '• Text Input: \$$textIn / 1M\n'
            '• \$0.00 billed when using Free Tier',
      'ja' =>
        '現在のモデル: ${tracker.model}\n'
            '• 音声入力: \$$audioIn / 1M\n'
            '• 音声出力: \$$audioOut / 1M\n'
            '• 映像/ビデオ入力: \$$videoIn / 1M\n'
            '• テキスト入力: \$$textIn / 1M\n'
            '• 無料枠 (Free Tier) 利用時は請求 \$0.00\n'
            '• 為替レート: 1 USD ≈ 155 JPY 換算',
      'zh' =>
        '当前模型: ${tracker.model}\n'
            '• 音频输入: \$$audioIn / 1M\n'
            '• 音频输出: \$$audioOut / 1M\n'
            '• 视频输入: \$$videoIn / 1M\n'
            '• 文本输入: \$$textIn / 1M\n'
            '• 使用免费额度 (Free Tier) 时费用为 \$0.00\n'
            '• 汇率: 按 1 USD ≈ 7.2 CNY 换算',
      _ =>
        '현재 모델: ${tracker.model}\n'
            '• 오디오 입력: \$$audioIn / 1M\n'
            '• 오디오 출력: \$$audioOut / 1M\n'
            '• 영상/비디오 입력: \$$videoIn / 1M\n'
            '• 텍스트 입력: \$$textIn / 1M\n'
            '• Free Tier 사용 시 비용 청구 \$0.00\n'
            '• 환율: 1 USD = ${tracker.usdToKrwRate.round()} KRW 적용',
    };
  }

  String get resetButtonLabel => switch (languageCode) {
    'en' => 'Reset Stats',
    'ja' => '統計をリセット',
    'zh' => '重置统计',
    _ => '통계 초기화',
  };

  String get closeButtonLabel => switch (languageCode) {
    'en' => 'Close',
    'ja' => '閉じる',
    'zh' => '关闭',
    _ => '닫기',
  };
}
