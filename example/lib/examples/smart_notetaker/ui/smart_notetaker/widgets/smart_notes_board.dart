import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../view_models/smart_notetaker_view_model.dart';
import 'highlights_summary_bar.dart';

/// Structured markdown note canvas with the highlights summary bar.
class SmartNotesBoard extends StatelessWidget {
  const SmartNotesBoard({super.key, required this.viewModel});

  final SmartNotetakerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Quick Insights Tags
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.amberAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI 실시간 구조화 노트',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.amberAccent,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: viewModel.copyNotesToClipboard,
                icon: const Icon(Icons.copy, size: 14),
                label: const Text(
                  'Markdown 복사',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Key Highlights Chips Bar
          if (viewModel.keyTakeaways.isNotEmpty ||
              viewModel.actionItems.isNotEmpty)
            HighlightsSummaryBar(viewModel: viewModel),

          const SizedBox(height: 12),

          // Main Markdown Note Canvas
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                controller: viewModel.noteScrollController,
                child: MarkdownBody(
                  data: viewModel.rawNotes,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    p: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    blockquote: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: const Border(
                        left: BorderSide(color: Colors.amberAccent, width: 3),
                      ),
                    ),
                    code: const TextStyle(
                      color: Colors.lightGreenAccent,
                      backgroundColor: Colors.black26,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
