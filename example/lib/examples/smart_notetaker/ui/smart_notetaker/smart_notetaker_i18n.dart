import 'package:example/app_translations.dart';

/// 4-language (EN, KO, JA, ZH) localization helper for Live Smart NoteTaker.
class SmartNotetakerI18n {
  final AppLanguage lang;
  const SmartNotetakerI18n(this.lang);

  static SmartNotetakerI18n get current =>
      SmartNotetakerI18n(AppLanguageController.instance.currentLanguage);

  // AppBar
  String get appTitle => switch (lang) {
    AppLanguage.ko => 'Live Smart NoteTaker',
    AppLanguage.ja => 'Live Smart NoteTaker',
    AppLanguage.zh => 'Live Smart NoteTaker',
    AppLanguage.en => 'Live Smart NoteTaker',
  };

  String get wrapUpTooltip => switch (lang) {
    AppLanguage.ko => 'AI 최종 요약본 정리',
    AppLanguage.ja => 'AI最終要約を生成',
    AppLanguage.zh => '生成AI最终总结',
    AppLanguage.en => 'Generate AI Executive Summary',
  };

  String get copyAllTooltip => switch (lang) {
    AppLanguage.ko => '마크다운 전체 복사',
    AppLanguage.ja => 'Markdown全文をコピー',
    AppLanguage.zh => '复制全部Markdown',
    AppLanguage.en => 'Copy All Markdown',
  };

  String get clearNotesTooltip => switch (lang) {
    AppLanguage.ko => '새 노트 시작 (초기화)',
    AppLanguage.ja => '新しいノートを開始（初期化）',
    AppLanguage.zh => '开始新笔记（重置）',
    AppLanguage.en => 'Start New Note (Reset)',
  };

  // SessionStatusBar
  String get recordingAndTranslating => switch (lang) {
    AppLanguage.ko => '녹음 및 실시간 통번역 중',
    AppLanguage.ja => '録音＆リアルタイム翻訳中',
    AppLanguage.zh => '正在录音与实时翻译',
    AppLanguage.en => 'RECORDING & TRANSLATING',
  };

  String get readyToRecord => switch (lang) {
    AppLanguage.ko => '녹음 대기 중',
    AppLanguage.ja => '録音待機中',
    AppLanguage.zh => '准备录音',
    AppLanguage.en => 'READY TO RECORD',
  };

  String get stopShort => switch (lang) {
    AppLanguage.ko => '종료',
    AppLanguage.ja => '終了',
    AppLanguage.zh => '停止',
    AppLanguage.en => 'Stop',
  };

  String get startShort => switch (lang) {
    AppLanguage.ko => '녹음 시작',
    AppLanguage.ja => '録音開始',
    AppLanguage.zh => '开始录音',
    AppLanguage.en => 'Record',
  };

  String get stopSession => switch (lang) {
    AppLanguage.ko => '세션 종료',
    AppLanguage.ja => 'セッション終了',
    AppLanguage.zh => '结束会话',
    AppLanguage.en => 'Stop Session',
  };

  String get startRecordingNote => switch (lang) {
    AppLanguage.ko => '노트 녹음 시작',
    AppLanguage.ja => 'ノート録音開始',
    AppLanguage.zh => '开始笔记录音',
    AppLanguage.en => 'Start Note Recording',
  };

  // MobileTabBar
  String liveSpeechTab(int count) => switch (lang) {
    AppLanguage.ko => '실시간 발화 ($count)',
    AppLanguage.ja => 'リアルタイム発話 ($count)',
    AppLanguage.zh => '实时发言 ($count)',
    AppLanguage.en => 'Live Speech ($count)',
  };

  String get smartNotesTab => switch (lang) {
    AppLanguage.ko => '스마트 노트',
    AppLanguage.ja => 'スマートノート',
    AppLanguage.zh => '智能笔记',
    AppLanguage.en => 'Smart Notes',
  };

  String tasksTab(int count) => switch (lang) {
    AppLanguage.ko => '할일 ($count)',
    AppLanguage.ja => 'タスク ($count)',
    AppLanguage.zh => '待办 ($count)',
    AppLanguage.en => 'Tasks ($count)',
  };

  // LiveTimelinePanel
  String get timelineHeader => switch (lang) {
    AppLanguage.ko => '실시간 발화 & 동시 번역',
    AppLanguage.ja => 'リアルタイム発話＆同時翻訳',
    AppLanguage.zh => '实时发言与同声传译',
    AppLanguage.en => 'Live Speech & Simultaneous Translation',
  };

  String speechTurnsCount(int count) => switch (lang) {
    AppLanguage.ko => '$count개 발화',
    AppLanguage.ja => '$count件の発話',
    AppLanguage.zh => '$count条发言',
    AppLanguage.en => '$count turns',
  };

  String get timelineEmptyHint => switch (lang) {
    AppLanguage.ko => '녹음을 시작하면 회의/강의 발화가\n실시간으로 텍스트화 및 번역됩니다.',
    AppLanguage.ja => '録音を開始すると、会議や講義の発話が\nリアルタイムで文字起こし・翻訳されます。',
    AppLanguage.zh => '开始录音后，会议/讲座发言将\n实时转写为文本并进行翻译。',
    AppLanguage.en =>
      'Start recording to transcribe and translate\nmeeting or lecture speech in real time.',
  };

  // SmartNotesBoard
  String get smartNotesHeader => switch (lang) {
    AppLanguage.ko => 'AI 실시간 구조화 노트',
    AppLanguage.ja => 'AIリアルタイム構造化ノート',
    AppLanguage.zh => 'AI实时结构化笔记',
    AppLanguage.en => 'AI Real-Time Structured Notes',
  };

  String get copyMarkdownButton => switch (lang) {
    AppLanguage.ko => 'Markdown 복사',
    AppLanguage.ja => 'Markdownコピー',
    AppLanguage.zh => '复制Markdown',
    AppLanguage.en => 'Copy Markdown',
  };

  // ActionItemsPanel
  String get actionItemsHeader => switch (lang) {
    AppLanguage.ko => '액션 아이템 & 할 일 체크리스트',
    AppLanguage.ja => 'アクションアイテム＆ToDoチェックリスト',
    AppLanguage.zh => '待办事项与任务清单',
    AppLanguage.en => 'Action Items & Task Checklist',
  };

  String completedCount(int done, int total) => switch (lang) {
    AppLanguage.ko => '$done / $total 완료',
    AppLanguage.ja => '$done / $total 完了',
    AppLanguage.zh => '已完成 $done / $total',
    AppLanguage.en => '$done / $total done',
  };

  String get actionItemsEmptyHint => switch (lang) {
    AppLanguage.ko => '감지된 액션 아이템이 없습니다.\n회의 중 과제나 할 일이 언급되면 자동 추가됩니다.',
    AppLanguage.ja => '検出されたアクションアイテムはありません。\n会議中に課題やタスクが言及されると自動追加されます。',
    AppLanguage.zh => '暂未检测到待办事项。\n会议中提及的任务或待办将自动添加。',
    AppLanguage.en =>
      'No action items detected yet.\nTasks mentioned during the session will be added automatically.',
  };

  // HighlightsSummaryBar
  String highlightsSummary(int keyCount, int actionCount) => switch (lang) {
    AppLanguage.ko => '핵심 요약 $keyCount건 · 액션 아이템 $actionCount건 감지됨',
    AppLanguage.ja => '重要ポイント $keyCount件・アクションアイテム $actionCount件を検出',
    AppLanguage.zh => '已检测到 $keyCount 条核心要点 · $actionCount 条待办事项',
    AppLanguage.en =>
      '$keyCount Key Takeaways · $actionCount Action Items detected',
  };

  String get viewTasksButton => switch (lang) {
    AppLanguage.ko => '할 일 목록 보기 ➔',
    AppLanguage.ja => 'タスク一覧を見る ➔',
    AppLanguage.zh => '查看待办列表 ➔',
    AppLanguage.en => 'View Tasks ➔',
  };

  // AudioDeviceSelectorButton
  String inputDeviceFallback(String id) => switch (lang) {
    AppLanguage.ko => '입력 장치 ($id)',
    AppLanguage.ja => '入力デバイス ($id)',
    AppLanguage.zh => '输入设备 ($id)',
    AppLanguage.en => 'Input Device ($id)',
  };

  String get defaultMicLabel => switch (lang) {
    AppLanguage.ko => '기본 마이크 (System Default)',
    AppLanguage.ja => 'システム既定のマイク',
    AppLanguage.zh => '系统默认麦克风',
    AppLanguage.en => 'System Default Microphone',
  };

  String get audioDeviceTooltip => switch (lang) {
    AppLanguage.ko => '오디오 입력 장치 선택 (BlackHole / 마이크)',
    AppLanguage.ja => '音声入力デバイスを選択 (BlackHole / マイク)',
    AppLanguage.zh => '选择音频输入设备 (BlackHole / 麦克风)',
    AppLanguage.en => 'Select Audio Input Device (BlackHole / Mic)',
  };

  String get systemAudioSuffix => switch (lang) {
    AppLanguage.ko => '시스템 오디오',
    AppLanguage.ja => 'システム音声',
    AppLanguage.zh => '系统音频',
    AppLanguage.en => 'System Audio',
  };

  // FoldablePill
  String get tabletopLabel => switch (lang) {
    AppLanguage.ko => '테이블탑',
    AppLanguage.ja => 'テーブルトップ',
    AppLanguage.zh => '立式模式',
    AppLanguage.en => 'TABLETOP',
  };

  String get duoLabel => switch (lang) {
    AppLanguage.ko => '듀얼스크린',
    AppLanguage.ja => 'デュアル',
    AppLanguage.zh => '双屏',
    AppLanguage.en => 'DUO',
  };

  String get foldLabel => switch (lang) {
    AppLanguage.ko => '폴더블',
    AppLanguage.ja => '折りたたみ',
    AppLanguage.zh => '折叠屏',
    AppLanguage.en => 'FOLD',
  };

  // InterimBubble & SpeechBubble
  String get listeningLive => switch (lang) {
    AppLanguage.ko => '실시간 청취 중...',
    AppLanguage.ja => 'リアルタイム聴取中...',
    AppLanguage.zh => '正在实时倾听...',
    AppLanguage.en => 'Listening live...',
  };

  String get speakerUtterance => switch (lang) {
    AppLanguage.ko => '발표자 발화',
    AppLanguage.ja => '発言者の発話',
    AppLanguage.zh => '发言人发言',
    AppLanguage.en => 'Speaker',
  };

  // ViewModel & Prompts
  String get apiKeyMissing => switch (lang) {
    AppLanguage.ko => 'Gemini API 키가 설정되지 않았습니다.',
    AppLanguage.ja => 'Gemini APIキーが設定されていません。',
    AppLanguage.zh => '未配置 Gemini API 密钥。',
    AppLanguage.en => 'Gemini API key is not configured.',
  };

  String liveSessionError(Object err) => switch (lang) {
    AppLanguage.ko => 'Live 세션 오류: $err',
    AppLanguage.ja => 'Liveセッションエラー: $err',
    AppLanguage.zh => 'Live 会话错误: $err',
    AppLanguage.en => 'Live session error: $err',
  };

  String sessionClosed(int? code, String reason) => switch (lang) {
    AppLanguage.ko => '세션 종료 ($code): $reason',
    AppLanguage.ja => 'セッション終了 ($code): $reason',
    AppLanguage.zh => '会话已结束 ($code): $reason',
    AppLanguage.en => 'Session closed ($code): $reason',
  };

  String sessionStartFailed(Object err) => switch (lang) {
    AppLanguage.ko => '세션 시작 실패: $err',
    AppLanguage.ja => 'セッション開始失敗: $err',
    AppLanguage.zh => '启动会话失败: $err',
    AppLanguage.en => 'Failed to start session: $err',
  };

  String get micPermissionRequired => switch (lang) {
    AppLanguage.ko => '마이크 권한이 필요합니다.',
    AppLanguage.ja => 'マイクの権限が必要です。',
    AppLanguage.zh => '需要麦克风权限。',
    AppLanguage.en => 'Microphone permission is required.',
  };

  String audioRecordStartError(Object err) => switch (lang) {
    AppLanguage.ko => '오디오 녹음 시작 오류: $err',
    AppLanguage.ja => '音声録音開始エラー: $err',
    AppLanguage.zh => '启动音频录制失败: $err',
    AppLanguage.en => 'Failed to start audio recording: $err',
  };

  String get noContentToSummarize => switch (lang) {
    AppLanguage.ko => '요약할 회의/강의 내용이 없습니다.',
    AppLanguage.ja => '要約する会議・講義の内容がありません。',
    AppLanguage.zh => '没有可总结的会议/讲座内容。',
    AppLanguage.en => 'No meeting or lecture content to summarize.',
  };

  String get wrapUpRequested => switch (lang) {
    AppLanguage.ko => 'AI에게 최종 요약 정리를 요청했습니다...',
    AppLanguage.ja => 'AIに最終要約の作成をリクエストしました...',
    AppLanguage.zh => '已向AI请求生成最终总结报告...',
    AppLanguage.en => 'Requested final executive summary from AI...',
  };

  String get noNotesToCopy => switch (lang) {
    AppLanguage.ko => '복사할 노트 내용이 없습니다.',
    AppLanguage.ja => 'コピーするノート内容がありません。',
    AppLanguage.zh => '没有可复制的笔记内容。',
    AppLanguage.en => 'No note content to copy.',
  };

  String get notesCopied => switch (lang) {
    AppLanguage.ko => '스마트 마크다운 노트가 클립보드에 복사되었습니다!',
    AppLanguage.ja => 'スマートMarkdownノートをクリップボードにコピーしました！',
    AppLanguage.zh => '智能 Markdown 笔记已复制到剪贴板！',
    AppLanguage.en => 'Smart Markdown notes copied to clipboard!',
  };

  String get wrapUpSummaryPrompt => switch (lang) {
    AppLanguage.ko =>
      '지금까지 청취한 전체 내용을 바탕으로 [최종 결론 요약 (Executive Summary)]과 [핵심 액션 아이템]을 명확한 마크다운 리포트로 최종 정리해줘.',
    AppLanguage.ja =>
      'これまでに聞き取った全内容に基づき、[最終要約 (Executive Summary)] と [重要アクションアイテム] を明確なMarkdownレポートとしてまとめてください。',
    AppLanguage.zh =>
      '请根据目前听到的全部内容，整理出一份包含【最终总结 (Executive Summary)】和【核心待办事项】的清晰 Markdown 报告。',
    AppLanguage.en =>
      'Based on everything heard so far, please compile a clear final Markdown report with [Executive Summary] and [Key Action Items].',
  };

  String get initialNoteGuide => switch (lang) {
    AppLanguage.ko =>
      '# 🎙️ 실시간 AI 회의 및 강의 노트\n'
          '> **Gemini 3.8 Live**가 실시간 오디오를 청취하여 '
          '실시간 통번역 및 핵심 메모를 자동으로 구조화합니다.\n\n'
          '### 💡 안내\n'
          '- **노트 녹음 시작** 버튼을 누르면 발표자의 발화가 실시간으로 분석됩니다.\n'
          '- 외국어 발화는 선택한 언어로 즉시 번역되며, 주요 논점과 액션 아이템이 자동 추출됩니다.\n',
    AppLanguage.ja =>
      '# 🎙️ リアルタイムAI会議・講義ノート\n'
          '> **Gemini 3.8 Live**がリアルタイム音声を聞き取り、'
          '同時通訳と重要メモを自動的に構造化します。\n\n'
          '### 💡 ご案内\n'
          '- **ノート録音開始**ボタンを押すと、発言者の発話がリアルタイムで分析されます。\n'
          '- 外国語の発話は選択した言語に即座に翻訳され、要点とアクションアイテムが自動抽出されます。\n',
    AppLanguage.zh =>
      '# 🎙️ 实时 AI 会议与讲座笔记\n'
          '> **Gemini 3.8 Live** 实时倾听音频流，'
          '自动完成同声传译并结构化整理核心笔记。\n\n'
          '### 💡 使用指南\n'
          '- 点击 **开始笔记录音** 按钮，即可实时分析发言人的讲话内容。\n'
          '- 外语发言将立即翻译为您选择的目标语言，并自动提取核心要点与待办事项。\n',
    AppLanguage.en =>
      '# 🎙️ Real-Time AI Meeting & Lecture Notes\n'
          '> **Gemini 3.8 Live** listens to live audio, '
          'translates speech simultaneously, and structures key notes automatically.\n\n'
          '### 💡 Getting Started\n'
          '- Tap **Start Note Recording** to analyze speaker utterances in real time.\n'
          '- Foreign speech is translated into your target language on the fly, with key takeaways and action items extracted automatically.\n',
  };
}
