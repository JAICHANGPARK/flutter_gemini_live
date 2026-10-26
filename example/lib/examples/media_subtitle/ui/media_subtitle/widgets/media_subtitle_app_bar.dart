import 'package:example/app_translations.dart';
import 'package:example/foldable_utils.dart';
import 'package:example/scrollable_app_bar_actions.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../domain/models/subtitle_languages.dart';
import '../media_subtitle_i18n.dart';
import '../view_models/media_subtitle_view_model.dart';
import 'audio_device_selector_button.dart';
import 'foldable_pill.dart';

class MediaSubtitleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MediaSubtitleAppBar({
    super.key,
    required this.viewModel,
    required this.foldableInfo,
  });

  final MediaSubtitleViewModel viewModel;
  final FoldableLayoutInfo foldableInfo;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final i18n = MediaSubtitleI18n.current;
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.subtitles_rounded, color: Colors.cyanAccent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              i18n.appBarTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      actions: [
        ScrollableAppBarActions(
          children: [
            const LanguageSelectorButton(compact: true),
            FoldablePill(foldableInfo: foldableInfo),
            // Target Language Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: vm.targetLanguageCode,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.cyanAccent,
                  ),
                  items: kSubtitleLanguages.map((lang) {
                    return DropdownMenuItem<String>(
                      value: lang['code'],
                      child: Text('${lang['flag']} ${lang['name']}'),
                    );
                  }).toList(),
                  onChanged: vm.isConnected
                      ? null
                      : (val) {
                          if (val != null) {
                            vm.setTargetLanguage(val);
                          }
                        },
                ),
              ),
            ),
            // Real-time token usage and cost badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GeminiLiveUsageBadge(tracker: vm.usageTracker),
            ),
            AudioDeviceSelectorButton(viewModel: vm, isCompact: true),
            IconButton(
              icon: const Icon(Icons.copy_all_rounded),
              tooltip: i18n.copyAllSubtitlesTooltip,
              onPressed: vm.copySubtitlesToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: i18n.clearSubtitlesTooltip,
              onPressed: vm.clearSubtitles,
            ),
          ],
        ),
      ],
    );
  }
}
