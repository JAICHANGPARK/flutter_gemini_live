import 'package:example/foldable_utils.dart';
import 'package:flutter/material.dart';

import '../view_models/translation_view_model.dart';
import 'translation_my_panel.dart';
import 'translation_partner_panel.dart';

/// 🔄 양방향 대면 분할 뷰 (폴더블 듀얼스크린 북모드 및 테이블 맞은편 180도 회전 뷰)
class TranslationDualFlipLayout extends StatelessWidget {
  const TranslationDualFlipLayout({super.key, required this.viewModel});

  final TranslationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final myLang = vm.myLanguage;
    final targetLang = vm.targetLanguage;
    final partnerMessages = vm.history.where((m) => !m.isUser).toList();
    final myMessages = vm.history;
    final foldableInfo = FoldableLayoutInfo.of(context);

    Widget myPanel() => TranslationMyPanel(
      myLang: myLang,
      targetLang: targetLang,
      myMessages: myMessages,
      isConnected: vm.isConnected,
      scrollController: vm.scrollController,
    );

    Widget partnerPanel({required bool rotate180}) => TranslationPartnerPanel(
      targetLang: targetLang,
      partnerMessages: partnerMessages,
      isConnected: vm.isConnected,
      scrollController: vm.partnerScrollController,
      rotate180: rotate180,
    );

    // 1. 폴더블 듀얼스크린 북모드 (Surface Duo 또는 갤럭시 폴드 펼친 좌우 화면)
    if (foldableInfo.hasHinge && foldableInfo.isBookMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 왼쪽 화면: 내 언어 & 통역 기록
          Expanded(child: myPanel()),

          // 중앙 힌지 여백 (하드웨어 베젤 가림 방지)
          SizedBox(
            width: (foldableInfo.hingeBounds?.width ?? 16).clamp(8.0, 36.0),
            child: Center(
              child: Container(
                width: 2,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ),

          // 오른쪽 화면: 상대방 언어 & 실시간 번역문 (정방향)
          Expanded(child: partnerPanel(rotate180: false)),
        ],
      );
    }

    // 2. 테이블탑 / 상하 대면 플립 모드 (테이블 맞은편 상대방을 위한 180도 회전 뷰)
    return Column(
      children: [
        // 상단 절반: 맞은편 상대방 화면 (180도 회전!)
        Expanded(child: partnerPanel(rotate180: true)),

        // 중앙 분할선 (테이블 중앙 구분바 및 힌지 라인)
        Container(
          height: 28,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.arrow_upward_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '상대방: ${targetLang['name']} (180°)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    '내 화면: ${myLang['name']}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_downward_rounded,
                    size: 14,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 하단 절반: 내 화면 (정방향 및 통역 기록)
        Expanded(child: myPanel()),
      ],
    );
  }
}
