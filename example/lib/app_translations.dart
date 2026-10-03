import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported application languages.
enum AppLanguage {
  en(code: 'en', name: 'English', flag: '🇺🇸'),
  ko(code: 'ko', name: '한국어', flag: '🇰🇷'),
  ja(code: 'ja', name: '日本語', flag: '🇯🇵'),
  zh(code: 'zh', name: '中文', flag: '🇨🇳');

  final String code;
  final String name;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.flag,
  });

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.en,
    );
  }
}

/// Global language state controller with persistent storage.
class AppLanguageController extends ChangeNotifier {
  static final AppLanguageController instance = AppLanguageController._();
  AppLanguageController._();

  static const String _prefKey = 'gemini_live_example_language';

  AppLanguage _currentLanguage = AppLanguage.en;

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get currentLocale => Locale(_currentLanguage.code);
  AppTranslations get t => AppTranslations.of(_currentLanguage);

  /// Initializes the stored language preference. Defaults to English.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null) {
        _currentLanguage = AppLanguage.fromCode(savedCode);
      } else {
        _currentLanguage = AppLanguage.en;
      }
      notifyListeners();
    } catch (_) {
      _currentLanguage = AppLanguage.en;
    }
  }

  /// Changes the current application language and persists the choice.
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language.code);
    } catch (_) {}
  }
}

/// Global translation repository for English, Korean, Japanese, and Chinese.
class AppTranslations {
  final AppLanguage language;

  const AppTranslations._(this.language);

  static AppTranslations of(AppLanguage language) {
    return AppTranslations._(language);
  }

  static AppTranslations get current =>
      AppTranslations.of(AppLanguageController.instance.currentLanguage);

  // Common UI
  String get appTitle {
    switch (language) {
      case AppLanguage.ko:
        return 'Gemini Live API 예제 모음';
      case AppLanguage.ja:
        return 'Gemini Live API サンプル集';
      case AppLanguage.zh:
        return 'Gemini Live API 示例套件';
      case AppLanguage.en:
        return 'Gemini Live API Examples';
    }
  }

  String get settingsTooltip {
    switch (language) {
      case AppLanguage.ko:
        return 'API 키 및 오디오 설정';
      case AppLanguage.ja:
        return 'APIキーと音声設定';
      case AppLanguage.zh:
        return 'API密钥与音频设置';
      case AppLanguage.en:
        return 'API Key & Audio Settings';
    }
  }

  String get languageTooltip {
    switch (language) {
      case AppLanguage.ko:
        return '언어 변경 (Language)';
      case AppLanguage.ja:
        return '言語の変更 (Language)';
      case AppLanguage.zh:
        return '切换语言 (Language)';
      case AppLanguage.en:
        return 'Switch Language';
    }
  }

  String get viewModeAuto {
    switch (language) {
      case AppLanguage.ko:
        return '자동 반응형';
      case AppLanguage.ja:
        return '自動レイアウト';
      case AppLanguage.zh:
        return '自适应布局';
      case AppLanguage.en:
        return 'Auto Layout';
    }
  }

  String get viewModeList {
    switch (language) {
      case AppLanguage.ko:
        return '리스트 뷰';
      case AppLanguage.ja:
        return 'リスト表示';
      case AppLanguage.zh:
        return '列表视图';
      case AppLanguage.en:
        return 'List View';
    }
  }

  String get viewModeGrid {
    switch (language) {
      case AppLanguage.ko:
        return '그리드 뷰';
      case AppLanguage.ja:
        return 'グリッド表示';
      case AppLanguage.zh:
        return '网格视图';
      case AppLanguage.en:
        return 'Grid View';
    }
  }

  String get viewModeFoldable {
    switch (language) {
      case AppLanguage.ko:
        return '폴더블 / 2화면 뷰';
      case AppLanguage.ja:
        return '折りたたみ / 2画面';
      case AppLanguage.zh:
        return '折叠屏 / 双屏视图';
      case AppLanguage.en:
        return 'Foldable / Dual-Screen';
    }
  }

  String get foldableDetected {
    switch (language) {
      case AppLanguage.ko:
        return '폴더블 / 듀얼스크린 감지됨';
      case AppLanguage.ja:
        return '折りたたみ/2画面デバイスを検出';
      case AppLanguage.zh:
        return '检测到折叠屏 / 双屏设备';
      case AppLanguage.en:
        return 'Foldable / Dual-Screen Active';
    }
  }

  String get tabletopMode {
    switch (language) {
      case AppLanguage.ko:
        return '테이블탑 / 플렉스 모드';
      case AppLanguage.ja:
        return 'テーブルトップ / フレックスモード';
      case AppLanguage.zh:
        return '立式交互 / 悬停折叠模式';
      case AppLanguage.en:
        return 'Tabletop / Flex Mode';
    }
  }

  String get featuredServices {
    switch (language) {
      case AppLanguage.ko:
        return '주요 라이브 서비스';
      case AppLanguage.ja:
        return '注目のライブサービス';
      case AppLanguage.zh:
        return '精选实时服务';
      case AppLanguage.en:
        return 'Featured Live Services';
    }
  }

  String get basicExamples {
    switch (language) {
      case AppLanguage.ko:
        return '기본 예제';
      case AppLanguage.ja:
        return '基本サンプル';
      case AppLanguage.zh:
        return '基础示例';
      case AppLanguage.en:
        return 'Basic Examples';
    }
  }

  String get newFeatures {
    switch (language) {
      case AppLanguage.ko:
        return '신규 기능 데모';
      case AppLanguage.ja:
        return '新機能デモ';
      case AppLanguage.zh:
        return '新特性演示';
      case AppLanguage.en:
        return 'New Features';
    }
  }

  String get setupHeader {
    switch (language) {
      case AppLanguage.ko:
        return '설정 및 환경 구성';
      case AppLanguage.ja:
        return '環境設定とセットアップ';
      case AppLanguage.zh:
        return '环境配置与设置';
      case AppLanguage.en:
        return 'Setup & Configuration';
    }
  }

  String get capabilitiesHeader {
    switch (language) {
      case AppLanguage.ko:
        return '지원하는 핵심 기능 목록';
      case AppLanguage.ja:
        return 'サポートされる主要機能一覧';
      case AppLanguage.zh:
        return '支持的核心功能清单';
      case AppLanguage.en:
        return 'Supported Live API Capabilities';
    }
  }

  String get apiKeyMissingWarning {
    switch (language) {
      case AppLanguage.ko:
        return 'Gemini API 키가 설정되지 않았습니다. Settings에서 먼저 입력하세요.';
      case AppLanguage.ja:
        return 'Gemini APIキーが設定されていません。設定で先に入力してください。';
      case AppLanguage.zh:
        return '未配置Gemini API密钥。请先在“设置”中输入。';
      case AppLanguage.en:
        return 'Gemini API key is not configured. Please enter it in Settings first.';
    }
  }

  String get apiKeyConfigTitle {
    switch (language) {
      case AppLanguage.ko:
        return 'API 키 구성 상태';
      case AppLanguage.ja:
        return 'APIキー構成ステータス';
      case AppLanguage.zh:
        return 'API密钥配置状态';
      case AppLanguage.en:
        return 'API Key Configuration';
    }
  }

  String get statusLabel {
    switch (language) {
      case AppLanguage.ko:
        return '상태:';
      case AppLanguage.ja:
        return '状態:';
      case AppLanguage.zh:
        return '状态:';
      case AppLanguage.en:
        return 'Status:';
    }
  }

  String configuredStatus(String masked) {
    switch (language) {
      case AppLanguage.ko:
        return '구성됨 ($masked)';
      case AppLanguage.ja:
        return '設定済み ($masked)';
      case AppLanguage.zh:
        return '已配置 ($masked)';
      case AppLanguage.en:
        return 'Configured ($masked)';
    }
  }

  String get notConfiguredStatus {
    switch (language) {
      case AppLanguage.ko:
        return '미설정 (API 키 필요)';
      case AppLanguage.ja:
        return '未設定 (APIキーが必要)';
      case AppLanguage.zh:
        return '未配置 (需要API密钥)';
      case AppLanguage.en:
        return 'Not configured';
    }
  }

  String get apiKeySettingsHelp {
    switch (language) {
      case AppLanguage.ko:
        return '앱 우측 상단의 Settings 메뉴에서 언제든지 API 키를 변경할 수 있습니다.';
      case AppLanguage.ja:
        return '右上の「設定」メニューからいつでもAPIキーを変更できます。';
      case AppLanguage.zh:
        return '您可以随时点击右上角的“设置”菜单修改API密钥。';
      case AppLanguage.en:
        return 'You can enter or update your Gemini API key anytime from the Settings menu.';
    }
  }

  String get getApiKeyLink {
    switch (language) {
      case AppLanguage.ko:
        return 'Google AI Studio에서 API 키 발급받기';
      case AppLanguage.ja:
        return 'Google AI StudioでAPIキーを取得する';
      case AppLanguage.zh:
        return '从Google AI Studio获取API密钥';
      case AppLanguage.en:
        return 'Get your API key from Google AI Studio';
    }
  }

  String get openSettingsButton {
    switch (language) {
      case AppLanguage.ko:
        return '설정 열기';
      case AppLanguage.ja:
        return '設定を開く';
      case AppLanguage.zh:
        return '打开设置';
      case AppLanguage.en:
        return 'Open Settings';
    }
  }

  // Demo Cards
  String get liveTranslationTitle {
    switch (language) {
      case AppLanguage.ko:
        return '🌐 Live Translation (양방향 대면 번역)';
      case AppLanguage.ja:
        return '🌐 Live Translation (双方向対面翻訳)';
      case AppLanguage.zh:
        return '🌐 Live Translation (双向面对面翻译)';
      case AppLanguage.en:
        return '🌐 Live Translation (Two-Way Face-to-Face)';
    }
  }

  String get liveTranslationSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return '실시간 음성 대 음성 통역 · 테이블 대면 플립 뷰 (180도 회전 자막) · gemini-3.5-live-translate-preview';
      case AppLanguage.ja:
        return 'リアルタイム音声通訳・対面180度反転字幕・gemini-3.5-live-translate-preview';
      case AppLanguage.zh:
        return '实时语音对语音翻译 · 面对面180度翻转字幕 · gemini-3.5-live-translate-preview';
      case AppLanguage.en:
        return 'Real-time speech-to-speech translation · Face-to-face 180° flipped view · gemini-3.5-live-translate-preview';
    }
  }

  String get liveMediaSubtitleTitle {
    switch (language) {
      case AppLanguage.ko:
        return '🎬 Live Media Subtitles (유튜브/미디어 실시간 번역 자막)';
      case AppLanguage.ja:
        return '🎬 Live Media Subtitles (YouTube/メディアリアルタイム翻訳)';
      case AppLanguage.zh:
        return '🎬 Live Media Subtitles (YouTube与媒体实时字幕)';
      case AppLanguage.en:
        return '🎬 Live Media Subtitles (YouTube & Media HUD)';
    }
  }

  String get liveMediaSubtitleSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return 'YouTube 영상 링크 재생 · 시스템/마이크 오디오 실시간 번역 자막 HUD · gemini-3.8-live';
      case AppLanguage.ja:
        return 'YouTube動画再生・システム/マイク音声リアルタイム翻訳HUD・gemini-3.8-live';
      case AppLanguage.zh:
        return 'YouTube视频播放 · 系统/麦克风实时双语HUD字幕 · gemini-3.8-live';
      case AppLanguage.en:
        return 'YouTube video playback · Real-time system/mic translated subtitle HUD · gemini-3.8-live';
    }
  }

  String get liveSmartNoteTitle {
    switch (language) {
      case AppLanguage.ko:
        return '📝 Live AI Smart NoteTaker (실시간 강의/회의 통번역 노트)';
      case AppLanguage.ja:
        return '📝 Live AI Smart NoteTaker (リアルタイム講義・会議ノート)';
      case AppLanguage.zh:
        return '📝 Live AI Smart NoteTaker (实时讲座与会议速记)';
      case AppLanguage.en:
        return '📝 Live AI Smart NoteTaker (Lecture & Meeting Notes)';
    }
  }

  String get liveSmartNoteSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return '실시간 음성 전사(STT) · 동시 번역 · 마크다운 실시간 구조화 노트 및 액션 아이템 추출';
      case AppLanguage.ja:
        return 'リアルタイムSTT文字起こし・同時翻訳・Markdown構造化ノートとアクションアイテム抽出';
      case AppLanguage.zh:
        return '实时语音转写(STT) · 同声传译 · Markdown实时结构化笔记与待办提取';
      case AppLanguage.en:
        return 'Real-time STT transcription · Simultaneous translation · Markdown structured notes & action items';
    }
  }

  String get liveVisionAgentTitle {
    switch (language) {
      case AppLanguage.ko:
        return '✨ Live Vision Agent (비전 음성 대화)';
      case AppLanguage.ja:
        return '✨ Live Vision Agent (ビジョン音声対話)';
      case AppLanguage.zh:
        return '✨ Live Vision Agent (实时视觉语音助手)';
      case AppLanguage.en:
        return '✨ Live Vision Agent';
    }
  }

  String get liveVisionAgentSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return '실시간 카메라 뷰파인더 & 마이크 양방향 스트리밍 · 저지연 음성 대화 응답';
      case AppLanguage.ja:
        return 'リアルタイムカメラとマイク双方向ストリーミング・超低遅延音声対話';
      case AppLanguage.zh:
        return '实时摄像头取景与麦克风双向流式传输 · 超低延迟音频交互';
      case AppLanguage.en:
        return 'Real-time camera viewfinder & mic streaming with low-latency audio response';
    }
  }

  String get liveMusicStudioTitle {
    switch (language) {
      case AppLanguage.ko:
        return '🎵 Live Music Studio (Lyria 실시간 음원 생성)';
      case AppLanguage.ja:
        return '🎵 Live Music Studio (Lyriaリアルタイム音楽生成)';
      case AppLanguage.zh:
        return '🎵 Live Music Studio (Lyria实时音乐生成)';
      case AppLanguage.en:
        return '🎵 Live Music Studio (Lyria RealTime)';
    }
  }

  String get liveMusicStudioSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return 'BidiGenerateMusic 양방향 스트리밍 · 가중치 프롬프트 실시간 제어 · BPM/스케일 믹싱 & 48kHz 실시간 PCM 오디오';
      case AppLanguage.ja:
        return '双方向音楽ストリーミング・加重プロンプトリアルタイム制御・BPM/スケールミキシング・48kHz PCM再生';
      case AppLanguage.zh:
        return '双向音乐流式传输 · 权重提示词实时控制 · BPM/调式混音 · 48kHz实时PCM音频';
      case AppLanguage.en:
        return 'Bidirectional music streaming · Real-time weighted prompt steering · BPM & scale mixing · 48kHz PCM playback';
    }
  }

  String get proDjConsoleTitle {
    switch (language) {
      case AppLanguage.ko:
        return '🎧 Pro DJ Console (프로 DJ 콘솔)';
      case AppLanguage.ja:
        return '🎧 Pro DJ Console (プロDJコンソール)';
      case AppLanguage.zh:
        return '🎧 Pro DJ Console (专业DJ控制台)';
      case AppLanguage.en:
        return '🎧 Pro DJ Console';
    }
  }

  String get proDjConsoleSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return '플래그십 DJ 하드웨어 콘솔 UI · 듀얼 조그 휠 회전 · 3밴드 EQ 노브 & 듀얼 스테레오 VU 미터 · 8구 RGB 핫 큐 패드';
      case AppLanguage.ja:
        return 'DJハードウェアUI・デュアル回転ジョグホイール・3バンドEQ・ステレオVUメーター・8個のRGBホットキュー';
      case AppLanguage.zh:
        return '旗舰DJ硬件控制台UI · 双旋转慢动盘 · 3段EQ与立体声VU表 · 8个RGB热指示点';
      case AppLanguage.en:
        return 'Flagship DJ hardware console UI · Dual rotating jog wheels · 3-band EQ & stereo VU meters · 8 RGB hot cues';
    }
  }

  String get djMidiBoxTitle {
    switch (language) {
      case AppLanguage.ko:
        return '🎛️ DJ MIDI Box (AI Studio Prompt DJ)';
      case AppLanguage.ja:
        return '🎛️ DJ MIDI Box (AI Studio Prompt DJ)';
      case AppLanguage.zh:
        return '🎛️ DJ MIDI Box (AI Studio Prompt DJ)';
      case AppLanguage.en:
        return '🎛️ DJ MIDI Box (AI Studio Prompt DJ)';
    }
  }

  String get djMidiBoxSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return '16구 로터리 다이얼 그리드 · 네온 헤일로 링 & 아크 게이지 · 원터치 토글 및 실시간 드래그 제어 · Lyria 실시간 음원 믹싱';
      case AppLanguage.ja:
        return '16個のロータリーノブグリッド・ネオンハローとアークゲージ・ワンタッチ切替＆ドラグ制御・Lyriaリアルタイムミキシング';
      case AppLanguage.zh:
        return '16旋钮网格 · 霓虹光环与弧形仪表 · 一键切换与拖拽控制 · Lyria实时音乐混音';
      case AppLanguage.en:
        return '16-pad rotary knob grid · Neon halos & arc gauges · One-touch toggles & real-time drag steering · Lyria Live mixing';
    }
  }

  String get chatInterfaceTitle {
    switch (language) {
      case AppLanguage.ko:
        return 'Chat Interface (기본 대화)';
      case AppLanguage.ja:
        return 'Chat Interface (基本対話)';
      case AppLanguage.zh:
        return 'Chat Interface (基础对话)';
      case AppLanguage.en:
        return 'Chat Interface';
    }
  }

  String get chatInterfaceSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return '텍스트, 이미지, 오디오 입력을 지원하는 멀티모달 대화 인터페이스';
      case AppLanguage.ja:
        return 'テキスト、画像、音声入力を備えたマルチモーダル対話';
      case AppLanguage.zh:
        return '支持文本、图像和音频输入的多模态对话界面';
      case AppLanguage.en:
        return 'Basic multimodal chat with text, image, and audio input';
    }
  }

  String get liveApiFeaturesTitle {
    switch (language) {
      case AppLanguage.ko:
        return 'Live API Features (신규 기능 모음)';
      case AppLanguage.ja:
        return 'Live API Features (新機能検証)';
      case AppLanguage.zh:
        return 'Live API Features (新特性综合演示)';
      case AppLanguage.en:
        return 'Live API Features';
    }
  }

  String get liveApiFeaturesSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return 'VAD 음성 감지, 실시간 전사, 세션 재개 등 신규 프로토콜 검증 데모';
      case AppLanguage.ja:
        return '音声活動検出(VAD)、文字起こし、セッション再開などのプロトコル検証';
      case AppLanguage.zh:
        return 'VAD语音检测、实时转写、会话恢复等全套新特性验证演示';
      case AppLanguage.en:
        return 'Demo of all Live API features: VAD, transcription, session resumption, etc.';
    }
  }

  String get functionCallingTitle {
    switch (language) {
      case AppLanguage.ko:
        return 'Function Calling (도구 호출)';
      case AppLanguage.ja:
        return 'Function Calling (ツール呼び出し)';
      case AppLanguage.zh:
        return 'Function Calling (函数调用/工具)';
      case AppLanguage.en:
        return 'Function Calling';
    }
  }

  String get functionCallingSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return '날씨, 시간, 환율, 검색, 알림 연동 도구 호출(Tool Calling) 데모';
      case AppLanguage.ja:
        return '天気、時間、為替、検索、リマインダー連携ツール呼び出しデモ';
      case AppLanguage.zh:
        return '天气、时间、汇率、搜索与提醒工具的实时函数调用演示';
      case AppLanguage.en:
        return 'Tool calling with weather/time/fx/search/reminder functions';
    }
  }

  String get realtimeMediaTitle {
    switch (language) {
      case AppLanguage.ko:
        return 'Realtime Media (실시간 미디어)';
      case AppLanguage.ja:
        return 'Realtime Media (リアルタイムメディア)';
      case AppLanguage.zh:
        return 'Realtime Media (实时流媒体)';
      case AppLanguage.en:
        return 'Realtime Media';
    }
  }

  String get realtimeMediaSubtitle {
    switch (language) {
      case AppLanguage.ko:
        return '실시간 카메라 프리뷰, 마이크 스트리밍 및 사용자 활동 감지';
      case AppLanguage.ja:
        return 'カメラプレビュー、マイクストリーミング、アクティビティ検出';
      case AppLanguage.zh:
        return '实时摄像头预览、麦克风流式传输及用户活动检测';
      case AppLanguage.en:
        return 'Realtime camera preview, microphone streaming, and activity detection';
    }
  }

  // Settings Dialog
  String get settingsDialogTitle {
    switch (language) {
      case AppLanguage.ko:
        return 'Live API 설정';
      case AppLanguage.ja:
        return 'Live API 設定';
      case AppLanguage.zh:
        return 'Live API 设置';
      case AppLanguage.en:
        return 'Live API Settings';
    }
  }

  String get apiKeyLabel {
    switch (language) {
      case AppLanguage.ko:
        return 'Gemini API 키';
      case AppLanguage.ja:
        return 'Gemini APIキー';
      case AppLanguage.zh:
        return 'Gemini API密钥';
      case AppLanguage.en:
        return 'Gemini API Key';
    }
  }

  String get apiKeyFieldHint {
    switch (language) {
      case AppLanguage.ko:
        return 'Google AI Studio에서 발급받은 API 키를 입력하세요.';
      case AppLanguage.ja:
        return 'Google AI Studioで取得したAPIキーを入力してください。';
      case AppLanguage.zh:
        return '请输入在Google AI Studio获取的API密钥。';
      case AppLanguage.en:
        return 'Enter the API key issued from Google AI Studio.';
    }
  }

  String get liveModelLabel {
    switch (language) {
      case AppLanguage.ko:
        return 'Gemini Live 모델';
      case AppLanguage.ja:
        return 'Gemini Live モデル';
      case AppLanguage.zh:
        return 'Gemini Live 模型';
      case AppLanguage.en:
        return 'Gemini Live Model';
    }
  }

  String get customModelOption {
    switch (language) {
      case AppLanguage.ko:
        return 'Custom model (직접 입력)';
      case AppLanguage.ja:
        return 'カスタムモデル (直接入力)';
      case AppLanguage.zh:
        return '自定义模型 (手动输入)';
      case AppLanguage.en:
        return 'Custom model (manual input)';
    }
  }

  String get voiceLabel {
    switch (language) {
      case AppLanguage.ko:
        return 'Gemini Voice (AI 음성)';
      case AppLanguage.ja:
        return 'Gemini Voice (AI音声)';
      case AppLanguage.zh:
        return 'Gemini Voice (AI音色)';
      case AppLanguage.en:
        return 'Gemini Voice';
    }
  }

  String get audioDeviceLabel {
    switch (language) {
      case AppLanguage.ko:
        return '오디오 입력 장치 (마이크)';
      case AppLanguage.ja:
        return '音声入力デバイス (マイク)';
      case AppLanguage.zh:
        return '音频输入设备 (麦克风)';
      case AppLanguage.en:
        return 'Audio Input Device (Microphone)';
    }
  }

  String get defaultDeviceLabel {
    switch (language) {
      case AppLanguage.ko:
        return '시스템 기본 마이크';
      case AppLanguage.ja:
        return 'システム既定のマイク';
      case AppLanguage.zh:
        return '系统默认麦克风';
      case AppLanguage.en:
        return 'System Default Microphone';
    }
  }

  String get voiceSelectionDesc {
    switch (language) {
      case AppLanguage.ko:
        return 'Gemini Live 답변 시 재생될 모델의 목소리를 선택하세요.';
      case AppLanguage.ja:
        return 'Gemini Liveの応答で使用されるモデルの音声を選択してください。';
      case AppLanguage.zh:
        return '请选择Gemini Live回复时所使用的模型音色。';
      case AppLanguage.en:
        return 'Select the voice used when the model speaks in Gemini Live.';
    }
  }

  String get audioDeviceDesc {
    switch (language) {
      case AppLanguage.ko:
        return '기본 장치로 음성이 잡히지 않을 경우 원하는 마이크를 직접 지정하세요.';
      case AppLanguage.ja:
        return '既定のデバイスで音声が拾われない場合は、任意の入力マイクを直接指定してください。';
      case AppLanguage.zh:
        return '如果默认设备无法拾取声音，请直接指定所需的输入麦克风。';
      case AppLanguage.en:
        return 'Select a specific microphone if the system default does not pick up audio.';
    }
  }

  String get saveButton {
    switch (language) {
      case AppLanguage.ko:
        return '설정 저장';
      case AppLanguage.ja:
        return '設定を保存';
      case AppLanguage.zh:
        return '保存设置';
      case AppLanguage.en:
        return 'Save Settings';
    }
  }

  String get cancelButton {
    switch (language) {
      case AppLanguage.ko:
        return '취소';
      case AppLanguage.ja:
        return 'キャンセル';
      case AppLanguage.zh:
        return '取消';
      case AppLanguage.en:
        return 'Cancel';
    }
  }
}

/// Inherited widget for reactive language propagation down the widget tree.
class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    return scope?.notifier ?? AppLanguageController.instance;
  }
}

/// Material 3 language switcher widget suitable for [AppBar.actions].
class LanguageSelectorButton extends StatelessWidget {
  final bool compact;

  const LanguageSelectorButton({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguageController.instance,
      builder: (context, _) {
        final current = AppLanguageController.instance.currentLanguage;

        return PopupMenuButton<AppLanguage>(
          tooltip: AppTranslations.current.languageTooltip,
          initialValue: current,
          onSelected: (AppLanguage newLang) {
            AppLanguageController.instance.setLanguage(newLang);
          },
          itemBuilder: (BuildContext context) {
            return AppLanguage.values.map((lang) {
              final isSelected = lang == current;
              return PopupMenuItem<AppLanguage>(
                value: lang,
                child: Row(
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                  ],
                ),
              );
            }).toList();
          },
          child: compact
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        current.code.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${current.flag} ${current.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
