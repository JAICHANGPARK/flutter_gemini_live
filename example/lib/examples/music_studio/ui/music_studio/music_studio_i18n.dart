import 'package:example/app_translations.dart';

import '../../domain/models/music_studio_status.dart';

/// Localization strings for Live Music Studio (`en`, `ko`, `ja`, `zh`).
class MusicStudioI18n {
  final AppLanguage language;

  const MusicStudioI18n._(this.language);

  static MusicStudioI18n of(AppLanguage language) =>
      MusicStudioI18n._(language);

  static MusicStudioI18n get current =>
      MusicStudioI18n.of(AppLanguageController.instance.currentLanguage);

  // App Bar
  String get appBarTitle => switch (language) {
    AppLanguage.ko => '라이브 뮤직 스튜디오',
    AppLanguage.ja => 'ライブ音楽スタジオ',
    AppLanguage.zh => '实时音乐工作室',
    AppLanguage.en => 'Live Music Studio',
  };

  String get lyriaRealtimeBadge => switch (language) {
    AppLanguage.ko => 'Lyria 실시간',
    AppLanguage.ja => 'Lyria リアルタイム',
    AppLanguage.zh => 'Lyria 实时',
    AppLanguage.en => 'Lyria Realtime',
  };

  String get midiBoxButton => switch (language) {
    AppLanguage.ko => 'MIDI 박스',
    AppLanguage.ja => 'MIDI BOX',
    AppLanguage.zh => 'MIDI 盒',
    AppLanguage.en => 'MIDI BOX',
  };

  String get djConsoleButton => switch (language) {
    AppLanguage.ko => 'DJ 콘솔',
    AppLanguage.ja => 'DJ コンソール',
    AppLanguage.zh => 'DJ 控制台',
    AppLanguage.en => 'DJ CONSOLE',
  };

  String get settingsTooltip => switch (language) {
    AppLanguage.ko => '설정',
    AppLanguage.ja => '設定',
    AppLanguage.zh => '设置',
    AppLanguage.en => 'Settings',
  };

  // Connection Card
  String get modelLabel => switch (language) {
    AppLanguage.ko => 'Lyria 라이브 모델',
    AppLanguage.ja => 'Lyria ライブモデル',
    AppLanguage.zh => 'Lyria 实时模型',
    AppLanguage.en => 'Lyria Live Model',
  };

  String get modelStandardOption => switch (language) {
    AppLanguage.ko => 'lyria-realtime-exp (표준)',
    AppLanguage.ja => 'lyria-realtime-exp (標準)',
    AppLanguage.zh => 'lyria-realtime-exp (标准)',
    AppLanguage.en => 'lyria-realtime-exp (Standard)',
  };

  String get connectButton => switch (language) {
    AppLanguage.ko => '연결',
    AppLanguage.ja => '接続',
    AppLanguage.zh => '连接',
    AppLanguage.en => 'Connect',
  };

  String get disconnectButton => switch (language) {
    AppLanguage.ko => '연결 해제',
    AppLanguage.ja => '切断',
    AppLanguage.zh => '断开',
    AppLanguage.en => 'Disconnect',
  };

  String statusText(MusicStudioStatus status) => switch (status) {
    MusicStudioStatus.disconnected => switch (language) {
      AppLanguage.ko => '연결 안 됨',
      AppLanguage.ja => '未接続',
      AppLanguage.zh => '未连接',
      AppLanguage.en => 'Disconnected',
    },
    MusicStudioStatus.connecting => switch (language) {
      AppLanguage.ko => 'Lyria에 연결 중...',
      AppLanguage.ja => 'Lyriaに接続中...',
      AppLanguage.zh => '正在连接 Lyria...',
      AppLanguage.en => 'Connecting to Lyria...',
    },
    MusicStudioStatus.connected => switch (language) {
      AppLanguage.ko => '연결됨 (준비 완료)',
      AppLanguage.ja => '接続済み (準備完了)',
      AppLanguage.zh => '已连接 (就绪)',
      AppLanguage.en => 'Connected (Ready)',
    },
    MusicStudioStatus.failed => switch (language) {
      AppLanguage.ko => '연결 실패',
      AppLanguage.ja => '接続失敗',
      AppLanguage.zh => '连接失败',
      AppLanguage.en => 'Connection failed',
    },
    MusicStudioStatus.streaming => switch (language) {
      AppLanguage.ko => '오디오 스트리밍 중',
      AppLanguage.ja => 'オーディオストリーミング中',
      AppLanguage.zh => '正在流式传输音频',
      AppLanguage.en => 'Streaming Audio',
    },
    MusicStudioStatus.paused => switch (language) {
      AppLanguage.ko => '일시정지됨',
      AppLanguage.ja => '一時停止中',
      AppLanguage.zh => '已暂停',
      AppLanguage.en => 'Paused',
    },
    MusicStudioStatus.stopped => switch (language) {
      AppLanguage.ko => '정지됨 (컨텍스트 초기화)',
      AppLanguage.ja => '停止 (コンテキストリセット)',
      AppLanguage.zh => '已停止 (上下文已重置)',
      AppLanguage.en => 'Stopped (Context Reset)',
    },
  };

  String streamMetrics(int chunks, String kb) => switch (language) {
    AppLanguage.ko => '청크: $chunks · $kb KB',
    AppLanguage.ja => 'チャンク: $chunks · $kb KB',
    AppLanguage.zh => '块数: $chunks · $kb KB',
    AppLanguage.en => 'Chunks: $chunks · $kb KB',
  };

  // Visualizer Card
  String get visualizerTitle => switch (language) {
    AppLanguage.ko => '실시간 스트림 비주얼라이저',
    AppLanguage.ja => 'リアルタイムストリームビジュアライザー',
    AppLanguage.zh => '实时音频流可视化',
    AppLanguage.en => 'Real-time Stream Visualizer',
  };

  String get pcmLiveBadge => switch (language) {
    AppLanguage.ko => 'PCM 48kHz 라이브',
    AppLanguage.ja => 'PCM 48kHz LIVE',
    AppLanguage.zh => 'PCM 48kHz 实时',
    AppLanguage.en => 'PCM 48kHz LIVE',
  };

  String get streamIdleBadge => switch (language) {
    AppLanguage.ko => '스트림 대기',
    AppLanguage.ja => 'ストリーム待機中',
    AppLanguage.zh => '流空闲',
    AppLanguage.en => 'STREAM IDLE',
  };

  // Transport Controls
  String get playTooltip => switch (language) {
    AppLanguage.ko => '생성 시작 / 재개',
    AppLanguage.ja => '生成を開始 / 再開',
    AppLanguage.zh => '开始 / 恢复生成',
    AppLanguage.en => 'Start / Resume Generation',
  };

  String get pauseTooltip => switch (language) {
    AppLanguage.ko => '스트림 일시정지',
    AppLanguage.ja => 'ストリームを一時停止',
    AppLanguage.zh => '暂停流',
    AppLanguage.en => 'Pause Stream',
  };

  String get stopTooltip => switch (language) {
    AppLanguage.ko => '정지 및 컨텍스트 초기화',
    AppLanguage.ja => '停止してコンテキストをリセット',
    AppLanguage.zh => '停止并重置上下文',
    AppLanguage.en => 'Stop & Reset Context',
  };

  String get resetContextButton => switch (language) {
    AppLanguage.ko => '컨텍스트 초기화',
    AppLanguage.ja => 'コンテキストリセット',
    AppLanguage.zh => '重置上下文',
    AppLanguage.en => 'Reset Context',
  };

  // Prompts Section
  String get steerablePromptsTitle => switch (language) {
    AppLanguage.ko => '🎛️ 실시간 가중치 프롬프트',
    AppLanguage.ja => '🎛️ スティアラブル重み付きプロンプト',
    AppLanguage.zh => '🎛️ 可控加权提示词',
    AppLanguage.en => '🎛️ Steerable Weighted Prompts',
  };

  String get addPromptButton => switch (language) {
    AppLanguage.ko => '프롬프트 추가',
    AppLanguage.ja => 'プロンプト追加',
    AppLanguage.zh => '添加提示词',
    AppLanguage.en => 'Add Prompt',
  };

  String get crossfaderTitle => switch (language) {
    AppLanguage.ko => '프롬프트 DJ 크로스페이더 (A ⟷ B)',
    AppLanguage.ja => 'プロンプト DJ クロスフェーダー (A ⟷ B)',
    AppLanguage.zh => '提示词 DJ 交叉推子 (A ⟷ B)',
    AppLanguage.en => 'Prompt DJ Crossfader (A ⟷ B)',
  };

  String get tagBankTitle => switch (language) {
    AppLanguage.ko => '프롬프트 DJ 태그 뱅크 (공식 가이드 어휘)',
    AppLanguage.ja => 'プロンプト DJ タグバンク (公式ガイド語彙)',
    AppLanguage.zh => '提示词 DJ 标签库 (官方指南词汇)',
    AppLanguage.en => 'Prompt DJ Tag Bank (Official Guide Vocabularies)',
  };

  String get promptHint => switch (language) {
    AppLanguage.ko => '스타일, 악기 또는 분위기를 입력하세요...',
    AppLanguage.ja => 'スタイル、楽器、または雰囲気を入力...',
    AppLanguage.zh => '输入音乐风格、乐器或氛围...',
    AppLanguage.en => 'Prompt style, instrument, or vibe...',
  };

  String weightLabel(String weight) => switch (language) {
    AppLanguage.ko => '가중치: $weight',
    AppLanguage.ja => '重み: $weight',
    AppLanguage.zh => '权重: $weight',
    AppLanguage.en => 'Weight: $weight',
  };

  String get removeTooltip => switch (language) {
    AppLanguage.ko => '삭제',
    AppLanguage.ja => '削除',
    AppLanguage.zh => '移除',
    AppLanguage.en => 'Remove',
  };

  String get updatePromptsButton => switch (language) {
    AppLanguage.ko => '가중치 프롬프트 업데이트',
    AppLanguage.ja => 'プロンプトを更新',
    AppLanguage.zh => '更新可控提示词',
    AppLanguage.en => 'Update Steerable Prompts',
  };

  // Generation Config Section
  String get generationParamsTitle => switch (language) {
    AppLanguage.ko => '⚙️ 음악 생성 파라미터',
    AppLanguage.ja => '⚙️ 音楽生成パラメータ',
    AppLanguage.zh => '⚙️ 音乐生成参数',
    AppLanguage.en => '⚙️ Music Generation Parameters',
  };

  String get scaleKeyLabel => switch (language) {
    AppLanguage.ko => '스케일 / 조성:',
    AppLanguage.ja => 'スケール / キー:',
    AppLanguage.zh => '音阶 / 调性:',
    AppLanguage.en => 'Scale / Key:',
  };

  String get defaultFreeScale => switch (language) {
    AppLanguage.ko => '기본 / 자유 스케일',
    AppLanguage.ja => 'デフォルト / フリースケール',
    AppLanguage.zh => '默认 / 自由音阶',
    AppLanguage.en => 'Default / Free Scale',
  };

  String get modeLabel => switch (language) {
    AppLanguage.ko => '모드:',
    AppLanguage.ja => 'モード:',
    AppLanguage.zh => '模式:',
    AppLanguage.en => 'Mode:',
  };

  String get modeQuality => switch (language) {
    AppLanguage.ko => '고품질',
    AppLanguage.ja => '品質',
    AppLanguage.zh => '高质',
    AppLanguage.en => 'Quality',
  };

  String get modeDiversity => switch (language) {
    AppLanguage.ko => '다양성',
    AppLanguage.ja => '多様性',
    AppLanguage.zh => '多样',
    AppLanguage.en => 'Diversity',
  };

  String get modeVocal => switch (language) {
    AppLanguage.ko => '보컬',
    AppLanguage.ja => 'ボーカル',
    AppLanguage.zh => '人声',
    AppLanguage.en => 'Vocal',
  };

  String get varianceTempLabel => switch (language) {
    AppLanguage.ko => '변화도 (Temp)',
    AppLanguage.ja => '変化度 (Temp)',
    AppLanguage.zh => '变化度 (Temp)',
    AppLanguage.en => 'Variance (Temp)',
  };

  String get guidancePromptLabel => switch (language) {
    AppLanguage.ko => '가이던스 (Prompt)',
    AppLanguage.ja => 'ガイダンス (Prompt)',
    AppLanguage.zh => '引导强度 (Prompt)',
    AppLanguage.en => 'Guidance (Prompt)',
  };

  String get densityLabel => switch (language) {
    AppLanguage.ko => '밀도 (Density)',
    AppLanguage.ja => '密度 (Density)',
    AppLanguage.zh => '密度 (Density)',
    AppLanguage.en => 'Density',
  };

  String get brightnessLabel => switch (language) {
    AppLanguage.ko => '밝기 (Brightness)',
    AppLanguage.ja => '明るさ (Brightness)',
    AppLanguage.zh => '明亮度 (Brightness)',
    AppLanguage.en => 'Brightness',
  };

  String get muteBassChip => switch (language) {
    AppLanguage.ko => '베이스 음소거',
    AppLanguage.ja => 'ベースをミュート',
    AppLanguage.zh => '静音贝斯',
    AppLanguage.en => 'Mute Bass',
  };

  String get muteDrumsChip => switch (language) {
    AppLanguage.ko => '드럼 음소거',
    AppLanguage.ja => 'ドラムをミュート',
    AppLanguage.zh => '静音鼓组',
    AppLanguage.en => 'Mute Drums',
  };

  String get onlyBassAndDrumsChip => switch (language) {
    AppLanguage.ko => '베이스 & 드럼만 재생',
    AppLanguage.ja => 'ベース＆ドラムのみ',
    AppLanguage.zh => '仅贝斯和鼓',
    AppLanguage.en => 'Only Bass & Drums',
  };

  String get autoResetTitle => switch (language) {
    AppLanguage.ko => 'BPM/스케일 변경 시 컨텍스트 자동 초기화',
    AppLanguage.ja => 'BPM/スケール変更時にコンテキストを自動リセット',
    AppLanguage.zh => '更改 BPM/音阶时自动重置上下文',
    AppLanguage.en => 'Auto-reset Context on BPM/Scale change',
  };

  String get autoResetSubtitle => switch (language) {
    AppLanguage.ko =>
      'Lyria 문서 권장: 새로운 템포나 조성을 즉시 반영하려면 resetContext()가 필요합니다.',
    AppLanguage.ja => 'Lyriaドキュメント: 新しいテンポ/キーの適用には resetContext() が必要です。',
    AppLanguage.zh => 'Lyria 文档建议：更改速度或调性后需调用 resetContext() 才能生效。',
    AppLanguage.en =>
      'Lyria docs: BPM/Scale changes require resetContext() for new tempo/key adoption.',
  };

  String get applyConfigButton => switch (language) {
    AppLanguage.ko => '생성 설정 적용',
    AppLanguage.ja => '生成設定を適用',
    AppLanguage.zh => '应用生成配置',
    AppLanguage.en => 'Apply Generation Config',
  };

  // Diagnostics / Logs Section
  String get diagnosticsTitle => switch (language) {
    AppLanguage.ko => '📜 진단 및 스트림 로그',
    AppLanguage.ja => '📜 診断＆ストリームログ',
    AppLanguage.zh => '📜 诊断与流日志',
    AppLanguage.en => '📜 Diagnostics & Stream Logs',
  };

  String get noLogsYet => switch (language) {
    AppLanguage.ko => '아직 로그가 없습니다. 연결하여 스트리밍을 시작하세요.',
    AppLanguage.ja => 'ログはまだありません。接続してストリーミングを開始してください。',
    AppLanguage.zh => '暂无日志。请连接以开始流式传输。',
    AppLanguage.en => 'No logs yet. Connect to start streaming.',
  };

  // SnackBar / Notice Messages
  String get noticeMinPromptRequired => switch (language) {
    AppLanguage.ko => '최소 하나 이상의 가중치 프롬프트가 필요합니다.',
    AppLanguage.ja => '少なくとも1つの重み付きプロンプトが必要です。',
    AppLanguage.zh => '至少需要保留一个加权提示词。',
    AppLanguage.en => 'At least one weighted prompt is required.',
  };

  String get noticeEnterValidPrompt => switch (language) {
    AppLanguage.ko => '유효한 프롬프트 텍스트를 하나 이상 입력하세요.',
    AppLanguage.ja => '有効なプロンプトテキストを1つ以上入力してください。',
    AppLanguage.zh => '请输入至少一个有效的提示词文本。',
    AppLanguage.en => 'Please enter at least one valid prompt text.',
  };

  String noticeAppliedPrompts(int count) => switch (language) {
    AppLanguage.ko => '$count개의 가중치 프롬프트를 Lyria에 적용했습니다.',
    AppLanguage.ja => '$count個の重み付きプロンプトをLyriaに適用しました。',
    AppLanguage.zh => '已向 Lyria 应用 $count 个加权提示词。',
    AppLanguage.en => 'Applied $count weighted prompts to Lyria.',
  };

  String get noticeContextReset => switch (language) {
    AppLanguage.ko => '음악 컨텍스트가 초기화되었습니다. 새로운 변주를 매끄럽게 생성합니다.',
    AppLanguage.ja => '音楽コンテキストをリセットしました。新しいバリエーションをシームレスに生成します。',
    AppLanguage.zh => '音乐上下文已重置。正在无缝生成全新变奏。',
    AppLanguage.en =>
      'Music context reset. Generating fresh variation seamlessly.',
  };

  String get noticeConfigAndAutoReset => switch (language) {
    AppLanguage.ko => '설정을 적용하고 새 템포/스케일에 맞춰 컨텍스트를 자동 초기화했습니다.',
    AppLanguage.ja => '設定を適用し、新しいテンポ/スケールのためにコンテキストを自動リセットしました。',
    AppLanguage.zh => '已应用配置并为新速度/音阶自动重置上下文。',
    AppLanguage.en =>
      'Applied config & auto-reset context for new tempo/scale.',
  };

  String get noticeConfigUpdated => switch (language) {
    AppLanguage.ko => '음악 생성 설정이 업데이트되었습니다.',
    AppLanguage.ja => '音楽生成設定を更新しました。',
    AppLanguage.zh => '音乐生成配置已更新。',
    AppLanguage.en => 'Music generation configuration updated.',
  };

  String noticeAddedTag(String tag) => switch (language) {
    AppLanguage.ko => '프롬프트에 "$tag" 태그를 추가했습니다.',
    AppLanguage.ja => 'プロンプトにタグ「$tag」を追加しました。',
    AppLanguage.zh => '已将标签 "$tag" 添加到可控提示词。',
    AppLanguage.en => 'Added tag "$tag" to steerable prompts.',
  };

  String noticeLiveMusicError(Object error) => switch (language) {
    AppLanguage.ko => '라이브 뮤직 오류: $error',
    AppLanguage.ja => 'ライブ音楽エラー: $error',
    AppLanguage.zh => '实时音乐错误: $error',
    AppLanguage.en => 'Live Music Error: $error',
  };

  String noticeFailedToConnect(Object error) => switch (language) {
    AppLanguage.ko => '연결 실패: $error',
    AppLanguage.ja => '接続に失敗しました: $error',
    AppLanguage.zh => '连接失败: $error',
    AppLanguage.en => 'Failed to connect: $error',
  };
}
