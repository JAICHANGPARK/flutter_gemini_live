import 'package:flutter/material.dart';

import '../view_models/math_tutor_view_model.dart';

/// "Live Dialog Log" tab: mic status banner + chat-style transcript list.
class TranscriptLogTab extends StatelessWidget {
  const TranscriptLogTab({
    super.key,
    required this.viewModel,
    this.scrollController,
  });

  final MathTutorViewModel viewModel;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Column(
      children: [
        // Live Audio & Mic Status Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF131D2E),
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              // Real-time Mic level meter
              ValueListenableBuilder<double>(
                valueListenable: vm.liveMicVolumeNotifier,
                builder: (context, vol, _) {
                  final isActive = vol > 0.08;
                  return Row(
                    children: [
                      Icon(
                        vm.isMicMuted
                            ? Icons.mic_off_rounded
                            : (isActive
                                  ? Icons.mic_rounded
                                  : Icons.mic_none_rounded),
                        size: 16,
                        color: vm.isMicMuted
                            ? Colors.redAccent
                            : (isActive ? Colors.greenAccent : Colors.white54),
                      ),
                      const SizedBox(width: 6),
                      // Animated 5-bar volume level indicator
                      Row(
                        children: List.generate(5, (index) {
                          final barLevel = (index + 1) / 5.0;
                          final isFilled = vol >= (barLevel * 0.6);
                          return Container(
                            width: 3,
                            height: 6 + (index * 2.5),
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isFilled
                                  ? Colors.greenAccent
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vm.isConnected
                      ? (vm.isAiSpeaking
                            ? '🤖 튜터 음성 설명 중...'
                            : (vm.isUserSpeaking
                                  ? '🗣️ 학생 음성 인식 중...'
                                  : '🎙️ 음성 인식 대기 중 ("이거 풀어줘")'))
                      : '🔴 세션 연결 대기 중',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (vm.transcriptEntries.isNotEmpty)
                InkWell(
                  onTap: vm.clearTranscript,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '기록 지우기',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Dialog list
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: vm.transcriptUpdateNotifier,
            builder: (context, _, _) {
              if (vm.transcriptEntries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.forum_outlined,
                            size: 36,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '실시간 대화 로그가 없습니다',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '카메라로 문제를 비추고 "이거 풀어줘"라고 말하면\n내 음성과 AI 튜터의 답변이 실시간 텍스트로 기록됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white38,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController ?? vm.transcriptScrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                itemCount: vm.transcriptEntries.length,
                itemBuilder: (context, index) {
                  final entry = vm.transcriptEntries[index];
                  final timeStr =
                      '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';

                  if (entry.role == 'system') {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: entry.isInterrupted
                            ? const Color(0x33DC2626)
                            : const Color(0x221E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: entry.isInterrupted
                              ? Colors.redAccent.withValues(alpha: 0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.text,
                              style: TextStyle(
                                fontSize: 11,
                                color: entry.isInterrupted
                                    ? Colors.redAccent.shade100
                                    : Colors.white60,
                                fontWeight: entry.isInterrupted
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Colors.white30,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final isUser = entry.role == 'user';
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFF0F3E3B)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isUser
                              ? const Radius.circular(12)
                              : const Radius.circular(2),
                          bottomRight: isUser
                              ? const Radius.circular(2)
                              : const Radius.circular(12),
                        ),
                        border: Border.all(
                          color: isUser
                              ? Colors.cyanAccent.withValues(alpha: 0.3)
                              : Colors.amber.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isUser
                                    ? Icons.person_rounded
                                    : Icons.smart_toy_rounded,
                                size: 12,
                                color: isUser
                                    ? Colors.cyanAccent
                                    : Colors.amberAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isUser ? '나 (학생)' : 'AI 튜터',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isUser
                                      ? Colors.cyanAccent
                                      : Colors.amberAccent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white30,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            entry.text,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
