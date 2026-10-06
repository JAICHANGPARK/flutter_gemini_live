import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/live_translation_message.dart';

/// Right / top panel: the translated text for the person on the other side.
class TranslationPartnerPanel extends StatelessWidget {
  const TranslationPartnerPanel({
    super.key,
    required this.targetLang,
    required this.partnerMessages,
    required this.isConnected,
    required this.scrollController,
    required this.rotate180,
  });

  final Map<String, String> targetLang;
  final List<LiveTranslationMessage> partnerMessages;
  final bool isConnected;
  final ScrollController scrollController;
  final bool rotate180;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: Colors.amber.shade50.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                targetLang['flag'] ?? '🌐',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'For Partner: ${targetLang['name']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.amber.shade900,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.person_pin_rounded,
                size: 18,
                color: Colors.amber,
              ),
            ],
          ),
          const Divider(height: 12),
          Expanded(
            child: partnerMessages.isEmpty
                ? Center(
                    child: Text(
                      isConnected
                          ? 'Listening...\nTranslations (${targetLang['name']}) will appear here for your partner.'
                          : 'Waiting for session to start.',
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
                    itemCount: partnerMessages.length,
                    itemBuilder: (context, idx) {
                      final msg = partnerMessages[idx];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    if (rotate180) {
      return Transform.rotate(angle: math.pi, child: content);
    }
    return content;
  }
}
