import 'package:flutter/material.dart';

import '../view_models/media_subtitle_view_model.dart';

/// Cinematic floating subtitle overlay shown on top of the video.
class FloatingSubtitleHud extends StatelessWidget {
  const FloatingSubtitleHud({super.key, required this.viewModel});

  final MediaSubtitleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return ValueListenableBuilder<int>(
      valueListenable: vm.subtitleRevision,
      builder: (context, _, _) {
        final activeTranslated = vm.currentTranslatedSubtitle.trim();
        final activeOriginal = vm.currentOriginalSubtitle.trim();

        final lastEntry = vm.subtitleHistory.isNotEmpty
            ? vm.subtitleHistory.last
            : null;

        final displayOriginal = activeOriginal.isNotEmpty
            ? activeOriginal
            : (lastEntry != null ? lastEntry.originalText : '');
        final displayTranslated = activeTranslated.isNotEmpty
            ? activeTranslated
            : (lastEntry != null ? lastEntry.translatedText : '');

        final hasTranslated = displayTranslated.isNotEmpty;
        final hasOriginal = displayOriginal.isNotEmpty;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: vm.isConnected
                  ? Colors.cyanAccent.withValues(alpha: 0.5)
                  : Colors.white12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Original Speech (Transcribed in real time)
              if (vm.showOriginalText && hasOriginal) ...[
                Text(
                  displayOriginal,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: vm.subtitleFontSize * 0.75,
                    fontStyle: FontStyle.italic,
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Translated Subtitle (Prominent Real-time Streaming)
              Text(
                hasTranslated
                    ? displayTranslated
                    : (vm.isConnected
                          ? '실시간 음성을 스트리밍 통역 중입니다...'
                          : '스트리밍을 시작하면 실시간 통역 자막이 여기에 표시됩니다.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hasTranslated
                      ? const Color(0xFFFDE047)
                      : Colors.white38,
                  fontSize: vm.subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 6,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
