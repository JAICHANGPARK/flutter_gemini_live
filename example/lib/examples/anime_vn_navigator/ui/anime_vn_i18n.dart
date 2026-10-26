import 'package:example/app_translations.dart';

/// Complete 4-language (`en`, `ko`, `ja`, `zh`) localization helper for
/// `AnimeVnNavigatorPage` (`ときめき☆Gemini Live`).
class AnimeVnI18n {
  final AppLanguage lang;
  const AnimeVnI18n(this.lang);

  static AnimeVnI18n get current =>
      AnimeVnI18n(AppLanguageController.instance.currentLanguage);

  // ---------------------------------------------------------------------------
  // Top HUD & Navigation
  // ---------------------------------------------------------------------------

  String get gameTitleBadge => switch (lang) {
    AppLanguage.ko => '도키메키☆Gemini Live 내비',
    AppLanguage.ja => 'ときめき☆Gemini Live ナビ',
    AppLanguage.zh => '心动☆Gemini Live 领航',
    AppLanguage.en => 'Tokimeki☆Gemini Live Nav',
  };

  String get backToExamplesTooltip => switch (lang) {
    AppLanguage.ko => '예제 목록으로 돌아가기',
    AppLanguage.ja => 'サンプル一覧に戻る',
    AppLanguage.zh => '返回示例列表',
    AppLanguage.en => 'Back to Examples',
  };

  String studyNoteToggleLabel({
    required bool isCompact,
    required bool isVisible,
  }) => switch (lang) {
    AppLanguage.ko =>
      isCompact
          ? (isVisible ? 'SDK 노트 닫기' : 'SDK 노트')
          : (isVisible ? '📘 SDK 코드 학습노트 닫기' : '📘 SDK 코드 학습노트 보기'),
    AppLanguage.ja =>
      isCompact
          ? (isVisible ? '学習ノート閉' : '学習ノート')
          : (isVisible ? '📘 SDK コード学習ノートを閉じる' : '📘 SDK コード学習ノートを見る'),
    AppLanguage.zh =>
      isCompact
          ? (isVisible ? '关闭笔记' : 'SDK 笔记')
          : (isVisible ? '📘 关闭 SDK 代码学习笔记' : '📘 查看 SDK 代码学习笔记'),
    AppLanguage.en =>
      isCompact
          ? (isVisible ? 'Hide Notes' : 'SDK Notes')
          : (isVisible ? '📘 Hide SDK Study Notes' : '📘 Show SDK Study Notes'),
  };

  String dualModeLabel({required bool isCompact}) => switch (lang) {
    AppLanguage.ko => isCompact ? '👯 2인' : '👯 2인 동시',
    AppLanguage.ja => isCompact ? '👯 2人' : '👯 2人同時',
    AppLanguage.zh => isCompact ? '👯 双人' : '👯 双人同台',
    AppLanguage.en => isCompact ? '👯 Dual' : '👯 Dual Stage',
  };

  String reinaModeLabel({required bool isCompact}) => switch (lang) {
    AppLanguage.ko => isCompact ? '🌺 레이나' : '🌺 레이나(갸루)',
    AppLanguage.ja => isCompact ? '🌺 レイナ' : '🌺 レイナ(ギャル)',
    AppLanguage.zh => isCompact ? '🌺 玲奈' : '🌺 玲奈(辣妹)',
    AppLanguage.en => isCompact ? '🌺 Reina' : '🌺 Reina (Gyaru)',
  };

  String hikariModeLabel({required bool isCompact}) => switch (lang) {
    AppLanguage.ko => isCompact ? '🌸 히카리' : '🌸 히카리(청순)',
    AppLanguage.ja => isCompact ? '🌸 ヒカリ' : '🌸 ヒカリ(清楚)',
    AppLanguage.zh => isCompact ? '🌸 光' : '🌸 光(纯情)',
    AppLanguage.en => isCompact ? '🌸 Hikari' : '🌸 Hikari (Pure)',
  };

  String hikariAffectionBadge(int pts, {required bool isCompact}) =>
      isCompact
      ? '🌸 $pts%'
      : switch (lang) {
          AppLanguage.ko => '🌸 히카리 $pts%',
          AppLanguage.ja => '🌸 ヒカリ $pts%',
          AppLanguage.zh => '🌸 光 $pts%',
          AppLanguage.en => '🌸 Hikari $pts%',
        };

  String reinaAffectionBadge(int pts, {required bool isCompact}) =>
      isCompact
      ? '🌺 $pts%'
      : switch (lang) {
          AppLanguage.ko => '🌺 레이나 $pts%',
          AppLanguage.ja => '🌺 レイナ $pts%',
          AppLanguage.zh => '🌺 玲奈 $pts%',
          AppLanguage.en => '🌺 Reina $pts%',
        };

  String soloAffectionBadge(int pts, {required bool isCompact}) =>
      isCompact
      ? '$pts%'
      : switch (lang) {
          AppLanguage.ko => '호감도 $pts%',
          AppLanguage.ja => '好感度 $pts%',
          AppLanguage.zh => '好感度 $pts%',
          AppLanguage.en => 'Affection $pts%',
        };

  String affectionRankLabel(int pts) {
    if (pts >= 90) {
      return switch (lang) {
        AppLanguage.ko => 'Lv.MAX 운명의 파트너 💖',
        AppLanguage.ja => 'Lv.MAX 運命の相棒 💖',
        AppLanguage.zh => 'Lv.MAX 命运的搭档 💖',
        AppLanguage.en => 'Lv.MAX Destined Partner 💖',
      };
    }
    if (pts >= 75) {
      return switch (lang) {
        AppLanguage.ko => 'Lv.4 최애 선배 💕',
        AppLanguage.ja => 'Lv.4 大好きセンパイ 💕',
        AppLanguage.zh => 'Lv.4 最喜欢的前辈 💕',
        AppLanguage.en => 'Lv.4 Beloved Senpai 💕',
      };
    }
    if (pts >= 50) {
      return switch (lang) {
        AppLanguage.ko => 'Lv.3 단짝 내비게이터 ✨',
        AppLanguage.ja => 'Lv.3 仲良しナビ ✨',
        AppLanguage.zh => 'Lv.3 亲密领航员 ✨',
        AppLanguage.en => 'Lv.3 Bestie Navigator ✨',
      };
    }
    return switch (lang) {
      AppLanguage.ko => 'Lv.2 반가워요 선배 🌸',
      AppLanguage.ja => 'Lv.2 はじめまして 🌸',
      AppLanguage.zh => 'Lv.2 初次见面 🌸',
      AppLanguage.en => 'Lv.2 Nice to Meet You 🌸',
    };
  }

  String connectionPillLabel({
    required bool isConnected,
    required bool isConnecting,
  }) {
    if (isConnected) {
      return switch (lang) {
        AppLanguage.ko => 'LIVE 연결 중 (ja-JP)',
        AppLanguage.ja => 'LIVE 接続中 (ja-JP)',
        AppLanguage.zh => 'LIVE 已连接 (ja-JP)',
        AppLanguage.en => 'LIVE Connected (ja-JP)',
      };
    }
    if (isConnecting) {
      return switch (lang) {
        AppLanguage.ko => '연결 중...',
        AppLanguage.ja => '接続中...',
        AppLanguage.zh => '正在连接...',
        AppLanguage.en => 'Connecting...',
      };
    }
    return switch (lang) {
      AppLanguage.ko => '미연결 (탭하여 시작)',
      AppLanguage.ja => '未接続 (タップで開始)',
      AppLanguage.zh => '未连接 (点击开始)',
      AppLanguage.en => 'Disconnected (Tap to start)',
    };
  }

  String get voiceSelectorTooltip => switch (lang) {
    AppLanguage.ko => 'CV (캐릭터 보이스) 변경',
    AppLanguage.ja => 'CV（キャラクターボイス）変更',
    AppLanguage.zh => '切换角色声优 (CV)',
    AppLanguage.en => 'Change Character Voice (CV)',
  };

  String get sceneSelectorTooltip => switch (lang) {
    AppLanguage.ko => '배경 스테이지 변경',
    AppLanguage.ja => '背景ステージ変更',
    AppLanguage.zh => '切换背景舞台',
    AppLanguage.en => 'Change Background Stage',
  };

  String get settingsTooltip => AppTranslations.of(lang).settingsTooltip;

  // ---------------------------------------------------------------------------
  // Backlog Sheet & Ask Dialog
  // ---------------------------------------------------------------------------

  String get backlogTitle => switch (lang) {
    AppLanguage.ko => '📜 지난 대사 기록 (LOG / バックログ)',
    AppLanguage.ja => '📜 バックログ (会話履歴 / LOG)',
    AppLanguage.zh => '📜 对话历史记录 (LOG / バックログ)',
    AppLanguage.en => '📜 Dialogue Backlog (LOG / バックログ)',
  };

  String get askDialogTitle => switch (lang) {
    AppLanguage.ko => '💬 히카리에게 직접 질문하기 (Gemini Live)',
    AppLanguage.ja => '💬 ヒカリに直接質問する (Gemini Live)',
    AppLanguage.zh => '💬 直接向光提问 (Gemini Live)',
    AppLanguage.en => '💬 Ask Hikari Directly (Gemini Live)',
  };

  String get askDialogHint => switch (lang) {
    AppLanguage.ko => '예: gemini_live에서 Barge-in은 어떻게 처리해?',
    AppLanguage.ja => '例: gemini_liveでバージインはどう処理するの？',
    AppLanguage.zh => '例如：在 gemini_live 中如何处理打断 (Barge-in)？',
    AppLanguage.en => 'e.g. How do I handle Barge-in in gemini_live?',
  };

  String get cancelButton => AppTranslations.of(lang).cancelButton;

  String get sendQuestionButton => switch (lang) {
    AppLanguage.ko => '질문 보내기',
    AppLanguage.ja => '質問を送る',
    AppLanguage.zh => '发送问题',
    AppLanguage.en => 'Send Question',
  };

  String get chapterJumpMenuTitle => switch (lang) {
    AppLanguage.ko => '📚 전 10화 마스터 커리큘럼 선택 (Ch.1 ~ Ch.10)',
    AppLanguage.ja => '📚 全10話 マスターカリキュラム選択 (Ch.1 ~ Ch.10)',
    AppLanguage.zh => '📚 全10话大师课程目录 (Ch.1 ~ Ch.10)',
    AppLanguage.en => '📚 10-Chapter Master Curriculum (Ch.1 ~ Ch.10)',
  };

  // ---------------------------------------------------------------------------
  // Voice Tuner Sheet & Dialogue Box Controls
  // ---------------------------------------------------------------------------

  String get voiceTunerSheetTitle => switch (lang) {
    AppLanguage.ko => '🌺 히로인 캐릭터 & 미소녀/갸루 보이스 튜너',
    AppLanguage.ja => '🌺 ヒロイン選択＆ギャル・美少女ボイスチューナー',
    AppLanguage.zh => '🌺 女主角切换与美少女/辣妹语音调音台',
    AppLanguage.en => '🌺 Heroine & Anime Voice Tuner',
  };

  String get testVoiceNowButton => switch (lang) {
    AppLanguage.ko => '지금 목소리 테스트',
    AppLanguage.ja => '今の声をテスト',
    AppLanguage.zh => '立即试听声音',
    AppLanguage.en => 'Test Voice Now',
  };

  String get voiceTunerSection1 => switch (lang) {
    AppLanguage.ko => '1. 파트너 히로인 캐릭터 선택 (클릭 시 일러스트 & 대사 스타일 즉시 전환)',
    AppLanguage.ja => '1. パートナーヒロイン選択（クリックで立ち絵＆セリフ口調を即時切替）',
    AppLanguage.zh => '1. 选择搭档女主角（点击立即切换立绘与台词风格）',
    AppLanguage.en =>
      '1. Select Partner Heroine (Instantly switches sprite & dialogue style)',
  };

  String get voiceTunerSection2 => switch (lang) {
    AppLanguage.ko => '2. 실시간 성우 연기 톤 & SoLoud DSP 피치 (재연결 없이 즉시 적용)',
    AppLanguage.ja => '2. リアルタイム声優演技トーン＆SoLoud DSPピッチ（即時反映）',
    AppLanguage.zh => '2. 实时声优演技语调与 SoLoud DSP 音高（无需重连立即生效）',
    AppLanguage.en =>
      '2. Real-Time Seiyuu Acting Tone & SoLoud DSP Pitch (Applied instantly)',
  };

  String get voiceTunerSection3 => switch (lang) {
    AppLanguage.ko => '3. Gemini Live 성우 베이스 프리셋 (변경 시 자동 재연결)',
    AppLanguage.ja => '3. Gemini Live 声優ベースプリセット（変更時に自動再接続）',
    AppLanguage.zh => '3. Gemini Live 声优基础音色预设（切换时自动重连）',
    AppLanguage.en =>
      '3. Gemini Live Base Voice Presets (Auto-reconnects on change)',
  };

  List<(String, String, double, bool)> pitchPresets(bool isGyaru) =>
      switch (lang) {
        AppLanguage.ko => [
          (
            '🌺 하이텐션 시부야 갸루 보이스 (추천)',
            '+2.3 반음 + 갸루 말투/연기 톤 (~っしょ! / 마린 톤)',
            1.14,
            true,
          ),
          ('🎀 초절정 모에 미소녀', '+3.3 반음 (블루아카/갸루게 청순 하이톤)', 1.21, false),
          ('🌸 정통 미연시 히로인', '+2.6 반음 (귀엽고 달콤한 정통파 후배 톤)', 1.16, false),
          ('✨ 상큼 발랄 후배 톤', '+1.5 반음 (밝고 경쾌한 애니 소녀)', 1.09, false),
          ('🎙️ 오리지널 내추럴 원음', '0.0 반음 (DSP 피치 변조 없음)', 1.00, isGyaru),
        ],
        AppLanguage.ja => [
          (
            '🌺 渋谷系ハイテンション・ギャルボイス (推奨)',
            '+2.3半音 + ギャル声優演技トーン (〜っしょ！✨)',
            1.14,
            true,
          ),
          ('🎀 超絶萌え美少女ボイス', '+3.3半音 (ブルアカ・ギャルゲー清楚高音)', 1.21, false),
          ('🌸 王道ギャルゲーヒロイン', '+2.6半音 (甘くて可愛い清楚後輩トーン)', 1.16, false),
          ('✨ 明るく元気な後輩トーン', '+1.5半音 (爽やかなアニメ美少女)', 1.09, false),
          ('🎙️ オリジナル原音', '0.0半音 (DSPピッチ変調なし)', 1.00, isGyaru),
        ],
        AppLanguage.zh => [
          (
            '🌺 涉谷系元气辣妹音色 (推荐)',
            '+2.3半音 + 辣妹声优演技语调 (〜っしょ！✨)',
            1.14,
            true,
          ),
          ('🎀 超绝萌系美少女音色', '+3.3半音 (蔚蓝档案/Galgame纯情高音)', 1.21, false),
          ('🌸 王道视觉小说女主角', '+2.6半音 (甜美可爱的纯情学妹语调)', 1.16, false),
          ('✨ 明亮元气学妹语调', '+1.5半音 (清爽的动漫美少女)', 1.09, false),
          ('🎙️ 原始自然原音', '0.0半音 (无 DSP 音高调制)', 1.00, isGyaru),
        ],
        AppLanguage.en => [
          (
            '🌺 High-Tension Shibuya Gyaru Voice (Recommended)',
            '+2.3 semitones + lively Gyaru acting tone (~ssho! ✨)',
            1.14,
            true,
          ),
          (
            '🎀 Ultra-Moe Anime Heroine',
            '+3.3 semitones (Bright high-pitched Blue Archive / VN tone)',
            1.21,
            false,
          ),
          (
            '🌸 Classic Visual Novel Heroine',
            '+2.6 semitones (Sweet & gentle kouhai tone)',
            1.16,
            false,
          ),
          (
            '✨ Cheerful Kouhai Tone',
            '+1.5 semitones (Crisp & energetic anime voice)',
            1.09,
            false,
          ),
          (
            '🎙️ Original Natural Voice',
            '0.0 semitones (No DSP pitch shift)',
            1.00,
            isGyaru,
          ),
        ],
      };

  List<(String, String)> get voiceActors => switch (lang) {
    AppLanguage.ko => const [
      ('Autonoe', '하이텐션 갸루 & 에너지 소녀 (레이나 추천)'),
      ('Leda', '밝고 통통 튀는 하이톤 소녀 (히카리 추천)'),
      ('Zephyr', '맑고 청량한 쿨뷰티 소녀 보이스'),
      ('Despina', '부드럽고 다정한 선배 보이스'),
      ('Aoede', '차분한 성인 내레이터 보이스'),
    ],
    AppLanguage.ja => const [
      ('Autonoe', 'ハイテンション・ギャル＆元気美少女 (レイナ推奨)'),
      ('Leda', '明るく弾むハイトーン美少女 (ヒカリ推奨)'),
      ('Zephyr', '透明感のある爽やか美少女'),
      ('Despina', '優しくて甘いお姉さんボイス'),
      ('Aoede', '落ち着いたナレーターボイス'),
    ],
    AppLanguage.zh => const [
      ('Autonoe', '元气辣妹与活力少女 (玲奈推荐)'),
      ('Leda', '明亮欢快的高音美少女 (光推荐)'),
      ('Zephyr', '清澈清爽的冷艳美少女音色'),
      ('Despina', '温柔甜美的学姐音色'),
      ('Aoede', '沉稳成熟的旁白音色'),
    ],
    AppLanguage.en => const [
      ('Autonoe', 'High-tension Gyaru & energetic heroine (Reina pick)'),
      ('Leda', 'Bright & bubbly high-tone heroine (Hikari pick)'),
      ('Zephyr', 'Clear & refreshing cool-beauty voice'),
      ('Despina', 'Gentle & sweet older-sister voice'),
      ('Aoede', 'Calm & composed narrator voice'),
    ],
  };

  String get showDialogueBoxButton => switch (lang) {
    AppLanguage.ko => '대사창 표시 (OPEN)',
    AppLanguage.ja => 'メッセージ枠を表示 (OPEN)',
    AppLanguage.zh => '显示对话框 (OPEN)',
    AppLanguage.en => 'Show Dialogue (OPEN)',
  };

  String heroineSwitchPill({
    required String badgeEmoji,
    required bool isReina,
  }) => switch (lang) {
    AppLanguage.ko =>
      '$badgeEmoji 히로인 전환: ${isReina ? "레이나(갸루) → 히카리" : "히카리(청순) → 레이나(갸루)"}',
    AppLanguage.ja =>
      '$badgeEmoji ヒロイン切替: ${isReina ? "レイナ(ギャル) → ヒカリ" : "ヒカリ(清楚) → レイナ(ギャル)"}',
    AppLanguage.zh =>
      '$badgeEmoji 切换女主: ${isReina ? "玲奈(辣妹) → 光" : "光(纯情) → 玲奈(辣妹)"}',
    AppLanguage.en =>
      '$badgeEmoji Switch Heroine: ${isReina ? "Reina (Gyaru) → Hikari" : "Hikari (Pure) → Reina (Gyaru)"}',
  };

  String voiceTunerPill({
    required bool isGyaru,
    required String selectedVoice,
    required double pitchShift,
  }) {
    final pitch = pitchShift.toStringAsFixed(2);
    return switch (lang) {
      AppLanguage.ko =>
        '${isGyaru ? "🌺 갸루 보이스" : "🎀 미소녀 보이스"} ($selectedVoice • ${pitch}x)',
      AppLanguage.ja =>
        '${isGyaru ? "🌺 ギャルボイス" : "🎀 美少女ボイス"} ($selectedVoice • ${pitch}x)',
      AppLanguage.zh =>
        '${isGyaru ? "🌺 辣妹音色" : "🎀 萌系音色"} ($selectedVoice • ${pitch}x)',
      AppLanguage.en =>
        '${isGyaru ? "🌺 Gyaru Voice" : "🎀 Moe Voice"} ($selectedVoice • ${pitch}x)',
    };
  }

  String voicePlaybackStatusPill({
    required bool isConnected,
    required bool isConnecting,
    required bool isAiSpeaking,
    required String selectedVoice,
  }) {
    if (isConnected) {
      if (isAiSpeaking) {
        return switch (lang) {
          AppLanguage.ko => '🔊 일본어 음성 출력 중 (24kHz)',
          AppLanguage.ja => '🔊 日本語ボイス出力中 (24kHz)',
          AppLanguage.zh => '🔊 正在播放日语语音 (24kHz)',
          AppLanguage.en => '🔊 Playing Japanese Voice (24kHz)',
        };
      }
      return switch (lang) {
        AppLanguage.ko => '🔊 음성 다시 듣기 ($selectedVoice)',
        AppLanguage.ja => '🔊 ボイスをもう一度聴く ($selectedVoice)',
        AppLanguage.zh => '🔊 重播语音 ($selectedVoice)',
        AppLanguage.en => '🔊 Replay Voice ($selectedVoice)',
      };
    }
    if (isConnecting) {
      return switch (lang) {
        AppLanguage.ko => '⏳ Gemini Live 연결 중...',
        AppLanguage.ja => '⏳ Gemini Live 接続中...',
        AppLanguage.zh => '⏳ 正在连接 Gemini Live...',
        AppLanguage.en => '⏳ Connecting Gemini Live...',
      };
    }
    return switch (lang) {
      AppLanguage.ko => '🔌 탭하여 일본어 음성 연결',
      AppLanguage.ja => '🔌 タップして日本語ボイス接続',
      AppLanguage.zh => '🔌 点击连接日语语音',
      AppLanguage.en => '🔌 Tap to Connect Japanese Voice',
    };
  }

  String bottomHintText({
    required bool isChoiceOverlayOpen,
    required int beatNum,
    required int totalBeats,
  }) {
    if (isChoiceOverlayOpen) {
      return switch (lang) {
        AppLanguage.ko => '👆 화면 중앙의 선택지를 클릭하세요',
        AppLanguage.ja => '👆 画面中央の選択肢をクリックしてください',
        AppLanguage.zh => '👆 请点击屏幕中央的选项',
        AppLanguage.en => '👆 Click a choice in the center of the screen',
      };
    }
    return switch (lang) {
      AppLanguage.ko => '💡 대화창을 클릭하면 다음 대사($beatNum/$totalBeats)로 넘어갑니다',
      AppLanguage.ja => '💡 ウィンドウをクリックすると次のセリフ($beatNum/$totalBeats)へ進みます',
      AppLanguage.zh => '💡 点击对话框继续下一句台词 ($beatNum/$totalBeats)',
      AppLanguage.en => '💡 Click the dialogue box to advance ($beatNum/$totalBeats)',
    };
  }

  // ---------------------------------------------------------------------------
  // Showcase Card & Stage Inspector
  // ---------------------------------------------------------------------------

  String get copyCodeTooltip => switch (lang) {
    AppLanguage.ko => 'Dart 코드 복사 (Copy Code)',
    AppLanguage.ja => 'Dartコードをコピー (Copy Code)',
    AppLanguage.zh => '复制 Dart 代码 (Copy Code)',
    AppLanguage.en => 'Copy Dart Code',
  };

  String get copyCodeSnackBar => switch (lang) {
    AppLanguage.ko => '📋 예제 Dart 코드가 클립보드에 복사되었습니다!',
    AppLanguage.ja => '📋 サンプルDartコードをクリップボードにコピーしました！',
    AppLanguage.zh => '📋 示例 Dart 代码已复制到剪贴板！',
    AppLanguage.en => '📋 Example Dart code copied to clipboard!',
  };

  String get closeShowcaseTooltip => switch (lang) {
    AppLanguage.ko => '학습 노트 접기 (하단 CODE 버튼으로 다시 열기)',
    AppLanguage.ja => '学習ノートを閉じる（下部 CODE ボタンで再表示）',
    AppLanguage.zh => '收起学习笔记（可通过底部 CODE 按钮重新打开）',
    AppLanguage.en => 'Collapse Study Notes (Reopen via CODE button below)',
  };

  String get prevStepButton => switch (lang) {
    AppLanguage.ko => '◀ 이전 단계',
    AppLanguage.ja => '◀ 前のステップ',
    AppLanguage.zh => '◀ 上一步',
    AppLanguage.en => '◀ Prev Step',
  };

  String get nextStepButton => switch (lang) {
    AppLanguage.ko => '다음 단계 ▶',
    AppLanguage.ja => '次のステップ ▶',
    AppLanguage.zh => '下一步 ▶',
    AppLanguage.en => 'Next Step ▶',
  };

  String get rigInspectorTitle => switch (lang) {
    AppLanguage.ko => '2.5D 스켈레탈 본 & 물리 인스펙터',
    AppLanguage.ja => '2.5D スケルトン＆物理インスペクター',
    AppLanguage.zh => '2.5D 骨骼与物理检查器',
    AppLanguage.en => '2.5D Skeletal Bone & Physics Inspector',
  };

  String get rigInspectorLegend => switch (lang) {
    AppLanguage.ko =>
      '• Cyan: 날개 헤어핀 & 앞머리 파츠 (Z +0.85)\n'
          '• Green: 강체 얼굴 & 시선 트래킹 본 (Z +0.55)\n'
          '• Pink: 진자 물리 뒷머리 & 양갈래 (Z -1.00)\n'
          '• Amber: 상체 호흡 & 리본 스프링 (Z 0.00)',
    AppLanguage.ja =>
      '• Cyan: ウイング髪飾り＆前髪パーツ (Z +0.85)\n'
          '• Green: 剛体フェイス＆視線追従ボーン (Z +0.55)\n'
          '• Pink: 振り子物理・後ろ髪＆おさげ (Z -1.00)\n'
          '• Amber: 上半身呼吸＆リボンスプリング (Z 0.00)',
    AppLanguage.zh =>
      '• Cyan: 飞翼发夹与刘海部件 (Z +0.85)\n'
          '• Green: 刚体面部与视线追踪骨骼 (Z +0.55)\n'
          '• Pink: 摆锤物理后发与双马尾 (Z -1.00)\n'
          '• Amber: 上半身呼吸与领结弹簧 (Z 0.00)',
    AppLanguage.en =>
      '• Cyan: Wing hairpins & front bangs (Z +0.85)\n'
          '• Green: Rigid face & eye-tracking bone (Z +0.55)\n'
          '• Pink: Pendulum back-hair & twin-tails (Z -1.00)\n'
          '• Amber: Torso breathing & ribbon spring (Z 0.00)',
  };

  String steppedAnimModeLabel({required bool isStepped}) => switch (lang) {
    AppLanguage.ko =>
      isStepped ? '🎬 12fps 리미티드 작화 ON' : '⚡ 60fps Live2D 보간 ON',
    AppLanguage.ja =>
      isStepped ? '🎬 12fps リミテッド作画 ON' : '⚡ 60fps Live2D 補間 ON',
    AppLanguage.zh =>
      isStepped ? '🎬 12fps 抽帧作画 ON' : '⚡ 60fps Live2D 插值 ON',
    AppLanguage.en =>
      isStepped ? '🎬 12fps Stepped Anime ON' : '⚡ 60fps Live2D Smooth ON',
  };

  String get bounceImpulseButton => switch (lang) {
    AppLanguage.ko => '탱글 바운스!',
    AppLanguage.ja => 'ぷるんバウンス！',
    AppLanguage.zh => 'Q弹跳跃！',
    AppLanguage.en => 'Boing Bounce!',
  };

  String heartPopupLabel({required bool isReina}) => switch (lang) {
    AppLanguage.ko => isReina ? '🌺 레이나 호감도 UP! +4%' : '🌸 히카리 호감도 UP! +4%',
    AppLanguage.ja => isReina ? '🌺 レイナ 好感度 UP! +4%' : '🌸 ヒカリ 好感度 UP! +4%',
    AppLanguage.zh => isReina ? '🌺 玲奈 好感度 UP! +4%' : '🌸 光 好感度 UP! +4%',
    AppLanguage.en =>
      isReina ? '🌺 Reina Affection UP! +4%' : '🌸 Hikari Affection UP! +4%',
  };

  // ---------------------------------------------------------------------------
  // ViewModel Messages & Statuses
  // ---------------------------------------------------------------------------

  String get userSpeakerLabel => switch (lang) {
    AppLanguage.ko => '선배 (You)',
    AppLanguage.ja => '先輩 (You)',
    AppLanguage.zh => '前辈 (You)',
    AppLanguage.en => 'Senpai (You)',
  };

  String bargeInPrimary({required bool useGyaru}) {
    if (useGyaru) {
      return switch (lang) {
        AppLanguage.ko =>
          '앗! 💦 미안 미안 선배~☆ 선배가 말하려던 참이었지?! 편하게 말해줘~💖',
        AppLanguage.ja =>
          'あっ！💦 ごめんごめんセンパイっ☆ 何か言おうとしてたよね？！なんでも聞いて〜💖',
        AppLanguage.zh =>
          '啊！💦 抱歉抱歉前辈~☆ 你刚才想说话对吧？！尽管问我吧~💖',
        AppLanguage.en =>
          'Oh! 💦 My bad, Senpai~☆ You were about to say something, right?! Ask me anything~💖',
      };
    }
    return switch (lang) {
      AppLanguage.ko => '앗! 💦 죄송해요 선배, 말씀하시려던 참이었군요! 편하게 말씀해 주세요!',
      AppLanguage.ja => 'あっ！💦 ごめんなさい先輩っ、お話し中でしたよね！どうぞ聞かせてくださいっ！',
      AppLanguage.zh => '啊！💦 对不起前辈，您刚才正在说话吧！请尽管跟我说！',
      AppLanguage.en =>
        'Oh! 💦 Excuse me, Senpai! You were speaking—please go ahead, I\'m listening!',
    };
  }

  String bargeInSecondary({required bool useGyaru}) {
    if (lang == AppLanguage.ja) return '';
    return useGyaru
        ? '「あっ！💦 ごめんごめんセンパイっ☆ 何か言おうとしてたよね？！なんでも聞いて〜💖」'
        : '「あっ！💦 ごめんなさい先輩っ、お話し中でしたよね！どうぞ聞かせてくださいっ！」';
  }

  String get liveAiRespondingHint => switch (lang) {
    AppLanguage.ko =>
      '💬 Live AI 응답 중 (대사가 끝나면 대화창을 클릭해 다음 선택지로 이동하세요)',
    AppLanguage.ja =>
      '💬 Live AI 応答中（話し終わったらウィンドウをクリックして選択肢へ進めます）',
    AppLanguage.zh =>
      '💬 Live AI 正在回答（回答结束后点击对话框即可进入选项）',
    AppLanguage.en =>
      '💬 Live AI responding (Click the dialogue box when finished to open choices)',
  };

  String get preparingAnswer => switch (lang) {
    AppLanguage.ko => '질문에 대한 답변을 준비하고 있어요... 💭',
    AppLanguage.ja => '質問への回答を準備しています... 💭',
    AppLanguage.zh => '正在准备您问题的回答... 💭',
    AppLanguage.en => 'Preparing an answer to your question... 💭',
  };

  String get apiKeyRequiredSimulatedHint => switch (lang) {
    AppLanguage.ko =>
      'API 키를 연결하면 제 목소리(24kHz)로 실시간 답변을 들으실 수 있어요! 대화창을 클릭하면 다음 선택지로 이동합니다.',
    AppLanguage.ja =>
      'APIキーを設定すると、私の声（24kHz）でリアルタイム回答をお聴きいただけます！ウィンドウをクリックすると選択肢へ戻ります。',
    AppLanguage.zh =>
      '配置 API 密钥后即可听到我 24kHz 的实时语音回答！点击对话框返回选项。',
    AppLanguage.en =>
      'Configure your API key to hear my real-time 24kHz voice response! Click the dialogue box to return to choices.',
  };

  String get thinkingCustomReply => switch (lang) {
    AppLanguage.ko => '히카리가 답변을 생각하고 있습니다...',
    AppLanguage.ja => 'ヒカリが返答を考えています...',
    AppLanguage.zh => '光正在思考回答...',
    AppLanguage.en => 'Hikari is thinking of a reply...',
  };

  String connectionFailed(Object error) => switch (lang) {
    AppLanguage.ko => '연결 실패: $error',
    AppLanguage.ja => '接続失敗: $error',
    AppLanguage.zh => '连接失败: $error',
    AppLanguage.en => 'Connection failed: $error',
  };

  String get micPermissionRequired => switch (lang) {
    AppLanguage.ko => '마이크 권한이 필요합니다',
    AppLanguage.ja => 'マイク権限が必要です',
    AppLanguage.zh => '需要麦克风权限',
    AppLanguage.en => 'Microphone permission required',
  };

  String micStartError(Object error) => switch (lang) {
    AppLanguage.ko => '마이크 시작 오류: $error',
    AppLanguage.ja => 'マイク開始エラー: $error',
    AppLanguage.zh => '麦克风启动错误: $error',
    AppLanguage.en => 'Microphone start error: $error',
  };

  // ---------------------------------------------------------------------------
  // Chapter Titles (EN & ZH translations; KO & JA live on VnSdkChapter)
  // ---------------------------------------------------------------------------

  static String chapterTitleEn(String chapterId, String fallback) =>
      switch (chapterId) {
        'ch1_quickstart' =>
          'Ch.1: Package Install & 5-Line Quickstart Connection',
        'ch2_config_voice' =>
          'Ch.2: 30 Voice Personas, System Prompt & Live Subtitles',
        'ch3_audio_stream' =>
          'Ch.3: 16kHz Mic Input, 24kHz Audio Playback & Lip-Sync',
        'ch4_barge_in' =>
          'Ch.4: Barge-In Interruption, VAD Sensitivity & Manual PTT',
        'ch5_vision_stream' =>
          'Ch.5: Real-Time Camera Vision Streaming & HUD Overlay',
        'ch6_tools_grounding' =>
          'Ch.6: Async Function Calling & Google Search / Maps Grounding',
        'ch7_widgets_controller' =>
          'Ch.7: GeminiLiveSessionController & 19 Built-In UI Widgets',
        'ch8_thinking_context' =>
          'Ch.8: Extended Thinking, Context Compression & Dynamic Updates',
        'ch9_translate_music' =>
          'Ch.9: Live Speech Translation & Lyria 48kHz Realtime Music',
        'ch10_production_mastery' =>
          'Ch.10: Production Auth, Session Resume, Cost Tracking & Testing',
        _ => fallback,
      };

  static String chapterTitleZh(String chapterId, String fallback) =>
      switch (chapterId) {
        'ch1_quickstart' => '第1话：安装依赖包与最短5行代码首次连接',
        'ch2_config_voice' => '第2话：30种声优音色 · 系统提示词 · 实时字幕配置',
        'ch3_audio_stream' => '第3话：16kHz麦克风输入 & 24kHz语音播放与角色口型同步',
        'ch4_barge_in' => '第4话：Barge-In（打断即停）· VAD灵敏度 · 手动PTT按键通话',
        'ch5_vision_stream' => '第5话：实时摄像头视觉(Vision)流式传输与取景器HUD',
        'ch6_tools_grounding' => '第6话：Function Calling（异步工具调用）与 Google 搜索/地图接地',
        'ch7_widgets_controller' => '第7话：GeminiLiveSessionController 与 19种内置UI组件',
        'ch8_thinking_context' => '第8话：Extended Thinking（深度推理）· 长会话压缩 · 动态上下文更新',
        'ch9_translate_music' => '第9话：面对面实时语音同传 & Lyria 48kHz 实时音乐生成',
        'ch10_production_mastery' => '第10话：生产环境实战（临时令牌 · 会话恢复 · 费用计算 · 单元测试）',
        _ => fallback,
      };

  // ---------------------------------------------------------------------------
  // Showcase Titles, Summaries & KeyPoints (EN & ZH)
  // ---------------------------------------------------------------------------

  static (String title, String summary, List<String> keyPoints)?
  showcaseEn(String topicId) => switch (topicId) {
    'ch1_quickstart' => (
      'Step 1-1: Add gemini_live to pubspec.yaml',
      'Zero Firebase required! Get started with a single package.',
      const [
        'No firebase_core, firebase_ai, or GoogleService-Info.plist setup needed',
        'Full cross-platform support: iOS, Android, macOS, Windows, Linux, and Web',
        'Use gemini_live standalone for text/vision, or pair with record + flutter_soloud for voice chat',
      ],
    ),
    'ch1_connect' => (
      'Step 1-2: Create GoogleGenAI & Open WebSocket Session',
      'Connect directly to Gemini Live servers via genAI.live.connect().',
      const [
        'genAI.live.connect() safely awaits the server setupComplete packet before returning LiveSession',
        'Supports both LiveCallbacks and await for (final msg in session.receive()) stream patterns',
      ],
    ),
    'ch1_send_close' => (
      'Step 1-3: Send Your First Prompt & Close Cleanly',
      'Send prompts with sendText() and release resources with close().',
      const [
        'session.sendText() sends a user text turn with turnComplete: true in one call',
        'Always call session.close() inside StatefulWidget.dispose() to release sockets cleanly',
      ],
    ),
    'ch2_voice' => (
      'Step 2-1: SpeechConfig & 30 Native Voice Personas',
      'Pick from 30 expressive voices (Leda, Autonoe, Zephyr, Aoede, etc.).',
      const [
        'Setting responseModalities: [Modality.AUDIO] streams expressive native speech directly',
        'Inspect all 30 voice personas via GeminiLiveVoice.values and VoicesService',
      ],
    ),
    'ch2_system_instruction' => (
      'Step 2-2: Inject Persona & Rules via systemInstruction',
      'Define voice acting tone, personality, language, and domain rules.',
      const [
        'Native Audio models reflect acting directions (cheerful, whispered, high-pitched) directly in speech',
        'Update system instructions mid-call anytime without reconnecting via session.sendContextUpdate()',
      ],
    ),
    'ch2_transcription' => (
      'Step 2-3: Real-Time Input & Output Audio Subtitles',
      'Stream live text transcriptions for both user mic and AI voice.',
      const [
        'inputAudioTranscription streams real-time STT transcripts of what the user says',
        'outputAudioTranscription streams the exact script of the AI\'s 24kHz spoken response',
      ],
    ),
    'ch3_mic_capture' => (
      'Step 3-1: Capture & Stream 16kHz Mono PCM Microphone Audio',
      'Record 16,000Hz / 16-bit / Mono PCM and pass chunks to sendAudio().',
      const [
        'Microphone input spec: 16-bit Linear PCM, 16,000Hz, 1 channel (Mono)',
        'Enable echoCancel: true and noiseSuppress: true to prevent speaker feedback loops',
      ],
    ),
    'ch3_speaker_output' => (
      'Step 3-2: Receive & Play 24kHz PCM Audio Chunks',
      'Decode base64 message.data and feed your 24,000Hz audio stream player.',
      const [
        'AI speech output spec: 24,000Hz, 16-bit Linear PCM, Mono (note: mic input is 16kHz!)',
        'Use built-in buildWavFile() when you need a standard RIFF WAV header for file players',
      ],
    ),
    'ch3_lipsync_rms' => (
      'Step 3-3: Real-Time Lip-Sync & Waveform via GeminiLiveAudioUtils',
      'Compute RMS energy, peak, dBFS, and visual scale (0.0-1.0) from PCM bytes.',
      const [
        'GeminiLiveAudioUtils calculates RMS, Peak, and dBFS without external FFT libraries',
        'Bind the 0.0-1.0 scale directly to character mouth rigging or GeminiLiveWaveform',
      ],
    ),
    'ch4_barge_in' => (
      'Step 4-1: Instant Buffer Flush on serverContent.interrupted',
      'Immediately clear local audio playback queues when the user barges in.',
      const [
        'The server streams 24kHz audio faster than real-time, so unplayed audio sits in your local buffer',
        'Flushing audioPlayer.clear() on content.interrupted == true stops overlapping speech instantly',
      ],
    ),
    'ch4_vad_config' => (
      'Step 4-2: Server VAD Sensitivity Tuning & Manual Push-to-Talk',
      'Configure speech start/end sensitivity, silence duration, or manual PTT.',
      const [
        'Increase silenceDurationMs so the AI waits patiently when the user pauses to think',
        'Set activityHandling: ActivityHandling.NO_INTERRUPTION to disable barge-in during AI speech',
      ],
    ),
    'ch4_affective_proactive' => (
      'Step 4-3: Affective Dialog & Proactive Audio',
      'Sense emotional nuances in the user\'s voice and speak proactively.',
      const [
        'enableAffectiveDialog: true adapts AI tone to match happy, hesitant, or urgent user speech',
        'proactiveAudio: true lets the AI ignore background chatter and respond only when relevant',
      ],
    ),
    'ch5_vision_send' => (
      'Step 5-1: Stream 1-2 FPS JPEG Camera Frames in Real Time',
      'Compress camera frames to JPEG 1-2 times per second via sendVideoFrame().',
      const [
        'Gemini Live vision is optimized for 1-2 FPS JPEG frames rather than 30fps video streams',
        'Use 640x480 or 768x768 at ~75% JPEG quality for optimal latency and token efficiency',
      ],
    ),
    'ch5_vision_hud' => (
      'Step 5-2: Built-In GeminiLiveVisionOverlay Viewfinder HUD',
      'Wrap CameraPreview to get a Project Astra-style HUD with scanlines & FPS badge.',
      const [
        'Provides corner target brackets, animated scanline, and real-time FPS counter out of the box',
        'Ideal for live exam tutors, spatial object inspection, and screen-sharing assistants',
      ],
    ),
    'ch6_tool_declare' => (
      'Step 6-1: FunctionDeclaration & Async NON_BLOCKING Mode',
      'Define tool schemas and execute functions asynchronously without pausing speech.',
      const [
        'behavior: Behavior.NON_BLOCKING lets the AI keep talking naturally while async tools run',
        'Add Tool(googleSearch: GoogleSearch()) and Tool(googleMaps: GoogleMaps()) in one line',
      ],
    ),
    'ch6_tool_response' => (
      'Step 6-2: Handle toolCall & Return sendToolResponse',
      'Execute requested Dart functions and return JSON results to the server.',
      const [
        'Control when the AI speaks tool results via FunctionResponseScheduling (INTERRUPT / WHEN_IDLE / SILENT)',
        'Handle message.toolCallCancellation?.ids to cancel in-flight tasks on user barge-in',
      ],
    ),
    'ch7_controller' => (
      'Step 7-1: GeminiLiveSessionController & GeminiLiveChatView',
      'Build a complete AI voice chat screen in 10 lines with the reactive controller.',
      const [
        'GeminiLiveSessionController manages WebSocket parsing, transcripts, barge-in, and token usage',
        'Drop in GeminiLiveChatView for an instant full-screen UI with status badge, waveform, and controls',
      ],
    ),
    'ch7_modular_widgets' => (
      'Step 7-2: Compose 19+ Material 3 & Cupertino Modular Widgets',
      'Mix and match mic buttons, waveforms, captions, tool chips, and iOS widgets.',
      const [
        'Includes 16 Material 3 widgets plus 3 native iOS/macOS Cupertino widgets out of the box',
        'Includes GeminiLiveVoiceSelector sheet and GeminiLiveAudioRouteButton for speaker/Bluetooth routing',
      ],
    ),
    'ch8_thinking_compression' => (
      'Step 8-1: ThinkingConfig & ContextWindowCompressionConfig',
      'Enable deep reasoning budgets and 15+ minute sliding-window compression.',
      const [
        'ThinkingConfig(thinkingBudget: 1024, includeThoughts: true) streams intermediate reasoning thoughts',
        'SlidingWindow context compression prevents token limit disconnects during long sessions',
      ],
    ),
    'ch8_context_update' => (
      'Step 8-2: Zero-Downtime Mid-Call Updates via sendContextUpdate',
      'Swap system instructions and tools mid-session without reconnecting.',
      const [
        'Update AI persona or active tools on the fly without closing the WebSocket session',
        'Pairs seamlessly with built-in GeminiLiveThinkingIndicator and GeminiLiveContextConfigSheet',
      ],
    ),
    'ch9_live_translate' => (
      'Step 9-1: TranslationConfig & 180° Face-to-Face Split Interpreter UI',
      'Build low-latency speech-to-speech interpreters with gemini-3.5-live-translate-preview.',
      const [
        'Configure sourceLanguageCodes and targetLanguageCode for instant bidirectional speech translation',
        'GeminiLiveTranslateSplitView flips the top pane 180° so two people across a table can converse',
      ],
    ),
    'ch9_lyria_music' => (
      'Step 9-2: genAI.live.music (Lyria 48kHz Stereo Realtime Music)',
      'Steer weighted prompts, BPM, and musical scales in real time at 48kHz stereo.',
      const [
        'Lyria outputs 48,000Hz, 16-bit PCM, Stereo (2ch) audio—distinct from 24kHz mono speech',
        'Crossfade genres and instruments live without stopping playback via setWeightedPrompts()',
      ],
    ),
    'ch10_auth_resumption' => (
      'Step 10-1: Ephemeral Client Tokens & SessionResumptionConfig',
      'Protect master API keys with single-use tokens and auto-resume dropped sessions.',
      const [
        'Mint short-lived client tokens via AuthTokensService so master API keys never ship in app binaries',
        'Save sessionResumptionUpdate.newHandle to seamlessly resume context after mobile network drops (1006)',
      ],
    ),
    'ch10_cost_compat_test' => (
      'Step 10-2: Real-Time Cost Tracking, firebase_ai Compat & Unit Testing',
      'Track modality token costs, migrate in 1 line, and test without API quota.',
      const [
        'GeminiTokenUsageTracker tallies audio/text/video tokens and estimates USD/KRW costs in real time',
        'Use handleServerMessageForTesting() to deterministically test barge-in and tool calls offline',
      ],
    ),
    _ => null,
  };

  static (String title, String summary, List<String> keyPoints)?
  showcaseZh(String topicId) => switch (topicId) {
    'ch1_quickstart' => (
      'Step 1-1: 在 pubspec.yaml 中添加 gemini_live',
      '零 Firebase 依赖！只需添加一个包即可开始开发。',
      const [
        '完全不需要配置 firebase_core、firebase_ai 或 GoogleService-Info.plist',
        '全平台支持：iOS、Android、macOS、Windows、Linux 与 Web',
        '纯文本/视觉可单独使用 gemini_live，语音通话推荐搭配 record + flutter_soloud',
      ],
    ),
    'ch1_connect' => (
      'Step 1-2: 创建 GoogleGenAI 并建立 WebSocket 会话',
      '通过 genAI.live.connect() 直接连接 Gemini Live 实时服务器。',
      const [
        'genAI.live.connect() 会安全等待服务器返回 setupComplete 后再返回 LiveSession（可获取 session.sessionId）',
        '同时支持 LiveCallbacks 回调模式与 await for (final msg in session.receive()) 流式监听模式',
      ],
    ),
    'ch1_send_close' => (
      'Step 1-3: 发送首条消息与安全关闭会话',
      '使用 sendText() 立即发起对话，并在页面销毁时调用 close()。',
      const [
        'session.sendText() 一行代码即可发送用户文本并自动附带 turnComplete 信号',
        '在 StatefulWidget 的 dispose() 中务必调用 session.close() 释放 WebSocket 资源',
      ],
    ),
    'ch2_voice' => (
      'Step 2-1: SpeechConfig 与 30种原生声优音色选择',
      '通过 GeminiLiveVoice 枚举自由切换 30种表现力丰富的角色音色。',
      const [
        '设置 responseModalities: [Modality.AUDIO] 时，模型直接生成带有情感与语调的原生语音',
        '可通过 GeminiLiveVoice.values 与 VoicesService 查询全部 30种音色的详细元数据',
      ],
    ),
    'ch2_system_instruction' => (
      'Step 2-2: 使用 systemInstruction 注入角色人设与规则',
      '定义声优演技语调、角色性格、回复语言与领域规则。',
      const [
        'Native Audio 模型会将 systemInstruction 中的语气指示（欢快、耳语、高音等）直接体现在语音中',
        '通话途中如需修改系统提示词，可使用第8话介绍的 session.sendContextUpdate() 无缝切换',
      ],
    ),
    'ch2_transcription' => (
      'Step 2-3: 输入/输出语音实时字幕 (AudioTranscriptionConfig)',
      '同时将麦克风输入与 AI 语音输出实时转换为文本字幕。',
      const [
        'inputAudioTranscription：将用户麦克风说话内容实时转写为 STT 文本片段',
        'outputAudioTranscription：实时流式返回 AI 正在播报的 24kHz 语音台词文本',
      ],
    ),
    'ch3_mic_capture' => (
      'Step 3-1: 16kHz Mono PCM 麦克风音频采集与发送',
      '使用 record 包采集 16,000Hz / 16-bit / 单声道 PCM 并传入 sendAudio()。',
      const [
        '麦克风输入标准规格：16-bit Linear PCM、16,000Hz、单声道 (Mono)',
        '开启 echoCancel: true 与 noiseSuppress: true，防止扬声器声音回传至麦克风产生啸叫',
      ],
    ),
    'ch3_speaker_output' => (
      'Step 3-2: 接收并低延迟播放 24kHz PCM 语音分片',
      '对 message.data 进行 base64Decode，并立即推入 24,000Hz 音频流缓冲区。',
      const [
        'AI 语音输出标准规格：24,000Hz、16-bit Linear PCM、Mono（注意与麦克风输入的 16kHz 区分！）',
        '内置 buildWavFile() 工具函数，可一键为原始 PCM 字节流添加标准 RIFF WAV 文件头',
      ],
    ),
    'ch3_lipsync_rms' => (
      'Step 3-3: 使用 GeminiLiveAudioUtils 实现实时口型同步与波形计算',
      '从 PCM 字节流直接计算 RMS 音量、峰值、dBFS 与动画缩放值 (0.0~1.0)。',
      const [
        'GeminiLiveAudioUtils 无需外部 FFT 库即可高性能计算 RMS、Peak 与 dBFS',
        '可将 0.0~1.0 的能量值直接绑定至角色口型骨骼或 GeminiLiveWaveform 波形组件',
      ],
    ),
    'ch4_barge_in' => (
      'Step 4-1: 收到 serverContent.interrupted 时立即清空缓冲区',
      '当用户插话打断的瞬间，立即清空本地正在播放的语音队列。',
      const [
        '服务器发送 24kHz 语音分片的速度快于实际播放速度，因此本地队列中会存有未播放的音频',
        '当 content.interrupted == true 时必须立即调用 audioPlayer.clear()，防止语音重叠',
      ],
    ),
    'ch4_vad_config' => (
      'Step 4-2: 服务器 VAD 灵敏度调优与手动 Push-to-Talk 控制',
      '配置语音开始/结束灵敏度、静音判定时长(ms)或对讲机式手动 PTT。',
      const [
        '适当调大 silenceDurationMs，即使说话中途短暂思考，AI 也不会急于打断',
        '设置 activityHandling: ActivityHandling.NO_INTERRUPTION 可禁止在 AI 说话时插话',
      ],
    ),
    'ch4_affective_proactive' => (
      'Step 4-3: 情感共鸣对话 (Affective Dialog) 与主动发话 (Proactive)',
      '从语音语调中感知情绪共鸣，并根据上下文由 AI 主动搭话。',
      const [
        'enableAffectiveDialog: true 让 AI 根据用户开心、犹豫或焦急的语气做出富有情感的回应',
        'proactiveAudio: true 让 AI 在常开麦克风环境下自动忽略无关闲聊，仅在被呼唤时主动回应',
      ],
    ),
    'ch5_vision_send' => (
      'Step 5-1: 1~2 FPS JPEG 摄像头画面实时流式传输',
      '每秒截取 1~2 帧摄像头画面压缩为 JPEG 并通过 sendVideoFrame() 发送。',
      const [
        'Gemini Live 视觉流官方推荐规格为每秒 1~2 帧 (1~2 FPS) JPEG，而非 30fps 视频流',
        '分辨率建议 640x480 或 768x768、JPEG 质量 75%，可大幅节省带宽与 Token 消耗',
      ],
    ),
    'ch5_vision_hud' => (
      'Step 5-2: 内置 GeminiLiveVisionOverlay 取景器 HUD 组件',
      '只需包裹 CameraPreview，即可呈现 Project Astra 风格的科幻取景器 HUD。',
      const [
        '开箱即用提供四角瞄准框、扫描线动画与实时 FPS 帧率徽章',
        '非常适合实时解题私教 (Live Exam Tutor)、实物识别与屏幕共享助手',
      ],
    ),
    'ch6_tool_declare' => (
      'Step 6-1: FunctionDeclaration 声明与 NON_BLOCKING 异步模式',
      '定义 AI 可调用的函数 Schema，并在后台异步执行工具而不中断对话。',
      const [
        '设置 behavior: Behavior.NON_BLOCKING 后，即使执行耗时的外部 API 查询，AI 也能继续自然交谈',
        '仅需一行代码即可同时启用 Tool(googleSearch: GoogleSearch()) 与 Google Maps 实时接地',
      ],
    ),
    'ch6_tool_response' => (
      'Step 6-2: 处理 toolCall 请求并通过 sendToolResponse 返回结果',
      '执行 AI 请求的本地 Dart 函数，并将 JSON 结果返回给服务器。',
      const [
        '通过 FunctionResponseScheduling (INTERRUPT / WHEN_IDLE / SILENT) 控制异步工具完成后的播报时机',
        '监听 message.toolCallCancellation?.ids，在用户打断时安全取消正在执行的异步任务',
      ],
    ),
    'ch7_controller' => (
      'Step 7-1: GeminiLiveSessionController 与高级聊天视图',
      '结合响应式控制器与内置组件，仅需 10 行代码即可构建完整的 AI 语音通话界面。',
      const [
        'GeminiLiveSessionController 自动管理消息解析、字幕累积、打断状态与 Token 费用统计',
        '放入 GeminiLiveChatView 即可呈现状态徽章、音频波形、毛玻璃字幕气泡与通话控制栏',
      ],
    ),
    'ch7_modular_widgets' => (
      'Step 7-2: 像搭积木一样组合 19+ 种 Material 3 与 Cupertino 组件',
      '自由组合麦克风按钮、实时波形、字幕气泡、工具状态芯片与 iOS 原生风格组件。',
      const [
        '内置 16种 Material 3 组件 + 3种 iOS/macOS 原生质感 Cupertino 专属组件',
        '包含 GeminiLiveVoiceSelector（声优选择面板）与 GeminiLiveAudioRouteButton（扬声器/蓝牙切换）',
      ],
    ),
    'ch8_thinking_compression' => (
      'Step 8-1: ThinkingConfig（深度推理）与滑动窗口上下文压缩',
      '开启深度推理预算，并通过自动滑动窗口压缩支持 15 分钟以上的长时通话。',
      const [
        'ThinkingConfig(thinkingBudget: 1024, includeThoughts: true) 可流式输出模型的深度思考过程',
        '配置 ContextWindowCompressionConfig 后，长时间通话也不会因超出 Token 上限而断开',
      ],
    ),
    'ch8_context_update' => (
      'Step 8-2: 通话中零中断动态更新人设与工具 (sendContextUpdate)',
      '无需断开重连，在通话过程中实时替换系统提示词与可用工具列表。',
      const [
        '无需关闭 WebSocket 重新 connect()，即可在保持对话上下文的同时切换角色模式或工具集',
        '与内置的 GeminiLiveThinkingIndicator 和 GeminiLiveContextConfigSheet 组件 100% 联动',
      ],
    ),
    'ch9_live_translate' => (
      'Step 9-1: TranslationConfig 与 180° 面对面分屏同传组件',
      '使用 gemini-3.5-live-translate-preview 模型打造超低延迟语音同声传译器。',
      const [
        '在 TranslationConfig 中指定源语言与目标语言代码，即可实现超低延迟双向语音同传',
        'GeminiLiveTranslateSplitView 将上半屏 180° 翻转显示，方便隔桌相对的双方直接阅读',
      ],
    ),
    'ch9_lyria_music' => (
      'Step 9-2: genAI.live.music（Lyria 48kHz 立体声实时音乐生成）',
      '像 DJ 一样实时混合权重提示词 (WeightedPrompt)、BPM 与音阶，生成 48kHz 立体声音乐。',
      const [
        'Lyria 音乐输出采用 48,000Hz、16-bit PCM、双声道立体声 (Stereo) 规格（区别于语音的 24kHz 单声道）',
        '通过 setWeightedPrompts() 可在不停止播放的情况下实时渐变混合不同曲风与乐器比重',
      ],
    ),
    'ch10_auth_resumption' => (
      'Step 10-1: Ephemeral Token（临时安全令牌）与无感会话恢复',
      '签发一次性临时令牌保护主 API 密钥，并在网络闪断时自动恢复会话上下文。',
      const [
        '后端通过 AuthTokensService 签发短期令牌，防止主 API 密钥被反编译泄露',
        '保存 sessionResumptionUpdate.newHandle 后，即使进电梯/地铁断网也能 100% 恢复此前的对话上下文',
      ],
    ),
    'ch10_cost_compat_test' => (
      'Step 10-2: 实时 Token 费用计算 · firebase_ai 1:1 兼容 · 单元测试',
      '按模态精准统计实时费用，修改 1 行 import 即可从 firebase_ai 迁移，零费用离线测试。',
      const [
        'GeminiTokenUsageTracker 分别统计音频/文本/视觉输入输出 Token，实时估算 USD/KRW 成本',
        '使用 handleServerMessageForTesting() 无需真实网络连接或消耗配额即可 100% 验证打断与工具调用逻辑',
      ],
    ),
    _ => null,
  };

  // ---------------------------------------------------------------------------
  // Dialogue Beats (EN & ZH translations for all 10 chapters)
  // ---------------------------------------------------------------------------

  static String? beatTextEn(
    int chapterNumber,
    int beatIndex, {
    required bool useGyaru,
  }) {
    if (chapterNumber == 1 && beatIndex == 0 && useGyaru) {
      return "Yahho, Senpai☆ I'm Reina, a Shibuya tech-gyaru engineer~💖 Today let's master Flutter's `gemini_live` package together at max tension✌️✨";
    }
    final base = switch ((chapterNumber, beatIndex)) {
      (1, 0) =>
        "Hello, Senpai! ✨ I'm Hikari, the official navigator for Flutter's ultra-low-latency multimodal SDK `gemini_live`! Let's master it step by step from the basics♪",
      (1, 1) =>
        'First up is Step 1-1! Just run `flutter pub add gemini_live` in your terminal. Zero complicated Firebase console setup required 💡',
      (1, 2) =>
        'Next is Step 1-2! Create `GoogleGenAI(apiKey: ...)` in Dart and call `genAI.live.connect()` to open a bidirectional WebSocket session right away!',
      (1, 3) =>
        'And Step 1-3! Call `session.sendText("Hello!")` on your connected `session`, and my spoken response streams back immediately ✨',
      (1, 4) =>
        "How was that, Senpai? Connecting for the first time is super simple, right?♪ In Chapter 2, let's configure my Voice Persona and System Instructions!",
      (2, 0) =>
        "In Chapter 2, let's explore how to configure my Voice Persona, Character System Prompt, and the Live Subtitles shown on screen step by step 🎀",
      (2, 1) =>
        'Step 2-1! Specify `GeminiLiveVoice.leda.id` inside `speechConfig` of `GenerationConfig` to choose from 30 expressive prebuilt voices♪',
      (2, 2) =>
        'Step 2-2! When you want the AI to roleplay a specific character or speaking style, pass a prompt to `systemInstruction` in `LiveConnectParameters` ✨',
      (2, 3) =>
        'And Step 2-3! Want live subtitles on screen during voice mode? Just add `inputAudioTranscription` and `outputAudioTranscription` to receive real-time captions!',
      (3, 0) =>
        "In Chapter 3, I'll explain the heart of two-way voice chat: 16kHz microphone capture, 24kHz audio playback, and how my real-time lip-sync works 🎙️",
      (3, 1) =>
        'First, Step 3-1: Microphone input! Start a PCM stream with `sampleRate: 16000` and `numChannels: 1` using `record`, and pipe chunks straight into `session.sendAudio(bytes)`♪',
      (3, 2) =>
        'Next, Step 3-2: Receiving and playing AI speech! My voice arrives from the server as 24,000Hz mono 16-bit PCM base64-encoded inside `message.data`!',
      (3, 3) =>
        'And Step 3-3! My mouth moves in sync with my voice because `GeminiLiveAudioUtils.calculateRms()` computes real-time audio energy directly from the PCM bytes ✨',
      (4, 0) =>
        'Oh! Senpai💦 Do you know how I stop speaking immediately without overlapping voices if you suddenly interrupt me mid-sentence?',
      (4, 1) =>
        'Step 4-1! The instant the server detects your voice, `serverContent.interrupted == true` arrives. Calling `audioPlayer.clear()` immediately to flush the playback buffer is the #1 rule ⚡',
      (4, 2) =>
        'Step 4-2! To prevent false triggers in noisy venues, fine-tune server VAD sensitivity and silence duration via `AutomaticActivityDetection` in `RealtimeInputConfig`♪',
      (4, 3) =>
        'Plus Step 4-3! You can enable `enableAffectiveDialog` to sense emotion in the user\'s voice and `proactiveAudio` for smart self-initiated responses in just one line 💖',
      (5, 0) =>
        "In Chapter 5, let's learn multimodal Vision streaming so we can share not just our voices, but also live camera sight 📷✨",
      (5, 1) =>
        'Step 5-1! No need to send 30 frames per second—sending 1 to 2 JPEG frames per second (1-2 FPS) via `session.sendVideoFrame(jpegBytes)` is the official best practice 💡',
      (5, 2) =>
        'Step 5-2! `gemini_live` also includes the `GeminiLiveVisionOverlay` widget out of the box to render cyber target brackets, scanlines, and an FPS badge over your camera preview♪',
      (6, 0) =>
        "In Chapter 6, let's learn Function Calling—where the AI invokes your Dart functions directly—and real-time Grounding with Google Search & Maps 🛠️✨",
      (6, 1) =>
        'Step 6-1! Declare function schemas with `FunctionDeclaration`. Setting `behavior: Behavior.NON_BLOCKING` lets me keep talking naturally while async tasks run in the background 💡',
      (6, 2) =>
        'Step 6-2! When `message.toolCall` arrives, run your local Dart function and return the result via `session.sendToolResponse()`. You can also handle `toolCallCancellation` on barge-in♪',
      (7, 0) =>
        "In Chapter 7, let's meet the 19 built-in UI widgets that let you assemble a polished voice chat screen in 5 minutes without writing low-level WebSocket callbacks 🎨✨",
      (7, 1) =>
        'Step 7-1! `GeminiLiveSessionController` automatically manages connection state, live subtitles, and barge-in. Pair it with `GeminiLiveChatView` for a complete screen in one widget♪',
      (7, 2) =>
        'Step 7-2! Or mix and match modular widgets like `GeminiLiveMicButton`, `GeminiLiveWaveform`, and frosted-glass `GeminiLiveCaptionBubble` in your own custom layout 💡',
      (8, 0) =>
        "In Chapter 8, I'll explain Extended Thinking for deep reasoning agents and Context Window Compression for 15+ minute continuous sessions 🧠✨",
      (8, 1) =>
        'Step 8-1! For math or complex architecture reasoning, enable `ThinkingConfig(thinkingBudget: 1024, includeThoughts: true)`, and add `ContextWindowCompressionConfig` for long calls♪',
      (8, 2) =>
        'And Step 8-2! Use `session.sendContextUpdate()` to dynamically update system instructions or tools mid-call without disconnecting the WebSocket 💡',
      (9, 0) =>
        "In Chapter 9, let's explore two special features of `gemini_live`: real-time speech-to-speech translation and Lyria real-time music generation 🎵✨",
      (9, 1) =>
        'Step 9-1! Combine `TranslationConfig` with `GeminiLiveTranslateSplitView` to build a 180° flipped face-to-face tabletop interpreter app in minutes 🌐',
      (9, 2) =>
        'And Step 9-2! Connect to Google\'s Lyria music AI via `genAI.live.music.connect()` to stream 48kHz stereo music while steering BPM, scale, and weighted prompts live 🎧',
      (10, 0) =>
        "Finally, Chapter 10! 🎉 Let's master the essentials for shipping a production app: Ephemeral Auth Tokens, Session Resumption, Cost Tracking, and Unit Testing!",
      (10, 1) =>
        'Step 10-1! Never hardcode master API keys in client apps! Mint single-use ephemeral tokens on your backend via `genAI.authTokens.create()`, and use `SessionResumptionConfig` to auto-recover dropped connections 🔐',
      (10, 2) =>
        'Step 10-2! `GeminiTokenUsageTracker` calculates real-time modality tokens and USD/KRW costs automatically. Plus, migrating from `firebase_ai` takes just a 1-line import swap 💡',
      (10, 3) =>
        'Congratulations, Senpai! 🎉✨ You completed all 10 chapters of the `gemini_live` curriculum! Let\'s keep building amazing Flutter × Gemini Live apps together—I love you, Senpai💖',
      _ => null,
    };
    if (base == null) return null;
    if (!useGyaru) return base;
    return base
        .replaceAll("I'm Hikari", "I'm Reina")
        .replaceAll('Hikari', 'Reina')
        .replaceAll('Senpai!', 'Senpai~☆')
        .replaceAll('♪', '✌️✨');
  }

  static String? beatTextZh(
    int chapterNumber,
    int beatIndex, {
    required bool useGyaru,
  }) {
    if (chapterNumber == 1 && beatIndex == 0 && useGyaru) {
      return '呀吼~前辈☆ 我是涉谷系元气辣妹工程师“玲奈”哦~💖 今天就由我陪前辈一起嗨翻天，彻底掌握 Flutter 的 `gemini_live` 包吧✌️✨';
    }
    final base = switch ((chapterNumber, beatIndex)) {
      (1, 0) =>
        '前辈，你好呀！✨ 我是 Flutter 超低延迟多模态 SDK『gemini_live』的官方领航员“光 (Hikari)”！让我们从基础开始一步步轻松掌握吧♪',
      (1, 1) =>
        '首先是 Step 1-1！只需在终端运行一行 `flutter pub add gemini_live` 即可，完全不需要繁琐的 Firebase 控制台配置哦 💡',
      (1, 2) =>
        '接着是 Step 1-2！在 Dart 代码中创建 `GoogleGenAI(apiKey: ...)` 实例，调用 `genAI.live.connect()` 即可立即开启 WebSocket 实时会话！',
      (1, 3) =>
        '然后是 Step 1-3！对已连接的 `session` 调用 `session.sendText("你好！")`，我的语音回复就会立刻流式传回啦 ✨',
      (1, 4) =>
        '怎么样前辈？第一次连接非常简单吧♪ 下一话（第2话）我们来学习如何设置我的“声音（声优预设）”与“性格（系统指令）”吧！',
      (2, 0) =>
        '在第2话中，让我们一步步了解如何设置我的“声音”、“角色人设”，以及现在屏幕上显示的“实时字幕”吧 🎀',
      (2, 1) =>
        'Step 2-1！在 `GenerationConfig` 的 `speechConfig` 中指定 `GeminiLiveVoice.leda.id` 等参数，就能从 30种个性丰富的声优音色中自由选择♪',
      (2, 2) =>
        'Step 2-2！如果想让 AI 扮演特定角色或说话语气，只需在 `LiveConnectParameters` 的 `systemInstruction` 中传入角色扮演指令即可 ✨',
      (2, 3) =>
        '还有 Step 2-3！在语音模式下也想在屏幕上显示字幕对吧？只需加上 `inputAudioTranscription` 和 `outputAudioTranscription`，就能实时收到双向字幕啦！',
      (3, 0) =>
        '在第3话中，我将为您讲解双向语音通话的核心：“16kHz 麦克风输入”、“24kHz 语音播放”，以及我的“口型同步（Lip-Sync）”是如何实现的 🎙️',
      (3, 1) =>
        '首先是 Step 3-1，麦克风输入！使用 `record` 包开启 `sampleRate: 16000`、`numChannels: 1` 的 PCM 流，原样传给 `session.sendAudio(bytes)` 即可♪',
      (3, 2) =>
        '接着是 Step 3-2，AI 语音接收与播放！服务器传来的我的声音是“24,000Hz 单声道”16-bit PCM，以 Base64 编码保存在 `message.data` 中！',
      (3, 3) =>
        '然后是 Step 3-3！我的嘴巴之所以能随着声音自然张合，是因为使用了内置的 `GeminiLiveAudioUtils.calculateRms()` 实时计算音频能量哦 ✨',
      (4, 0) =>
        '啊！前辈💦 如果在我说话的中途前辈突然插话，你知道怎样才能让声音不重叠、立刻停下来吗？',
      (4, 1) =>
        'Step 4-1！当服务器检测到前辈声音的瞬间，会立即发来 `serverContent.interrupted == true`。此时立刻调用 `audioPlayer.clear()` 清空播放缓冲区是最核心的规则 ⚡',
      (4, 2) =>
        'Step 4-2！在嘈杂会场想要防止误触发时，可以通过 `RealtimeInputConfig` 中的 `AutomaticActivityDetection` 精细调节 VAD（语音活动检测）灵敏度与静音时间♪',
      (4, 3) =>
        '此外还有 Step 4-3！感知用户声音情绪的 `enableAffectiveDialog` 以及仅在必要时主动搭话的 `proactiveAudio`，也只需一行代码就能开启哦 💖',
      (5, 0) =>
        '在第5话中，我们来学习不仅共享声音，还能实时共享“眼睛（摄像头画面）”的多模态 Vision 流式传输吧 📷✨',
      (5, 1) =>
        'Step 5-1！摄像头画面完全不需要每秒发送 30 帧。每秒发送 1~2 张（1~2 FPS）JPEG 图像到 `session.sendVideoFrame(jpegBytes)` 是官方推荐的最佳实践 💡',
      (5, 2) =>
        'Step 5-2！而且『gemini_live』还内置了 `GeminiLiveVisionOverlay` 组件，可以在摄像头预览上直接叠加赛博风瞄准框、扫描线和 FPS 徽章♪',
      (6, 0) =>
        '在第6话中，我们来学习让 AI 直接调用应用函数的“Function Calling”，以及搜索最新实时信息的“Grounding（接地）”吧 🛠️✨',
      (6, 1) =>
        'Step 6-1！用 `FunctionDeclaration` 定义函数名与参数。如果指定 `behavior: Behavior.NON_BLOCKING`，即使在执行耗时任务期间，我也不会中断说话哦 💡',
      (6, 2) =>
        'Step 6-2！收到服务器的 `message.toolCall` 后，执行本地 Dart 函数并通过 `session.sendToolResponse()` 返回结果。若中途被打断还能处理 `toolCallCancellation`♪',
      (7, 0) =>
        '在第7话中，我将介绍无需手写复杂 WebSocket 回调、5分钟就能拼出精美语音界面的“19种内置 UI 组件” 🎨✨',
      (7, 1) =>
        'Step 7-1！使用 `GeminiLiveSessionController` 可以自动管理连接状态、实时字幕与打断状态！再绑定 `GeminiLiveChatView`，一行代码就能渲染全屏语音界面♪',
      (7, 2) =>
        'Step 7-2！当然也可以像搭积木一样，自由组合涟漪麦克风按钮 `GeminiLiveMicButton`、实时波形 `GeminiLiveWaveform` 和毛玻璃字幕 `GeminiLiveCaptionBubble` 💡',
      (8, 0) =>
        '在第8话中，我将讲解用于高阶 AI 智能体的“Extended Thinking（深度推理）”，以及支撑 15 分钟以上长通话的“上下文窗口压缩” 🧠✨',
      (8, 1) =>
        'Step 8-1！需要解答数学题或复杂架构推理时，开启 `ThinkingConfig(thinkingBudget: 1024, includeThoughts: true)`；再配合 `ContextWindowCompressionConfig` 即可无惧长通话 Token 上限♪',
      (8, 2) =>
        '还有 Step 8-2！通话途中无需断开 WebSocket 重连，使用 `session.sendContextUpdate()` 就能实时替换系统提示词或工具列表，非常强大 💡',
      (9, 0) =>
        '在第9话中，为您介绍『gemini_live』的两大特色功能：“实时双向语音同传”与像 DJ 一样操控音乐的“Lyria 实时音乐生成” 🎵✨',
      (9, 1) =>
        'Step 9-1！结合 `TranslationConfig` 与内置的 `GeminiLiveTranslateSplitView` 组件，几分钟就能做出把手机平放在桌面上、180度翻转面对面交流的同声传译应用 🌐',
      (9, 2) =>
        '然后是 Step 9-2！通过 `genAI.live.music.connect()` 直连 Google 的音乐生成 AI“Lyria”，即可边实时调节 BPM、音阶与提示词权重，边播放 48kHz 立体声高品质音乐 🎧',
      (10, 0) =>
        '终于来到最终章第10话啦🎉 让我们一口气掌握正式发布商业级应用不可或缺的“临时安全令牌”、“自动重连恢复”、“实时费用计算”与“单元测试”吧！',
      (10, 1) =>
        'Step 10-1！正式应用绝不能硬编码主 API 密钥！在后端调用 `genAI.authTokens.create()` 签发一次性临时令牌，并配合 `SessionResumptionConfig` 在断网重连时无感恢复对话 🔐',
      (10, 2) =>
        'Step 10-2！`GeminiTokenUsageTracker` 会自动按模态统计 Token 消耗并估算 USD/KRW 费用。而且从 `firebase_ai` 迁移也只需替换一行 import 代码 💡',
      (10, 3) =>
        '恭喜前辈🎉✨ 您已经通关了全部 10 话的『gemini_live』大师课程！今后也请继续和光一起打造最棒的 Flutter × Gemini Live 应用吧，最喜欢前辈了💖',
      _ => null,
    };
    if (base == null) return null;
    if (!useGyaru) return base;
    return base
        .replaceAll('“光 (Hikari)”', '“玲奈 (Reina)”')
        .replaceAll('光', '玲奈')
        .replaceAll('前辈，', '前辈~☆ ')
        .replaceAll('♪', '✌️✨');
  }

  // ---------------------------------------------------------------------------
  // Choice Labels (EN & ZH translations by choice id)
  // ---------------------------------------------------------------------------

  static String? choiceLabelEn(String choiceId) => switch (choiceId) {
    'ch1_to_ch2' =>
      '🌸 Go to Ch.2: Learn 30 Voice Personas & System Instructions',
    'ch1_to_ch3' =>
      '🎙️ Skip to Ch.3: 16kHz Mic Input & 24kHz Audio Streaming',
    'ch1_ask_live' =>
      '💬 Ask Hikari: "What is the biggest difference between REST API and Gemini Live WebSocket?"',
    'ch2_to_ch3' =>
      '🎙️ Go to Ch.3: Learn 16kHz Mic Capture, 24kHz Playback & Lip-Sync',
    'ch2_ask_voices' =>
      '💬 Ask Hikari: "Which voices do you recommend among the 30 presets?"',
    'ch2_back_ch1' => '◀ Back to Ch.1 (Package Install & First Connection)',
    'ch3_to_ch4' =>
      '⚡ Go to Ch.4: Learn Barge-In Interruption & VAD Sensitivity',
    'ch3_ask_ai' =>
      '💬 Ask Hikari: "Why is mic input 16kHz while AI audio output is 24kHz?"',
    'ch3_back_ch2' => '◀ Back to Ch.2 (Voice, System Prompt & Subtitles)',
    'ch4_to_ch5' =>
      '📷 Go to Ch.5: Learn Real-Time Camera Vision Streaming',
    'ch4_test_barge' =>
      '😮 Demo Hikari\'s Barge-In Interruption Reaction Live!',
    'ch4_back_ch3' => '◀ Back to Ch.3 (16kHz Mic Input & 24kHz Audio Output)',
    'ch5_to_ch6' =>
      '🛠️ Go to Ch.6: Async Function Calling & Google Search Grounding',
    'ch5_ask_vision' =>
      '💬 Ask Hikari: "What kind of apps can I build by combining Camera Vision and Voice?"',
    'ch5_back_ch4' => '◀ Back to Ch.4 (Barge-In & VAD Control)',
    'ch6_to_ch7' =>
      '🎨 Go to Ch.7: Learn Controller & 19 Built-In UI Widgets',
    'ch6_test_tool' =>
      '⚡ Live Demo: Have Hikari invoke the set_character_emotion tool!',
    'ch6_back_ch5' => '◀ Back to Ch.5 (Camera Vision Streaming)',
    'ch7_to_ch8' =>
      '🧠 Go to Ch.8: Learn Extended Thinking & Long-Session Compression',
    'ch7_back_ch6' => '◀ Back to Ch.6 (Function Calling & Search Grounding)',
    'ch8_to_ch9' =>
      '🎵 Go to Ch.9: Live Speech Translation & Lyria Realtime Music',
    'ch8_back_ch7' => '◀ Back to Ch.7 (Controller & 19 Built-In UI Widgets)',
    'ch9_to_ch10' =>
      '🚀 Go to Final Ch.10: Production Auth, Session Resume, Cost & Testing',
    'ch9_back_ch8' =>
      '◀ Back to Ch.8 (Extended Thinking & Long-Session Compression)',
    'ch10_ask_migration' =>
      '🔥 Ask Hikari: "Tell me the key points for migrating from firebase_ai again!"',
    'ch10_restart_ch1' =>
      '🌸 Review from Ch.1 (Package Install & First Connection)',
    _ => null,
  };

  static String? choiceLabelZh(String choiceId) => switch (choiceId) {
    'ch1_to_ch2' => '🌸 进入第2话：学习 30种声优音色与系统提示词设置',
    'ch1_to_ch3' => '🎙️ 跳至第3话：16kHz 麦克风输入与 24kHz 语音流播放',
    'ch1_ask_live' =>
      '💬 向光提问：“普通 REST API 与 Gemini Live WebSocket 最大的区别是什么？”',
    'ch2_to_ch3' => '🎙️ 进入第3话：学习 16kHz 麦克风录音、24kHz 播放与口型同步',
    'ch2_ask_voices' => '💬 向光提问：“在 30种音色中你最推荐哪几个声音？”',
    'ch2_back_ch1' => '◀ 返回第1话（安装依赖包与首次连接）',
    'ch3_to_ch4' => '⚡ 进入第4话：学习插话打断「Barge-In」与 VAD 灵敏度控制',
    'ch3_ask_ai' => '💬 向光提问：“为什么麦克风输入是 16kHz，而 AI 语音输出是 24kHz？”',
    'ch3_back_ch2' => '◀ 返回第2话（音色 · 系统提示词 · 字幕设置）',
    'ch4_to_ch5' => '📷 进入第5话：学习实时摄像头视觉 (Vision) 视频流传输',
    'ch4_test_barge' => '😮 现场演示光被插话打断 (Barge-In) 时的害羞反应！',
    'ch4_back_ch3' => '◀ 返回第3话（16kHz 麦克风输入 & 24kHz 语音输出）',
    'ch5_to_ch6' => '🛠️ 进入第6话：学习 Function Calling（异步工具调用）与 Google 搜索联动',
    'ch5_ask_vision' => '💬 向光提问：“同时结合摄像头画面和语音可以做出什么样的应用？”',
    'ch5_back_ch4' => '◀ 返回第4话（Barge-In 与 VAD 控制）',
    'ch6_to_ch7' => '🎨 进入第7话：学习 Controller 与 19种内置 UI 组件用法',
    'ch6_test_tool' => '⚡ 现场演示：让光亲自调用 set_character_emotion 工具！',
    'ch6_back_ch5' => '◀ 返回第5话（摄像头视觉流式传输）',
    'ch7_to_ch8' => '🧠 进入第8话：学习 Extended Thinking（深度推理）与长会话压缩',
    'ch7_back_ch6' => '◀ 返回第6话（Function Calling 与搜索接地）',
    'ch8_to_ch9' => '🎵 进入第9话：学习实时双向语音同传与 Lyria 音乐生成',
    'ch8_back_ch7' => '◀ 返回第7话（Controller 与内置 UI 组件）',
    'ch9_to_ch10' => '🚀 进入最终章（第10话）：生产环境安全令牌 · 会话恢复 · 费用计算 · 测试',
    'ch9_back_ch8' => '◀ 返回第8话（Extended Thinking 与长会话压缩）',
    'ch10_ask_migration' => '🔥 向光提问：“再给我讲讲从 firebase_ai 迁移的核心要点吧！”',
    'ch10_restart_ch1' => '🌸 从第1话（安装依赖包与首次连接）重新复习',
    _ => null,
  };
}
