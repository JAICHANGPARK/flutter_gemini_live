import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/vn_sdk_chapter.dart';
import '../view_models/anime_vn_view_model.dart';

/// Collapsible `gemini_live` SDK Study Note & Code Card (`📘 SDK 학습 노트`).
///
/// Positioned neatly in the top-left corner so it never covers Hikari's face
/// or the centered Visual Novel choices, allowing developers to read and copy
/// the exact Dart code while listening to Hikari's step-by-step explanation.
class VnSdkShowcaseCard extends StatelessWidget {
  final VnSdkShowcaseData showcase;
  final Color accentColor;
  final VoidCallback onClose;
  final AnimeVnViewModel? viewModel;

  const VnSdkShowcaseCard({
    super.key,
    required this.showcase,
    required this.accentColor,
    required this.onClose,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final isKo =
        AppLanguageController.instance.currentLanguage == AppLanguage.ko;
    final codeText = isKo
        ? showcase.codeSnippet
        : (showcase.codeSnippetJa ?? showcase.codeSnippet);
    final keyPoints = isKo
        ? showcase.keyPointsKo
        : (showcase.keyPointsJa.isNotEmpty
              ? showcase.keyPointsJa
              : showcase.keyPointsKo);

    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xE00F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge + Copy + Close
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    '📘 ${showcase.badgeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: isKo
                    ? 'Dart 코드 복사 (Copy Code)'
                    : 'Dartコードをコピー (Copy Code)',
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 15,
                  color: Colors.white70,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: codeText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isKo
                            ? '📋 예제 Dart 코드가 클립보드에 복사되었습니다!'
                            : '📋 サンプルDartコードをクリップボードにコピーしました！',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: isKo
                    ? '학습 노트 접기 (하단 CODE 버튼으로 다시 열기)'
                    : '学習ノートを閉じる（下部 CODE ボタンで再表示）',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white60,
                ),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title + Summary (Localized)
          Text(
            isKo ? showcase.titleKo : showcase.titleJa,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isKo ? showcase.summaryKo : showcase.summaryJa,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),

          // Key Learning Takeaways
          for (final point in keyPoints)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✔ ',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Copyable Dart Code Window
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 165),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                codeText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF7DD3FC),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ),

          // Step-by-Step 10-Chapter Curriculum Quick Stepper (if viewModel is provided)
          if (viewModel != null) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < VnScenarioCatalog.chapters.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: InkWell(
                        onTap: () => viewModel!.selectChapter(i),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: viewModel!.currentChapterIndex == i
                                ? accentColor.withValues(alpha: 0.30)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: viewModel!.currentChapterIndex == i
                                  ? accentColor
                                  : Colors.white24,
                            ),
                          ),
                          child: Text(
                            'Ch.${i + 1}',
                            style: TextStyle(
                              color: viewModel!.currentChapterIndex == i
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: viewModel!.previousDialogue,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      isKo ? '◀ 이전 단계' : '◀ 前のステップ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Ch.${viewModel!.currentChapter.chapterNumber}/${VnScenarioCatalog.chapters.length} • STEP ${viewModel!.currentBeatIndex + 1}/${viewModel!.totalBeatsInChapter}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: viewModel!.advanceDialogue,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor),
                    ),
                    child: Text(
                      isKo ? '다음 단계 ▶' : '次のステップ ▶',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
