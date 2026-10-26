import 'package:example/app_translations.dart';

/// Multilingual translation helper for Live Media Subtitle Page (en, ko, ja, zh).
class MediaSubtitleI18n {
  final AppLanguage lang;
  const MediaSubtitleI18n(this.lang);

  static MediaSubtitleI18n get current =>
      MediaSubtitleI18n(AppLanguageController.instance.currentLanguage);

  String get appBarTitle => switch (lang) {
    AppLanguage.ko => 'Live Media Subtitles (미디어 자막)',
    AppLanguage.ja => 'Live Media Subtitles (メディア字幕)',
    AppLanguage.zh => 'Live Media Subtitles (媒体实时字幕)',
    AppLanguage.en => 'Live Media Subtitles',
  };

  String get copyAllSubtitlesTooltip => switch (lang) {
    AppLanguage.ko => '자막 전체 복사',
    AppLanguage.ja => '字幕をすべてコピー',
    AppLanguage.zh => '复制全部字幕',
    AppLanguage.en => 'Copy All Subtitles',
  };

  String get clearSubtitlesTooltip => switch (lang) {
    AppLanguage.ko => '자막 초기화',
    AppLanguage.ja => '字幕をクリア',
    AppLanguage.zh => '清空字幕',
    AppLanguage.en => 'Clear Subtitles',
  };

  String get liveSubtitlesOn => switch (lang) {
    AppLanguage.ko => 'LIVE SUBTITLES ON',
    AppLanguage.ja => 'LIVE SUBTITLES ON',
    AppLanguage.zh => 'LIVE SUBTITLES ON',
    AppLanguage.en => 'LIVE SUBTITLES ON',
  };

  String get standby => switch (lang) {
    AppLanguage.ko => 'STANDBY',
    AppLanguage.ja => 'STANDBY',
    AppLanguage.zh => 'STANDBY',
    AppLanguage.en => 'STANDBY',
  };

  String get openVideoInBrowser => switch (lang) {
    AppLanguage.ko => '브라우저에서 영상 열기',
    AppLanguage.ja => 'ブラウザで動画を開く',
    AppLanguage.zh => '在浏览器中打开视频',
    AppLanguage.en => 'Open Video in Browser',
  };

  String get playVideoAndStartSubtitles => switch (lang) {
    AppLanguage.ko => '영상 재생 & 실시간 자막 시작',
    AppLanguage.ja => '動画再生 & リアルタイム字幕開始',
    AppLanguage.zh => '播放视频并开启实时字幕',
    AppLanguage.en => 'Play Video & Start Live Subtitles',
  };

  String get streamingRealtimeAudio => switch (lang) {
    AppLanguage.ko => '실시간 음성을 스트리밍 통역 중입니다...',
    AppLanguage.ja => 'リアルタイム音声をストリーミング通訳中です...',
    AppLanguage.zh => '正在实时流式翻译音频...',
    AppLanguage.en => 'Streaming real-time audio translation...',
  };

  String get startStreamingForSubtitles => switch (lang) {
    AppLanguage.ko => '스트리밍을 시작하면 실시간 통역 자막이 여기에 표시됩니다.',
    AppLanguage.ja => 'ストリーミングを開始するとリアルタイム翻訳字幕がここに表示されます。',
    AppLanguage.zh => '开始流式传输后，实时翻译字幕将显示在此处。',
    AppLanguage.en =>
      'Start streaming to display real-time translated subtitles here.',
  };

  String get statusStreamingNarrow => switch (lang) {
    AppLanguage.ko => '초저지연 번역 스트리밍 중',
    AppLanguage.ja => '超低遅延翻訳ストリーミング中',
    AppLanguage.zh => '超低延迟翻译流式传输中',
    AppLanguage.en => 'Ultra-low-latency translation streaming',
  };

  String get statusStreamingWide => switch (lang) {
    AppLanguage.ko => '오디오 수음 및 초저지연 번역 스트리밍 중',
    AppLanguage.ja => '音声収音および超低遅延翻訳ストリーミング中',
    AppLanguage.zh => '正在拾音并进行超低延迟翻译流传输',
    AppLanguage.en => 'Capturing audio & streaming low-latency translation',
  };

  String get statusConnectedWaiting => switch (lang) {
    AppLanguage.ko => '연결됨 (오디오 대기 중)',
    AppLanguage.ja => '接続済み (音声待機中)',
    AppLanguage.zh => '已连接 (等待音频中)',
    AppLanguage.en => 'Connected (Waiting for audio)',
  };

  String get statusOffline => switch (lang) {
    AppLanguage.ko => 'Live Translate (gemini-3.5) 자막기 오프라인',
    AppLanguage.ja => 'Live Translate (gemini-3.5) 字幕オフライン',
    AppLanguage.zh => 'Live Translate (gemini-3.5) 字幕机离线',
    AppLanguage.en => 'Live Translate (gemini-3.5) Subtitler Offline',
  };

  String get stopSubtitles => switch (lang) {
    AppLanguage.ko => '자막 정지',
    AppLanguage.ja => '字幕停止',
    AppLanguage.zh => '停止字幕',
    AppLanguage.en => 'Stop Subtitles',
  };

  String get startLiveSubtitles => switch (lang) {
    AppLanguage.ko => '실시간 자막 시작',
    AppLanguage.ja => 'リアルタイム字幕開始',
    AppLanguage.zh => '开启实时字幕',
    AppLanguage.en => 'Start Live Subtitles',
  };

  String get audioInputDeviceLabel => switch (lang) {
    AppLanguage.ko => '오디오 입력 장치:',
    AppLanguage.ja => '音声入力デバイス:',
    AppLanguage.zh => '音频输入设备:',
    AppLanguage.en => 'Audio Input Device:',
  };

  String get hudOptionsLabel => switch (lang) {
    AppLanguage.ko => 'HUD 옵션:',
    AppLanguage.ja => 'HUD オプション:',
    AppLanguage.zh => 'HUD 选项:',
    AppLanguage.en => 'HUD Options:',
  };

  String get showOriginalTextChip => switch (lang) {
    AppLanguage.ko => '원문 함께 보기',
    AppLanguage.ja => '原文も表示',
    AppLanguage.zh => '同时显示原文',
    AppLanguage.en => 'Show Original',
  };

  String get floatingSubtitleChip => switch (lang) {
    AppLanguage.ko => '플로팅 자막',
    AppLanguage.ja => 'フローティング字幕',
    AppLanguage.zh => '悬浮字幕',
    AppLanguage.en => 'Floating HUD',
  };

  String get decreaseFontSizeTooltip => switch (lang) {
    AppLanguage.ko => '글자 크기 축소',
    AppLanguage.ja => '文字サイズ縮小',
    AppLanguage.zh => '缩小字号',
    AppLanguage.en => 'Decrease Font Size',
  };

  String get increaseFontSizeTooltip => switch (lang) {
    AppLanguage.ko => '글자 크기 확대',
    AppLanguage.ja => '文字サイズ拡大',
    AppLanguage.zh => '放大字号',
    AppLanguage.en => 'Increase Font Size',
  };

  String inputDeviceFallback(String id) => switch (lang) {
    AppLanguage.ko => '입력 장치 ($id)',
    AppLanguage.ja => '入力デバイス ($id)',
    AppLanguage.zh => '输入设备 ($id)',
    AppLanguage.en => 'Input Device ($id)',
  };

  String get systemDefaultMic => switch (lang) {
    AppLanguage.ko => '기본 마이크 (System Default)',
    AppLanguage.ja => 'デフォルトマイク (System Default)',
    AppLanguage.zh => '系统默认麦克风 (System Default)',
    AppLanguage.en => 'System Default Microphone',
  };

  String get selectAudioInputDeviceTooltip => switch (lang) {
    AppLanguage.ko => '오디오 입력 장치 선택 (BlackHole / 마이크)',
    AppLanguage.ja => '音声入力デバイス選択 (BlackHole / マイク)',
    AppLanguage.zh => '选择音频输入设备 (BlackHole / 麦克风)',
    AppLanguage.en => 'Select Audio Input Device (BlackHole / Mic)',
  };

  String blackHoleSystemAudio(String label) => switch (lang) {
    AppLanguage.ko => '🔈 $label (시스템 오디오)',
    AppLanguage.ja => '🔈 $label (システム音声)',
    AppLanguage.zh => '🔈 $label (系统音频)',
    AppLanguage.en => '🔈 $label (System Audio)',
  };

  String get videoAndControlsTab => switch (lang) {
    AppLanguage.ko => '영상 & 컨트롤',
    AppLanguage.ja => '動画 & コントロール',
    AppLanguage.zh => '视频与控制',
    AppLanguage.en => 'Video & Controls',
  };

  String subtitleTimelineTab(int count) => switch (lang) {
    AppLanguage.ko => '자막 타임라인 ($count)',
    AppLanguage.ja => '字幕タイムライン ($count)',
    AppLanguage.zh => '字幕时间轴 ($count)',
    AppLanguage.en => 'Subtitle Timeline ($count)',
  };

  String get playYoutubeCaptureAudio => switch (lang) {
    AppLanguage.ko => '유튜브 재생 (오디오 캡처)',
    AppLanguage.ja => 'YouTube再生 (音声キャプチャ)',
    AppLanguage.zh => '播放 YouTube (音频捕获)',
    AppLanguage.en => 'Play YouTube (Capture Audio)',
  };

  String get playYoutubeHint => switch (lang) {
    AppLanguage.ko =>
      '💡 클릭 시 브라우저에서 유튜브가 열리며, BlackHole 2ch를 통해 영상 소리가 실시간 번역 자막으로 변환됩니다.',
    AppLanguage.ja =>
      '💡 クリックするとブラウザでYouTubeが開き、BlackHole 2ch経由で動画の音声がリアルタイム翻訳字幕に変換されます。',
    AppLanguage.zh => '💡 点击后将在浏览器中打开 YouTube，并通过 BlackHole 2ch 将视频声音实时转换为翻译字幕。',
    AppLanguage.en =>
      '💡 Opens YouTube in your browser and translates video audio into live subtitles via BlackHole 2ch.',
  };

  String get recommendedVideoPresets => switch (lang) {
    AppLanguage.ko => '추천 비디오 프리셋:',
    AppLanguage.ja => 'おすすめ動画プリセット:',
    AppLanguage.zh => '推荐视频预设:',
    AppLanguage.en => 'Recommended Video Presets:',
  };

  String presetTitle(String videoId, String fallback) {
    switch (videoId) {
      case 'jV1vkHv4zq8':
        return switch (lang) {
          AppLanguage.ko => 'Google Gemini AI 발표',
          AppLanguage.ja => 'Google Gemini AI 発表',
          AppLanguage.zh => 'Google Gemini AI 发布',
          AppLanguage.en => 'Google Gemini AI Launch',
        };
      case 'UF8uR6Z6KLc':
        return switch (lang) {
          AppLanguage.ko => 'Steve Jobs 스탠포드 연설',
          AppLanguage.ja => 'スティーブ・ジョブズ 講演',
          AppLanguage.zh => '乔布斯斯坦福演讲',
          AppLanguage.en => 'Steve Jobs Speech',
        };
      default:
        return fallback;
    }
  }

  String get urlFieldHint => switch (lang) {
    AppLanguage.ko => 'YouTube 링크 또는 Video ID 입력 (e.g. XEzRZ33sJCE)',
    AppLanguage.ja => 'YouTubeリンクまたはVideo IDを入力 (例: XEzRZ33sJCE)',
    AppLanguage.zh => '输入 YouTube 链接或 Video ID (如 XEzRZ33sJCE)',
    AppLanguage.en => 'Enter YouTube link or Video ID (e.g. XEzRZ33sJCE)',
  };

  String get loadButton => switch (lang) {
    AppLanguage.ko => '로드',
    AppLanguage.ja => '読込',
    AppLanguage.zh => '加载',
    AppLanguage.en => 'Load',
  };

  String get liveSubtitleTimelineTitle => switch (lang) {
    AppLanguage.ko => '실시간 자막 타임라인',
    AppLanguage.ja => 'リアルタイム字幕タイムライン',
    AppLanguage.zh => '实时字幕时间轴',
    AppLanguage.en => 'Live Subtitle Timeline',
  };

  String sentencesCount(int count) => switch (lang) {
    AppLanguage.ko => '$count개 문장',
    AppLanguage.ja => '$count 文',
    AppLanguage.zh => '$count 句',
    AppLanguage.en => '$count sentences',
  };

  String get emptyTranscriptPlaceholder => switch (lang) {
    AppLanguage.ko => '수신된 자막 기록이 없습니다.\n실시간 자막을 시작하면 타임라인이 누적됩니다.',
    AppLanguage.ja => '受信された字幕履歴がありません。\nリアルタイム字幕を開始するとタイムラインが蓄積されます。',
    AppLanguage.zh => '暂无字幕记录。\n开启实时字幕后将在此累计时间轴。',
    AppLanguage.en =>
      'No subtitle history yet.\nStart live subtitles to populate the timeline.',
  };

  String get liveTranslatingBadge => switch (lang) {
    AppLanguage.ko => 'LIVE 통역 중',
    AppLanguage.ja => 'LIVE 通訳中',
    AppLanguage.zh => 'LIVE 翻译中',
    AppLanguage.en => 'LIVE TRANSLATING',
  };

  String videoLoadedNotice(String id) => switch (lang) {
    AppLanguage.ko => 'YouTube 영상이 로드되었습니다: $id',
    AppLanguage.ja => 'YouTube動画が読み込まれました: $id',
    AppLanguage.zh => '已加载 YouTube 视频: $id',
    AppLanguage.en => 'YouTube video loaded: $id',
  };

  String get invalidYoutubeUrlNotice => switch (lang) {
    AppLanguage.ko => '올바른 YouTube URL 또는 11자리 비디오 ID를 입력하세요.',
    AppLanguage.ja => '正しいYouTube URLまたは11桁の動画IDを入力してください。',
    AppLanguage.zh => '请输入有效的 YouTube URL 或 11 位视频 ID。',
    AppLanguage.en =>
      'Please enter a valid YouTube URL or 11-character Video ID.',
  };

  String playingInBrowserNotice(String url) => switch (lang) {
    AppLanguage.ko =>
      'YouTube 영상을 브라우저에서 재생합니다: $url\nBlackHole을 통해 오디오가 실시간 자막으로 번역됩니다.',
    AppLanguage.ja =>
      'YouTube動画をブラウザで再生します: $url\nBlackHole経由で音声がリアルタイム字幕に翻訳されます。',
    AppLanguage.zh =>
      '正在浏览器中播放 YouTube 视频: $url\n音频将通过 BlackHole 实时翻译为字幕。',
    AppLanguage.en =>
      'Playing YouTube video in browser: $url\nAudio will be translated into live subtitles via BlackHole.',
  };

  String get apiKeyNotConfigured => switch (lang) {
    AppLanguage.ko => 'Gemini API 키가 설정되지 않았습니다.',
    AppLanguage.ja => 'Gemini APIキーが設定されていません。',
    AppLanguage.zh => '未配置 Gemini API 密钥。',
    AppLanguage.en => 'Gemini API key is not configured.',
  };

  String liveApiError(Object err) => switch (lang) {
    AppLanguage.ko => 'Live API 오류: $err',
    AppLanguage.ja => 'Live APIエラー: $err',
    AppLanguage.zh => 'Live API 错误: $err',
    AppLanguage.en => 'Live API error: $err',
  };

  String liveConnectionClosed(int? code, String reason) => switch (lang) {
    AppLanguage.ko => 'Live 연결 종료 ($code): $reason',
    AppLanguage.ja => 'Live接続終了 ($code): $reason',
    AppLanguage.zh => 'Live 连接已关闭 ($code): $reason',
    AppLanguage.en => 'Live connection closed ($code): $reason',
  };

  String connectionFailed(Object error) => switch (lang) {
    AppLanguage.ko => '연결 실패: $error',
    AppLanguage.ja => '接続失敗: $error',
    AppLanguage.zh => '连接失败: $error',
    AppLanguage.en => 'Connection failed: $error',
  };

  String get voiceSpeechFallback => switch (lang) {
    AppLanguage.ko => '(음성 발화)',
    AppLanguage.ja => '(音声発話)',
    AppLanguage.zh => '(语音发言)',
    AppLanguage.en => '(Voice speech)',
  };

  String get micPermissionRequired => switch (lang) {
    AppLanguage.ko => '마이크/오디오 캡처 권한이 필요합니다.',
    AppLanguage.ja => 'マイク/音声キャプチャ権限が必要です。',
    AppLanguage.zh => '需要麦克风/音频捕获权限。',
    AppLanguage.en => 'Microphone / audio capture permission is required.',
  };

  String audioStreamingStartError(Object error) => switch (lang) {
    AppLanguage.ko => '오디오 스트리밍 시작 오류: $error',
    AppLanguage.ja => '音声ストリーミング開始エラー: $error',
    AppLanguage.zh => '启动音频流失败: $error',
    AppLanguage.en => 'Failed to start audio streaming: $error',
  };

  String get noSubtitlesToCopy => switch (lang) {
    AppLanguage.ko => '복사할 자막 기록이 없습니다.',
    AppLanguage.ja => 'コピーする字幕履歴がありません。',
    AppLanguage.zh => '没有可复制的字幕记录。',
    AppLanguage.en => 'No subtitle history to copy.',
  };

  String get subtitlesCopiedToClipboard => switch (lang) {
    AppLanguage.ko => '전체 자막이 클립보드에 복사되었습니다.',
    AppLanguage.ja => 'すべての字幕がクリップボードにコピーされました。',
    AppLanguage.zh => '全部字幕已复制到剪贴板。',
    AppLanguage.en => 'All subtitles copied to clipboard.',
  };
}
