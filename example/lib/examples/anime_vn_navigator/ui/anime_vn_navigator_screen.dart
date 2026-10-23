import 'package:example/app_settings_dialog.dart';
import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models/vn_character_models.dart';
import 'view_models/anime_vn_view_model.dart';
import 'widgets/live_anime_character_stage.dart';
import 'widgets/vn_dialogue_box.dart';
import 'widgets/vn_sdk_showcase_card.dart';

/// Interactive Japanese Bishoujo Visual Novel (`美少女ノベルゲーム`) & `gemini_live` SDK Tutor.
///
/// Follows the classic Visual Novel UX (matching the user's reference screenshots):
/// - **Full-screen scenic stage** with Hikari standing in the center (`Alignment.bottomCenter`).
/// - **Bottom full-width Visual Novel dialogue window** (`VnDialogueBox`) where clicking
///   (or pressing Space / Enter) advances step-by-step through the lesson dialogue (`1/4 -> 4/4`)
///   while Hikari speaks each line in Japanese (`24kHz` Gemini Live audio).
/// - **Centered glossy sky-blue Choice Overlay** (`VnChoiceOverlayPanel`) that appears right
///   in the center of the screen when a dialogue sequence finishes.
class AnimeVnNavigatorPage extends StatefulWidget {
  const AnimeVnNavigatorPage({super.key});

  @override
  State<AnimeVnNavigatorPage> createState() => _AnimeVnNavigatorPageState();
}

class _AnimeVnNavigatorPageState extends State<AnimeVnNavigatorPage> {
  late final AnimeVnViewModel _viewModel;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = AnimeVnViewModel()
      ..onNotice = _showNotice
      ..requestApiKeySetup = _requestApiKeySetup;
    _viewModel.init();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool?> _requestApiKeySetup() {
    return AppSettingsDialog.show(context);
  }

  Future<void> _openSettings() async {
    final changed = await AppSettingsDialog.show(context);
    if (changed == true && mounted) {
      await _viewModel.connectSession(sendInitialGreeting: true);
    }
  }

  void _openBacklog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xF2140F23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final logs = _viewModel.dialogueHistory;
        final isKo = _viewModel.isKorean;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history_edu_rounded,
                      color: Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isKo
                          ? '📜 지난 대사 기록 (LOG / バックログ)'
                          : '📜 バックログ (会話履歴 / LOG)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final item = logs[index];
                      return ListTile(
                        dense: true,
                        leading: Text(
                          item.isUser ? '🎙️' : item.emotion.badgeEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          item.speaker,
                          style: TextStyle(
                            color: item.isUser
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFFF472B6),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        subtitle: Text(
                          item.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _viewModel.advanceDialogue();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _viewModel.previousDialogue();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;

          return Scaffold(
            backgroundColor: const Color(0xFF090D16),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Full-Screen Scenic Background + Centered Animated Character
                LiveAnimeCharacterStage(
                  viewModel: vm,
                  characterAlignment: Alignment.bottomCenter,
                ),

                // 2. Minimal Top-Left / Top-Right Floating Pill (Back + Study Note Toggle)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 560;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 10 : 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // Back to Examples Button
                              IconButton.filledTonal(
                                visualDensity: isCompact
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                                tooltip: vm.isKorean
                                    ? '예제 목록으로 돌아가기'
                                    : 'サンプル一覧に戻る',
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                              SizedBox(width: isCompact ? 6 : 10),

                              // Toggleable Study Note Pill (Wrapped in Flexible so it never overflows)
                              Flexible(
                                child: ActionChip(
                                  visualDensity: isCompact
                                      ? VisualDensity.compact
                                      : VisualDensity.standard,
                                  backgroundColor: vm.isShowcaseVisible
                                      ? const Color(0xE61E293B)
                                      : Colors.black54,
                                  side: BorderSide(
                                    color: vm.isShowcaseVisible
                                        ? const Color(0xFF38BDF8)
                                        : Colors.white30,
                                  ),
                                  avatar: const Icon(
                                    Icons.menu_book_rounded,
                                    size: 15,
                                    color: Color(0xFF38BDF8),
                                  ),
                                  label: Text(
                                    vm.isKorean
                                        ? (isCompact
                                              ? (vm.isShowcaseVisible
                                                    ? 'SDK 노트 닫기'
                                                    : 'SDK 노트')
                                              : (vm.isShowcaseVisible
                                                    ? '📘 SDK 코드 학습노트 닫기'
                                                    : '📘 SDK 코드 학습노트 보기'))
                                        : (isCompact
                                              ? (vm.isShowcaseVisible
                                                    ? '学習ノート閉'
                                                    : '学習ノート')
                                              : (vm.isShowcaseVisible
                                                    ? '📘 SDK コード学習ノートを閉じる'
                                                    : '📘 SDK コード学習ノートを見る')),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompact ? 11 : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: vm.toggleShowcase,
                                ),
                              ),
                              SizedBox(width: isCompact ? 6 : 10),

                              // Quick Heroine Switcher Pill (🌺 레이나(갸루) <-> 🌸 히카리(청순))
                              ActionChip(
                                visualDensity: isCompact
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                                backgroundColor: vm.selectedHeroine.accentColor
                                    .withValues(alpha: 0.25),
                                side: BorderSide(
                                  color: vm.selectedHeroine.accentColor,
                                ),
                                label: Text(
                                  vm.isKorean
                                      ? (isCompact
                                            ? '${vm.selectedHeroine.badgeEmoji} ${vm.selectedHeroine.nameKo}'
                                            : '${vm.selectedHeroine.badgeEmoji} ${vm.selectedHeroine.nameKo} (${vm.selectedHeroine == VnHeroineCharacter.reina ? "갸루" : "청순"})')
                                      : (isCompact
                                            ? '${vm.selectedHeroine.badgeEmoji} ${vm.selectedHeroine.nameJa}'
                                            : '${vm.selectedHeroine.badgeEmoji} ${vm.selectedHeroine.nameJa} (${vm.selectedHeroine == VnHeroineCharacter.reina ? "ギャル" : "清楚"})'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isCompact ? 11 : 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  final next =
                                      vm.selectedHeroine ==
                                          VnHeroineCharacter.reina
                                      ? VnHeroineCharacter.hikari
                                      : VnHeroineCharacter.reina;
                                  vm.selectHeroine(next);
                                },
                              ),
                              SizedBox(width: isCompact ? 6 : 8),

                              // Quick Language Toggle Pill (🇯🇵 日本語 <-> 🇰🇷 한국어)
                              ActionChip(
                                visualDensity: isCompact
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                                backgroundColor: Colors.black54,
                                side: const BorderSide(color: Colors.white24),
                                label: Text(
                                  vm.isKorean
                                      ? (isCompact ? '🇰🇷 KO' : '🇰🇷 한국어')
                                      : (isCompact ? '🇯🇵 JA' : '🇯🇵 日本語'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isCompact ? 11 : 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  final nextLang = vm.isKorean
                                      ? AppLanguage.ja
                                      : AppLanguage.ko;
                                  AppLanguageController.instance.setLanguage(
                                    nextLang,
                                  );
                                },
                              ),
                              SizedBox(width: isCompact ? 6 : 8),

                              // Affection Indicator Pill
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 8 : 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      color: Color(0xFFF472B6),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isCompact
                                          ? '${vm.affectionPoints}%'
                                          : (vm.isKorean
                                                ? '호감도 ${vm.affectionPoints}%'
                                                : '好感度 ${vm.affectionPoints}%'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isCompact ? 11 : 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 3. Collapsible SDK Code & Study Note Card (Top-Left, hidden during Choice Phase)
                if (vm.isShowcaseVisible && !vm.isChoiceOverlayOpen)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 58,
                          left: 16,
                          right: 16,
                          bottom: 220,
                        ),
                        child: SingleChildScrollView(
                          child: VnSdkShowcaseCard(
                            showcase: vm.currentShowcase,
                            accentColor: vm.currentEmotion.accentColor,
                            onClose: vm.toggleShowcase,
                            viewModel: vm,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 4. Centered Glossy Sky-Blue Choice Overlay (Screenshot 2 Style!)
                if (vm.isChoiceOverlayOpen)
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    bottom: 205,
                    child: VnChoiceOverlayPanel(viewModel: vm),
                  ),

                // 5. Classic Full-Width Bottom Visual Novel Dialogue Box (Screenshot 1 Style!)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VnDialogueBox(
                    viewModel: vm,
                    onOpenBacklog: _openBacklog,
                    onOpenSettings: _openSettings,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
