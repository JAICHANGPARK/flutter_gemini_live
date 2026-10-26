import 'package:flutter/material.dart';

import '../translation_i18n.dart';
import '../view_models/translation_view_model.dart';

/// 💬 일반 채팅형 단일 레이아웃
class TranslationStandardChatLayout extends StatelessWidget {
  const TranslationStandardChatLayout({super.key, required this.viewModel});

  final TranslationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final i18n = TranslationI18n.current;
    final myLang = vm.myLanguage;
    final targetLang = vm.targetLanguage;
    final myLangName = myLang['name'] ?? '';
    final targetLangName = targetLang['name'] ?? '';
    final history = vm.history;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.record_voice_over_rounded,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              vm.isConnected
                  ? i18n.standardChatConnectedEmpty(myLangName, targetLangName)
                  : i18n.standardChatDisconnectedEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: vm.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Align(
          alignment: item.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: item.isUser
                  ? Colors.blueAccent.shade700
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(item.isUser ? 14 : 2),
                bottomRight: Radius.circular(item.isUser ? 2 : 14),
              ),
            ),
            child: Column(
              crossAxisAlignment: item.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isUser ? Icons.mic : Icons.translate,
                      size: 13,
                      color: item.isUser ? Colors.white70 : Colors.blueAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isUser
                          ? i18n.myVoiceChatLabel(myLangName)
                          : i18n.translationResultChatLabel(targetLangName),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.isUser ? Colors.white70 : Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.isUser ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
