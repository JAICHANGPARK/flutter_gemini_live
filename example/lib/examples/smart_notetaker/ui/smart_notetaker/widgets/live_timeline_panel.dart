import 'package:flutter/material.dart';

import '../view_models/smart_notetaker_view_model.dart';
import 'interim_bubble.dart';
import 'speech_bubble.dart';

/// Live speech feed with simultaneous translation.
class LiveTimelinePanel extends StatelessWidget {
  const LiveTimelinePanel({super.key, required this.viewModel});

  final SmartNotetakerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final speechTurns = viewModel.speechTurns;
    final interimSpeech = viewModel.interimSpeech;

    return Container(
      color: const Color(0xFF090D16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                color: Colors.amberAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                '실시간 발화 & 동시 번역',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${speechTurns.length}개 발화',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: speechTurns.isEmpty && interimSpeech.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          size: 44,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '녹음을 시작하면 회의/강의 발화가\n실시간으로 텍스트화 및 번역됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: viewModel.timelineScrollController,
                    itemCount:
                        speechTurns.length + (interimSpeech.isNotEmpty ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index < speechTurns.length) {
                        final turn = speechTurns[index];
                        return SpeechBubble(turn: turn);
                      }
                      // Interim live speech bubble
                      return InterimBubble(text: interimSpeech);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
