import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  group('GeminiTokenUsageTracker', () {
    test('initial state is zero', () {
      final tracker = GeminiTokenUsageTracker();
      expect(tracker.promptTokens, 0);
      expect(tracker.responseTokens, 0);
      expect(tracker.totalTokens, 0);
      expect(tracker.estimatedCostUsd, 0.0);
      expect(tracker.formatTokens(), '0 tokens');
    });

    test('accumulates tokens from LiveServerMessage correctly', () {
      final tracker = GeminiTokenUsageTracker(
        model: 'gemini-3.5-live-translate-preview',
      );

      final message = LiveServerMessage(
        usageMetadata: UsageMetadata(
          promptTokenCount: 25,
          responseTokenCount: 25,
          totalTokenCount: 50,
          promptTokensDetails: [
            ModalityTokenCount(
              modality: MediaModality.AUDIO,
              tokenCount: 25,
            ),
            ModalityTokenCount(
              modality: MediaModality.TEXT,
              tokenCount: 500,
            ),
          ],
          responseTokensDetails: [
            ModalityTokenCount(
              modality: MediaModality.AUDIO,
              tokenCount: 25,
            ),
          ],
        ),
      );

      tracker.recordMessage(message);

      expect(tracker.promptTokens, 25);
      expect(tracker.responseTokens, 25);
      expect(tracker.totalTokens, 50);
      expect(tracker.audioInputTokens, 25);
      expect(tracker.textInputTokens, 500);
      expect(tracker.audioOutputTokens, 25);

      // Translating rates: Audio In ($3.50/M), Audio Out ($21.00/M), Text In ($0.075/M)
      // 25 * 0.0000035 + 25 * 0.000021 + 500 * 0.000000075
      // = 0.0000875 + 0.000525 + 0.0000375 = 0.00065
      expect(tracker.estimatedCostUsd, closeTo(0.00065, 0.00001));
      expect(tracker.estimatedCostKrw, closeTo(0.00065 * 1400.0, 0.01));

      // Reset
      tracker.reset();
      expect(tracker.totalTokens, 0);
      expect(tracker.audioInputTokens, 0);
      expect(tracker.estimatedCostUsd, 0.0);
    });

    test('supports video and image modalities and calculates costs', () {
      final tracker = GeminiTokenUsageTracker(
        model: 'gemini-3.8-flash',
      );

      tracker.recordUsage(
        UsageMetadata(
          promptTokenCount: 1500,
          responseTokenCount: 100,
          totalTokenCount: 1600,
          promptTokensDetails: [
            ModalityTokenCount(
              modality: MediaModality.VIDEO,
              tokenCount: 1000,
            ),
            ModalityTokenCount(
              modality: MediaModality.IMAGE,
              tokenCount: 500,
            ),
          ],
          responseTokensDetails: [
            ModalityTokenCount(
              modality: MediaModality.TEXT,
              tokenCount: 100,
            ),
          ],
        ),
      );

      expect(tracker.videoInputTokens, 1000);
      expect(tracker.imageInputTokens, 500);
      expect(tracker.textOutputTokens, 100);

      // gemini-3.8-flash rates: videoIn ($0.75/M), imageIn ($0.75/M), textOut ($3.75/M)
      // 1000 * 0.00000075 + 500 * 0.00000075 + 100 * 0.00000375
      // = 0.00075 + 0.000375 + 0.000375 = 0.0015
      expect(tracker.estimatedCostUsd, closeTo(0.0015, 0.00001));
    });

    test('GeminiPricingRates resolves distinct rates for models', () {
      final translateRates = GeminiPricingRates.forModel('gemini-3.5-live-translate-preview');
      expect(translateRates.audioInputPerM, 3.50);
      expect(translateRates.audioOutputPerM, 21.00);

      final flash38Rates = GeminiPricingRates.forModel('gemini-3.8-flash');
      expect(flash38Rates.textInputPerM, 0.75);
      expect(flash38Rates.textOutputPerM, 3.75);

      final liveNativeAudioRates = GeminiPricingRates.forModel('gemini-2.5-flash-native-audio-preview-12-2025');
      expect(liveNativeAudioRates.audioInputPerM, 3.00);
      expect(liveNativeAudioRates.audioOutputPerM, 12.00);

      final liteRates = GeminiPricingRates.forModel('gemini-2.5-flash-lite');
      expect(liteRates.textInputPerM, 0.10);
      expect(liteRates.audioInputPerM, 0.30);
    });
  });

  group('GeminiLiveUsageBadge & Dialog', () {
    testWidgets('renders badge and shows details dialog on tap', (tester) async {
      final tracker = GeminiTokenUsageTracker(
        model: 'gemini-3.5-live-translate-preview',
      );

      tracker.recordUsage(
        UsageMetadata(
          promptTokenCount: 1000,
          responseTokenCount: 250,
          totalTokenCount: 1250,
          promptTokensDetails: [
            ModalityTokenCount(modality: MediaModality.AUDIO, tokenCount: 1000),
          ],
          responseTokensDetails: [
            ModalityTokenCount(modality: MediaModality.AUDIO, tokenCount: 250),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                GeminiLiveUsageBadge(tracker: tracker),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1,250 tokens'), findsOneWidget);
      expect(find.byIcon(Icons.toll_rounded), findsOneWidget);

      // Tap badge to open dialog
      await tester.tap(find.byType(GeminiLiveUsageBadge));
      await tester.pumpAndSettle();

      expect(find.text('Gemini Live 사용량 및 비용'), findsOneWidget);
      expect(find.text('세부 모달리티 사용 내역'), findsOneWidget);
      expect(find.text('입력 프롬프트 토큰 (Prompt)'), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.text('통계 초기화'));
      await tester.pumpAndSettle();
      expect(tracker.totalTokens, 0);

      // Close dialog
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('0 tokens'), findsOneWidget);
    });
  });
}
