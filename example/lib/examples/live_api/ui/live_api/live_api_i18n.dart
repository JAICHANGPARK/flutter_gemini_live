import 'package:example/app_translations.dart';

/// Multilingual translation helper for LiveAPIDemoPage (en, ko, ja, zh).
class LiveApiI18n {
  final AppLanguage lang;
  const LiveApiI18n(this.lang);

  static LiveApiI18n get current =>
      LiveApiI18n(AppLanguageController.instance.currentLanguage);

  String get appBarTitle => switch (lang) {
    AppLanguage.ko => 'Live API 고급 기능 데모',
    AppLanguage.ja => 'Live API 機能デモ',
    AppLanguage.zh => 'Live API 高级功能演示',
    AppLanguage.en => 'Live API Features Demo',
  };

  String get closeConnectionTooltip => switch (lang) {
    AppLanguage.ko => '연결 종료',
    AppLanguage.ja => '接続を閉じる',
    AppLanguage.zh => '关闭连接',
    AppLanguage.en => 'Close connection',
  };

  // Feature toggles
  String get toggleRealtimeConfig => switch (lang) {
    AppLanguage.ko => '실시간 입력 설정',
    AppLanguage.ja => 'リアルタイム設定',
    AppLanguage.zh => '实时输入配置',
    AppLanguage.en => 'Realtime Config',
  };

  String get toggleTranscription => switch (lang) {
    AppLanguage.ko => '음성 자막(전사)',
    AppLanguage.ja => '文字起こし',
    AppLanguage.zh => '语音转写',
    AppLanguage.en => 'Transcription',
  };

  String get toggleSmartMode => switch (lang) {
    AppLanguage.ko => '스마트 모드',
    AppLanguage.ja => 'スマートモード',
    AppLanguage.zh => '智能模式',
    AppLanguage.en => 'Smart Mode',
  };

  String get toggleSessionResume => switch (lang) {
    AppLanguage.ko => '세션 재개(Resume)',
    AppLanguage.ja => 'セッション再開',
    AppLanguage.zh => '会话恢复',
    AppLanguage.en => 'Session Resume',
  };

  String get toggleContextCompression => switch (lang) {
    AppLanguage.ko => '컨텍스트 압축',
    AppLanguage.ja => 'コンテキスト圧縮',
    AppLanguage.zh => '上下文压缩',
    AppLanguage.en => 'Context Compression',
  };

  String get toggleServerTimeout => switch (lang) {
    AppLanguage.ko => 'X-Server-Timeout (30s)',
    AppLanguage.ja => 'X-Server-Timeout (30s)',
    AppLanguage.zh => 'X-Server-Timeout (30s)',
    AppLanguage.en => 'X-Server-Timeout (30s)',
  };

  String supportsHeadersBadge(bool supported) => switch (lang) {
    AppLanguage.ko => 'WS 헤더 지원: ${supported ? "ON (IO)" : "OFF (Web)"}',
    AppLanguage.ja => 'WSヘッダー: ${supported ? "ON (IO)" : "OFF (Web)"}',
    AppLanguage.zh => 'WS 请求头: ${supported ? "ON (IO)" : "OFF (Web)"}',
    AppLanguage.en => 'WS Headers: ${supported ? "ON (IO)" : "OFF (Web)"}',
  };

  // Connection button
  String get connecting => switch (lang) {
    AppLanguage.ko => '연결 중...',
    AppLanguage.ja => '接続中...',
    AppLanguage.zh => '连接中...',
    AppLanguage.en => 'Connecting...',
  };

  String get connected => switch (lang) {
    AppLanguage.ko => '연결됨',
    AppLanguage.ja => '接続済み',
    AppLanguage.zh => '已连接',
    AppLanguage.en => 'Connected',
  };

  String get connectToLiveApi => switch (lang) {
    AppLanguage.ko => 'Live API 연결',
    AppLanguage.ja => 'Live API に接続',
    AppLanguage.zh => '连接到 Live API',
    AppLanguage.en => 'Connect to Live API',
  };

  // Action buttons
  String get sendTextBtn => switch (lang) {
    AppLanguage.ko => '텍스트 전송',
    AppLanguage.ja => 'テキスト送信',
    AppLanguage.zh => '发送文本',
    AppLanguage.en => 'Send Text',
  };

  String get multiTurnBtn => switch (lang) {
    AppLanguage.ko => '멀티턴 컨텐츠',
    AppLanguage.ja => 'マルチターン送信',
    AppLanguage.zh => '多轮对话内容',
    AppLanguage.en => 'Multi-turn',
  };

  String get realtimeInputBtn => switch (lang) {
    AppLanguage.ko => '실시간 입력',
    AppLanguage.ja => 'リアルタイム入力',
    AppLanguage.zh => '实时输入',
    AppLanguage.en => 'Realtime Input',
  };

  String get contextUpdateBtn => switch (lang) {
    AppLanguage.ko => '컨텍스트 업데이트',
    AppLanguage.ja => 'コンテキスト更新',
    AppLanguage.zh => '上下文更新',
    AppLanguage.en => 'Context Update',
  };

  String get activityStartBtn => switch (lang) {
    AppLanguage.ko => '발화 활동 시작',
    AppLanguage.ja => 'アクティビティ開始',
    AppLanguage.zh => '开始活动',
    AppLanguage.en => 'Activity Start',
  };

  String get activityEndBtn => switch (lang) {
    AppLanguage.ko => '발화 활동 종료',
    AppLanguage.ja => 'アクティビティ終了',
    AppLanguage.zh => '结束活动',
    AppLanguage.en => 'Activity End',
  };

  // Text input dialog
  String get sendMessageTitle => switch (lang) {
    AppLanguage.ko => '메시지 전송',
    AppLanguage.ja => 'メッセージを送信',
    AppLanguage.zh => '发送消息',
    AppLanguage.en => 'Send Message',
  };

  String get enterYourMessageHint => switch (lang) {
    AppLanguage.ko => '보낼 메시지를 입력하세요',
    AppLanguage.ja => 'メッセージを入力してください',
    AppLanguage.zh => '请输入您的消息',
    AppLanguage.en => 'Enter your message',
  };

  String get cancelBtn => switch (lang) {
    AppLanguage.ko => '취소',
    AppLanguage.ja => 'キャンセル',
    AppLanguage.zh => '取消',
    AppLanguage.en => 'Cancel',
  };

  String get sendBtn => switch (lang) {
    AppLanguage.ko => '전송',
    AppLanguage.ja => '送信',
    AppLanguage.zh => '发送',
    AppLanguage.en => 'Send',
  };

  // Logs & status messages
  String get logApiKeyNotConfigured => switch (lang) {
    AppLanguage.ko => '❌ API 키가 설정되지 않았습니다. 먼저 설정을 열어주세요.',
    AppLanguage.ja => '❌ APIキーが設定されていません。先に設定を開いてください。',
    AppLanguage.zh => '❌ 未配置 API 密钥。请先打开设置。',
    AppLanguage.en => '❌ API key is not configured. Open Settings first.',
  };

  String get logConnecting => switch (lang) {
    AppLanguage.ko => 'Gemini 3.8 Live API에 연결 중...',
    AppLanguage.ja => 'Gemini 3.8 Live API に接続中...',
    AppLanguage.zh => '正在连接到 Gemini 3.8 Live API...',
    AppLanguage.en => 'Connecting to Gemini 3.8 Live API...',
  };

  String logTransportInfo({
    required bool supportsHeaders,
    required int? serverTimeoutSec,
    required bool hasCredentials,
  }) => switch (lang) {
    AppLanguage.ko =>
      '🌐 전송 설정: supportsHeaders=$supportsHeaders, X-Server-Timeout=${serverTimeoutSec != null ? "${serverTimeoutSec}s" : "없음"}, GenAICredentials=${hasCredentials ? "활성" : "기본 API 키"}',
    AppLanguage.ja =>
      '🌐 トランスポート: supportsHeaders=$supportsHeaders, X-Server-Timeout=${serverTimeoutSec != null ? "${serverTimeoutSec}s" : "なし"}, GenAICredentials=${hasCredentials ? "有効" : "APIキー"}',
    AppLanguage.zh =>
      '🌐 传输配置: supportsHeaders=$supportsHeaders, X-Server-Timeout=${serverTimeoutSec != null ? "${serverTimeoutSec}s" : "无"}, GenAICredentials=${hasCredentials ? "已启用" : "默认 API 密钥"}',
    AppLanguage.en =>
      '🌐 Transport: supportsHeaders=$supportsHeaders, X-Server-Timeout=${serverTimeoutSec != null ? "${serverTimeoutSec}s" : "off"}, GenAICredentials=${hasCredentials ? "active" : "API key"}',
  };

  String get logConnectedSuccess => switch (lang) {
    AppLanguage.ko => '✅ 성공적으로 연결되었습니다',
    AppLanguage.ja => '✅ 正常に接続されました',
    AppLanguage.zh => '✅ 连接成功',
    AppLanguage.en => '✅ Connected successfully',
  };

  String logError(Object error) => switch (lang) {
    AppLanguage.ko => '❌ 오류: $error',
    AppLanguage.ja => '❌ エラー: $error',
    AppLanguage.zh => '❌ 错误: $error',
    AppLanguage.en => '❌ Error: $error',
  };

  String logConnectionClosed(int? code, String? reason) => switch (lang) {
    AppLanguage.ko => '🔒 연결 종료됨: 코드=$code, 사유=$reason',
    AppLanguage.ja => '🔒 接続が閉じられました: code=$code, reason=$reason',
    AppLanguage.zh => '🔒 连接已关闭: code=$code, reason=$reason',
    AppLanguage.en => '🔒 Connection closed: code=$code, reason=$reason',
  };

  String logSessionId(String id) => switch (lang) {
    AppLanguage.ko => '🆔 세션 ID: $id',
    AppLanguage.ja => '🆔 セッションID: $id',
    AppLanguage.zh => '🆔 会话 ID: $id',
    AppLanguage.en => '🆔 Session ID: $id',
  };

  String logConnectionFailed(Object error) => switch (lang) {
    AppLanguage.ko => '❌ 연결 실패: $error',
    AppLanguage.ja => '❌ 接続失敗: $error',
    AppLanguage.zh => '❌ 连接失败: $error',
    AppLanguage.en => '❌ Connection failed: $error',
  };

  String logInteractionStatus(String status) => switch (lang) {
    AppLanguage.ko => '⚡ 상호작용 상태: $status',
    AppLanguage.ja => '⚡ インタラクション状態: $status',
    AppLanguage.zh => '⚡ 交互状态: $status',
    AppLanguage.en => '⚡ Interaction status: $status',
  };

  String logReceivedAudio(int chars) => switch (lang) {
    AppLanguage.ko => '🔊 오디오 수신: $chars자',
    AppLanguage.ja => '🔊 音声を受信: $chars 文字',
    AppLanguage.zh => '🔊 收到音频: $chars 字符',
    AppLanguage.en => '🔊 Received audio: $chars chars',
  };

  String logInputTranscription(String? text, bool finished) => switch (lang) {
    AppLanguage.ko => '🎤 입력: $text ${finished ? "(완료)" : ""}',
    AppLanguage.ja => '🎤 入力: $text ${finished ? "(完了)" : ""}',
    AppLanguage.zh => '🎤 输入: $text ${finished ? "(完成)" : ""}',
    AppLanguage.en => '🎤 Input: $text ${finished ? "(complete)" : ""}',
  };

  String logOutputTranscription(String? text, bool finished) => switch (lang) {
    AppLanguage.ko => '🔈 출력: $text ${finished ? "(완료)" : ""}',
    AppLanguage.ja => '🔈 出力: $text ${finished ? "(完了)" : ""}',
    AppLanguage.zh => '🔈 输出: $text ${finished ? "(完成)" : ""}',
    AppLanguage.en => '🔈 Output: $text ${finished ? "(complete)" : ""}',
  };

  String logVoiceActivity(bool active) => switch (lang) {
    AppLanguage.ko => '🎤 음성 활동: ${active ? "발화 중" : "침묵"}',
    AppLanguage.ja => '🎤 音声アクティビティ: ${active ? "発話中" : "無音"}',
    AppLanguage.zh => '🎤 语音活动: ${active ? "正在说话" : "静音"}',
    AppLanguage.en => '🎤 Voice activity: ${active ? "speaking" : "silent"}',
  };

  String get logSpeechStarted => switch (lang) {
    AppLanguage.ko => '🎙️ 발화 시작됨',
    AppLanguage.ja => '🎙️ 発話開始',
    AppLanguage.zh => '🎙️ 开始说话',
    AppLanguage.en => '🎙️ Speech started',
  };

  String get logSpeechEnded => switch (lang) {
    AppLanguage.ko => '🎙️ 발화 종료됨',
    AppLanguage.ja => '🎙️ 発話終了',
    AppLanguage.zh => '🎙️ 结束说话',
    AppLanguage.en => '🎙️ Speech ended',
  };

  String logResumptionUpdate(String? handle) => switch (lang) {
    AppLanguage.ko => '🔄 세션 재개 업데이트: handle=$handle',
    AppLanguage.ja => '🔄 セッション再開更新: handle=$handle',
    AppLanguage.zh => '🔄 会话恢复更新: handle=$handle',
    AppLanguage.en => '🔄 Resumption update: handle=$handle',
  };

  String logGoAway(Object? timeRemaining, String? reason) => switch (lang) {
    AppLanguage.ko => '⏰ 서버 연결 종료 예정 (${timeRemaining}s 후): $reason',
    AppLanguage.ja => '⏰ サーバー切断予告 (${timeRemaining}s後): $reason',
    AppLanguage.zh => '⏰ 服务器将在 ${timeRemaining}s 后断开: $reason',
    AppLanguage.en =>
      '⏰ Server will disconnect in ${timeRemaining}s: $reason',
  };

  String get logPlayingAudio => switch (lang) {
    AppLanguage.ko => '▶️ 수신된 오디오 재생 중',
    AppLanguage.ja => '▶️ 受信した音声を再生中',
    AppLanguage.zh => '▶️ 正在播放收到的音频',
    AppLanguage.en => '▶️ Playing received audio',
  };

  String get logNotConnected => switch (lang) {
    AppLanguage.ko => '❌ 연결되어 있지 않습니다',
    AppLanguage.ja => '❌ 接続されていません',
    AppLanguage.zh => '❌ 未连接',
    AppLanguage.en => '❌ Not connected',
  };

  String get logMultiTurnContent => switch (lang) {
    AppLanguage.ko => '💬 [멀티턴 컨텐츠]',
    AppLanguage.ja => '💬 [マルチターンコンテンツ]',
    AppLanguage.zh => '💬 [多轮对话内容]',
    AppLanguage.en => '💬 [Multi-turn content]',
  };

  String get logRealtimeInputMedia => switch (lang) {
    AppLanguage.ko => '🎙️ [미디어를 포함한 실시간 입력]',
    AppLanguage.ja => '🎙️ [メディア付きリアルタイム入力]',
    AppLanguage.zh => '🎙️ [带媒体的实时输入]',
    AppLanguage.en => '🎙️ [Realtime input with media]',
  };

  String get logContextUpdate => switch (lang) {
    AppLanguage.ko => '🔄 [컨텍스트 업데이트: systemInstruction]',
    AppLanguage.ja => '🔄 [コンテキスト更新: systemInstruction]',
    AppLanguage.zh => '🔄 [上下文更新: systemInstruction]',
    AppLanguage.en => '🔄 [Context Update: systemInstruction]',
  };

  String get logActivityStart => switch (lang) {
    AppLanguage.ko => '🎙️ [발화 활동 시작]',
    AppLanguage.ja => '🎙️ [アクティビティ開始]',
    AppLanguage.zh => '🎙️ [开始活动]',
    AppLanguage.en => '🎙️ [Activity Start]',
  };

  String get logActivityEnd => switch (lang) {
    AppLanguage.ko => '🎙️ [발화 활동 종료]',
    AppLanguage.ja => '🎙️ [アクティビティ終了]',
    AppLanguage.zh => '🎙️ [结束活动]',
    AppLanguage.en => '🎙️ [Activity End]',
  };

  String get logClosingConnection => switch (lang) {
    AppLanguage.ko => '👋 연결 종료 중...',
    AppLanguage.ja => '👋 接続を閉じています...',
    AppLanguage.zh => '👋 正在关闭连接...',
    AppLanguage.en => '👋 Closing connection...',
  };
}
