import 'package:flutter/material.dart';

import '../../../domain/models/live_translation_message.dart';

/// Left / bottom panel: my own speech and the full translation history.
class TranslationMyPanel extends StatelessWidget {
  const TranslationMyPanel({
    super.key,
    required this.myLang,
    required this.targetLang,
    required this.myMessages,
    required this.isConnected,
    required this.scrollController,
  });

  final Map<String, String> myLang;
  final Map<String, String> targetLang;
  final List<LiveTranslationMessage> myMessages;
  final bool isConnected;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade50.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                myLang['flag'] ?? '🇰🇷',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                '내 화면 (${myLang['name']} 발화 및 통역 기록)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blueAccent,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.person_rounded,
                size: 18,
                color: Colors.blueAccent,
              ),
            ],
          ),
          const Divider(height: 12),
          Expanded(
            child: myMessages.isEmpty
                ? Center(
                    child: Text(
                      isConnected
                          ? '마이크로 ${myLang['name']}로 말씀하세요.\n내 음성과 상대방 번역 내용(${targetLang['name']})이 실시간으로 기록됩니다.'
                          : '하단 통역 시작 버튼을 누르면 실시간 통역이 시작됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: myMessages.length,
                    itemBuilder: (context, idx) {
                      final msg = myMessages[idx];
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.85,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? Colors.blueAccent.shade700
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: msg.isUser
                                ? null
                                : Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: msg.isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.isUser
                                    ? '🎤 내 발화 (${myLang['name']})'
                                    : '🌐 번역문 (${targetLang['name']})',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: msg.isUser
                                      ? Colors.white70
                                      : Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: msg.isUser
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
