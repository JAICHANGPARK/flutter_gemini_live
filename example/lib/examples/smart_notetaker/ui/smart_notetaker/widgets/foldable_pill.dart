import 'package:example/foldable_utils.dart';
import 'package:flutter/material.dart';

import '../smart_notetaker_i18n.dart';

/// Small pill showing the current foldable posture (TABLETOP / DUO / FOLD).
class FoldablePill extends StatelessWidget {
  const FoldablePill({super.key, required this.foldableInfo});

  final FoldableLayoutInfo foldableInfo;

  @override
  Widget build(BuildContext context) {
    if (!foldableInfo.hasHinge && !foldableInfo.isFoldableOrWide) {
      return const SizedBox.shrink();
    }
    final i18n = SmartNotetakerI18n.current;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: foldableInfo.isTabletop
            ? Colors.deepOrangeAccent.withValues(alpha: 0.2)
            : Colors.amberAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: foldableInfo.isTabletop
              ? Colors.deepOrangeAccent
              : Colors.amberAccent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            foldableInfo.isTabletop
                ? Icons.laptop_chromebook_rounded
                : (foldableInfo.isDualScreen
                      ? Icons.splitscreen_rounded
                      : Icons.developer_board_rounded),
            size: 13,
            color: foldableInfo.isTabletop
                ? Colors.deepOrangeAccent
                : Colors.amberAccent,
          ),
          const SizedBox(width: 4),
          Text(
            foldableInfo.isTabletop
                ? i18n.tabletopLabel
                : (foldableInfo.isDualScreen ? i18n.duoLabel : i18n.foldLabel),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: foldableInfo.isTabletop
                  ? Colors.deepOrangeAccent
                  : Colors.amberAccent,
            ),
          ),
        ],
      ),
    );
  }
}
