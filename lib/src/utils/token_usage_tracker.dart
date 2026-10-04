import 'package:flutter/foundation.dart';

import '../model/models.dart';

/// Pricing rates per 1,000,000 tokens (in USD) for a specific Gemini model.
class GeminiPricingRates {
  /// Cost per 1M text input tokens.
  final double textInputPerM;

  /// Cost per 1M audio input tokens.
  final double audioInputPerM;

  /// Cost per 1M image input tokens.
  final double imageInputPerM;

  /// Cost per 1M video input tokens.
  final double videoInputPerM;

  /// Cost per 1M candidate text output tokens (including thinking tokens).
  final double textOutputPerM;

  /// Cost per 1M candidate audio output tokens.
  final double audioOutputPerM;

  /// Creates a pricing rate tier for Gemini Live modalities.
  const GeminiPricingRates({
    required this.textInputPerM,
    required this.audioInputPerM,
    required this.imageInputPerM,
    required this.videoInputPerM,
    required this.textOutputPerM,
    required this.audioOutputPerM,
  });

  /// Resolves the pricing rates based on the model name.
  factory GeminiPricingRates.forModel(String modelName) {
    final lower = modelName.toLowerCase();

    // 1. Gemini 3.5 Live Translate
    if (lower.contains('translate')) {
      return const GeminiPricingRates(
        textInputPerM: 0.075,
        audioInputPerM: 3.50,
        imageInputPerM: 0.50,
        videoInputPerM: 3.00,
        textOutputPerM: 0.30,
        audioOutputPerM: 21.00,
      );
    }

    // 2. Gemini 3.5 Transcribe Live
    if (lower.contains('transcribe')) {
      return const GeminiPricingRates(
        textInputPerM: 0.075,
        audioInputPerM: 3.50,
        imageInputPerM: 0.50,
        videoInputPerM: 3.00,
        textOutputPerM: 21.00,
        audioOutputPerM: 21.00,
      );
    }

    // 3. Gemini 2.5 Flash Native Audio / Live API Preview
    if (lower.contains('native-audio') || lower.contains('realtime')) {
      return const GeminiPricingRates(
        textInputPerM: 0.50,
        audioInputPerM: 3.00,
        imageInputPerM: 3.00,
        videoInputPerM: 3.00,
        textOutputPerM: 2.00,
        audioOutputPerM: 12.00,
      );
    }

    // 4. Gemini 3.8 / 3.7 / 3.6 Flash
    if (lower.contains('gemini-3.8') ||
        lower.contains('gemini-3.7') ||
        lower.contains('gemini-3.6')) {
      return const GeminiPricingRates(
        textInputPerM: 0.75,
        audioInputPerM: 1.00,
        imageInputPerM: 0.75,
        videoInputPerM: 0.75,
        textOutputPerM: 3.75,
        audioOutputPerM: 12.00,
      );
    }

    // 5. Gemini 2.5 Flash-Lite
    if (lower.contains('flash-lite')) {
      return const GeminiPricingRates(
        textInputPerM: 0.10,
        audioInputPerM: 0.30,
        imageInputPerM: 0.10,
        videoInputPerM: 0.10,
        textOutputPerM: 0.40,
        audioOutputPerM: 2.00,
      );
    }

    // 6. Standard Gemini 2.5 Flash / Default Fallback
    return const GeminiPricingRates(
      textInputPerM: 0.30,
      audioInputPerM: 1.00,
      imageInputPerM: 0.30,
      videoInputPerM: 0.30,
      textOutputPerM: 2.50,
      audioOutputPerM: 10.00,
    );
  }
}

/// Real-time token usage and cost tracker for Gemini Live API sessions.
///
/// Listens to or receives [LiveServerMessage] and [UsageMetadata] emitted by
/// the Gemini Live WebSocket, aggregating token counts across modalities:
/// - Audio (input & output)
/// - Video (camera stream input)
/// - Image (still photos input)
/// - Text (prompts & output transcripts)
///
/// Automatically calculates estimated costs in USD and KRW based on official
/// Google AI pricing for the active model.
class GeminiTokenUsageTracker extends ChangeNotifier {
  /// The model identifier used in the session.
  final String model;

  /// Currency conversion rate from USD to KRW (default: 1400.0).
  final double usdToKrwRate;

  /// Pricing rates configuration. If not provided, automatically resolved from [model].
  final GeminiPricingRates pricingRates;

  int _promptTokens = 0;
  int _responseTokens = 0;
  int _totalTokens = 0;
  int _cachedTokens = 0;
  int _thoughtsTokens = 0;

  int _audioInputTokens = 0;
  int _audioOutputTokens = 0;
  int _videoInputTokens = 0;
  int _imageInputTokens = 0;
  int _textInputTokens = 0;
  int _textOutputTokens = 0;

  /// Creates a token usage tracker for monitoring session consumption.
  GeminiTokenUsageTracker({
    this.model = 'gemini-3.5-live-translate-preview',
    this.usdToKrwRate = 1400.0,
    GeminiPricingRates? pricingRates,
  }) : pricingRates = pricingRates ?? GeminiPricingRates.forModel(model);

  /// Total number of prompt (input) tokens processed.
  int get promptTokens => _promptTokens;

  /// Total number of candidate response (output) tokens generated.
  int get responseTokens => _responseTokens;

  /// Total tokens consumed (prompt + response).
  int get totalTokens => _totalTokens;

  /// Number of tokens in cached content.
  int get cachedTokens => _cachedTokens;

  /// Number of internal reasoning/thoughts tokens.
  int get thoughtsTokens => _thoughtsTokens;

  /// Audio input tokens processed.
  int get audioInputTokens => _audioInputTokens;

  /// Audio output tokens generated.
  int get audioOutputTokens => _audioOutputTokens;

  /// Video input tokens processed (camera frames).
  int get videoInputTokens => _videoInputTokens;

  /// Image input tokens processed (still images).
  int get imageInputTokens => _imageInputTokens;

  /// Text input tokens processed.
  int get textInputTokens => _textInputTokens;

  /// Text output tokens generated.
  int get textOutputTokens => _textOutputTokens;

  /// Records token usage from a top-level [LiveServerMessage].
  void recordMessage(LiveServerMessage message) {
    final usage = message.usageMetadata;
    if (usage != null) {
      recordUsage(usage);
    }
  }

  /// Records token usage directly from [UsageMetadata].
  void recordUsage(UsageMetadata usage) {
    bool changed = false;

    final prompt = usage.promptTokenCount ?? 0;
    final response = usage.responseTokenCount ?? 0;
    final total = usage.totalTokenCount ?? (prompt + response);
    final cached = usage.cachedContentTokenCount ?? 0;
    final thoughts = usage.thoughtsTokenCount ?? 0;

    if (prompt > 0 || response > 0 || total > 0) {
      _promptTokens += prompt;
      _responseTokens += response;
      _totalTokens += total;
      _cachedTokens += cached;
      _thoughtsTokens += thoughts;
      changed = true;
    }

    if (usage.promptTokensDetails != null) {
      for (final detail in usage.promptTokensDetails!) {
        final count = detail.tokenCount ?? 0;
        if (count > 0) {
          switch (detail.modality) {
            case MediaModality.AUDIO:
              _audioInputTokens += count;
              changed = true;
              break;
            case MediaModality.VIDEO:
              _videoInputTokens += count;
              changed = true;
              break;
            case MediaModality.IMAGE:
              _imageInputTokens += count;
              changed = true;
              break;
            case MediaModality.TEXT:
              _textInputTokens += count;
              changed = true;
              break;
            default:
              break;
          }
        }
      }
    }

    if (usage.responseTokensDetails != null) {
      for (final detail in usage.responseTokensDetails!) {
        final count = detail.tokenCount ?? 0;
        if (count > 0) {
          switch (detail.modality) {
            case MediaModality.AUDIO:
              _audioOutputTokens += count;
              changed = true;
              break;
            case MediaModality.TEXT:
              _textOutputTokens += count;
              changed = true;
              break;
            default:
              break;
          }
        }
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Resets all accumulated token counters and costs to zero.
  void reset() {
    _promptTokens = 0;
    _responseTokens = 0;
    _totalTokens = 0;
    _cachedTokens = 0;
    _thoughtsTokens = 0;
    _audioInputTokens = 0;
    _audioOutputTokens = 0;
    _videoInputTokens = 0;
    _imageInputTokens = 0;
    _textInputTokens = 0;
    _textOutputTokens = 0;
    notifyListeners();
  }

  /// Estimated cost in USD under Google AI Paid Tier.
  ///
  /// Computes exact sub-modalities costs when details are available,
  /// with a fallback to prompt/response general rates.
  double get estimatedCostUsd {
    if (_totalTokens == 0) return 0.0;

    final audioInCost = (_audioInputTokens / 1000000.0) * pricingRates.audioInputPerM;
    final videoInCost = (_videoInputTokens / 1000000.0) * pricingRates.videoInputPerM;
    final imageInCost = (_imageInputTokens / 1000000.0) * pricingRates.imageInputPerM;
    final textInCost = (_textInputTokens / 1000000.0) * pricingRates.textInputPerM;

    final audioOutCost = (_audioOutputTokens / 1000000.0) * pricingRates.audioOutputPerM;
    final textOutCost = (_textOutputTokens / 1000000.0) * pricingRates.textOutputPerM;

    final detailedSum =
        audioInCost + videoInCost + imageInCost + textInCost + audioOutCost + textOutCost;

    if (detailedSum > 0) {
      return detailedSum;
    }

    // Fallback if modality-specific breakdown wasn't provided by the server
    final fallbackIn = (_promptTokens / 1000000.0) * pricingRates.audioInputPerM;
    final fallbackOut = (_responseTokens / 1000000.0) * pricingRates.audioOutputPerM;
    return fallbackIn + fallbackOut;
  }

  /// Estimated cost in KRW using [usdToKrwRate].
  double get estimatedCostKrw => estimatedCostUsd * usdToKrwRate;

  /// Formatted token count string (e.g. `1,250 tokens`).
  String formatTokens() {
    return '${_formatNumber(_totalTokens)} tokens';
  }

  /// Formatted cost string with optional Korean Won conversion.
  ///
  /// Example: `$0.0042 (약 6원)`
  String formatCost({bool showKrw = true}) {
    final usd = estimatedCostUsd;
    final krw = estimatedCostKrw;

    final usdStr = usd < 0.0001 && usd > 0
        ? '< \$0.0001'
        : '\$${usd.toStringAsFixed(4)}';

    if (!showKrw) return usdStr;

    final krwRounded = krw.round();
    final krwStr = krwRounded > 0
        ? '약 ${_formatNumber(krwRounded)}원'
        : (krw > 0 ? '< 1원' : '0원');

    return '$usdStr ($krwStr)';
  }

  static String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}
