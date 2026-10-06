import 'package:example/foldable_utils.dart';
import 'package:example/scrollable_app_bar_actions.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../domain/models/note_language.dart';
import '../view_models/smart_notetaker_view_model.dart';
import 'audio_device_selector_button.dart';
import 'foldable_pill.dart';

/// AppBar with language picker, usage badge, device picker and note actions.
class SmartNotetakerAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SmartNotetakerAppBar({
    super.key,
    required this.viewModel,
    required this.foldableInfo,
  });

  final SmartNotetakerViewModel viewModel;
  final FoldableLayoutInfo foldableInfo;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note_rounded, color: Colors.amberAccent, size: 26),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Live Smart NoteTaker',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF131B2E),
      foregroundColor: Colors.white,
      actions: [
        ScrollableAppBarActions(
          children: [
            FoldablePill(foldableInfo: foldableInfo),
            // Target Language Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: viewModel.targetLanguageCode,
                  dropdownColor: const Color(0xFF131B2E),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.amberAccent,
                  ),
                  items: kNoteLanguages.map((lang) {
                    return DropdownMenuItem<String>(
                      value: lang['code'],
                      child: Text('${lang['flag']} ${lang['name']}'),
                    );
                  }).toList(),
                  onChanged: viewModel.isConnected
                      ? null
                      : (val) {
                          if (val != null) {
                            viewModel.targetLanguageCode = val;
                          }
                        },
                ),
              ),
            ),
            // Real-time token usage and cost badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GeminiLiveUsageBadge(tracker: viewModel.usageTracker),
            ),
            AudioDeviceSelectorButton(viewModel: viewModel, isCompact: true),
            IconButton(
              icon: const Icon(Icons.summarize_rounded),
              tooltip: 'AI 최종 요약본 정리',
              onPressed: viewModel.isConnected
                  ? viewModel.generateWrapUpSummary
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.copy_all_rounded),
              tooltip: '마크다운 전체 복사',
              onPressed: viewModel.copyNotesToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: '새 노트 시작 (초기화)',
              onPressed: viewModel.clearNotes,
            ),
          ],
        ),
      ],
    );
  }
}
