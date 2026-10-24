import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

import '../../domain/models/vn_character_models.dart';
import '../../domain/models/vn_sdk_chapter.dart';
import '../view_models/anime_vn_view_model.dart';

/// Classic Japanese Visual Novel (미연시) Bottom Dialogue Window
/// modeled directly after authentic Galgame / Visual Novel UIs (Screenshot 1).
///
/// Clicking anywhere on the dialogue window advances to the next dialogue beat
/// (`1/4 -> 2/4 -> 3/4 -> 4/4 -> Centered Choice Screen`), while Hikari speaks
/// each line in Japanese via Gemini Live 24kHz audio.
class VnDialogueBox extends StatefulWidget {
  final AnimeVnViewModel viewModel;
  final VoidCallback onOpenBacklog;
  final VoidCallback onOpenSettings;

  const VnDialogueBox({
    super.key,
    required this.viewModel,
    required this.onOpenBacklog,
    required this.onOpenSettings,
  });

  @override
  State<VnDialogueBox> createState() => _VnDialogueBoxState();
}

class _VnDialogueBoxState extends State<VnDialogueBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursorBlinkController;

  @override
  void initState() {
    super.initState();
    _cursorBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorBlinkController.dispose();
    super.dispose();
  }

  Future<void> _showAskDialog(BuildContext context) async {
    final isKo = widget.viewModel.isKorean;
    final controller = TextEditingController();
    final submitted = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1429),
        title: Text(
          isKo
              ? '💬 히카리에게 직접 질문하기 (Gemini Live)'
              : '💬 ヒカリに直接質問する (Gemini Live)',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isKo
                ? '예: gemini_live에서 Barge-in은 어떻게 처리해?'
                : '例: gemini_liveでバージインはどう処理するの？',
            hintStyle: const TextStyle(color: Colors.white54),
          ),
          onSubmitted: (val) => Navigator.of(ctx).pop(val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isKo ? '취소' : 'キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(isKo ? '질문 보내기' : '質問を送る'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (submitted != null && submitted.trim().isNotEmpty) {
      await widget.viewModel.sendCustomMessage(submitted);
    }
  }

  void _showChapterJumpMenu(BuildContext context) {
    final isKo = widget.viewModel.isKorean;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xF2171126),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isKo
                        ? '📚 전 10화 마스터 커리큘럼 선택 (Ch.1 ~ Ch.10)'
                        : '📚 全10話 マスターカリキュラム選択 (Ch.1 ~ Ch.10)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: VnScenarioCatalog.chapters.length,
                      itemBuilder: (context, i) {
                        final chapter = VnScenarioCatalog.chapters[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor:
                                widget.viewModel.currentChapterIndex == i
                                ? const Color(0xFF38BDF8)
                                : Colors.white12,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            isKo ? chapter.titleKo : chapter.titleJa,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            '${chapter.categoryBadge} • ${chapter.dialogueBeats.length} Steps',
                            style: const TextStyle(
                              color: Color(0xFF7DD3FC),
                              fontSize: 11,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFF38BDF8),
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            widget.viewModel.selectChapter(i);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMoeVoiceTunerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xF5171128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final vm = widget.viewModel;
            final isKo = vm.isKorean;
            final currentPitch = vm.voicePitchShift;
            final isGyaru = vm.isGyaruVoiceStyle;
            final pitchPresets = isKo
                ? <(String, String, double, bool)>[
                    (
                      '🌺 하이텐션 시부야 갸루 보이스 (추천)',
                      '+2.3 반음 + 갸루 말투/연기 톤 (~っしょ! / 마린 톤)',
                      1.14,
                      true,
                    ),
                    (
                      '🎀 초절정 모에 미소녀',
                      '+3.3 반음 (블루아카/갸루게 청순 하이톤)',
                      1.21,
                      false,
                    ),
                    (
                      '🌸 정통 미연시 히로인',
                      '+2.6 반음 (귀엽고 달콤한 정통파 후배 톤)',
                      1.16,
                      false,
                    ),
                    (
                      '✨ 상큼 발랄 후배 톤',
                      '+1.5 반음 (밝고 경쾌한 애니 소녀)',
                      1.09,
                      false,
                    ),
                    (
                      '🎙️ 오리지널 내추럴 원음',
                      '0.0 반음 (DSP 피치 변조 없음)',
                      1.00,
                      isGyaru,
                    ),
                  ]
                : <(String, String, double, bool)>[
                    (
                      '🌺 渋谷系ハイテンション・ギャルボイス (推奨)',
                      '+2.3半音 + ギャル声優演技トーン (〜っしょ！✨)',
                      1.14,
                      true,
                    ),
                    (
                      '🎀 超絶萌え美少女ボイス',
                      '+3.3半音 (ブルアカ・ギャルゲー清楚高音)',
                      1.21,
                      false,
                    ),
                    (
                      '🌸 王道ギャルゲーヒロイン',
                      '+2.6半音 (甘くて可愛い清楚後輩トーン)',
                      1.16,
                      false,
                    ),
                    (
                      '✨ 明るく元気な後輩トーン',
                      '+1.5半音 (爽やかなアニメ美少女)',
                      1.09,
                      false,
                    ),
                    (
                      '🎙️ オリジナル原音',
                      '0.0半音 (DSPピッチ変調なし)',
                      1.00,
                      isGyaru,
                    ),
                  ];
            final voiceActors = isKo
                ? <(String, String)>[
                    ('Autonoe', '하이텐션 갸루 & 에너지 소녀 (레이나 추천)'),
                    ('Leda', '밝고 통통 튀는 하이톤 소녀 (히카리 추천)'),
                    ('Zephyr', '맑고 청량한 쿨뷰티 소녀 보이스'),
                    ('Despina', '부드럽고 다정한 선배 보이스'),
                    ('Aoede', '차분한 성인 내레이터 보이스'),
                  ]
                : <(String, String)>[
                    ('Autonoe', 'ハイテンション・ギャル＆元気美少女 (レイナ推奨)'),
                    ('Leda', '明るく弾むハイトーン美少女 (ヒカリ推奨)'),
                    ('Zephyr', '透明感のある爽やか美少女'),
                    ('Despina', '優しくて甘いお姉さんボイス'),
                    ('Aoede', '落ち着いたナレーターボイス'),
                  ];

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.80,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isKo
                                    ? '🌺 히로인 캐릭터 & 미소녀/갸루 보이스 튜너'
                                    : '🌺 ヒロイン選択＆ギャル・美少女ボイスチューナー',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () {
                                if (!vm.isConnected) {
                                  vm.connectSession(sendInitialGreeting: true);
                                } else {
                                  vm.speakCurrentBeat();
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFEC4899),
                              ),
                              icon: const Icon(
                                Icons.volume_up_rounded,
                                size: 16,
                              ),
                              label: Text(isKo ? '지금 목소리 테스트' : '今の声をテスト'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isKo
                              ? '1. 파트너 히로인 캐릭터 선택 (클릭 시 일러스트 & 대사 스타일 즉시 전환)'
                              : '1. パートナーヒロイン選択（クリックで立ち絵＆セリフ口調を即時切替）',
                          style: const TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            for (final h in VnHeroineCharacter.values)
                              InkWell(
                                onTap: () => vm.selectHeroine(h),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 265,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: vm.selectedHeroine == h
                                        ? h.accentColor.withValues(alpha: 0.25)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: vm.selectedHeroine == h
                                          ? h.accentColor
                                          : Colors.white24,
                                      width: 1.6,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        h.badgeEmoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isKo
                                                  ? '${h.nameKo} (${h.nameJa})'
                                                  : h.nameJa,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isKo
                                                  ? h.subtitleKo
                                                  : h.subtitleJa,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isKo
                              ? '2. 실시간 성우 연기 톤 & SoLoud DSP 피치 (재연결 없이 즉시 적용)'
                              : '2. リアルタイム声優演技トーン＆SoLoud DSPピッチ（即時反映）',
                          style: const TextStyle(
                            color: Color(0xFFF472B6),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final (title, desc, shiftVal, gyaruMode)
                                in pitchPresets)
                              InkWell(
                                onTap: () {
                                  vm.setVoicePitchShift(
                                    shiftVal,
                                    gyaruStyle: gyaruMode,
                                  );
                                  if (vm.isConnected) {
                                    vm.speakCurrentBeat();
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 255,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        ((currentPitch - shiftVal).abs() <
                                                0.02 &&
                                            isGyaru == gyaruMode)
                                        ? const Color(0x44EC4899)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          ((currentPitch - shiftVal).abs() <
                                                  0.02 &&
                                              isGyaru == gyaruMode)
                                          ? const Color(0xFFF472B6)
                                          : Colors.white24,
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        desc,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isKo
                              ? '3. Gemini Live 성우 베이스 프리셋 (변경 시 자동 재연결)'
                              : '3. Gemini Live 声優ベースプリセット（変更時に自動再接続）',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final (voiceId, label) in voiceActors)
                              ChoiceChip(
                                label: Text('$voiceId ($label)'),
                                selected: vm.selectedVoice == voiceId,
                                selectedColor: const Color(0xFF0284C7),
                                backgroundColor: Colors.white10,
                                labelStyle: TextStyle(
                                  color: vm.selectedVoice == voiceId
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                onSelected: (_) => vm.changeVoice(voiceId),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final isKo = vm.isKorean;

    // When user clicks CLOSE, show only a tiny floating restore pill at bottom-right
    if (vm.isDialogueBoxHidden) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xCC241938),
              foregroundColor: Colors.white,
            ),
            onPressed: vm.toggleDialogueBoxHidden,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: Text(isKo ? '대사창 표시 (OPEN)' : 'メッセージ枠を表示 (OPEN)'),
          ),
        ),
      );
    }

    final beatNum = vm.currentBeatIndex + 1;
    final totalBeats = vm.totalBeatsInChapter;
    final chapterTitle = isKo
        ? vm.currentChapter.titleKo
        : vm.currentChapter.titleJa;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: vm.advanceDialogue,
      child: ClipPath(
        clipper: const _VnChamferedBoxClipper(),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 196, maxHeight: 340),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xD9281D3D), // Authentic translucent dark purple-indigo
                Color(0xEB181126),
              ],
            ),
            border: Border(
              top: BorderSide(color: Color(0x99B388FF), width: 1.5),
              bottom: BorderSide(color: Color(0xFFB388FF), width: 3.0),
            ),
          ),
          child: Stack(
            children: [
              // Subtle diamond background pattern inside dialogue window
              Positioned.fill(
                child: CustomPaint(painter: _VnDialoguePatternPainter()),
              ),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 680;
                  final hPad = isCompact ? 14.0 : 32.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Speaker Name + Status Badges (Wrap so every badge is 100% visible without clipping or ellipsis)
                        Padding(
                          padding: EdgeInsets.only(
                            left: isCompact ? 4 : 14,
                            right: isCompact ? 16 : 28,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ValueListenableBuilder<String>(
                                valueListenable: vm.speakerNameNotifier,
                                builder: (context, speaker, _) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      speaker,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isCompact ? 16.5 : 19,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 6,
                                            offset: Offset(1, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Chapter & Beat Step Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0x88B388FF),
                                  ),
                                ),
                                child: Text(
                                  isCompact
                                      ? 'Ch.${vm.currentChapter.chapterNumber} • STEP $beatNum/$totalBeats'
                                      : 'Ch.${vm.currentChapter.chapterNumber} ($chapterTitle)  •  STEP $beatNum / $totalBeats',
                                  style: const TextStyle(
                                    color: Color(0xFFE9D5FF),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              // Heroine Switcher Pill (🌺 갸루: 레이나 <-> 🌸 청순: 히카리)
                              InkWell(
                                onTap: () {
                                  final next =
                                      vm.selectedHeroine ==
                                          VnHeroineCharacter.reina
                                      ? VnHeroineCharacter.hikari
                                      : VnHeroineCharacter.reina;
                                  vm.selectHeroine(next);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: vm.selectedHeroine.accentColor
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: vm.selectedHeroine.accentColor,
                                    ),
                                  ),
                                  child: Text(
                                    isKo
                                        ? '${vm.selectedHeroine.badgeEmoji} 히로인 전환: ${vm.selectedHeroine == VnHeroineCharacter.reina ? "레이나(갸루) → 히카리" : "히카리(청순) → 레이나(갸루)"}'
                                        : '${vm.selectedHeroine.badgeEmoji} ヒロイン切替: ${vm.selectedHeroine == VnHeroineCharacter.reina ? "レイナ(ギャル) → ヒカリ" : "ヒカリ(清楚) → レイナ(ギャル)"}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.2,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),

                              // Moe / Gyaru Voice Pitch & Seiyuu Selector Pill
                              InkWell(
                                onTap: () => _showMoeVoiceTunerSheet(context),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x33EC4899),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFF472B6),
                                    ),
                                  ),
                                  child: Text(
                                    isKo
                                        ? '${vm.isGyaruVoiceStyle ? "🌺 갸루 보이스" : "🎀 미소녀 보이스"} (${vm.selectedVoice} • ${vm.voicePitchShift.toStringAsFixed(2)}x)'
                                        : '${vm.isGyaruVoiceStyle ? "🌺 ギャルボイス" : "🎀 美少女ボイス"} (${vm.selectedVoice} • ${vm.voicePitchShift.toStringAsFixed(2)}x)',
                                    style: const TextStyle(
                                      color: Color(0xFFFBCFE8),
                                      fontSize: 11.2,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),

                              // Live Japanese Voice / Replay Status Pill
                              InkWell(
                                onTap: () {
                                  if (!vm.isConnected) {
                                    vm.connectSession(
                                      sendInitialGreeting: true,
                                    );
                                  } else {
                                    vm.speakCurrentBeat();
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: vm.isConnected
                                        ? const Color(0x3310B981)
                                        : const Color(0x33F59E0B),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: vm.isConnected
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFFFBBF24),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        vm.isAiSpeaking
                                            ? Icons.volume_up_rounded
                                            : Icons.play_circle_outline_rounded,
                                        size: 15,
                                        color: vm.isConnected
                                            ? const Color(0xFF6EE7B7)
                                            : const Color(0xFFFDE68A),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        vm.isConnected
                                            ? (vm.isAiSpeaking
                                                  ? (isKo
                                                        ? '🔊 일본어 음성 출력 중 (24kHz)'
                                                        : '🔊 日本語ボイス出力中 (24kHz)')
                                                  : (isKo
                                                        ? '🔊 음성 다시 듣기 (${vm.selectedVoice})'
                                                        : '🔊 ボイスをもう一度聴く (${vm.selectedVoice})'))
                                            : (vm.isConnecting
                                                  ? (isKo
                                                        ? '⏳ Gemini Live 연결 중...'
                                                        : '⏳ Gemini Live 接続中...')
                                                  : (isKo
                                                        ? '🔌 탭하여 일본어 음성 연결'
                                                        : '🔌 タップして日本語ボイス接続')),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // 2. Classic Visual Novel Horizontal Divider Line under Speaker Name
                        Container(
                          height: 2.0,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFD8B4FE),
                                Color(0xAA9333EA),
                                Color(0x229333EA),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 3. Main Dialogue Text Area (Full text visible without ellipsis truncation)
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 4 : 14,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ValueListenableBuilder<String>(
                                  valueListenable: vm.subtitleNotifier,
                                  builder: (context, primaryText, _) {
                                    return RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isCompact ? 15.5 : 18.0,
                                          height: 1.42,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 4,
                                              offset: Offset(1, 1.5),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          TextSpan(text: '$primaryText '),
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: FadeTransition(
                                              opacity: _cursorBlinkController,
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.4,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                                child: const Text(
                                                  '▼',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                ValueListenableBuilder<String>(
                                  valueListenable: vm.japaneseLineNotifier,
                                  builder: (context, textJa, _) {
                                    if (textJa.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      textJa,
                                      style: TextStyle(
                                        color: const Color(0xFFBAE6FD),
                                        fontSize: isCompact ? 12.0 : 13.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 3,
                                            offset: Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 4. Bottom Visual Novel Hint & System Menu Bar (Wrap so neither hint nor buttons are ever truncated)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 4 : 14,
                          ),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                vm.isChoiceOverlayOpen
                                    ? (isKo
                                          ? '👆 화면 중앙의 선택지를 클릭하세요'
                                          : '👆 画面中央の選択肢をクリックしてください')
                                    : (isKo
                                          ? '💡 대화창을 클릭하면 다음 대사($beatNum/$totalBeats)로 넘어갑니다'
                                          : '💡 ウィンドウをクリックすると次のセリフ($beatNum/$totalBeats)へ進みます'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                children: [
                                  _VnMenuTextButton(
                                    label: '◀ PREV',
                                    onTap: vm.previousDialogue,
                                  ),
                                  _VnMenuTextButton(
                                    label: 'NEXT ▶',
                                    onTap: vm.advanceDialogue,
                                  ),
                                  _VnMenuTextButton(
                                    label: 'JUMP',
                                    onTap: () => _showChapterJumpMenu(context),
                                  ),
                                  _VnMenuTextButton(
                                    label: 'CHOICE',
                                    isActive: vm.isChoiceOverlayOpen,
                                    onTap: vm.toggleChoices,
                                  ),
                                  _VnMenuTextButton(
                                    label: 'CODE',
                                    isActive: vm.isShowcaseVisible,
                                    onTap: vm.toggleShowcase,
                                  ),
                                  _VnMenuTextButton(
                                    label: 'RIG',
                                    isActive: vm.isRigInspectorVisible,
                                    activeColor: const Color(0xFF4ADE80),
                                    onTap: vm.toggleRigInspector,
                                  ),
                                  _VnMenuTextButton(
                                    label: vm.isMicRecording
                                        ? '🎙️MIC ON'
                                        : '🎙️MIC',
                                    isActive: vm.isMicRecording,
                                    activeColor: const Color(0xFFF43F5E),
                                    onTap: vm.toggleMic,
                                  ),
                                  _VnMenuTextButton(
                                    label: 'ASK',
                                    onTap: () => _showAskDialog(context),
                                  ),
                                  _VnMenuTextButton(
                                    label: 'SKIP',
                                    onTap: vm.skipToChoices,
                                  ),
                                  _VnMenuTextButton(
                                    label: 'AUTO',
                                    isActive: vm.isAutoMode,
                                    onTap: vm.toggleAutoMode,
                                  ),
                                  _VnMenuTextButton(
                                    label: 'LOG',
                                    onTap: widget.onOpenBacklog,
                                  ),
                                  _VnMenuTextButton(
                                    label: 'CLOSE',
                                    onTap: vm.toggleDialogueBoxHidden,
                                  ),
                                  _VnMenuTextButton(
                                    label: 'CONFIG',
                                    onTap: widget.onOpenSettings,
                                  ),
                                  _VnMenuTextButton(
                                    label: 'QUIT',
                                    onTap: () =>
                                        Navigator.of(context).maybePop(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VnMenuTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  const _VnMenuTextButton({
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor = const Color(0xFF38BDF8),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : const Color(0xFFB8B2C8),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: const [
              Shadow(
                color: Colors.black87,
                blurRadius: 3,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered Visual Novel Choice Overlay matching Screenshot 2
/// (`media_1792673351420_d5fdee6c.png`):
/// Renders 3 large, glossy sky-blue horizontal choice bars right in the center
/// of the screen over Hikari when a dialogue sequence reaches a decision point.
class VnChoiceOverlayPanel extends StatelessWidget {
  final AnimeVnViewModel viewModel;

  const VnChoiceOverlayPanel({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final choices = viewModel.currentChapter.choices;
    if (!viewModel.isChoiceOverlayOpen || choices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < choices.length; i++) ...[
                _GlossyVnChoiceButton(
                  choice: choices[i],
                  onTap: () => viewModel.selectChoice(choices[i]),
                ),
                if (i < choices.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Glossy Sky-Blue / Aqua Visual Novel Choice Button modeled directly after
/// Screenshot 2 (`너에 대한 생각을 했어 .` / `실은 나 이중인격이야 .`).
class _GlossyVnChoiceButton extends StatefulWidget {
  final VnChoiceOption choice;
  final VoidCallback onTap;

  const _GlossyVnChoiceButton({
    required this.choice,
    required this.onTap,
  });

  @override
  State<_GlossyVnChoiceButton> createState() => _GlossyVnChoiceButtonState();
}

class _GlossyVnChoiceButtonState extends State<_GlossyVnChoiceButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.025 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _hovered
                    ? const [
                        Color(0xFFB3E5FC),
                        Color(0xFF4FC3F7),
                        Color(0xFF29B6F6),
                        Color(0xFF80DEEA),
                      ]
                    : const [
                        Color(0xCC90CAF9),
                        Color(0xCC4FC3F7),
                        Color(0xCC26C6DA),
                        Color(0xCC80DEEA),
                      ],
                stops: const [0.0, 0.45, 0.55, 1.0],
              ),
              border: Border.all(
                color: _hovered
                    ? Colors.white
                    : const Color(0xFF37474F),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                if (_hovered)
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.55),
                    blurRadius: 18,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top glossy glass reflection highlight strip (Screenshot 2 style)
                Positioned(
                  top: 3,
                  left: 10,
                  right: 10,
                  height: 22,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.55),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  child: Builder(
                    builder: (context) {
                      final isKo =
                          AppLanguageController.instance.currentLanguage ==
                          AppLanguage.ko;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main Choice Text with strong dark outline shadow
                          Text(
                            isKo
                                ? widget.choice.labelKo
                                : widget.choice.labelJa,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(-1.5, -1.5),
                                ),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(1.5, -1.5),
                                ),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(1.5, 1.5),
                                ),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(-1.5, 1.5),
                                ),
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          if (isKo) ...[
                            const SizedBox(height: 2),
                            // Japanese Sub-label (only shown when primary language is Korean)
                            Text(
                              widget.choice.labelJa,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFF0F9FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 4,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clips the top-right corner with a diagonal bevel matching Screenshot 1.
class _VnChamferedBoxClipper extends CustomClipper<Path> {
  const _VnChamferedBoxClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - 48, 0)
      ..lineTo(size.width, 28)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _VnDialoguePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const step = 44.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(x + size.height, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
