import 'dart:async';

import 'package:example/api_key_store.dart';
import 'package:example/app_translations.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

import '../../data/services/vn_audio_service.dart';
import '../../data/services/vn_live_service.dart';
import '../../domain/models/vn_character_models.dart';
import '../../domain/models/vn_sdk_chapter.dart';
import '../anime_vn_i18n.dart';

/// A single entry in the Visual Novel backlog (`LOG / バックログ`).
class VnDialogueLogEntry {
  final String speaker;
  final String textJa;
  final String textKo;
  final String textLocalized;
  final VnCharacterEmotion emotion;
  final DateTime timestamp;
  final bool isUser;

  const VnDialogueLogEntry({
    required this.speaker,
    required this.textJa,
    this.textKo = '',
    this.textLocalized = '',
    required this.emotion,
    required this.timestamp,
    this.isUser = false,
  });

  String get text {
    final lang = AppLanguageController.instance.currentLanguage;
    if (lang == AppLanguage.ja) {
      return textJa.isNotEmpty ? textJa : textLocalized;
    }
    final primary = textLocalized.isNotEmpty
        ? textLocalized
        : (lang == AppLanguage.ko && textKo.isNotEmpty ? textKo : textJa);
    if (primary.isNotEmpty && textJa.isNotEmpty && primary != textJa) {
      return '$primary\n$textJa';
    }
    return primary.isNotEmpty ? primary : textJa;
  }
}

/// ViewModel for the Japanese Bishoujo Visual Novel & `gemini_live` SDK Tutor.
///
/// Implements an authentic Visual Novel state machine:
/// 1. **Dialogue Progression (`Beat 1 -> Beat 2 -> Beat 3 -> Beat 4`)**:
///    Clicking the bottom dialogue box advances to the next scripted lesson line
///    and speaks it in Japanese via Gemini Live 24kHz audio.
/// 2. **Centered Choice Phase (Screenshot 2 style)**:
///    At the end of a chapter's dialogue sequence, 3 large glossy choice bars
///    appear in the center of the screen so the user can pick the next SDK topic
///    or ask Hikari a live question.
/// 3. **Live Voice / Custom Question Mode**:
///    At any time, the user can toggle the 16kHz microphone (`🎙️`) or ask a
///    question and receive a live spoken response from Hikari.
class AnimeVnViewModel extends ChangeNotifier {
  AnimeVnViewModel({
    VnAudioService? audioService,
    VnLiveService? liveService,
  }) : _audio = audioService ?? VnAudioService(),
       _live = liveService ?? VnLiveService();

  final VnAudioService _audio;
  final VnLiveService _live;
  AudioRecorder? _recorder;

  AudioRecorder get _micRecorder => _recorder ??= AudioRecorder();

  void Function(String message)? onNotice;
  Future<bool?> Function()? requestApiKeySetup;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  // --- Connection & Audio State ---
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isMicRecording = false;
  // Heroine selection: Hikari (Pure Moe) vs Reina (Shibuya Tech-Gyaru) + Dual Stage Mode
  VnHeroineCharacter _selectedHeroine = VnHeroineCharacter.reina;
  bool _isDualHeroineMode = true;
  bool _isGyaruVoiceStyle = true;
  // Default to heroine's recommended voice ('Autonoe' for Reina, 'Leda' for Hikari)
  String _selectedVoice = GeminiLiveVoice.autonoe.id;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isMicRecording => _isMicRecording;
  bool get isAiSpeaking => _audio.isAiSpeaking;
  VnHeroineCharacter get selectedHeroine => _selectedHeroine;
  bool get isDualHeroineMode => _isDualHeroineMode;

  /// Returns the heroine who is speaking the current dialogue beat.
  /// In Dual Heroine Mode (`_isDualHeroineMode == true`), Reina (Gyaru) and
  /// Hikari (Pure Moe) take turns beat-by-beat!
  VnHeroineCharacter get activeSpeakingHeroine {
    if (!_isDualHeroineMode) return _selectedHeroine;
    return (_currentBeatIndex % 2 == 0)
        ? VnHeroineCharacter.reina
        : VnHeroineCharacter.hikari;
  }

  bool get isGyaruVoiceStyle =>
      activeSpeakingHeroine == VnHeroineCharacter.reina || _isGyaruVoiceStyle;
  String get selectedVoice => _selectedVoice;
  double get voicePitchShift => _audio.pitchShift;

  void setVoicePitchShift(double shift, {bool? gyaruStyle}) {
    if (gyaruStyle != null) {
      _isGyaruVoiceStyle = gyaruStyle;
    }
    _audio.setPitchShift(shift);
    _refreshCurrentBeatDisplay();
    notifyListeners();
  }

  Future<void> enableDualHeroineMode() async {
    _isDualHeroineMode = true;
    final speaker = activeSpeakingHeroine;
    _selectedHeroine = speaker;
    _isGyaruVoiceStyle = speaker == VnHeroineCharacter.reina;
    _audio.setPitchShift(speaker.defaultPitchShift);
    _refreshCurrentBeatDisplay();
    notifyListeners();
    if (_isConnected) {
      speakCurrentBeat();
    } else {
      _audio.triggerSimulatedSpeechBurst(
        duration: const Duration(milliseconds: 2400),
      );
    }
  }

  Future<void> selectHeroine(
    VnHeroineCharacter heroine, {
    bool soloMode = true,
  }) async {
    if (soloMode) {
      _isDualHeroineMode = false;
    }
    _selectedHeroine = heroine;
    _isGyaruVoiceStyle = heroine == VnHeroineCharacter.reina;
    _audio.setPitchShift(heroine.defaultPitchShift);
    _heartBurstTick++;
    _refreshCurrentBeatDisplay();
    notifyListeners();

    if (_selectedVoice != heroine.defaultVoiceId) {
      await changeVoice(heroine.defaultVoiceId);
    } else if (_isConnected) {
      speakCurrentBeat();
    } else {
      _audio.triggerSimulatedSpeechBurst(
        duration: const Duration(milliseconds: 2400),
      );
    }
  }

  StreamSubscription<Uint8List>? _micSubscription;
  int _bargeInLoudChunks = 0;

  // --- Visual Novel Progression State ---
  int _currentChapterIndex = 0;
  int _currentBeatIndex = 0;
  bool _isChoiceOverlayOpen = false;
  bool _isDialogueBoxHidden = false; // CLOSE button in VN bar
  bool _isAutoMode = false;
  Timer? _autoAdvanceTimer;

  VnCharacterEmotion _currentEmotion = VnCharacterEmotion.happy;
  VnCharacterEmotion _hikariEmotion = VnCharacterEmotion.normal;
  VnCharacterEmotion _reinaEmotion = VnCharacterEmotion.happy;
  VnStageMotion _lastMotion = VnStageMotion.jump;
  int _motionTriggerTick = 0;
  int _hikariMotionTick = 0;
  int _reinaMotionTick = 0;
  int _heartBurstTick = 0;
  int _hikariHeartBurstTick = 0;
  int _reinaHeartBurstTick = 0;
  VnSceneBackground _currentScene = VnSceneBackground.tokyoConf;
  int _hikariAffection = 70; // 0..100
  int _reinaAffection = 70; // 0..100

  late VnSdkShowcaseData _currentShowcase =
      VnScenarioCatalog.chapters.first.showcase;
  bool _isShowcaseVisible = true;
  bool _isRigInspectorVisible = false;
  bool _isSteppedAnimationMode = false;

  VnCharacterEmotion get currentEmotion => _currentEmotion;
  VnCharacterEmotion emotionFor(VnHeroineCharacter h) =>
      h == VnHeroineCharacter.reina ? _reinaEmotion : _hikariEmotion;
  VnStageMotion get lastMotion => _lastMotion;
  int get motionTriggerTick => _motionTriggerTick;
  int motionTickFor(VnHeroineCharacter h) =>
      h == VnHeroineCharacter.reina ? _reinaMotionTick : _hikariMotionTick;
  int get heartBurstTick => _heartBurstTick;
  int heartBurstTickFor(VnHeroineCharacter h) => h == VnHeroineCharacter.reina
      ? _reinaHeartBurstTick
      : _hikariHeartBurstTick;
  VnSceneBackground get currentScene => _currentScene;
  int get hikariAffectionPoints => _hikariAffection;
  int get reinaAffectionPoints => _reinaAffection;
  int affectionFor(VnHeroineCharacter h) =>
      h == VnHeroineCharacter.reina ? _reinaAffection : _hikariAffection;
  int get affectionPoints => affectionFor(activeSpeakingHeroine);

  int get currentChapterIndex => _currentChapterIndex;
  VnSdkChapter get currentChapter =>
      VnScenarioCatalog.chapters[_currentChapterIndex];
  int get currentBeatIndex => _currentBeatIndex;
  int get totalBeatsInChapter => currentChapter.dialogueBeats.length;
  VnDialogueBeat get currentBeat =>
      currentChapter.dialogueBeats[_currentBeatIndex.clamp(
        0,
        currentChapter.dialogueBeats.length - 1,
      )];

  VnSdkShowcaseData get currentShowcase => _currentShowcase;
  bool get isShowcaseVisible => _isShowcaseVisible;
  bool get isRigInspectorVisible => _isRigInspectorVisible;
  bool get isSteppedAnimationMode => _isSteppedAnimationMode;

  /// True when the 3 large glossy choice bars are shown in the center of the screen.
  bool get isChoiceOverlayOpen => _isChoiceOverlayOpen;
  bool get isChoicesVisible => _isChoiceOverlayOpen;
  bool get isDialogueBoxHidden => _isDialogueBoxHidden;
  bool get isAutoMode => _isAutoMode;

  AppLanguage get currentLanguage =>
      AppLanguageController.instance.currentLanguage;

  AnimeVnI18n get i18n => AnimeVnI18n(currentLanguage);

  bool get isKorean => currentLanguage == AppLanguage.ko;

  String get defaultSpeakerLabel {
    final h = activeSpeakingHeroine;
    return '${h.badgeEmoji} ${h.nameFor(currentLanguage)}';
  }

  String get userSpeakerLabel => i18n.userSpeakerLabel;

  String _resolveBeatTextJa(VnDialogueBeat beat) {
    final speaker = activeSpeakingHeroine;
    if (speaker == VnHeroineCharacter.reina ||
        (!_isDualHeroineMode && _isGyaruVoiceStyle)) {
      return VnHeroineCharacter.toGyaruDialogueJa(
        beat.textJa,
        chapterNumber: currentChapter.chapterNumber,
        beatIndex: _currentBeatIndex,
      );
    }
    return beat.textJa;
  }

  String _resolveBeatTextKo(VnDialogueBeat beat) {
    final speaker = activeSpeakingHeroine;
    if (speaker == VnHeroineCharacter.reina ||
        (!_isDualHeroineMode && _isGyaruVoiceStyle)) {
      return VnHeroineCharacter.toGyaruDialogueKo(
        beat.textKo,
        chapterNumber: currentChapter.chapterNumber,
        beatIndex: _currentBeatIndex,
      );
    }
    return beat.textKo;
  }

  String _resolveBeatTextLocalized(VnDialogueBeat beat) {
    final lang = currentLanguage;
    final useGyaru =
        activeSpeakingHeroine == VnHeroineCharacter.reina ||
        (!_isDualHeroineMode && _isGyaruVoiceStyle);
    final chapterNum = currentChapter.chapterNumber;
    return switch (lang) {
      AppLanguage.ko => _resolveBeatTextKo(beat),
      AppLanguage.ja => _resolveBeatTextJa(beat),
      AppLanguage.zh =>
        AnimeVnI18n.beatTextZh(
              chapterNum,
              _currentBeatIndex,
              useGyaru: useGyaru,
            ) ??
            _resolveBeatTextJa(beat),
      AppLanguage.en =>
        AnimeVnI18n.beatTextEn(
              chapterNum,
              _currentBeatIndex,
              useGyaru: useGyaru,
            ) ??
            _resolveBeatTextJa(beat),
    };
  }

  void _refreshCurrentBeatDisplay() {
    if (_isSpeakingScriptedBeat) {
      final beat = currentBeat;
      final textJa = _resolveBeatTextJa(beat);
      final textLocalized = _resolveBeatTextLocalized(beat);
      speakerNameNotifier.value = defaultSpeakerLabel;
      subtitleNotifier.value = textLocalized;
      japaneseLineNotifier.value = currentLanguage != AppLanguage.ja
          ? '「$textJa」'
          : '';
    } else {
      speakerNameNotifier.value = defaultSpeakerLabel;
    }
  }

  String get affectionRankLabelJa => i18n.affectionRankLabel(affectionPoints);

  // --- Dialogue Window Notifiers ---
  late final ValueNotifier<String> speakerNameNotifier = ValueNotifier(
    defaultSpeakerLabel,
  );

  /// Primary text shown in the VN dialogue box (Japanese when locale is JA, Korean when KO).
  final ValueNotifier<String> subtitleNotifier = ValueNotifier('');

  /// Secondary Japanese script line shown in the dialogue box (only when primary is Korean).
  final ValueNotifier<String> japaneseLineNotifier = ValueNotifier('');

  final ValueNotifier<double> micVolumeNotifier = ValueNotifier(0.0);
  final ValueNotifier<String?> activeToolBannerNotifier = ValueNotifier(null);

  /// When true, we are playing a scripted lesson beat and only want the voice
  /// audio from Gemini Live (keeping the clean bilingual lesson text in the box).
  /// When false (user asked a live question via mic or AI choice), live transcripts
  /// stream directly into the dialogue box.
  bool _isSpeakingScriptedBeat = true;

  final StringBuffer _currentTurnTextBuffer = StringBuffer();
  final StringBuffer _currentUserTurnBuffer = StringBuffer();
  final List<VnDialogueLogEntry> _dialogueHistory = [];

  List<VnDialogueLogEntry> get dialogueHistory =>
      List.unmodifiable(_dialogueHistory);

  final GeminiTokenUsageTracker usageTracker = GeminiTokenUsageTracker(
    model: LiveModels.gemini38Live,
  );

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void _onLanguageChanged() {
    if (_disposed) return;
    _refreshCurrentBeatDisplay();
    notifyListeners();
  }

  Future<void> init() async {
    AppLanguageController.instance.addListener(_onLanguageChanged);
    _audio.setPitchShift(_selectedHeroine.defaultPitchShift);
    _applyBeatState(0, speakAloud: false);
    await _audio.init();
    if (ApiKeyStore.hasApiKey) {
      await connectSession(sendInitialGreeting: true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    AppLanguageController.instance.removeListener(_onLanguageChanged);
    _autoAdvanceTimer?.cancel();
    _micSubscription?.cancel();
    final rec = _recorder;
    if (rec != null) {
      unawaited(rec.dispose());
    }
    _live.close();
    _audio.dispose();
    subtitleNotifier.dispose();
    japaneseLineNotifier.dispose();
    speakerNameNotifier.dispose();
    micVolumeNotifier.dispose();
    activeToolBannerNotifier.dispose();
    usageTracker.dispose();
    super.dispose();
  }

  double sampleLipSyncEnergy(double elapsedSeconds) =>
      _audio.sampleLipSyncEnergy(elapsedSeconds);

  // ---------------------------------------------------------------------------
  // Visual Novel Script Progression (Click Dialogue -> Next Beat -> Choices)
  // ---------------------------------------------------------------------------

  void _applyBeatState(int beatIndex, {required bool speakAloud}) {
    final beats = currentChapter.dialogueBeats;
    if (beats.isEmpty) return;
    _currentBeatIndex = beatIndex.clamp(0, beats.length - 1);
    final beat = beats[_currentBeatIndex];

    _isSpeakingScriptedBeat = true;
    _currentEmotion = beat.emotion;
    if (activeSpeakingHeroine == VnHeroineCharacter.reina) {
      _reinaEmotion = beat.emotion;
    } else {
      _hikariEmotion = beat.emotion;
    }

    // Resolve the most recent showcaseOverride up to _currentBeatIndex so the
    // study note card evolves step-by-step with each dialogue beat!
    VnSdkShowcaseData resolvedShowcase = currentChapter.showcase;
    for (var i = 0; i <= _currentBeatIndex; i++) {
      if (beats[i].showcaseOverride != null) {
        resolvedShowcase = beats[i].showcaseOverride!;
      }
    }
    _currentShowcase = resolvedShowcase;

    final textJa = _resolveBeatTextJa(beat);
    final textKo = _resolveBeatTextKo(beat);
    final textLocalized = _resolveBeatTextLocalized(beat);
    speakerNameNotifier.value = defaultSpeakerLabel;
    subtitleNotifier.value = textLocalized;
    japaneseLineNotifier.value = currentLanguage != AppLanguage.ja
        ? '「$textJa」'
        : '';

    _dialogueHistory.add(
      VnDialogueLogEntry(
        speaker: defaultSpeakerLabel,
        textJa: textJa,
        textKo: textKo,
        textLocalized: textLocalized,
        emotion: beat.emotion,
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();

    if (speakAloud) {
      speakCurrentBeat();
    }
  }

  /// Speaks the current dialogue beat in Japanese via Gemini Live 24kHz audio
  /// with anime voice actress (声優) acting direction and triggers lip-sync.
  void speakCurrentBeat() {
    final beat = currentBeat;
    final spokenJa = _resolveBeatTextJa(beat);
    _audio.clear();
    _currentTurnTextBuffer.clear();
    _isSpeakingScriptedBeat = true;

    final useGyaruTone =
        activeSpeakingHeroine == VnHeroineCharacter.reina ||
        (!_isDualHeroineMode && _isGyaruVoiceStyle);
    if (_isDualHeroineMode) {
      _audio.setPitchShift(activeSpeakingHeroine.defaultPitchShift);
    }

    final actingDirection = useGyaruTone
        ? switch (beat.emotion) {
            VnCharacterEmotion.happy =>
              'テンションMAXでノリノリな17歳の渋谷系アニメギャル美少女声優トーン（喜多川海夢やブルアカの陽キャギャルヒロイン風！明るく弾む高めのギャル声で語尾を可愛く跳ね上げて）で',
            VnCharacterEmotion.explaining =>
              '自信たっぷりで面倒見のいい陽キャギャル美少女アニメ声優トーン（明るくてテンポが良く、フレンドリーで超キュートなギャル声）で',
            VnCharacterEmotion.surprised =>
              'ちょっぴり照れて焦ったツンデレ風アニメギャル美少女の声（「えっ、ちょ、センパイ待って〜💦」のような可愛く上ずったギャル声）で',
            VnCharacterEmotion.thinking =>
              'コギャル風の甘くてキュートな高めのアニメ美少女声で、いたずらっぽくウインクしながら',
            VnCharacterEmotion.normal =>
              '明るくてフレンドリー、距離感が近くて超かわいいアニメギャルヒロイン（喜多川海夢風）の声で',
          }
        : switch (beat.emotion) {
            VnCharacterEmotion.happy =>
              'ワントーン〜ツートーン高い、甘くてキラキラ弾む超かわいい16歳の美少女アニメヒロイン声（嬉しい・ときめき全開トーン）で',
            VnCharacterEmotion.explaining =>
              '高めで明るく元気いっぱいのキュートな美少女アニメ声優トーン（得意げで可愛い後輩ヒロイン風）で',
            VnCharacterEmotion.surprised =>
              '高めの可愛いアニメ美少女声で、ちょっぴり照れてドキドキ・慌てたキュートなギャルゲーヒロイン風に',
            VnCharacterEmotion.thinking =>
              '甘くて柔らかい高めの美少女アニメ声で、目を輝かせながら可愛らしく',
            VnCharacterEmotion.normal =>
              '高めで甘く優しい、超キュートな美少女ギャルゲーヒロインの声で',
          };

    if (_isConnected) {
      _live.sendText(
        '【アニメ声優演技指示：落ち着いたナレーター声は禁止！$actingDirection、前置きや返事は一切言わず、次の鉤括弧内のセリフだけをそのまま演じて発話してください】：「$spokenJa」',
      );
    } else if (!_isConnecting && ApiKeyStore.hasApiKey) {
      unawaited(connectSession(sendInitialGreeting: true));
    } else {
      _audio.triggerSimulatedSpeechBurst(
        duration: const Duration(milliseconds: 2800),
      );
    }
  }

  /// Called when the user clicks the bottom Visual Novel dialogue box (or presses Space/Enter).
  ///
  /// - If the dialogue box was hidden (`CLOSE`), un-hides it.
  /// - If choices are currently open, closes them or stays.
  /// - If there are more dialogue beats in the current chapter (`1/4 -> 2/4 -> 3/4 -> 4/4`),
  ///   advances to the next beat and speaks it in Japanese!
  /// - If we are on the final beat of the chapter (`4/4`), opens the **Centered Choice Overlay**
  ///   (matching Screenshot 2)!
  void advanceDialogue() {
    if (_isDialogueBoxHidden) {
      _isDialogueBoxHidden = false;
      notifyListeners();
      return;
    }

    if (_isChoiceOverlayOpen) {
      return;
    }

    if (_currentBeatIndex < currentChapter.dialogueBeats.length - 1) {
      _applyBeatState(_currentBeatIndex + 1, speakAloud: true);
    } else {
      // Reached the end of this chapter's dialogue sequence -> Show centered choices!
      _isChoiceOverlayOpen = true;
      notifyListeners();
    }
  }

  /// Steps back to the previous dialogue beat (or previous chapter if on beat 0).
  void previousDialogue() {
    if (_isChoiceOverlayOpen) {
      _isChoiceOverlayOpen = false;
      notifyListeners();
      return;
    }
    if (_currentBeatIndex > 0) {
      _applyBeatState(_currentBeatIndex - 1, speakAloud: true);
    } else if (_currentChapterIndex > 0) {
      selectChapter(_currentChapterIndex - 1);
    }
  }

  /// Jumps directly to a specific beat index within the current chapter.
  void selectBeat(int beatIndex) {
    _isChoiceOverlayOpen = false;
    _applyBeatState(beatIndex, speakAloud: true);
  }

  /// Skips directly to the chapter's centered choice screen (`SKIP` button).
  void skipToChoices() {
    _audio.clear();
    final lastIdx = currentChapter.dialogueBeats.length - 1;
    if (_currentBeatIndex < lastIdx) {
      _applyBeatState(lastIdx, speakAloud: false);
    }
    _isChoiceOverlayOpen = true;
    notifyListeners();
  }

  /// Toggles `AUTO` mode, which automatically advances dialogue beats.
  void toggleAutoMode() {
    _isAutoMode = !_isAutoMode;
    _autoAdvanceTimer?.cancel();
    if (_isAutoMode) {
      _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (_disposed || !_isAutoMode) return;
        if (!isAiSpeaking && !_isChoiceOverlayOpen) {
          advanceDialogue();
        }
      });
    }
    notifyListeners();
  }

  void toggleDialogueBoxHidden() {
    _isDialogueBoxHidden = !_isDialogueBoxHidden;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Session Connection & Voice Switching
  // ---------------------------------------------------------------------------

  Future<void> connectSession({bool sendInitialGreeting = false}) async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      final configured = await requestApiKeySetup?.call();
      if (configured != true || !ApiKeyStore.hasApiKey) return;
    }

    _isConnecting = true;
    notifyListeners();

    try {
      final useGyaru =
          _selectedHeroine == VnHeroineCharacter.reina || _isGyaruVoiceStyle;
      await _live.connect(
        voiceName: _selectedVoice,
        systemInstruction: useGyaru
            ? VnScenarioCatalog.systemInstructionReinaJa
            : VnScenarioCatalog.systemInstructionJa,
        onOpen: () {
          debugPrint(
            '🌸 [AnimeVN] WebSocket transport opened, waiting for setupComplete...',
          );
        },
        onMessage: _handleServerMessage,
        onError: (err, st) {
          if (_disposed) return;
          _isConnecting = false;
          _isConnected = false;
          onNotice?.call('WebSocket Error: $err');
          notifyListeners();
        },
        onClose: (code, reason) {
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          notifyListeners();
          // Automatically recover if the server closed the session unexpectedly (e.g. 1008/1006)
          if (code != null && code != 1000 && ApiKeyStore.hasApiKey) {
            Future<void>.delayed(const Duration(milliseconds: 450), () {
              if (!_disposed && !_isConnected && !_isConnecting) {
                unawaited(connectSession(sendInitialGreeting: false));
              }
            });
          }
        },
      );

      if (_disposed) return;
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();

      if (sendInitialGreeting) {
        speakCurrentBeat();
      }
    } catch (e) {
      if (_disposed) return;
      _isConnecting = false;
      _isConnected = false;
      onNotice?.call(i18n.connectionFailed(e));
      notifyListeners();
    }
  }

  Future<void> changeVoice(String newVoiceName) async {
    if (_selectedVoice == newVoiceName) return;
    _selectedVoice = newVoiceName;
    notifyListeners();
    if (_isConnected) {
      await connectSession(sendInitialGreeting: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Server Message & Tool Call Handling
  // ---------------------------------------------------------------------------

  void _handleServerMessage(LiveServerMessage message) {
    if (_disposed) return;

    if (message.usageMetadata != null) {
      usageTracker.recordUsage(message.usageMetadata!);
    }

    // 1. Handle Tool Calls
    final functionCalls = message.toolCall?.functionCalls;
    if (functionCalls != null && functionCalls.isNotEmpty) {
      for (final call in functionCalls) {
        _executeVnToolCall(call);
      }
    }

    final serverContent = message.serverContent;
    if (serverContent == null) return;

    // 2. Handle Instant Barge-In Interruption (ONLY when microphone is actively recording!)
    // When the microphone is OFF (!_isMicRecording), `serverContent.interrupted == true`
    // is just the server acknowledging that a new scripted beat's `sendText` superseded
    // the previous beat's turn. Ignoring it when Mic is OFF prevents false barge-in
    // messages and prevents cutting off the newly started beat's audio.
    if (serverContent.interrupted == true) {
      if (!_isMicRecording) {
        return;
      }
      _audio.clear();
      _currentEmotion = VnCharacterEmotion.surprised;
      if (activeSpeakingHeroine == VnHeroineCharacter.reina) {
        _reinaEmotion = VnCharacterEmotion.surprised;
      } else {
        _hikariEmotion = VnCharacterEmotion.surprised;
      }
      _triggerMotion(VnStageMotion.flusteredShake);
      speakerNameNotifier.value = defaultSpeakerLabel;
      final useGyaru =
          activeSpeakingHeroine == VnHeroineCharacter.reina ||
          _isGyaruVoiceStyle;
      subtitleNotifier.value = i18n.bargeInPrimary(useGyaru: useGyaru);
      japaneseLineNotifier.value = i18n.bargeInSecondary(useGyaru: useGyaru);
      notifyListeners();
      return;
    }

    // 3. Input Audio Transcription (User speaking via Mic)
    final inputTranscript = serverContent.inputTranscription?.text;
    if (inputTranscript != null && inputTranscript.isNotEmpty) {
      _isSpeakingScriptedBeat = false;
      _currentUserTurnBuffer.write(inputTranscript);
      speakerNameNotifier.value = '🎙️ $userSpeakerLabel';
      subtitleNotifier.value = _currentUserTurnBuffer.toString().trim();
      japaneseLineNotifier.value = '';
    }

    // 4. Output Audio Transcription (Hikari speaking in Japanese)
    final outputTranscript = serverContent.outputTranscription?.text;
    if (outputTranscript != null && outputTranscript.isNotEmpty) {
      if (_currentUserTurnBuffer.isNotEmpty) {
        _commitUserTranscript();
      }
      _currentTurnTextBuffer.write(outputTranscript);
      if (!_isSpeakingScriptedBeat) {
        speakerNameNotifier.value = defaultSpeakerLabel;
        subtitleNotifier.value = _currentTurnTextBuffer.toString().trim();
        japaneseLineNotifier.value = i18n.liveAiRespondingHint;
      }
    }

    // 5. Model Turn Parts (24kHz PCM Audio + fallback text)
    var appendedFromMessageData = false;
    if (message.data != null && message.data!.isNotEmpty) {
      _audio.appendBase64Chunk(message.data!);
      appendedFromMessageData = true;
    }

    final parts = serverContent.modelTurn?.parts;
    if (parts != null) {
      for (final part in parts) {
        final inline = part.inlineData;
        if (!appendedFromMessageData &&
            inline != null &&
            inline.mimeType.startsWith('audio/pcm') &&
            inline.data.isNotEmpty) {
          _audio.appendBase64Chunk(inline.data);
        } else if (part.text != null &&
            part.text!.isNotEmpty &&
            part.thought != true) {
          if (outputTranscript == null && !_isSpeakingScriptedBeat) {
            _currentTurnTextBuffer.write(part.text!);
            speakerNameNotifier.value = defaultSpeakerLabel;
            subtitleNotifier.value = _currentTurnTextBuffer.toString().trim();
          }
        }
      }
    }

    // 6. Turn Complete (wait for turnComplete so trailing audio chunks are never cut off early)
    if (serverContent.turnComplete == true) {
      _audio.onTurnComplete();
      if (_currentTurnTextBuffer.isNotEmpty) {
        final fullText = _currentTurnTextBuffer.toString().trim();
        if (!_isSpeakingScriptedBeat) {
          _dialogueHistory.add(
            VnDialogueLogEntry(
              speaker: defaultSpeakerLabel,
              textJa: fullText,
              emotion: _currentEmotion,
              timestamp: DateTime.now(),
            ),
          );
        }
        _currentTurnTextBuffer.clear();
        notifyListeners();
      }
    }
  }

  void _commitUserTranscript() {
    final text = _currentUserTurnBuffer.toString().trim();
    _currentUserTurnBuffer.clear();
    if (text.isEmpty) return;
    _dialogueHistory.add(
      VnDialogueLogEntry(
        speaker: userSpeakerLabel,
        textJa: text,
        emotion: _currentEmotion,
        timestamp: DateTime.now(),
        isUser: true,
      ),
    );
  }

  void _executeVnToolCall(FunctionCall call) {
    final name = call.name ?? '';
    final args = call.args ?? const <String, dynamic>{};

    if (name == 'set_character_emotion') {
      final emotionStr = args['emotion']?.toString();
      final motionStr = args['motion']?.toString();
      final deltaRaw = args['affection_delta'];
      final delta = deltaRaw is num
          ? deltaRaw.toInt()
          : int.tryParse(deltaRaw?.toString() ?? '0') ?? 0;

      _currentEmotion = VnCharacterEmotion.fromId(emotionStr);
      final motion = VnStageMotion.fromId(motionStr);
      _triggerMotion(motion);

      if (delta != 0) {
        _addAffection(delta);
      }

      _showToolBanner(
        '⚡ Tool: set_character_emotion(${_currentEmotion.id}, motion: ${motion.id})',
      );
      notifyListeners();

      if (call.id != null) {
        _live.sendToolResponse(
          id: call.id!,
          name: name,
          response: {
            'status': 'ok',
            'current_emotion': _currentEmotion.id,
            'affection': affectionPoints,
          },
        );
      }
    } else if (name == 'show_sdk_showcase') {
      final topicId = args['topic_id']?.toString();
      _currentShowcase = VnScenarioCatalog.showcaseById(topicId);
      _isShowcaseVisible = true;
      _triggerMotion(VnStageMotion.nod);
      _showToolBanner(
        '📊 Tool: show_sdk_showcase(topic: ${_currentShowcase.topicId})',
      );
      notifyListeners();

      if (call.id != null) {
        _live.sendToolResponse(
          id: call.id!,
          name: name,
          response: {
            'status': 'displayed',
            'topic_id': _currentShowcase.topicId,
          },
        );
      }
    } else if (name == 'change_background_scene') {
      final sceneId = args['scene_id']?.toString();
      _currentScene = VnSceneBackground.fromId(sceneId);
      _showToolBanner('🌸 Tool: change_background_scene(${_currentScene.id})');
      notifyListeners();

      if (call.id != null) {
        _live.sendToolResponse(
          id: call.id!,
          name: name,
          response: {'status': 'scene_changed', 'scene': _currentScene.id},
        );
      }
    }
  }

  void _showToolBanner(String text) {
    activeToolBannerNotifier.value = text;
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!_disposed && activeToolBannerNotifier.value == text) {
        activeToolBannerNotifier.value = null;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // User Interactions (Choices, Chapters, Headpat, Mic, Manual Controls)
  // ---------------------------------------------------------------------------

  Future<void> selectChapter(int index) async {
    if (index < 0 || index >= VnScenarioCatalog.chapters.length) return;
    _currentChapterIndex = index;
    final chapter = VnScenarioCatalog.chapters[index];
    _currentScene = chapter.defaultScene;
    _currentShowcase = chapter.showcase;
    _isChoiceOverlayOpen = false;
    _isDialogueBoxHidden = false;

    if (!_isConnected && ApiKeyStore.hasApiKey) {
      _applyBeatState(0, speakAloud: false);
      await connectSession(sendInitialGreeting: true);
    } else {
      _applyBeatState(0, speakAloud: true);
    }
  }

  Future<void> selectChoice(VnChoiceOption choice) async {
    _addAffection(choice.affectionBonus);
    _isChoiceOverlayOpen = false;
    _isDialogueBoxHidden = false;

    // Case 1: Choice jumps to another learning chapter's step-by-step script
    if (choice.targetChapterIndex != null) {
      await selectChapter(choice.targetChapterIndex!);
      return;
    }

    // Case 2: Choice sends a live AI question to Hikari
    _isSpeakingScriptedBeat = false;
    _currentEmotion = choice.previewEmotion;
    _triggerMotion(VnStageMotion.jump);

    final localizedChoiceLabel = choice.labelFor(currentLanguage);
    _dialogueHistory.add(
      VnDialogueLogEntry(
        speaker: userSpeakerLabel,
        textJa: choice.labelJa,
        textKo: choice.labelKo,
        textLocalized: localizedChoiceLabel,
        emotion: choice.previewEmotion,
        timestamp: DateTime.now(),
        isUser: true,
      ),
    );
    speakerNameNotifier.value = defaultSpeakerLabel;
    subtitleNotifier.value = i18n.preparingAnswer;
    japaneseLineNotifier.value = '『$localizedChoiceLabel』';
    notifyListeners();

    if (!_isConnected) {
      await connectSession(sendInitialGreeting: false);
    }
    if (_isConnected && choice.livePromptToSend != null) {
      _audio.clear();
      _currentTurnTextBuffer.clear();
      _live.sendText(choice.livePromptToSend!);
    } else {
      _audio.triggerSimulatedSpeechBurst();
      subtitleNotifier.value = i18n.apiKeyRequiredSimulatedHint;
    }
  }

  Future<void> sendCustomMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _addAffection(3);
    _isChoiceOverlayOpen = false;
    _isSpeakingScriptedBeat = false;

    _dialogueHistory.add(
      VnDialogueLogEntry(
        speaker: userSpeakerLabel,
        textJa: trimmed,
        textLocalized: trimmed,
        emotion: _currentEmotion,
        timestamp: DateTime.now(),
        isUser: true,
      ),
    );
    speakerNameNotifier.value = userSpeakerLabel;
    subtitleNotifier.value = '『$trimmed』';
    japaneseLineNotifier.value = i18n.thinkingCustomReply;
    notifyListeners();

    if (!_isConnected) {
      await connectSession(sendInitialGreeting: false);
    }
    if (_isConnected) {
      _audio.clear();
      _currentTurnTextBuffer.clear();
      _live.sendText(trimmed);
    }
  }

  /// Called when the user taps directly on a specific heroine's illustration!
  void onHeroineTapped(VnHeroineCharacter heroine) {
    _addAffectionFor(heroine, 4);
    final prevEmotion = emotionFor(heroine);
    final nextEmotion = switch (prevEmotion) {
      VnCharacterEmotion.normal => VnCharacterEmotion.happy,
      VnCharacterEmotion.happy => VnCharacterEmotion.surprised,
      _ => VnCharacterEmotion.happy,
    };

    if (heroine == VnHeroineCharacter.reina) {
      _reinaEmotion = nextEmotion;
      _reinaMotionTick++;
    } else {
      _hikariEmotion = nextEmotion;
      _hikariMotionTick++;
    }
    _currentEmotion = nextEmotion;
    _lastMotion = VnStageMotion.jump;
    _motionTriggerTick++;
    notifyListeners();
  }

  /// Legacy single-character tap entrypoint.
  void onCharacterTapped() {
    onHeroineTapped(activeSpeakingHeroine);
  }

  void setEmotionManually(VnCharacterEmotion emotion) {
    _currentEmotion = emotion;
    if (activeSpeakingHeroine == VnHeroineCharacter.reina) {
      _reinaEmotion = emotion;
      _reinaMotionTick++;
    } else {
      _hikariEmotion = emotion;
      _hikariMotionTick++;
    }
    if (!isAiSpeaking) {
      _audio.triggerSimulatedSpeechBurst(
        duration: const Duration(milliseconds: 1400),
      );
    }
    _triggerMotion(
      emotion == VnCharacterEmotion.surprised
          ? VnStageMotion.flusteredShake
          : VnStageMotion.jump,
    );
    notifyListeners();
  }

  void setSceneManually(VnSceneBackground scene) {
    _currentScene = scene;
    notifyListeners();
  }

  void toggleShowcase() {
    _isShowcaseVisible = !_isShowcaseVisible;
    notifyListeners();
  }

  void toggleRigInspector() {
    _isRigInspectorVisible = !_isRigInspectorVisible;
    notifyListeners();
  }

  void toggleSteppedAnimationMode() {
    _isSteppedAnimationMode = !_isSteppedAnimationMode;
    notifyListeners();
  }

  void toggleChoices() {
    _isChoiceOverlayOpen = !_isChoiceOverlayOpen;
    notifyListeners();
  }

  void _triggerMotion(VnStageMotion motion) {
    _lastMotion = motion;
    _motionTriggerTick++;
    if (activeSpeakingHeroine == VnHeroineCharacter.reina) {
      _reinaMotionTick++;
    } else {
      _hikariMotionTick++;
    }
  }

  void _addAffection(int delta) {
    _addAffectionFor(activeSpeakingHeroine, delta);
  }

  void _addAffectionFor(VnHeroineCharacter heroine, int delta) {
    if (heroine == VnHeroineCharacter.reina) {
      _reinaAffection = (_reinaAffection + delta).clamp(0, 100);
      if (delta > 0) {
        _reinaHeartBurstTick++;
        _heartBurstTick++;
      }
    } else {
      _hikariAffection = (_hikariAffection + delta).clamp(0, 100);
      if (delta > 0) {
        _hikariHeartBurstTick++;
        _heartBurstTick++;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 16kHz Microphone Capture & Barge-In Detection
  // ---------------------------------------------------------------------------

  Future<void> toggleMic() async {
    if (_isMicRecording) {
      await stopMic();
    } else {
      await startMic();
    }
  }

  Future<void> startMic() async {
    if (_isMicRecording) return;
    if (!_isConnected) {
      await connectSession(sendInitialGreeting: false);
      if (!_isConnected) return;
    }

    try {
      final hasPerm = await _micRecorder.hasPermission();
      if (!hasPerm) {
        onNotice?.call(i18n.micPermissionRequired);
        return;
      }

      final stream = await _micRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
          autoGain: true,
        ),
      );

      _isMicRecording = true;
      _isChoiceOverlayOpen = false;
      _isSpeakingScriptedBeat = false;
      notifyListeners();

      _micSubscription = stream.listen((pcmBytes) {
        if (_disposed || !_isConnected) return;
        final rms = GeminiLiveAudioUtils.calculateRms(pcmBytes);
        final visual = GeminiLiveAudioUtils.toVisualScale(rms, factor: 2.0);
        micVolumeNotifier.value = visual;

        if (isAiSpeaking && visual > 0.35) {
          _bargeInLoudChunks++;
          if (_bargeInLoudChunks >= 5) {
            _bargeInLoudChunks = 0;
            _audio.clear();
            _currentEmotion = VnCharacterEmotion.surprised;
            _triggerMotion(VnStageMotion.flusteredShake);
            notifyListeners();
          }
        } else {
          _bargeInLoudChunks = 0;
        }

        _live.sendAudio(pcmBytes);
      });
    } catch (e) {
      onNotice?.call(i18n.micStartError(e));
    }
  }

  Future<void> stopMic() async {
    await _micSubscription?.cancel();
    _micSubscription = null;
    try {
      await _recorder?.stop();
    } catch (_) {}
    _isMicRecording = false;
    micVolumeNotifier.value = 0.0;
    notifyListeners();
  }
}
