import 'package:example/scrollable_app_bar_actions.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

import '../view_models/translation_view_model.dart';
import 'translation_foldable_badge.dart';

/// Screen app bar: title (with ellipsis) and scrollable action buttons.
class TranslationAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TranslationAppBar({
    super.key,
    required this.viewModel,
    required this.onOpenSettings,
  });

  final TranslationViewModel viewModel;
  final VoidCallback onOpenSettings;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.translate_rounded, color: Colors.blueAccent),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Live Translation (동시통역)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        ScrollableAppBarActions(
          children: [
            // Real-time token usage and cost badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GeminiLiveUsageBadge(tracker: vm.usageTracker),
            ),
            // Voice Output Toggle Button (번역 음성 스피커 출력 ON/OFF)
            IconButton(
              icon: Icon(
                vm.isAudioOutputEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: vm.isAudioOutputEnabled
                    ? Colors.greenAccent
                    : Colors.white54,
              ),
              tooltip: vm.isAudioOutputEnabled
                  ? '번역 음성 출력 켜짐 (클릭하여 음소거)'
                  : '번역 음성 출력 꺼짐 (클릭하여 켜기)',
              onPressed: vm.toggleAudioOutput,
            ),
            // Echo Loop Prevention Toggle Button
            IconButton(
              icon: Icon(
                vm.preventEchoLoop
                    ? Icons.hearing_rounded
                    : Icons.hearing_disabled_rounded,
                color: vm.preventEchoLoop ? Colors.blueAccent : Colors.white54,
              ),
              tooltip: vm.preventEchoLoop
                  ? '에코 방지 켜짐 (스피커 출력 중 마이크 자동 차단으로 무한반복 방지)'
                  : '에코 방지 꺼짐 (헤드셋/이어폰 착용 시)',
              onPressed: vm.togglePreventEchoLoop,
            ),
            // Dual Flip Mode Toggle Button
            IconButton(
              icon: Icon(
                vm.isDualFlipMode
                    ? Icons.splitscreen_rounded
                    : Icons.chat_bubble_outline_rounded,
                color: vm.isDualFlipMode ? Colors.amber : null,
              ),
              tooltip: vm.isDualFlipMode
                  ? '단일 채팅 모드로 전환'
                  : '양방향 대면 모드(Dual Flip)로 전환',
              onPressed: vm.toggleDualFlipMode,
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: '설정',
              onPressed: onOpenSettings,
            ),
            const TranslationFoldableBadge(),
          ],
        ),
      ],
    );
  }
}
