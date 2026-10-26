import 'package:example/app_translations.dart';

/// Multilingual translation helper for Live Translation Page (en, ko, ja, zh).
class TranslationI18n {
  final AppLanguage lang;
  const TranslationI18n(this.lang);

  static TranslationI18n get current =>
      TranslationI18n(AppLanguageController.instance.currentLanguage);

  String get appBarTitle => switch (lang) {
    AppLanguage.ko => 'Live Translation (동시통역)',
    AppLanguage.ja => 'Live Translation (同時通訳)',
    AppLanguage.zh => 'Live Translation (同声传译)',
    AppLanguage.en => 'Live Translation (Interpreter)',
  };

  String get voiceOutputOnTooltip => switch (lang) {
    AppLanguage.ko => '번역 음성 출력 켜짐 (클릭하여 음소거)',
    AppLanguage.ja => '翻訳音声出力 ON (クリックでミュート)',
    AppLanguage.zh => '翻译语音输出已开启 (点击静音)',
    AppLanguage.en => 'Translated Voice Output ON (Click to mute)',
  };

  String get voiceOutputOffTooltip => switch (lang) {
    AppLanguage.ko => '번역 음성 출력 꺼짐 (클릭하여 켜기)',
    AppLanguage.ja => '翻訳音声出力 OFF (クリックでON)',
    AppLanguage.zh => '翻译语音输出已关闭 (点击开启)',
    AppLanguage.en => 'Translated Voice Output OFF (Click to unmute)',
  };

  String get echoPreventOnTooltip => switch (lang) {
    AppLanguage.ko => '에코 방지 켜짐 (스피커 출력 중 마이크 자동 차단으로 무한반복 방지)',
    AppLanguage.ja => 'エコー防止 ON (スピーカー出力中のマイク自動遮断でループ防止)',
    AppLanguage.zh => '回声消除已开启 (扬声器播放时自动屏蔽麦克风以防无限循环)',
    AppLanguage.en =>
      'Echo Prevention ON (Auto-mutes mic during speaker playback)',
  };

  String get echoPreventOffTooltip => switch (lang) {
    AppLanguage.ko => '에코 방지 꺼짐 (헤드셋/이어폰 착용 시)',
    AppLanguage.ja => 'エコー防止 OFF (ヘッドセット・イヤホン着用時)',
    AppLanguage.zh => '回声消除已关闭 (佩戴耳机时使用)',
    AppLanguage.en => 'Echo Prevention OFF (Use when wearing headphones)',
  };

  String get switchToSingleChatTooltip => switch (lang) {
    AppLanguage.ko => '단일 채팅 모드로 전환',
    AppLanguage.ja => 'シングルチャットモードに切替',
    AppLanguage.zh => '切换为单屏聊天模式',
    AppLanguage.en => 'Switch to Single Chat Mode',
  };

  String get switchToDualFlipTooltip => switch (lang) {
    AppLanguage.ko => '양방향 대면 모드(Dual Flip)로 전환',
    AppLanguage.ja => '双方向対面モード(Dual Flip)に切替',
    AppLanguage.zh => '切换为双向面对面模式 (Dual Flip)',
    AppLanguage.en => 'Switch to Face-to-Face Dual Flip Mode',
  };

  String get settingsTooltip => switch (lang) {
    AppLanguage.ko => '설정',
    AppLanguage.ja => '設定',
    AppLanguage.zh => '设置',
    AppLanguage.en => 'Settings',
  };

  String get tabletopModeTooltip => switch (lang) {
    AppLanguage.ko => '테이블탑 / 플렉스 모드',
    AppLanguage.ja => 'テーブルトップ / フレックスモード',
    AppLanguage.zh => '桌面 / 悬停折叠模式',
    AppLanguage.en => 'Tabletop / Flex Mode',
  };

  String get dualScreenTooltip => switch (lang) {
    AppLanguage.ko => '듀얼스크린 감지됨',
    AppLanguage.ja => 'デュアルスクリーン検出',
    AppLanguage.zh => '检测到双屏设备',
    AppLanguage.en => 'Dual-Screen Detected',
  };

  String get foldableWideTooltip => switch (lang) {
    AppLanguage.ko => '폴더블 와이드 감지됨',
    AppLanguage.ja => '折りたたみワイド画面検出',
    AppLanguage.zh => '检测到折叠宽屏',
    AppLanguage.en => 'Foldable Wide Screen Detected',
  };

  String get myLanguageLabel => switch (lang) {
    AppLanguage.ko => '내 언어:',
    AppLanguage.ja => '自分の言語:',
    AppLanguage.zh => '我的语言:',
    AppLanguage.en => 'My Language:',
  };

  String get swapLanguagesTooltip => switch (lang) {
    AppLanguage.ko => '내 언어와 상대방 언어 맞바꾸기',
    AppLanguage.ja => '自分の言語と相手の言語を入れ替え',
    AppLanguage.zh => '互换我的语言与对方语言',
    AppLanguage.en => 'Swap my language and partner language',
  };

  String get partnerLanguageLabel => switch (lang) {
    AppLanguage.ko => '상대방 언어:',
    AppLanguage.ja => '相手の言語:',
    AppLanguage.zh => '对方语言:',
    AppLanguage.en => 'Partner Language:',
  };

  String get tabletopFaceToFaceMode => switch (lang) {
    AppLanguage.ko => '테이블 대면 모드',
    AppLanguage.ja => 'テーブル対面モード',
    AppLanguage.zh => '桌面面对面模式',
    AppLanguage.en => 'Face-to-Face Mode',
  };

  String get standardChatMode => switch (lang) {
    AppLanguage.ko => '일반 채팅 모드',
    AppLanguage.ja => '通常チャットモード',
    AppLanguage.zh => '标准聊天模式',
    AppLanguage.en => 'Standard Chat Mode',
  };

  String get voiceOutputOn => switch (lang) {
    AppLanguage.ko => '음성 출력 ON',
    AppLanguage.ja => '音声出力 ON',
    AppLanguage.zh => '语音输出 ON',
    AppLanguage.en => 'Voice Out ON',
  };

  String get voiceOutputOff => switch (lang) {
    AppLanguage.ko => '음성 출력 OFF',
    AppLanguage.ja => '音声出力 OFF',
    AppLanguage.zh => '语音输出 OFF',
    AppLanguage.en => 'Voice Out OFF',
  };

  String get echoPreventionOn => switch (lang) {
    AppLanguage.ko => '에코방지 ON',
    AppLanguage.ja => 'エコー防止 ON',
    AppLanguage.zh => '防回声 ON',
    AppLanguage.en => 'Echo Guard ON',
  };

  String get echoPreventionOff => switch (lang) {
    AppLanguage.ko => '에코방지 OFF',
    AppLanguage.ja => 'エコー防止 OFF',
    AppLanguage.zh => '防回声 OFF',
    AppLanguage.en => 'Echo Guard OFF',
  };

  String partnerSplitLabel(String targetLangName) => switch (lang) {
    AppLanguage.ko => '상대방: $targetLangName (180°)',
    AppLanguage.ja => '相手側: $targetLangName (180°)',
    AppLanguage.zh => '对方: $targetLangName (180°)',
    AppLanguage.en => 'Partner: $targetLangName (180°)',
  };

  String myScreenSplitLabel(String myLangName) => switch (lang) {
    AppLanguage.ko => '내 화면: $myLangName',
    AppLanguage.ja => '自分の画面: $myLangName',
    AppLanguage.zh => '我的屏幕: $myLangName',
    AppLanguage.en => 'My Screen: $myLangName',
  };

  String myPanelHeader(String myLangName) => switch (lang) {
    AppLanguage.ko => '내 화면 ($myLangName 발화 및 통역 기록)',
    AppLanguage.ja => '自分の画面 ($myLangName 発話・通訳履歴)',
    AppLanguage.zh => '我的屏幕 ($myLangName 发言与翻译记录)',
    AppLanguage.en => 'My Screen ($myLangName Speech & Transcript)',
  };

  String myPanelConnectedEmpty(String myLangName, String targetLangName) =>
      switch (lang) {
        AppLanguage.ko =>
          '마이크로 $myLangName로 말씀하세요.\n내 음성과 상대방 번역 내용($targetLangName)이 실시간으로 기록됩니다.',
        AppLanguage.ja =>
          'マイクに向かって $myLangName で話してください。\n自分の音声と相手への翻訳($targetLangName)がリアルタイムで記録されます。',
        AppLanguage.zh =>
          '请对着麦克风用 $myLangName 说话。\n您的语音与翻译内容 ($targetLangName) 将实时记录在此。',
        AppLanguage.en =>
          'Speak in $myLangName into the microphone.\nYour speech and translations ($targetLangName) will be recorded in real time.',
      };

  String get myPanelDisconnectedEmpty => switch (lang) {
    AppLanguage.ko => '하단 통역 시작 버튼을 누르면 실시간 통역이 시작됩니다.',
    AppLanguage.ja => '下の「通訳開始」ボタンを押すとリアルタイム通訳が始まります。',
    AppLanguage.zh => '点击底部的“开始翻译”按钮即可启动实时同传。',
    AppLanguage.en =>
      'Press "Start Interpreter" below to begin real-time translation.',
  };

  String mySpeechBubbleLabel(String myLangName) => switch (lang) {
    AppLanguage.ko => '🎤 내 발화 ($myLangName)',
    AppLanguage.ja => '🎤 自分の発話 ($myLangName)',
    AppLanguage.zh => '🎤 我的发言 ($myLangName)',
    AppLanguage.en => '🎤 My Speech ($myLangName)',
  };

  String translatedBubbleLabel(String targetLangName) => switch (lang) {
    AppLanguage.ko => '🌐 번역문 ($targetLangName)',
    AppLanguage.ja => '🌐 翻訳文 ($targetLangName)',
    AppLanguage.zh => '🌐 译文 ($targetLangName)',
    AppLanguage.en => '🌐 Translation ($targetLangName)',
  };

  String partnerPanelHeader(String targetLangName) => switch (lang) {
    AppLanguage.ko => '상대방 화면 (For Partner): $targetLangName',
    AppLanguage.ja => '相手用画面 (For Partner): $targetLangName',
    AppLanguage.zh => '对方屏幕 (For Partner): $targetLangName',
    AppLanguage.en => 'For Partner: $targetLangName',
  };

  String partnerPanelConnectedEmpty(String targetLangName) => switch (lang) {
    AppLanguage.ko =>
      '듣는 중 (Listening)...\n번역된 내용($targetLangName)이 맞은편 상대방을 위해 여기에 표시됩니다.',
    AppLanguage.ja =>
      '聞き取り中 (Listening)...\n翻訳結果($targetLangName)が相手向けにここに表示されます。',
    AppLanguage.zh => '正在倾听 (Listening)...\n翻译结果 ($targetLangName) 将在此处向对方显示。',
    AppLanguage.en =>
      'Listening...\nTranslations ($targetLangName) will appear here for your partner.',
  };

  String get partnerPanelDisconnectedEmpty => switch (lang) {
    AppLanguage.ko => '통역 세션 시작 대기 중 (Waiting for session to start).',
    AppLanguage.ja => '通訳セッション開始待機中 (Waiting for session to start).',
    AppLanguage.zh => '等待翻译会话开始 (Waiting for session to start).',
    AppLanguage.en => 'Waiting for session to start.',
  };

  String standardChatConnectedEmpty(String myLangName, String targetLangName) =>
      switch (lang) {
        AppLanguage.ko =>
          '마이크로 $myLangName로 말하기를 시작하세요.\n원문과 번역문($targetLangName)이 실시간 음성/자막으로 출력됩니다.',
        AppLanguage.ja =>
          'マイクで $myLangName を話し始めてください。\n原文と翻訳文($targetLangName)がリアルタイム音声・字幕で出力されます。',
        AppLanguage.zh =>
          '请开始用 $myLangName 对着麦克风说话。\n原文和译文 ($targetLangName) 将以实时语音和字幕输出。',
        AppLanguage.en =>
          'Start speaking in $myLangName.\nOriginal speech and translations ($targetLangName) will stream in real-time voice and captions.',
      };

  String get standardChatDisconnectedEmpty => switch (lang) {
    AppLanguage.ko => '하단의 "통역 시작" 버튼을 눌러 실시간 번역 세션을 연결하세요.',
    AppLanguage.ja => '下の「通訳開始」ボタンを押してリアルタイム翻訳セッションに接続してください。',
    AppLanguage.zh => '请点击底部的“开始翻译”按钮连接实时翻译会话。',
    AppLanguage.en =>
      'Press "Start Interpreter" below to connect the live translation session.',
  };

  String myVoiceChatLabel(String myLangName) => switch (lang) {
    AppLanguage.ko => '내 음성 ($myLangName)',
    AppLanguage.ja => '自分の音声 ($myLangName)',
    AppLanguage.zh => '我的语音 ($myLangName)',
    AppLanguage.en => 'My Voice ($myLangName)',
  };

  String translationResultChatLabel(String targetLangName) => switch (lang) {
    AppLanguage.ko => '통역 결과 ($targetLangName)',
    AppLanguage.ja => '通訳結果 ($targetLangName)',
    AppLanguage.zh => '翻译结果 ($targetLangName)',
    AppLanguage.en => 'Translation ($targetLangName)',
  };

  String get statusSpeaking => switch (lang) {
    AppLanguage.ko => '🔊 실시간 음성 출력 중 (에코 방지 대기)',
    AppLanguage.ja => '🔊 翻訳音声をリアルタイム出力中 (エコー防止待機)',
    AppLanguage.zh => '🔊 正在实时输出翻译语音 (回声保护等待中)',
    AppLanguage.en => '🔊 Playing translated speech (Echo guard active)',
  };

  String get statusTranslating => switch (lang) {
    AppLanguage.ko => '실시간 동시통역 중 (말씀하시면 즉시 번역됩니다)',
    AppLanguage.ja => 'リアルタイム同時通訳中 (話すと即座に翻訳されます)',
    AppLanguage.zh => '实时同声传译中 (开口即刻翻译)',
    AppLanguage.en => 'Live Interpreting (Speak now for instant translation)',
  };

  String get statusMicPaused => switch (lang) {
    AppLanguage.ko => '마이크 일시 정지됨',
    AppLanguage.ja => 'マイク一時停止中',
    AppLanguage.zh => '麦克风已暂停',
    AppLanguage.en => 'Microphone paused',
  };

  String get statusConnecting => switch (lang) {
    AppLanguage.ko => 'Live Translate 서버 연결 중...',
    AppLanguage.ja => 'Live Translate サーバーに接続中...',
    AppLanguage.zh => '正在连接 Live Translate 服务器...',
    AppLanguage.en => 'Connecting to Live Translate server...',
  };

  String get statusReady => switch (lang) {
    AppLanguage.ko => '준비 완료 (통역 시작을 누르세요)',
    AppLanguage.ja => '準備完了 (「通訳開始」を押してください)',
    AppLanguage.zh => '准备就绪 (请点击“开始翻译”)',
    AppLanguage.en => 'Ready (Press Start Interpreter)',
  };

  String get pauseMicTooltip => switch (lang) {
    AppLanguage.ko => '마이크 일시중지',
    AppLanguage.ja => 'マイク一時停止',
    AppLanguage.zh => '暂停麦克风',
    AppLanguage.en => 'Pause Microphone',
  };

  String get resumeMicTooltip => switch (lang) {
    AppLanguage.ko => '마이크 재개',
    AppLanguage.ja => 'マイク再開',
    AppLanguage.zh => '恢复麦克风',
    AppLanguage.en => 'Resume Microphone',
  };

  String get stopTranslation => switch (lang) {
    AppLanguage.ko => '통역 종료',
    AppLanguage.ja => '通訳終了',
    AppLanguage.zh => '结束翻译',
    AppLanguage.en => 'Stop',
  };

  String get connectingLabel => switch (lang) {
    AppLanguage.ko => '연결 중...',
    AppLanguage.ja => '接続中...',
    AppLanguage.zh => '连接中...',
    AppLanguage.en => 'Connecting...',
  };

  String get startTranslation => switch (lang) {
    AppLanguage.ko => '통역 시작',
    AppLanguage.ja => '通訳開始',
    AppLanguage.zh => '开始翻译',
    AppLanguage.en => 'Start',
  };

  String get apiKeyNotConfigured => switch (lang) {
    AppLanguage.ko => 'Gemini API 키가 설정되지 않았습니다.',
    AppLanguage.ja => 'Gemini APIキーが設定されていません。',
    AppLanguage.zh => '未配置 Gemini API 密钥。',
    AppLanguage.en => 'Gemini API key is not configured.',
  };

  String sessionError(Object error) => switch (lang) {
    AppLanguage.ko => '세션 오류: $error',
    AppLanguage.ja => 'セッションエラー: $error',
    AppLanguage.zh => '会话错误: $error',
    AppLanguage.en => 'Session error: $error',
  };

  String connectionFailed(Object error) => switch (lang) {
    AppLanguage.ko => '연결 실패: $error',
    AppLanguage.ja => '接続失敗: $error',
    AppLanguage.zh => '连接失败: $error',
    AppLanguage.en => 'Connection failed: $error',
  };

  String get micPermissionRequired => switch (lang) {
    AppLanguage.ko => '마이크 권한이 필요합니다.',
    AppLanguage.ja => 'マイク権限が必要です。',
    AppLanguage.zh => '需要麦克风权限。',
    AppLanguage.en => 'Microphone permission is required.',
  };
}
