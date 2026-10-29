import 'package:example/app_settings_dialog.dart';
import 'package:example/app_translations.dart';
import 'package:example/examples/dj_midi_box/ui/dj_midi_box/dj_midi_box_screen.dart';
import 'package:example/foldable_utils.dart';
import 'package:example/examples/pro_dj_console/ui/pro_dj_console/pro_dj_console_screen.dart';
import 'package:example/scrollable_app_bar_actions.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../music_studio_i18n.dart';
import 'foldable_pill.dart';

/// App bar with title, foldable badge, DJ page shortcuts, language and
/// settings buttons.
class MusicStudioAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MusicStudioAppBar({
    super.key,
    required this.foldableInfo,
    required this.usageTracker,
  });

  final FoldableLayoutInfo foldableInfo;
  final GeminiTokenUsageTracker usageTracker;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final i18n = MusicStudioI18n.current;
    final isNarrow = MediaQuery.sizeOf(context).width < 440;
    return AppBar(
      backgroundColor: const Color(0xFF1E222B),
      elevation: 0,
      titleSpacing: isNarrow ? 6 : null,
      title: Row(
        children: [
          const Icon(Icons.music_note_rounded, color: Colors.purpleAccent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              i18n.appBarTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 8),
            Flexible(
              flex: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purpleAccent.withAlpha(100)),
                ),
                child: Text(
                  i18n.lyriaRealtimeBadge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        ScrollableAppBarActions(
          children: [
            FoldablePill(foldableInfo: foldableInfo),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DjMidiBoxPage()),
                );
              },
              icon: const Icon(
                Icons.grid_view_rounded,
                size: 16,
                color: Color(0xFFA855F7),
              ),
              label: Text(
                i18n.midiBoxButton,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF261840),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
              ),
            ),
            const SizedBox(width: 6),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProDjConsolePage()),
                );
              },
              icon: const Icon(
                Icons.album_rounded,
                size: 16,
                color: Color(0xFF00E5FF),
              ),
              label: Text(
                i18n.djConsoleButton,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E2638),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GeminiLiveUsageBadge(
              tracker: usageTracker,
              compact: true,
              backgroundColor: Colors.white.withAlpha(20),
              foregroundColor: Colors.white,
            ),
            const SizedBox(width: 6),
            const LanguageSelectorButton(compact: true),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: i18n.settingsTooltip,
              onPressed: () => AppSettingsDialog.show(context),
            ),
          ],
        ),
      ],
    );
  }
}
