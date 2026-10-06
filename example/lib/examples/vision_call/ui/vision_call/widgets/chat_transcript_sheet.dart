import 'package:flutter/material.dart';

import '../../../domain/models/vision_chat_message.dart';
import '../vision_call_i18n.dart';

/// Opens the live transcript bottom sheet. [chatHistory] is the live list.
void showChatTranscriptSheet(
  BuildContext context, {
  required VisionCallI18n i18n,
  required List<VisionChatMessage> chatHistory,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0C2417),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        i18n.liveTranscriptTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        i18n.messagesCount(chatHistory.length),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Expanded(
                    child: chatHistory.isEmpty
                        ? Center(
                            child: Text(
                              i18n.transcriptWaiting,
                              style: const TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            itemCount: chatHistory.length,
                            reverse: true,
                            itemBuilder: (context, index) {
                              final item =
                                  chatHistory[chatHistory.length - 1 - index];
                              return Align(
                                alignment: item.isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.isUser
                                        ? const Color(0xFF1B4D36)
                                        : const Color(0xFF143323),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: item.isUser
                                          ? Colors.greenAccent.withAlpha(50)
                                          : Colors.white12,
                                    ),
                                  ),
                                  child: Text(
                                    item.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
