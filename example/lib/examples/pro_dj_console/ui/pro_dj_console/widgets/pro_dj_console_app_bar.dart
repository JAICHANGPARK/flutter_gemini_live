import 'package:example/app_settings_dialog.dart';
import 'package:example/app_translations.dart';
import 'package:example/dj_midi_box_page.dart';
import 'package:example/foldable_utils.dart';
import 'package:example/scrollable_app_bar_actions.dart';
import 'package:flutter/material.dart';

/// Console app bar: title, ON AIR badge, MIDI box, language, settings and
/// foldable badge.
class ProDjConsoleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isPlaying;

  const ProDjConsoleAppBar({super.key, required this.isPlaying});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF14171E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white70),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.shade900,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PRO DJ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'DIGITAL MULTI-PLAYER CONSOLE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        ScrollableAppBarActions(
          children: [
            // ON AIR Glowing LED Badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isPlaying
                    ? Colors.redAccent.withAlpha(50)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isPlaying ? Colors.redAccent : Colors.white24,
                  width: 1.5,
                ),
                boxShadow: isPlaying
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withAlpha(150),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isPlaying ? Colors.redAccent : Colors.white38,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'ON AIR',
                    style: TextStyle(
                      color: isPlaying ? Colors.redAccent : Colors.white38,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.grid_view_rounded,
                color: Color(0xFFA855F7),
              ),
              tooltip: 'DJ MIDI Box (16-Pad Rotary Grid)',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DjMidiBoxPage()),
                );
              },
            ),
            const LanguageSelectorButton(compact: true),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: () => AppSettingsDialog.show(context),
              tooltip: 'Settings',
            ),
            Builder(
              builder: (context) {
                final foldableInfo = FoldableLayoutInfo.of(context);
                if (!foldableInfo.hasHinge && !foldableInfo.isFoldableOrWide) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8, left: 2),
                  child: Tooltip(
                    message: foldableInfo.isTabletop
                        ? 'Tabletop / Flex Mode'
                        : (foldableInfo.isDualScreen
                              ? 'Duo Dual-Screen Active'
                              : 'Foldable Active'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            foldableInfo.isTabletop
                                ? Icons.laptop_chromebook_rounded
                                : Icons.devices_fold_rounded,
                            size: 13,
                            color: Colors.cyanAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            foldableInfo.isTabletop
                                ? 'FLEX DJ'
                                : (foldableInfo.isDualScreen
                                      ? 'DUO DJ'
                                      : 'FOLD DJ'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
