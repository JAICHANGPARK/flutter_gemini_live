import 'package:flutter/material.dart';

import '../../../domain/models/live_translation_message.dart';
import '../translation_i18n.dart';

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
    final i18n = TranslationI18n.current;
    final myLangName = myLang['name'] ?? '';
    final targetLangName = targetLang['name'] ?? '';
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
              Expanded(
                child: Text(
                  i18n.myPanelHeader(myLangName),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                          ? i18n.myPanelConnectedEmpty(
                              myLangName,
                              targetLangName,
                            )
                          : i18n.myPanelDisconnectedEmpty,
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
                                    ? i18n.mySpeechBubbleLabel(myLangName)
                                    : i18n.translatedBubbleLabel(
                                        targetLangName,
                                      ),
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
