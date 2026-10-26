import 'package:example/app_translations.dart';

/// Localization strings for Pro DJ Console (`en`, `ko`, `ja`, `zh`).
class ProDjConsoleI18n {
  final AppLanguage language;

  const ProDjConsoleI18n._(this.language);

  static ProDjConsoleI18n of(AppLanguage language) =>
      ProDjConsoleI18n._(language);

  static ProDjConsoleI18n get current =>
      ProDjConsoleI18n.of(AppLanguageController.instance.currentLanguage);

  // App Bar
  String get appBarSubtitle => switch (language) {
    AppLanguage.ko => '디지털 멀티 플레이어 콘솔',
    AppLanguage.ja => 'デジタルマルチプレイヤーコンソール',
    AppLanguage.zh => '数字多轨打碟控制台',
    AppLanguage.en => 'DIGITAL MULTI-PLAYER CONSOLE',
  };

  String get onAirBadge => 'ON AIR';

  String get midiBoxTooltip => switch (language) {
    AppLanguage.ko => 'DJ MIDI 박스 (16패드 로터리 그리드)',
    AppLanguage.ja => 'DJ MIDI Box (16パッドロータリーグリッド)',
    AppLanguage.zh => 'DJ MIDI 盒 (16旋钮矩阵)',
    AppLanguage.en => 'DJ MIDI Box (16-Pad Rotary Grid)',
  };

  String get settingsTooltip => switch (language) {
    AppLanguage.ko => '설정',
    AppLanguage.ja => '設定',
    AppLanguage.zh => '设置',
    AppLanguage.en => 'Settings',
  };

  String get tabletopTooltip => switch (language) {
    AppLanguage.ko => '테이블탑 / 플렉스 모드',
    AppLanguage.ja => 'テーブルトップ / フレックスモード',
    AppLanguage.zh => '桌面 / 悬停模式',
    AppLanguage.en => 'Tabletop / Flex Mode',
  };

  String get duoScreenTooltip => switch (language) {
    AppLanguage.ko => '듀얼 스크린 활성',
    AppLanguage.ja => 'デュアルスクリーン有効',
    AppLanguage.zh => '双屏模式已启用',
    AppLanguage.en => 'Duo Dual-Screen Active',
  };

  String get foldableTooltip => switch (language) {
    AppLanguage.ko => '폴더블 모드 활성',
    AppLanguage.ja => 'フォルダブル有効',
    AppLanguage.zh => '折叠屏模式已启用',
    AppLanguage.en => 'Foldable Active',
  };

  // Master LCD Display (Top Status Strip)
  String get lcdTimeLabel => switch (language) {
    AppLanguage.ko => '시간  ',
    AppLanguage.ja => 'TIME  ',
    AppLanguage.zh => '时间  ',
    AppLanguage.en => 'TIME  ',
  };

  String get lcdNoKey => switch (language) {
    AppLanguage.ko => '조성 없음',
    AppLanguage.ja => 'キーなし',
    AppLanguage.zh => '自由调性',
    AppLanguage.en => 'NO KEY',
  };

  String get lcdOnline => switch (language) {
    AppLanguage.ko => 'LYRIA 실시간 온라인',
    AppLanguage.ja => 'LYRIA REALTIME オンライン',
    AppLanguage.zh => 'LYRIA 实时在线',
    AppLanguage.en => 'LYRIA REALTIME ONLINE',
  };

  String get lcdStandby => switch (language) {
    AppLanguage.ko => '대기 중',
    AppLanguage.ja => 'スタンバイ',
    AppLanguage.zh => '待机',
    AppLanguage.en => 'STANDBY',
  };

  // CDJ Deck
  String deckTitle(bool isDeckA) => isDeckA
      ? switch (language) {
          AppLanguage.ko => 'DECK 1 (A)',
          AppLanguage.ja => 'DECK 1 (A)',
          AppLanguage.zh => '碟机 1 (A)',
          AppLanguage.en => 'DECK 1 (A)',
        }
      : switch (language) {
          AppLanguage.ko => 'DECK 2 (B)',
          AppLanguage.ja => 'DECK 2 (B)',
          AppLanguage.zh => '碟机 2 (B)',
          AppLanguage.en => 'DECK 2 (B)',
        };

  String get vinylModeBadge => switch (language) {
    AppLanguage.ko => '바이닐 모드',
    AppLanguage.ja => 'VINYL モード',
    AppLanguage.zh => '黑胶模式',
    AppLanguage.en => 'VINYL MODE',
  };

  String get steerablePromptLabel => switch (language) {
    AppLanguage.ko => '실시간 프롬프트',
    AppLanguage.ja => 'スティアラブルプロンプト',
    AppLanguage.zh => '实时可控提示词',
    AppLanguage.en => 'STEERABLE PROMPT',
  };

  String weightLabel(String weight) => switch (language) {
    AppLanguage.ko => '가중치: $weight',
    AppLanguage.ja => 'WEIGHT: $weight',
    AppLanguage.zh => '权重: $weight',
    AppLanguage.en => 'WEIGHT: $weight',
  };

  String get editPromptTooltip => switch (language) {
    AppLanguage.ko => '프롬프트 편집',
    AppLanguage.ja => 'プロンプトを編集',
    AppLanguage.zh => '编辑提示词',
    AppLanguage.en => 'Edit Prompt',
  };

  // DJM Center Mixer
  String get mixerHeader => switch (language) {
    AppLanguage.ko => '4채널 디지털 믹서',
    AppLanguage.ja => '4-CH デジタルミキサー',
    AppLanguage.zh => '4通道数字混音台',
    AppLanguage.en => '4-CH DIGITAL MIXER',
  };

  String get knobTrimTemp => switch (language) {
    AppLanguage.ko => 'TRIM (변화)',
    AppLanguage.ja => 'TRIM (TEMP)',
    AppLanguage.zh => 'TRIM (变化)',
    AppLanguage.en => 'TRIM (TEMP)',
  };

  String get knobHiBright => switch (language) {
    AppLanguage.ko => 'HI (밝기)',
    AppLanguage.ja => 'HI (明瞭)',
    AppLanguage.zh => 'HI (明亮)',
    AppLanguage.en => 'HI (BRIGHT)',
  };

  String get knobMidDense => switch (language) {
    AppLanguage.ko => 'MID (밀도)',
    AppLanguage.ja => 'MID (密度)',
    AppLanguage.zh => 'MID (密度)',
    AppLanguage.en => 'MID (DENSE)',
  };

  String get knobLowGuide => switch (language) {
    AppLanguage.ko => 'LOW (가이드)',
    AppLanguage.ja => 'LOW (誘導)',
    AppLanguage.zh => 'LOW (引导)',
    AppLanguage.en => 'LOW (GUIDE)',
  };

  String get bassKill => switch (language) {
    AppLanguage.ko => '베이스 차단',
    AppLanguage.ja => 'BASS KILL',
    AppLanguage.zh => '切低音',
    AppLanguage.en => 'BASS KILL',
  };

  String get drumKill => switch (language) {
    AppLanguage.ko => '드럼 차단',
    AppLanguage.ja => 'DRUM KILL',
    AppLanguage.zh => '切鼓组',
    AppLanguage.en => 'DRUM KILL',
  };

  String get onlyBassDrum => switch (language) {
    AppLanguage.ko => '베이스/드럼만',
    AppLanguage.ja => 'BASS/DRUMのみ',
    AppLanguage.zh => '仅低音/鼓',
    AppLanguage.en => 'ONLY BASS/DRUM',
  };

  String get crossfaderLeft => switch (language) {
    AppLanguage.ko => '크로스페이더 [A]',
    AppLanguage.ja => 'CROSSFADER [A]',
    AppLanguage.zh => '交叉推子 [A]',
    AppLanguage.en => 'CROSSFADER [A]',
  };

  String get crossfaderRight => switch (language) {
    AppLanguage.ko => '[B] 크로스페이더',
    AppLanguage.ja => '[B] CROSSFADER',
    AppLanguage.zh => '[B] 交叉推子',
    AppLanguage.en => '[B] CROSSFADER',
  };

  // Performance Pads Section
  String get hotCueHeader => switch (language) {
    AppLanguage.ko => '핫 큐 / 사운드 뱅크 (8패드 퍼포먼스)',
    AppLanguage.ja => 'ホットキュー / サウンドバンク (8パッド)',
    AppLanguage.zh => '热键点 / 音色库 (8打击垫)',
    AppLanguage.en => 'HOT CUE / SOUND BANK (8-PAD RUBBER PERFORMANCE)',
  };

  String get rgbBacklitBadge => switch (language) {
    AppLanguage.ko => 'RGB 벨로시티 백라이트',
    AppLanguage.ja => 'RGB ベロシティバックライト',
    AppLanguage.zh => 'RGB 力度背光',
    AppLanguage.en => 'RGB VELOCITY BACKLIT',
  };

  // Master Transport Bar
  String get connectingButton => switch (language) {
    AppLanguage.ko => '연결 중...',
    AppLanguage.ja => '接続中...',
    AppLanguage.zh => '正在连接...',
    AppLanguage.en => 'CONNECTING...',
  };

  String get disconnectButton => switch (language) {
    AppLanguage.ko => '연결 해제',
    AppLanguage.ja => '切断',
    AppLanguage.zh => '断开连接',
    AppLanguage.en => 'DISCONNECT',
  };

  String get connectConsoleButton => switch (language) {
    AppLanguage.ko => '콘솔 연결',
    AppLanguage.ja => 'コンソール接続',
    AppLanguage.zh => '连接控制台',
    AppLanguage.en => 'CONNECT CONSOLE',
  };

  String get pauseButton => switch (language) {
    AppLanguage.ko => '일시정지',
    AppLanguage.ja => '一時停止',
    AppLanguage.zh => '暂停',
    AppLanguage.en => 'PAUSE',
  };

  String get playMasterButton => switch (language) {
    AppLanguage.ko => '마스터 재생',
    AppLanguage.ja => 'マスター再生',
    AppLanguage.zh => '主控播放',
    AppLanguage.en => 'PLAY MASTER',
  };

  String get stopCueButton => switch (language) {
    AppLanguage.ko => '정지 / CUE',
    AppLanguage.ja => '停止 / CUE',
    AppLanguage.zh => '停止 / CUE',
    AppLanguage.en => 'STOP / CUE',
  };

  String get hardDropButton => switch (language) {
    AppLanguage.ko => '하드 드롭',
    AppLanguage.ja => 'ハードドロップ',
    AppLanguage.zh => '强力Drop',
    AppLanguage.en => 'HARD DROP',
  };

  // Console Logs
  String get diagnosticTerminalTitle => switch (language) {
    AppLanguage.ko => '🎛️ DJ 콘솔 진단 터미널',
    AppLanguage.ja => '🎛️ DJコンソール 診断ターミナル',
    AppLanguage.zh => '🎛️ DJ 控制台诊断终端',
    AppLanguage.en => '🎛️ DJ CONSOLE DIAGNOSTIC TERMINAL',
  };

  // Edit Prompt Dialog
  String editDeckPromptTitle(bool isDeckA) => isDeckA
      ? switch (language) {
          AppLanguage.ko => 'Deck 1 (A) 프롬프트 편집',
          AppLanguage.ja => 'Deck 1 (A) プロンプト編集',
          AppLanguage.zh => '编辑碟机 1 (A) 提示词',
          AppLanguage.en => 'Edit Deck 1 (A) Prompt',
        }
      : switch (language) {
          AppLanguage.ko => 'Deck 2 (B) 프롬프트 편집',
          AppLanguage.ja => 'Deck 2 (B) プロンプト編集',
          AppLanguage.zh => '编辑碟机 2 (B) 提示词',
          AppLanguage.en => 'Edit Deck 2 (B) Prompt',
        };

  String get editPromptHint => switch (language) {
    AppLanguage.ko => '음악 스타일, 악기 또는 분위기를 입력하세요...',
    AppLanguage.ja => '音楽スタイル、楽器、または雰囲気を入力...',
    AppLanguage.zh => '输入音乐风格、乐器或氛围...',
    AppLanguage.en => 'Enter musical style, instruments, or vibe...',
  };

  String get cancelButton => switch (language) {
    AppLanguage.ko => '취소',
    AppLanguage.ja => 'キャンセル',
    AppLanguage.zh => '取消',
    AppLanguage.en => 'CANCEL',
  };

  String get applyButton => switch (language) {
    AppLanguage.ko => '적용',
    AppLanguage.ja => '適用',
    AppLanguage.zh => '应用',
    AppLanguage.en => 'APPLY',
  };

  // Notices / SnackBars
  String get noticeConnected => switch (language) {
    AppLanguage.ko => '🎧 프로 DJ 콘솔이 Lyria RealTime에 연결되었습니다!',
    AppLanguage.ja => '🎧 Pro DJコンソールがLyria RealTimeに接続されました！',
    AppLanguage.zh => '🎧 专业 DJ 控制台已连接至 Lyria RealTime！',
    AppLanguage.en => '🎧 Pro DJ Console Connected to Lyria RealTime!',
  };

  String noticeConnectionFailed(Object error) => switch (language) {
    AppLanguage.ko => '연결 실패: $error',
    AppLanguage.ja => '接続失敗: $error',
    AppLanguage.zh => '连接失败: $error',
    AppLanguage.en => 'Connection failed: $error',
  };

  String get noticeHardDrop => switch (language) {
    AppLanguage.ko => '⚡ 인스턴트 비트 드롭: 컨텍스트 초기화 완료!',
    AppLanguage.ja => '⚡ インスタントビートドロップ: コンテキストリセット実行！',
    AppLanguage.zh => '⚡ 瞬间节拍切换：上下文重置已执行！',
    AppLanguage.en => '⚡ Instant Beat Drop: Context reset executed!',
  };
}
