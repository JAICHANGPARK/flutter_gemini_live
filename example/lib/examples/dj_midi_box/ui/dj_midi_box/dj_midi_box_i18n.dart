import 'package:example/app_translations.dart';

/// Localization strings for DJ MIDI Box (`en`, `ko`, `ja`, `zh`).
class DjMidiBoxI18n {
  final AppLanguage language;

  const DjMidiBoxI18n._(this.language);

  static DjMidiBoxI18n of(AppLanguage language) => DjMidiBoxI18n._(language);

  static DjMidiBoxI18n get current =>
      DjMidiBoxI18n.of(AppLanguageController.instance.currentLanguage);

  // Top Header
  String get backTooltip => switch (language) {
    AppLanguage.ko => '뒤로',
    AppLanguage.ja => '戻る',
    AppLanguage.zh => '返回',
    AppLanguage.en => 'Back',
  };

  String get headerTitle => switch (language) {
    AppLanguage.ko => 'DJ MIDI BOX',
    AppLanguage.ja => 'DJ MIDI BOX',
    AppLanguage.zh => 'DJ MIDI BOX',
    AppLanguage.en => 'DJ MIDI BOX',
  };

  String get connectingPill => switch (language) {
    AppLanguage.ko => '연결 중',
    AppLanguage.ja => '接続中',
    AppLanguage.zh => '连接中',
    AppLanguage.en => 'CONNECTING',
  };

  String get onlinePill => switch (language) {
    AppLanguage.ko => '온라인',
    AppLanguage.ja => 'オンライン',
    AppLanguage.zh => '在线',
    AppLanguage.en => 'ONLINE',
  };

  String get connectPill => switch (language) {
    AppLanguage.ko => '연결',
    AppLanguage.ja => '接続',
    AppLanguage.zh => '连接',
    AppLanguage.en => 'CONNECT',
  };

  String get hideConsoleTooltip => switch (language) {
    AppLanguage.ko => '콘솔 숨기기',
    AppLanguage.ja => 'コンソールを隠す',
    AppLanguage.zh => '隐藏控制台',
    AppLanguage.en => 'Hide Console',
  };

  String get showConsoleTooltip => switch (language) {
    AppLanguage.ko => '콘솔 표시 (프롬프트, 설정, 로그)',
    AppLanguage.ja => 'コンソールを表示 (プロンプト、設定、ログ)',
    AppLanguage.zh => '显示控制台 (提示词、设置、日志)',
    AppLanguage.en => 'Show Console (Prompt, Settings, Logs)',
  };

  String get settingsTooltip => switch (language) {
    AppLanguage.ko => '설정',
    AppLanguage.ja => '設定',
    AppLanguage.zh => '设置',
    AppLanguage.en => 'Settings',
  };

  // Tabletop Orb
  String tabletopPlaying(int bpm) => switch (language) {
    AppLanguage.ko => '재생 중 · $bpm BPM',
    AppLanguage.ja => '再生中 · $bpm BPM',
    AppLanguage.zh => '播放中 · $bpm BPM',
    AppLanguage.en => 'PLAYING · $bpm BPM',
  };

  String get tabletopReady => switch (language) {
    AppLanguage.ko => '준비 완료 · 다이얼을 탭하여 재생',
    AppLanguage.ja => '準備完了 · ダイヤルをタップして再生',
    AppLanguage.zh => '就绪 · 点击旋钮开始播放',
    AppLanguage.en => 'READY · TAP DIALS TO PLAY',
  };

  // Bottom Controls & Visualizer
  String get matrixSectionLabel => switch (language) {
    AppLanguage.ko => '16채널 로터리 스템 매트릭스 // 48kHz DSP',
    AppLanguage.ja => '16CH ロータリーステムマトリックス // 48kHz DSP',
    AppLanguage.zh => '16 通道旋钮干声矩阵 // 48kHz DSP',
    AppLanguage.en => '16-CH ROTARY STEM MATRIX // 48kHz DSP',
  };

  String get masterBusLabel => switch (language) {
    AppLanguage.ko => 'MASTER L/R',
    AppLanguage.ja => 'MASTER L/R',
    AppLanguage.zh => '主输出 L/R',
    AppLanguage.en => 'MASTER L/R',
  };

  String get bassCutLabel => switch (language) {
    AppLanguage.ko => 'BASS CUT',
    AppLanguage.ja => 'BASS CUT',
    AppLanguage.zh => '低音切除',
    AppLanguage.en => 'BASS CUT',
  };

  String get drumCutLabel => switch (language) {
    AppLanguage.ko => 'DRUM CUT',
    AppLanguage.ja => 'DRUM CUT',
    AppLanguage.zh => '鼓组切除',
    AppLanguage.en => 'DRUM CUT',
  };

  String get masterGainLabel => switch (language) {
    AppLanguage.ko => 'MASTER DRIVE',
    AppLanguage.ja => 'MASTER DRIVE',
    AppLanguage.zh => '主总线激励',
    AppLanguage.en => 'MASTER DRIVE',
  };

  String get liveFftTitle => switch (language) {
    AppLanguage.ko => '실시간 FFT & 파형',
    AppLanguage.ja => 'ライブ FFT & 波形',
    AppLanguage.zh => '实时 FFT 与波形',
    AppLanguage.en => 'LIVE FFT & WAVEFORM',
  };

  String get subBassAxis => switch (language) {
    AppLanguage.ko => '서브 베이스 (40Hz)',
    AppLanguage.ja => 'SUB BASS (40Hz)',
    AppLanguage.zh => '超低音 (40Hz)',
    AppLanguage.en => 'SUB BASS (40Hz)',
  };

  String get lowMidAxis => switch (language) {
    AppLanguage.ko => '중저음 (500Hz)',
    AppLanguage.ja => 'LOW-MID (500Hz)',
    AppLanguage.zh => '中低频 (500Hz)',
    AppLanguage.en => 'LOW-MID (500Hz)',
  };

  String get midHighAxis => switch (language) {
    AppLanguage.ko => '중고음 (4kHz)',
    AppLanguage.ja => 'MID-HIGH (4kHz)',
    AppLanguage.zh => '中高频 (4kHz)',
    AppLanguage.en => 'MID-HIGH (4kHz)',
  };

  String get trebleAxis => switch (language) {
    AppLanguage.ko => '고음 (16kHz)',
    AppLanguage.ja => 'TREBLE (16kHz)',
    AppLanguage.zh => '高频 (16kHz)',
    AppLanguage.en => 'TREBLE (16kHz)',
  };

  // Console Panel
  String get consolePanelTitle => switch (language) {
    AppLanguage.ko => 'DJ 콘솔',
    AppLanguage.ja => 'DJ コンソール',
    AppLanguage.zh => 'DJ 控制台',
    AppLanguage.en => 'DJ CONSOLE',
  };

  String get streamingBadge => switch (language) {
    AppLanguage.ko => '스트리밍 중',
    AppLanguage.ja => '配信中',
    AppLanguage.zh => '流传输中',
    AppLanguage.en => 'STREAMING',
  };

  String get idleBadge => switch (language) {
    AppLanguage.ko => '대기',
    AppLanguage.ja => '待機中',
    AppLanguage.zh => '空闲',
    AppLanguage.en => 'IDLE',
  };

  String get tabPrompt => switch (language) {
    AppLanguage.ko => '프롬프트',
    AppLanguage.ja => 'プロンプト',
    AppLanguage.zh => '提示词',
    AppLanguage.en => 'PROMPT',
  };

  String get tabSettings => switch (language) {
    AppLanguage.ko => '설정',
    AppLanguage.ja => '設定',
    AppLanguage.zh => '设置',
    AppLanguage.en => 'SETTINGS',
  };

  String get tabLogs => switch (language) {
    AppLanguage.ko => '로그',
    AppLanguage.ja => 'ログ',
    AppLanguage.zh => '日志',
    AppLanguage.en => 'LOGS',
  };

  // Prompt Tab
  String get customPromptHeader => switch (language) {
    AppLanguage.ko => '커스텀 프롬프트 주입',
    AppLanguage.ja => 'カスタムプロンプト注入',
    AppLanguage.zh => '自定义提示词注入',
    AppLanguage.en => 'CUSTOM PROMPT INJECTION',
  };

  String get customPromptActiveStatus => switch (language) {
    AppLanguage.ko => '활성: 16개의 로터리 노브와 함께 음악을 조종합니다',
    AppLanguage.ja => '有効: 16個のロータリーノブと共に音楽を操作中',
    AppLanguage.zh => '已启用：与 16 个旋钮共同控制音乐',
    AppLanguage.en => 'Active: Steering the music along with the 16 rotary knobs',
  };

  String get customPromptDisabledStatus => switch (language) {
    AppLanguage.ko => '비활성: 로터리 노브만 작동합니다',
    AppLanguage.ja => '無効: ロータリーノブのみ有効です',
    AppLanguage.zh => '已禁用：仅旋钮处于活动状态',
    AppLanguage.en => 'Disabled: Only rotary knobs are active',
  };

  String get customPromptHint => switch (language) {
    AppLanguage.ko => '실시간 음악 스타일 프롬프트를 입력하세요...',
    AppLanguage.ja => 'リアルタイム音楽スタイルプロンプトを入力...',
    AppLanguage.zh => '输入实时音乐风格提示词...',
    AppLanguage.en => 'Enter real-time music style prompt...',
  };

  String get promptWeightLabel => switch (language) {
    AppLanguage.ko => '프롬프트 가중치 (영향력):',
    AppLanguage.ja => 'プロンプトの重み (影響度):',
    AppLanguage.zh => '提示词权重 (影响力):',
    AppLanguage.en => 'Prompt Weight (Influence):',
  };

  String get applyPromptButton => switch (language) {
    AppLanguage.ko => '믹스에 프롬프트 적용',
    AppLanguage.ja => 'ミックスにプロンプトを適用',
    AppLanguage.zh => '将提示词应用到混音',
    AppLanguage.en => 'APPLY PROMPT TO MIX',
  };

  String get quickStylePresetsHeader => switch (language) {
    AppLanguage.ko => '빠른 스타일 프리셋',
    AppLanguage.ja => 'クイックスタイルプリセット',
    AppLanguage.zh => '快速风格预设',
    AppLanguage.en => 'QUICK STYLE PRESETS',
  };

  // Settings Tab
  String get tempoBpmHeader => switch (language) {
    AppLanguage.ko => '템포 (BPM)',
    AppLanguage.ja => 'テンポ (BPM)',
    AppLanguage.zh => '速度 (BPM)',
    AppLanguage.en => 'TEMPO (BPM)',
  };

  String get generationModeHeader => switch (language) {
    AppLanguage.ko => '생성 모드',
    AppLanguage.ja => '生成モード',
    AppLanguage.zh => '生成模式',
    AppLanguage.en => 'GENERATION MODE',
  };

  String get musicalScaleHeader => switch (language) {
    AppLanguage.ko => '음악 스케일 / 조성',
    AppLanguage.ja => '音楽スケール / 調性',
    AppLanguage.zh => '音乐音阶 / 调性',
    AppLanguage.en => 'MUSICAL SCALE',
  };

  String get autoScaleOption => switch (language) {
    AppLanguage.ko => '자동 스케일 (모델 결정)',
    AppLanguage.ja => '自動スケール (モデルにおまかせ)',
    AppLanguage.zh => '自动音阶 (模型自动决定)',
    AppLanguage.en => 'Auto Scale (Model Decides)',
  };

  String get guidanceScaleHeader => switch (language) {
    AppLanguage.ko => '가이던스 강도',
    AppLanguage.ja => 'ガイダンススケール',
    AppLanguage.zh => '引导强度',
    AppLanguage.en => 'GUIDANCE SCALE',
  };

  String get soundDensityHeader => switch (language) {
    AppLanguage.ko => '사운드 밀도',
    AppLanguage.ja => 'サウンド密度',
    AppLanguage.zh => '声音密度',
    AppLanguage.en => 'SOUND DENSITY',
  };

  String get brightnessHeader => switch (language) {
    AppLanguage.ko => '밝기 (Brightness)',
    AppLanguage.ja => '明るさ (Brightness)',
    AppLanguage.zh => '明亮度 (Brightness)',
    AppLanguage.en => 'BRIGHTNESS',
  };

  String get muteBassSwitch => switch (language) {
    AppLanguage.ko => '베이스 음소거',
    AppLanguage.ja => 'ベースをミュート',
    AppLanguage.zh => '静音贝斯',
    AppLanguage.en => 'Mute Bass',
  };

  String get muteDrumsSwitch => switch (language) {
    AppLanguage.ko => '드럼 음소거',
    AppLanguage.ja => 'ドラムをミュート',
    AppLanguage.zh => '静音鼓组',
    AppLanguage.en => 'Mute Drums',
  };

  // Logs Tab
  String eventsHeader(int count) => switch (language) {
    AppLanguage.ko => '이벤트 ($count)',
    AppLanguage.ja => 'イベント ($count)',
    AppLanguage.zh => '事件 ($count)',
    AppLanguage.en => 'EVENTS ($count)',
  };

  String get clearLogsButton => switch (language) {
    AppLanguage.ko => '지우기',
    AppLanguage.ja => 'クリア',
    AppLanguage.zh => '清空',
    AppLanguage.en => 'CLEAR',
  };

  String get emptyLogsText => switch (language) {
    AppLanguage.ko => '기록된 이벤트가 없습니다.\n연결하거나 재생하여 실시간 WebSocket 이벤트를 확인하세요.',
    AppLanguage.ja =>
      'イベントログはまだありません。\n接続または再生してリアルタイムWebSocketイベントを表示します。',
    AppLanguage.zh => '暂无事件记录。\n连接或播放即可查看实时 WebSocket 事件。',
    AppLanguage.en =>
      'No events logged yet.\nConnect or play to view real-time WebSocket events.',
  };

  // Edit Knob Dialog
  String editKnobTitle(String title) => switch (language) {
    AppLanguage.ko => '노브 편집: $title',
    AppLanguage.ja => 'ノブを編集: $title',
    AppLanguage.zh => '编辑旋钮: $title',
    AppLanguage.en => 'Edit Knob: $title',
  };

  String get labelBadgeTitleField => switch (language) {
    AppLanguage.ko => '라벨 배지 이름',
    AppLanguage.ja => 'ラベルバッジ名',
    AppLanguage.zh => '标签名称',
    AppLanguage.en => 'Label Badge Title',
  };

  String get musicalPromptField => switch (language) {
    AppLanguage.ko => '음악 설명 프롬프트',
    AppLanguage.ja => '音楽説明プロンプト',
    AppLanguage.zh => '音乐描述提示词',
    AppLanguage.en => 'Musical Description Prompt',
  };

  String get cancelButton => switch (language) {
    AppLanguage.ko => '취소',
    AppLanguage.ja => 'キャンセル',
    AppLanguage.zh => '取消',
    AppLanguage.en => 'CANCEL',
  };

  String get saveButton => switch (language) {
    AppLanguage.ko => '저장',
    AppLanguage.ja => '保存',
    AppLanguage.zh => '保存',
    AppLanguage.en => 'SAVE',
  };

  // Notices / SnackBars
  String get noticeConnected => switch (language) {
    AppLanguage.ko => '🎛️ DJ MIDI 박스가 Lyria RealTime에 연결되었습니다! ▶ 버튼을 눌러 재생하세요.',
    AppLanguage.ja => '🎛️ DJ MIDI BoxがLyria RealTimeに接続されました！ ▶をタップして再生。',
    AppLanguage.zh => '🎛️ DJ MIDI 盒已连接至 Lyria RealTime！点击 ▶ 开始播放。',
    AppLanguage.en =>
      '🎛️ DJ MIDI Box Connected to Lyria RealTime! Tap ▶ to Play.',
  };

  String noticeConnectionFailed(Object error) => switch (language) {
    AppLanguage.ko => '연결 실패: $error',
    AppLanguage.ja => '接続失敗: $error',
    AppLanguage.zh => '连接失败: $error',
    AppLanguage.en => 'Connection failed: $error',
  };
}
