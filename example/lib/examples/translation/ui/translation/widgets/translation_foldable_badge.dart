import 'package:example/foldable_utils.dart';
import 'package:flutter/material.dart';

/// App bar chip that shows the detected foldable posture (FLEX / DUO / FOLD).
class TranslationFoldableBadge extends StatelessWidget {
  const TranslationFoldableBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final foldableInfo = FoldableLayoutInfo.of(context);
    if (!foldableInfo.hasHinge && !foldableInfo.isFoldableOrWide) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8, left: 2),
      child: Tooltip(
        message: foldableInfo.isTabletop
            ? '테이블탑 / 플렉스 모드'
            : (foldableInfo.isDualScreen ? '듀얼스크린 감지됨' : '폴더블 와이드 감지됨'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                foldableInfo.isTabletop
                    ? Icons.laptop_chromebook_rounded
                    : Icons.devices_fold_rounded,
                size: 13,
                color: Colors.amber.shade900,
              ),
              const SizedBox(width: 4),
              Text(
                foldableInfo.isTabletop
                    ? 'FLEX'
                    : (foldableInfo.isDualScreen ? 'DUO' : 'FOLD'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
