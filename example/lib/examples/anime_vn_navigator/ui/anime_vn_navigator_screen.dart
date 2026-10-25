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
  bool _didConfigureInitialMobileLayout = false;

  @override
  void initState() {
    super.initState();
    _viewModel = AnimeVnViewModel()
      ..onNotice = _showNotice
      ..requestApiKeySetup = _requestApiKeySetup;
    _viewModel.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didConfigureInitialMobileLayout) {
      _didConfigureInitialMobileLayout = true;
      if (MediaQuery.sizeOf(context).width < 600 &&
          _viewModel.isShowcaseVisible) {
        _viewModel.toggleShowcase();
      }
    }
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
                    Expanded(
                      child: Text(
                        isKo
                            ? '📜 지난 대사 기록 (LOG / バックログ)'
                            : '📜 バックログ (会話履歴 / LOG)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
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

  Widget _buildHeroineModeButton({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required bool isCompact,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 7 : 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: isCompact ? 10.5 : 11.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
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

          final screenSize = MediaQuery.sizeOf(context);
          final isMobileScreen = screenSize.width < 600;
          final isShortScreen = screenSize.height < 520;
          final topOverlayOffset = isShortScreen
              ? 48.0
              : (isMobileScreen ? 92.0 : 58.0);
          final bottomOverlayOffset = isShortScreen
              ? (screenSize.height * 0.42).clamp(110.0, 165.0)
              : (isMobileScreen ? 225.0 : 210.0);

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

                // 2. Top Floating HUD Bar (Wrap on mobile so it never overflows on any screen width)
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 640;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 8 : 16,
                            vertical: isCompact ? 6 : 10,
                          ),
                          child: Wrap(
                            spacing: isCompact ? 6 : 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Back to Examples Button
                              IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints(
                                  minWidth: 34,
                                  minHeight: 34,
                                ),
                                padding: const EdgeInsets.all(6),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                                tooltip: vm.isKorean
                                    ? '예제 목록으로 돌아가기'
                                    : 'サンプル一覧に戻る',
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 15,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),

                              // Toggleable Study Note Pill
                              ActionChip(
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
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
                                  size: 14,
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isCompact ? 11 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: vm.toggleShowcase,
                              ),

                              // 3-Way Character Stage Selector: [👯 2인 동시] [🌺 레이나(갸루)] [🌸 히카리(청순)]
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _buildHeroineModeButton(
                                      label: vm.isKorean
                                          ? (isCompact ? '👯 2인' : '👯 2인 동시')
                                          : (isCompact ? '👯 2人' : '👯 2人同時'),
                                      isSelected: vm.isDualHeroineMode,
                                      activeColor: const Color(0xFFA855F7),
                                      isCompact: isCompact,
                                      onTap: vm.enableDualHeroineMode,
                                    ),
                                    _buildHeroineModeButton(
                                      label: vm.isKorean
                                          ? (isCompact
                                                ? '🌺 레이나'
                                                : '🌺 레이나(갸루)')
                                          : (isCompact
                                                ? '🌺 レイナ'
                                                : '🌺 レイナ(ギャル)'),
                                      isSelected:
                                          !vm.isDualHeroineMode &&
                                          vm.selectedHeroine ==
                                              VnHeroineCharacter.reina,
                                      activeColor:
                                          VnHeroineCharacter.reina.accentColor,
                                      isCompact: isCompact,
                                      onTap: () => vm.selectHeroine(
                                        VnHeroineCharacter.reina,
                                        soloMode: true,
                                      ),
                                    ),
                                    _buildHeroineModeButton(
                                      label: vm.isKorean
                                          ? (isCompact
                                                ? '🌸 히카리'
                                                : '🌸 히카리(청순)')
                                          : (isCompact
                                                ? '🌸 ヒカリ'
                                                : '🌸 ヒカリ(清楚)'),
                                      isSelected:
                                          !vm.isDualHeroineMode &&
                                          vm.selectedHeroine ==
                                              VnHeroineCharacter.hikari,
                                      activeColor:
                                          VnHeroineCharacter.hikari.accentColor,
                                      isCompact: isCompact,
                                      onTap: () => vm.selectHeroine(
                                        VnHeroineCharacter.hikari,
                                        soloMode: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quick Language Toggle Pill (🇯🇵 日本語 <-> 🇰🇷 한국어)
                              ActionChip(
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
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

                              // Affection Indicator Pill (Individual Heroine Affection in Dual Mode)
                              if (vm.isDualHeroineMode)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 8 : 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => vm.onHeroineTapped(
                                          VnHeroineCharacter.hikari,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.favorite_rounded,
                                                color: Color(0xFFF472B6),
                                                size: 13,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                isCompact
                                                    ? '🌸 ${vm.hikariAffectionPoints}%'
                                                    : (vm.isKorean
                                                          ? '🌸 히카리 ${vm.hikariAffectionPoints}%'
                                                          : '🌸 ヒカリ ${vm.hikariAffectionPoints}%'),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isCompact
                                                      ? 10.5
                                                      : 11.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 12,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        color: Colors.white24,
                                      ),
                                      InkWell(
                                        onTap: () => vm.onHeroineTapped(
                                          VnHeroineCharacter.reina,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.favorite_rounded,
                                                color: Color(0xFFF59E0B),
                                                size: 13,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                isCompact
                                                    ? '🌺 ${vm.reinaAffectionPoints}%'
                                                    : (vm.isKorean
                                                          ? '🌺 레이나 ${vm.reinaAffectionPoints}%'
                                                          : '🌺 レイナ ${vm.reinaAffectionPoints}%'),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isCompact
                                                      ? 10.5
                                                      : 11.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                InkWell(
                                  onTap: () => vm.onHeroineTapped(
                                    vm.selectedHeroine,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 8 : 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color:
                                              vm.selectedHeroine ==
                                                  VnHeroineCharacter.reina
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFFF472B6),
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
                        padding: EdgeInsets.only(
                          top: topOverlayOffset,
                          left: isMobileScreen ? 10 : 16,
                          right: isMobileScreen ? 10 : 16,
                          bottom: bottomOverlayOffset,
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
                    top: topOverlayOffset,
                    left: 0,
                    right: 0,
                    bottom: bottomOverlayOffset,
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
