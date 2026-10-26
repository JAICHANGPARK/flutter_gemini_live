import 'package:example/app_translations.dart';
import 'package:flutter/material.dart';

import '../../domain/models/vn_character_models.dart';
import '../../domain/models/vn_sdk_chapter.dart';
import '../anime_vn_i18n.dart';
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
    final i18n = AnimeVnI18n.current;
    final controller = TextEditingController();
    final submitted = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1429),
        title: Text(
          i18n.askDialogTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: i18n.askDialogHint,
            hintStyle: const TextStyle(color: Colors.white54),
          ),
          onSubmitted: (val) => Navigator.of(ctx).pop(val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(i18n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(i18n.sendQuestionButton),
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
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = AnimeVnI18n(lang);
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
                    i18n.chapterJumpMenuTitle,
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
                            chapter.titleFor(lang),
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
          listenable: Listenable.merge([
            widget.viewModel,
            AppLanguageController.instance,
          ]),
          builder: (context, _) {
            final vm = widget.viewModel;
            final lang = AppLanguageController.instance.currentLanguage;
            final i18n = AnimeVnI18n(lang);
            final currentPitch = vm.voicePitchShift;
            final isGyaru = vm.isGyaruVoiceStyle;
            final pitchPresets = i18n.pitchPresets(isGyaru);
            final voiceActors = i18n.voiceActors;

            final sheetWidth = MediaQuery.sizeOf(ctx).width;
            final isNarrowSheet = sheetWidth < 560;

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isNarrowSheet ? 14 : 20,
                    16,
                    isNarrowSheet ? 14 : 20,
                    14,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              i18n.voiceTunerSheetTitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isNarrowSheet ? 14.5 : 15.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () {
                                if (!vm.isConnected) {
                                  vm.connectSession(sendInitialGreeting: true);
                                } else {
                                  vm.speakCurrentBeat();
                                }
                              },
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: const Color(0xFFEC4899),
                              ),
                              icon: const Icon(
                                Icons.volume_up_rounded,
                                size: 15,
                              ),
                              label: Text(i18n.testVoiceNowButton),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          i18n.voiceTunerSection1,
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
                                  width: isNarrowSheet ? double.infinity : 265,
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
                                              h.nameFor(lang),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              h.subtitleFor(lang),
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
                          i18n.voiceTunerSection2,
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
                                  width: isNarrowSheet ? double.infinity : 255,
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
                          i18n.voiceTunerSection3,
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
    final lang = AppLanguageController.instance.currentLanguage;
    final i18n = AnimeVnI18n(lang);

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
            label: Text(i18n.showDialogueBoxButton),
          ),
        ),
      );
    }

    final beatNum = vm.currentBeatIndex + 1;
    final totalBeats = vm.totalBeatsInChapter;
    final chapterTitle = vm.currentChapter.titleFor(lang);

    final screenSize = MediaQuery.sizeOf(context);
    final isShortViewport = screenSize.height < 520;
    final boxMinHeight = isShortViewport
        ? 135.0
        : (screenSize.width < 600 ? 175.0 : 196.0);
    final boxMaxHeight = isShortViewport
        ? (screenSize.height * 0.64).clamp(150.0, 260.0)
        : (screenSize.width < 600
              ? (screenSize.height * 0.46).clamp(240.0, 360.0)
              : 340.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: vm.advanceDialogue,
      child: ClipPath(
        clipper: const _VnChamferedBoxClipper(),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: boxMinHeight,
            maxHeight: boxMaxHeight,
          ),
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

              SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 680;
                    final hPad = isCompact ? 10.0 : 32.0;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        isCompact ? 9 : 12,
                        hPad,
                        isCompact ? 6 : 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Upper scrollable region (Header Badges + Divider + Full Dialogue Text)
                          // Guarantees zero vertical RenderFlex overflow on any mobile portrait/landscape screen!
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Speaker Name + Status Badges (Wrap so every badge is 100% visible without clipping or ellipsis)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: isCompact ? 4 : 14,
                                      right: isCompact ? 18 : 28,
                                    ),
                                    child: Wrap(
                                      spacing: isCompact ? 6 : 8,
                                      runSpacing: isCompact ? 4 : 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        ValueListenableBuilder<String>(
                                          valueListenable:
                                              vm.speakerNameNotifier,
                                          builder: (context, speaker, _) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 4,
                                              ),
                                              child: Text(
                                                speaker,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isCompact
                                                      ? 15.5
                                                      : 19,
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
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompact ? 8 : 10,
                                            vertical: isCompact ? 2 : 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black38,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0x88B388FF),
                                            ),
                                          ),
                                          child: Text(
                                            isCompact
                                                ? 'Ch.${vm.currentChapter.chapterNumber} • STEP $beatNum/$totalBeats'
                                                : 'Ch.${vm.currentChapter.chapterNumber} ($chapterTitle)  •  STEP $beatNum / $totalBeats',
                                            style: TextStyle(
                                              color: const Color(0xFFE9D5FF),
                                              fontSize: isCompact ? 10.5 : 11.5,
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
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isCompact ? 8 : 10,
                                              vertical: isCompact ? 3 : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: vm
                                                  .selectedHeroine
                                                  .accentColor
                                                  .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: vm
                                                    .selectedHeroine
                                                    .accentColor,
                                              ),
                                            ),
                                            child: Text(
                                              i18n.heroineSwitchPill(
                                                badgeEmoji: vm
                                                    .selectedHeroine
                                                    .badgeEmoji,
                                                isReina:
                                                    vm.selectedHeroine ==
                                                    VnHeroineCharacter.reina,
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isCompact
                                                    ? 10.5
                                                    : 11.2,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Moe / Gyaru Voice Pitch & Seiyuu Selector Pill
                                        InkWell(
                                          onTap: () =>
                                              _showMoeVoiceTunerSheet(context),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isCompact ? 8 : 10,
                                              vertical: isCompact ? 3 : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0x33EC4899),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFFF472B6),
                                              ),
                                            ),
                                            child: Text(
                                              i18n.voiceTunerPill(
                                                isGyaru: vm.isGyaruVoiceStyle,
                                                selectedVoice: vm.selectedVoice,
                                                pitchShift: vm.voicePitchShift,
                                              ),
                                              style: TextStyle(
                                                color: const Color(0xFFFBCFE8),
                                                fontSize: isCompact
                                                    ? 10.5
                                                    : 11.2,
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
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isCompact ? 8 : 10,
                                              vertical: isCompact ? 3 : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: vm.isConnected
                                                  ? const Color(0x3310B981)
                                                  : const Color(0x33F59E0B),
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                                      : Icons
                                                            .play_circle_outline_rounded,
                                                  size: isCompact ? 14 : 15,
                                                  color: vm.isConnected
                                                      ? const Color(0xFF6EE7B7)
                                                      : const Color(0xFFFDE68A),
                                                ),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    i18n.voicePlaybackStatusPill(
                                                      isConnected:
                                                          vm.isConnected,
                                                      isConnecting:
                                                          vm.isConnecting,
                                                      isAiSpeaking:
                                                          vm.isAiSpeaking,
                                                      selectedVoice:
                                                          vm.selectedVoice,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: isCompact
                                                          ? 10.5
                                                          : 11.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: isCompact ? 5 : 6),

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

                                  SizedBox(height: isCompact ? 7 : 10),

                                  // 3. Main Dialogue Text Area (Full text visible without ellipsis truncation)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 4 : 14,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ValueListenableBuilder<String>(
                                          valueListenable: vm.subtitleNotifier,
                                          builder: (context, primaryText, _) {
                                            return RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isCompact
                                                      ? 14.5
                                                      : 18.0,
                                                  height: 1.40,
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
                                                  TextSpan(
                                                    text: '$primaryText ',
                                                  ),
                                                  WidgetSpan(
                                                    alignment:
                                                        PlaceholderAlignment
                                                            .middle,
                                                    child: FadeTransition(
                                                      opacity:
                                                          _cursorBlinkController,
                                                      child: Container(
                                                        margin:
                                                            const EdgeInsets.only(
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
                                                              BorderRadius.circular(
                                                                3,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          '▼',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                          valueListenable:
                                              vm.japaneseLineNotifier,
                                          builder: (context, textJa, _) {
                                            if (textJa.isEmpty) {
                                              return const SizedBox.shrink();
                                            }
                                            return Text(
                                              textJa,
                                              style: TextStyle(
                                                color: const Color(0xFFBAE6FD),
                                                fontSize: isCompact
                                                    ? 11.5
                                                    : 13.5,
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
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isCompact ? 5 : 8),

                          // 4. Bottom Visual Novel Hint & System Menu Bar (Wrap so neither hint nor buttons are ever truncated)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 4 : 14,
                            ),
                            child: Wrap(
                              spacing: isCompact ? 8 : 12,
                              runSpacing: isCompact ? 3 : 4,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  i18n.bottomHintText(
                                    isChoiceOverlayOpen: vm.isChoiceOverlayOpen,
                                    beatNum: beatNum,
                                    totalBeats: totalBeats,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isCompact ? 10.5 : 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Wrap(
                                  spacing: isCompact ? 1 : 2,
                                  runSpacing: 2,
                                  children: [
                                    _VnMenuTextButton(
                                      label: '◀ PREV',
                                      compact: isCompact,
                                      onTap: vm.previousDialogue,
                                    ),
                                    _VnMenuTextButton(
                                      label: 'NEXT ▶',
                                      compact: isCompact,
                                      onTap: vm.advanceDialogue,
                                    ),
                                    _VnMenuTextButton(
                                      label: 'JUMP',
                                      compact: isCompact,
                                      onTap: () =>
                                          _showChapterJumpMenu(context),
                                    ),
                                    _VnMenuTextButton(
                                      label: 'CHOICE',
                                      compact: isCompact,
                                      isActive: vm.isChoiceOverlayOpen,
                                      onTap: vm.toggleChoices,
                                    ),
                                    _VnMenuTextButton(
                                      label: 'CODE',
                                      compact: isCompact,
                                      isActive: vm.isShowcaseVisible,
                                      onTap: vm.toggleShowcase,
                                    ),
                                    _VnMenuTextButton(
                                      label: 'RIG',
                                      compact: isCompact,
                                      isActive: vm.isRigInspectorVisible,
                                      activeColor: const Color(0xFF4ADE80),
                                      onTap: vm.toggleRigInspector,
                                    ),
                                    _VnMenuTextButton(
                                      label: vm.isMicRecording
                                          ? '🎙️MIC ON'
                                          : '🎙️MIC',
                                      compact: isCompact,
                                      isActive: vm.isMicRecording,
                                      activeColor: const Color(0xFFF43F5E),
                                      onTap: vm.toggleMic,
                                    ),
                                    _VnMenuTextButton(
                                      label: 'ASK',
                                      compact: isCompact,
                                      onTap: () => _showAskDialog(context),
                                    ),
                                    _VnMenuTextButton(
                                      label: 'SKIP',
                                      compact: isCompact,
                                      onTap: vm.skipToChoices,
                                    ),
                                    _VnMenuTextButton(
                                      label: 'AUTO',
                                      compact: isCompact,
                                      isActive: vm.isAutoMode,
                                      onTap: vm.toggleAutoMode,
                                    ),
                                    _VnMenuTextButton(
                                      label: 'LOG',
                                      compact: isCompact,
                                      onTap: widget.onOpenBacklog,
                                    ),
                                    _VnMenuTextButton(
                                      label: 'CLOSE',
                                      compact: isCompact,
                                      onTap: vm.toggleDialogueBoxHidden,
                                    ),
                                    _VnMenuTextButton(
                                      label: 'CONFIG',
                                      compact: isCompact,
                                      onTap: widget.onOpenSettings,
                                    ),
                                    _VnMenuTextButton(
                                      label: 'QUIT',
                                      compact: isCompact,
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
  final bool compact;
  final Color activeColor;

  const _VnMenuTextButton({
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.compact = false,
    this.activeColor = const Color(0xFF38BDF8),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 7,
          vertical: compact ? 2 : 3,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : const Color(0xFFB8B2C8),
            fontSize: compact ? 10.5 : 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
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
    final isCompact = MediaQuery.sizeOf(context).width < 520;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 20,
            vertical: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < choices.length; i++) ...[
                _GlossyVnChoiceButton(
                  choice: choices[i],
                  compact: isCompact,
                  onTap: () => viewModel.selectChoice(choices[i]),
                ),
                if (i < choices.length - 1)
                  SizedBox(height: isCompact ? 10 : 16),
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
  final bool compact;

  const _GlossyVnChoiceButton({
    required this.choice,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_GlossyVnChoiceButton> createState() => _GlossyVnChoiceButtonState();
}

class _GlossyVnChoiceButtonState extends State<_GlossyVnChoiceButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.compact;
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
            constraints: BoxConstraints(minHeight: isCompact ? 50 : 64),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 14 : 22,
                    vertical: isCompact ? 8 : 10,
                  ),
                  child: Builder(
                    builder: (context) {
                      final lang =
                          AppLanguageController.instance.currentLanguage;
                      final primaryChoiceLabel = widget.choice.labelFor(lang);
                      final showSubJa =
                          lang != AppLanguage.ja &&
                          primaryChoiceLabel != widget.choice.labelJa;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main Choice Text with strong dark outline shadow
                          Text(
                            primaryChoiceLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact ? 14.5 : 17.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                              shadows: const [
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
                          if (showSubJa) ...[
                            const SizedBox(height: 2),
                            // Japanese Sub-label (shown when primary language is EN/KO/ZH)
                            Text(
                              widget.choice.labelJa,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFF0F9FF),
                                fontSize: isCompact ? 11 : 12,
                                fontWeight: FontWeight.w700,
                                shadows: const [
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
