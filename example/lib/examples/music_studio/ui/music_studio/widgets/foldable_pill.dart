import 'package:example/foldable_utils.dart';
import 'package:flutter/material.dart';

/// Small badge in the app bar showing the foldable posture (hidden otherwise).
class FoldablePill extends StatelessWidget {
  const FoldablePill({super.key, required this.foldableInfo});

  final FoldableLayoutInfo foldableInfo;

  @override
  Widget build(BuildContext context) {
    if (!foldableInfo.hasHinge && !foldableInfo.isFoldableOrWide) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: foldableInfo.isTabletop
            ? Colors.deepOrangeAccent.withValues(alpha: 0.2)
            : Colors.purpleAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: foldableInfo.isTabletop
              ? Colors.deepOrangeAccent
              : Colors.purpleAccent,
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
                : Colors.purpleAccent,
          ),
          const SizedBox(width: 4),
          Text(
            foldableInfo.isTabletop
                ? 'TABLETOP'
                : (foldableInfo.isDualScreen ? 'DUO' : 'FOLD'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: foldableInfo.isTabletop
                  ? Colors.deepOrangeAccent
                  : Colors.purpleAccent,
            ),
          ),
        ],
      ),
    );
  }
}
