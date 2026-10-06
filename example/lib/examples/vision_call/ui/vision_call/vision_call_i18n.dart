import 'package:example/app_translations.dart';

/// Multilingual translation helper for Live Vision Call Page (ko, en, ja, zh).
class VisionCallI18n {
  final AppLanguage lang;
  const VisionCallI18n(this.lang);

  String get defaultSystemPrompt => switch (lang) {
    AppLanguage.ja =>
      'あなたはリアルタイムカメラと音声でユーザーをサポートする汎用マルチモーダルAIアシスタントです。\n'
          '【言語ルール】\n'
          '1. 最優先ルール: ユーザーが発話した言語を自動認識し、常にユーザーと同じ言語で自然に回答してください。'
          '(ユーザーが日本語で話したら日本語で、韓国語なら韓国語で、英語なら英語で、中国語なら中国語で回答)\n'
          '2. ユーザーが言葉を発していない時や言語が不明確な場合の基本・優先言語は日本語（Japanese）です。\n'
          '3. ユーザーが会話の途中で言語を変更した場合は、柔軟に変更後の言語に合わせて回答してください。\n'
          '【応答スタイル】\n'
          'カメラ映像（物体、文字、コード、周囲の状況）をリアルタイムで観察し、親切かつ簡潔に（1〜2文程度）自然な口語体でリアルタイム音声で回答してください。',
    AppLanguage.ko =>
      '너는 실시간 카메라와 음성으로 사용자를 도와주는 범용 멀티모달 AI 비서야.\n'
          '【언어 규칙】\n'
          '1. 최우선 규칙: 사용자가 말하는 언어를 자동으로 감지하여, 항상 사용자가 말한 언어와 동일한 언어로 자연스럽게 답변해줘. '
          '(사용자가 한국어로 말하면 한국어로, 일본어로 말하면 일본어로, 영어로 말하면 영어로, 중국어로 말하면 중국어로 답변)\n'
          '2. 사용자의 발화가 아직 없거나 언어가 불분명한 경우 기본 설정 언어는 한국어(Korean)야.\n'
          '3. 사용자가 대화 도중 언어를 바꾸면 유연하게 바뀐 언어에 맞춰서 자연스럽게 답변해줘.\n'
          '【응답 스타일】\n'
          '카메라 화면(사물, 텍스트, 코드, 주변 환경 등)을 실시간으로 관찰하고, 친절하고 간결하게(1~2문장 내외) 자연스러운 구어체 음성으로 답변해줘.',
    AppLanguage.zh =>
      '你是一个通过实时摄像头和语音协助用户的全能多模态AI助手。\n'
          '【语言规则】\n'
          '1. 最高优先级规则: 自动识别用户说话所使用的语言，并始终以与用户相同的语言自然回答。'
          '(用户说中文就用中文回答，说日文就用日文回答，说韩文就用韩文回答，说英文就用英文回答)\n'
          '2. 用户未发声或语言不明确时的默认/首选语言为中文（Chinese）。\n'
          '3. 如果用户在对话中切换了语言，请迅速灵活地跟进切换后的语言。\n'
          '【交互风格】\n'
          '实时观察镜头画面（物体、文字、代码、环境），并以亲切、简短（1-2句左右）且自然的口语语音回答。',
    AppLanguage.en =>
      'You are a versatile multimodal AI assistant helping the user via live camera vision and voice.\n'
          '【Language Rules】\n'
          '1. TOP PRIORITY: Automatically detect the language the user is speaking in, and ALWAYS reply in the exact same language as the user. '
          '(If the user speaks Japanese, reply in Japanese; if Korean, reply in Korean; if English, reply in English; if Chinese, reply in Chinese, etc.)\n'
          '2. When the user has not spoken yet or the language is ambiguous, use English as the default preferred language.\n'
          '3. If the user switches languages mid-conversation, dynamically match their new language.\n'
          '【Response Style】\n'
          'Continuously observe objects, text, code, and surroundings in the camera stream, and answer concisely (1 to 2 sentences) in natural spoken conversational speech.',
  };

  String get languageInstruction => switch (lang) {
    AppLanguage.ja =>
      '\n\n[Multilingual Voice Interaction Rule]:\n'
          '- Primary Rule: Always respond in the EXACT SAME language that the user speaks. If the user speaks Japanese, reply in Japanese; if Korean, reply in Korean; if English, reply in English.\n'
          '- Default/Fallback Language: Japanese (日本語) when the user has not spoken yet or language is ambiguous.',
    AppLanguage.ko =>
      '\n\n[Multilingual Voice Interaction Rule]:\n'
          '- Primary Rule: Always respond in the EXACT SAME language that the user speaks. If the user speaks Korean, reply in Korean; if Japanese, reply in Japanese; if English, reply in English.\n'
          '- Default/Fallback Language: Korean (한국어) when the user has not spoken yet or language is ambiguous.',
    AppLanguage.zh =>
      '\n\n[Multilingual Voice Interaction Rule]:\n'
          '- Primary Rule: Always respond in the EXACT SAME language that the user speaks. If the user speaks Chinese, reply in Chinese; if Japanese, reply in Japanese; if English, reply in English.\n'
          '- Default/Fallback Language: Chinese (中文) when the user has not spoken or language is ambiguous.',
    AppLanguage.en =>
      '\n\n[Multilingual Voice Interaction Rule]:\n'
          '- Primary Rule: Always respond in the EXACT SAME language that the user speaks. If the user speaks English, reply in English; if Japanese, reply in Japanese; if Korean, reply in Korean.\n'
          '- Default/Fallback Language: English when the user has not spoken yet or language is ambiguous.',
  };

  String get defaultTitle => switch (lang) {
    AppLanguage.ja => 'Live Vision AI',
    AppLanguage.ko => 'Live Vision AI',
    AppLanguage.zh => 'Live Vision AI',
    AppLanguage.en => 'Live Vision AI',
  };

  String get aiSpeaking => switch (lang) {
    AppLanguage.ja => 'AI 発話中...',
    AppLanguage.ko => 'AI 답변 중...',
    AppLanguage.zh => 'AI 发言中...',
    AppLanguage.en => 'AI Speaking...',
  };

  String get listening => switch (lang) {
    AppLanguage.ja => '聞き取り中...',
    AppLanguage.ko => '듣는 중...',
    AppLanguage.zh => '正在倾听...',
    AppLanguage.en => 'Listening...',
  };

  String liveStatus(String model) => switch (lang) {
    AppLanguage.ja => 'ライブ · $model',
    AppLanguage.ko => '실시간 · $model',
    AppLanguage.zh => '实时 · $model',
    AppLanguage.en => 'Live · $model',
  };

  String get connecting => switch (lang) {
    AppLanguage.ja => '接続中...',
    AppLanguage.ko => '연결 중...',
    AppLanguage.zh => '正在连接...',
    AppLanguage.en => 'Connecting...',
  };

  String get disconnected => switch (lang) {
    AppLanguage.ja => '切断済み',
    AppLanguage.ko => '연결 끊김',
    AppLanguage.zh => '已断开',
    AppLanguage.en => 'Disconnected',
  };

  String get noCameraFound => switch (lang) {
    AppLanguage.ja => '利用可能なカメラが見つかりません。',
    AppLanguage.ko => '사용 가능한 카메라를 찾을 수 없습니다.',
    AppLanguage.zh => '未找到可用摄像头。',
    AppLanguage.en => 'No available cameras found.',
  };

  String cameraPermissionError(Object e) => switch (lang) {
    AppLanguage.ja => 'ブラウザのカメラ権限を許可してください: $e',
    AppLanguage.ko => '브라우저 카메라 권한을 허용해 주세요: $e',
    AppLanguage.zh => '请允许浏览器摄像头权限: $e',
    AppLanguage.en => 'Please grant browser camera permissions: $e',
  };

  String cameraLoadError(Object e) => switch (lang) {
    AppLanguage.ja => 'カメラを読み込めませんでした: $e',
    AppLanguage.ko => '카메라를 불러오지 못했습니다: $e',
    AppLanguage.zh => '无法加载摄像头: $e',
    AppLanguage.en => 'Failed to load camera: $e',
  };

  String cameraInitError(Object e) => switch (lang) {
    AppLanguage.ja => 'カメラの初期化に失敗しました: $e',
    AppLanguage.ko => '카메라 초기화 실패: $e',
    AppLanguage.zh => '摄像头初始化失败: $e',
    AppLanguage.en => 'Camera initialization failed: $e',
  };

  String get cameraPaused => switch (lang) {
    AppLanguage.ja => 'カメラが一時停止中です',
    AppLanguage.ko => '카메라가 일시정지되었습니다',
    AppLanguage.zh => '摄像头已暂停',
    AppLanguage.en => 'Camera is paused',
  };

  String get cameraConnecting => switch (lang) {
    AppLanguage.ja => 'カメラ接続中...',
    AppLanguage.ko => '카메라 연결 중...',
    AppLanguage.zh => '摄像头连接中...',
    AppLanguage.en => 'Connecting camera...',
  };

  String get cameraPreparing => switch (lang) {
    AppLanguage.ja => 'カメラ準備中...',
    AppLanguage.ko => '카메라 준비 중...',
    AppLanguage.zh => '摄像头准备中...',
    AppLanguage.en => 'Preparing camera...',
  };

  String get retryCamera => switch (lang) {
    AppLanguage.ja => 'カメラを再試行',
    AppLanguage.ko => '카메라 다시 시도',
    AppLanguage.zh => '重试摄像头',
    AppLanguage.en => 'Retry Camera',
  };

  String get flipOn => switch (lang) {
    AppLanguage.ja => 'カメラ左右反転ON (文字正常読取モード)',
    AppLanguage.ko => '카메라 좌우 반전 켜짐 (텍스트 정상 읽기 모드)',
    AppLanguage.zh => '摄像头水平翻转已开启 (正常识字模式)',
    AppLanguage.en => 'Camera flip ON (Natural reading mode)',
  };

  String get flipOff => switch (lang) {
    AppLanguage.ja => 'カメラ左右反転OFF (ミラーモード)',
    AppLanguage.ko => '카메라 좌우 반전 꺼짐 (거울 모드)',
    AppLanguage.zh => '摄像头水平翻转已关闭 (镜像模式)',
    AppLanguage.en => 'Camera flip OFF (Mirror mode)',
  };

  String get flipToggleTextOn => switch (lang) {
    AppLanguage.ja => '反転 (文字読取)',
    AppLanguage.ko => '좌우반전 (글자 읽기)',
    AppLanguage.zh => '翻转 (正常识字)',
    AppLanguage.en => 'Flipped (Reading)',
  };

  String get flipToggleTextOff => switch (lang) {
    AppLanguage.ja => 'ミラーモード',
    AppLanguage.ko => '거울 모드',
    AppLanguage.zh => '镜像模式',
    AppLanguage.en => 'Mirror Mode',
  };

  String get apiKeyMissing => switch (lang) {
    AppLanguage.ja => 'Gemini APIキーが設定されていません。',
    AppLanguage.ko => 'Gemini API 키가 설정되지 않았습니다.',
    AppLanguage.zh => '未设置 Gemini API 密钥。',
    AppLanguage.en => 'Gemini API key is not configured.',
  };

  String connectionError(Object error) => switch (lang) {
    AppLanguage.ja => '⚠️ 接続切断 / エラー: $error',
    AppLanguage.ko => '⚠️ 연결 끊김 / 오류: $error',
    AppLanguage.zh => '⚠️ 连接断开 / 错误: $error',
    AppLanguage.en => '⚠️ Disconnected / Error: $error',
  };

  String connectionClosed(String reason) => switch (lang) {
    AppLanguage.ja => '接続終了: $reason',
    AppLanguage.ko => '연결 종료: $reason',
    AppLanguage.zh => '连接已关闭: $reason',
    AppLanguage.en => 'Session closed: $reason',
  };

  String connectionFailed(Object error) => switch (lang) {
    AppLanguage.ja => '⚠️ 接続失敗: $error\n(右上の ⚙️ 設定をご確認ください)',
    AppLanguage.ko => '⚠️ 연결 실패: $error\n(상단 ⚙️ 설정을 확인하세요)',
    AppLanguage.zh => '⚠️ 连接失败: $error\n(请检查顶部 ⚙️ 设置)',
    AppLanguage.en => '⚠️ Connection failed: $error\n(Check ⚙️ settings above)',
  };

  String get micPermissionRequired => switch (lang) {
    AppLanguage.ja => '⚠️ マイク権限が必要です。システムのプライバシー設定でアプリを許可してください。',
    AppLanguage.ko =>
      '⚠️ 마이크 권한이 필요합니다. [시스템 설정 > 개인정보 보호 및 보안 > 마이크]에서 앱을 허용해 주세요.',
    AppLanguage.zh => '⚠️ 需要麦克风权限。请在系统设置中允许应用访问麦克风。',
    AppLanguage.en =>
      '⚠️ Microphone permission required. Please allow access in system settings.',
  };

  String get transcriptWaiting => switch (lang) {
    AppLanguage.ja => '対話が始まると、ここにリアルタイム字幕が表示されます。',
    AppLanguage.ko => '대화가 시작되면 실시간 자막이 여기에 표시됩니다.',
    AppLanguage.zh => '对话开始后，实时字幕将显示在此处。',
    AppLanguage.en =>
      'Live transcripts will appear here once conversation starts.',
  };

  String get tabletopWaiting => switch (lang) {
    AppLanguage.ja => 'リアルタイム対話と Vision AI の分析がここに表示されます。',
    AppLanguage.ko => '실시간 대화와 Vision AI 분석이 여기에 표시됩니다.',
    AppLanguage.zh => '实时对话与 Vision AI 分析将显示在此处。',
    AppLanguage.en =>
      'Live conversation and Vision AI analysis will appear here.',
  };

  String get liveTranscriptTitle => switch (lang) {
    AppLanguage.ja => 'リアルタイム文字起こし',
    AppLanguage.ko => '실시간 자막 & 대화 기록',
    AppLanguage.zh => '实时文字记录',
    AppLanguage.en => 'Live Transcript',
  };

  String messagesCount(int count) => switch (lang) {
    AppLanguage.ja => '$count 件のメッセージ',
    AppLanguage.ko => '$count개 메시지',
    AppLanguage.zh => '$count 条消息',
    AppLanguage.en => '$count messages',
  };

  String get defaultMic => switch (lang) {
    AppLanguage.ja => 'デフォルトマイク (System Default)',
    AppLanguage.ko => '기본 마이크 (System Default)',
    AppLanguage.zh => '系统默认麦克风 (System Default)',
    AppLanguage.en => 'System Default Microphone',
  };

  String micSelectorTooltip(String label) => switch (lang) {
    AppLanguage.ja => 'マイク入力デバイス選択 ($label)',
    AppLanguage.ko => '마이크 입력 장치 선택 ($label)',
    AppLanguage.zh => '选择麦克风输入设备 ($label)',
    AppLanguage.en => 'Select Microphone Device ($label)',
  };

  String get switchCameraTooltip => switch (lang) {
    AppLanguage.ja => 'カメラ切り替え',
    AppLanguage.ko => '카메라 전환',
    AppLanguage.zh => '切换摄像头',
    AppLanguage.en => 'Switch Camera',
  };

  String get settingsTooltip => switch (lang) {
    AppLanguage.ja => 'APIキー・モデル設定',
    AppLanguage.ko => 'API 키 및 모델 설정',
    AppLanguage.zh => 'API 密钥及模型设置',
    AppLanguage.en => 'API Key & Model Settings',
  };

  String get cameraToggleTooltip => switch (lang) {
    AppLanguage.ja => 'カメラ ON/OFF',
    AppLanguage.ko => '카메라 켜기/끄기',
    AppLanguage.zh => '摄像头 开/关',
    AppLanguage.en => 'Camera On/Off',
  };

  String get micToggleTooltip => switch (lang) {
    AppLanguage.ja => 'マイクミュート切替',
    AppLanguage.ko => '마이크 음소거 전환',
    AppLanguage.zh => '麦克风静音切换',
    AppLanguage.en => 'Microphone Mute',
  };

  String get endSessionTooltip => switch (lang) {
    AppLanguage.ja => '通話を終了',
    AppLanguage.ko => '통화 종료',
    AppLanguage.zh => '结束通话',
    AppLanguage.en => 'End Session',
  };
}
