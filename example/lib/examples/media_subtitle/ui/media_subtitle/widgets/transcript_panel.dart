import 'package:flutter/material.dart';

import '../view_models/media_subtitle_view_model.dart';

/// Live subtitle timeline: finished entries plus the in-flight "LIVE" card.
class TranscriptPanel extends StatelessWidget {
  const TranscriptPanel({
    super.key,
    required this.viewModel,
    required this.scrollController,
  });

  final MediaSubtitleViewModel viewModel;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return ValueListenableBuilder<int>(
      valueListenable: vm.subtitleRevision,
      builder: (context, _, _) {
        final subtitleHistory = vm.subtitleHistory;
        final activeTranslated = vm.currentTranslatedSubtitle.trim();
        final activeOriginal = vm.currentOriginalSubtitle.trim();
        final hasActive =
            activeTranslated.isNotEmpty || activeOriginal.isNotEmpty;

        return Container(
          color: const Color(0xFF0F172A),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: Colors.cyanAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '실시간 자막 타임라인',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${subtitleHistory.length}개 문장',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: subtitleHistory.isEmpty && !hasActive
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.subtitles_off_rounded,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '수신된 자막 기록이 없습니다.\n실시간 자막을 시작하면 타임라인이 누적됩니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: subtitleHistory.length + (hasActive ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index < subtitleHistory.length) {
                            final item = subtitleHistory[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.cyanAccent.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          item.formatTime(),
                                          style: const TextStyle(
                                            color: Colors.cyanAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.originalText.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      item.originalText,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    item.translatedText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Active streaming card (LIVE)
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.cyanAccent.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.cyanAccent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'LIVE 통역 중',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (activeOriginal.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    activeOriginal,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                if (activeTranslated.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    activeTranslated,
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
