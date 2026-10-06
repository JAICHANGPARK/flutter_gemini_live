import 'package:flutter/material.dart';

import '../../../domain/models/vision_chat_message.dart';
import '../vision_call_i18n.dart';

/// Tabletop / Flex Mode (foldable device half-opened on desk).
class TabletopLayout extends StatelessWidget {
  const TabletopLayout({
    super.key,
    required this.backgroundColor,
    required this.i18n,
    required this.chatHistory,
    required this.header,
    required this.viewfinder,
    required this.controlBar,
  });

  final Color backgroundColor;
  final VisionCallI18n i18n;
  final List<VisionChatMessage> chatHistory;
  final Widget header;
  final Widget viewfinder;
  final Widget controlBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            header,
            // Top Upright Screen: Central Camera Viewfinder
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: viewfinder,
              ),
            ),

            // Physical Crease Divider
            Container(
              height: 3,
              color: Colors.greenAccent.withValues(alpha: 0.3),
            ),

            // Bottom Flat Screen: Live Subtitle, Transcript history, and Controls
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(
                    child: chatHistory.isEmpty
                        ? Center(
                            child: Text(
                              i18n.tabletopWaiting,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            itemCount: chatHistory.length,
                            itemBuilder: (context, index) {
                              final item =
                                  chatHistory[chatHistory.length - 1 - index];
                              return Align(
                                alignment: item.isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.isUser
                                        ? const Color(0xFF1B4D36)
                                        : const Color(0xFF143323),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  controlBar,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
