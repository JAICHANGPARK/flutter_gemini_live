import 'package:flutter/material.dart';

import '../../../domain/models/vision_chat_message.dart';
import '../vision_call_i18n.dart';

/// Dual-screen book mode (Surface Duo or Galaxy Fold unfolded side-by-side).
class BookModeLayout extends StatelessWidget {
  const BookModeLayout({
    super.key,
    required this.backgroundColor,
    required this.i18n,
    required this.chatHistory,
    required this.hingeWidth,
    required this.header,
    required this.viewfinder,
    required this.controlBar,
  });

  final Color backgroundColor;
  final VisionCallI18n i18n;
  final List<VisionChatMessage> chatHistory;

  /// Raw hinge width (or `null`); clamped here exactly as before.
  final double? hingeWidth;
  final Widget header;
  final Widget viewfinder;
  final Widget controlBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            // Left Screen: Header + Camera Viewfinder
            Expanded(
              child: Column(
                children: [
                  header,
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: viewfinder,
                    ),
                  ),
                ],
              ),
            ),

            // Center Hinge Spacer
            SizedBox(
              width: (hingeWidth ?? 16).clamp(8.0, 36.0),
              child: Center(
                child: Container(
                  width: 2,
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                ),
              ),
            ),

            // Right Screen: Transcript History & Controls
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        i18n.liveTranscriptTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  Expanded(
                    child: chatHistory.isEmpty
                        ? Center(
                            child: Text(
                              i18n.transcriptWaiting,
                              style: const TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
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
