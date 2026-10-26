import 'package:example/app_translations.dart';

/// Multilingual translation helper for FunctionCallingDemoPage (en, ko, ja, zh).
class FunctionCallingI18n {
  final AppLanguage lang;
  const FunctionCallingI18n(this.lang);

  static FunctionCallingI18n get current =>
      FunctionCallingI18n(AppLanguageController.instance.currentLanguage);

  String get appBarTitle => switch (lang) {
    AppLanguage.ko => '함수 호출(도구) 데모',
    AppLanguage.ja => '関数呼び出し(ツール)デモ',
    AppLanguage.zh => '函数调用(工具)演示',
    AppLanguage.en => 'Function Calling Demo',
  };

  String get clearToolsTooltip => switch (lang) {
    AppLanguage.ko => '세션 중 도구 비활성화 (sendContextUpdate)',
    AppLanguage.ja => 'セッション中にツールをクリア (sendContextUpdate)',
    AppLanguage.zh => '在会话中清除工具 (sendContextUpdate)',
    AppLanguage.en => 'Clear tools in-session (sendContextUpdate)',
  };

  String get restoreToolsTooltip => switch (lang) {
    AppLanguage.ko => '세션 중 도구 복원 (sendContextUpdate)',
    AppLanguage.ja => 'セッション中にツールを復元 (sendContextUpdate)',
    AppLanguage.zh => '在会话中恢复工具 (sendContextUpdate)',
    AppLanguage.en => 'Restore tools in-session (sendContextUpdate)',
  };

  String get connecting => switch (lang) {
    AppLanguage.ko => '연결 중...',
    AppLanguage.ja => '接続中...',
    AppLanguage.zh => '连接中...',
    AppLanguage.en => 'Connecting...',
  };

  String get connect => switch (lang) {
    AppLanguage.ko => '연결',
    AppLanguage.ja => '接続',
    AppLanguage.zh => '连接',
    AppLanguage.en => 'Connect',
  };

  // FunctionInfoCard
  String get availableFunctionsTitle => switch (lang) {
    AppLanguage.ko => '사용 가능한 함수:',
    AppLanguage.ja => '利用可能な関数:',
    AppLanguage.zh => '可用函数:',
    AppLanguage.en => 'Available Functions:',
  };

  String get descGetWeather => switch (lang) {
    AppLanguage.ko => '지역별 날씨 조회 (+ 단위)',
    AppLanguage.ja => '指定地域の天気を取得 (+ 単位)',
    AppLanguage.zh => '获取指定地点的天气（+ 单位）',
    AppLanguage.en => 'Get weather for a location (+ unit)',
  };

  String get descGetCurrentTime => switch (lang) {
    AppLanguage.ko => '타임존별 현재 시간 조회',
    AppLanguage.ja => 'タイムゾーンの現在時刻を取得',
    AppLanguage.zh => '获取指定时区的当前时间',
    AppLanguage.en => 'Get current time for a timezone',
  };

  String get descGetExchangeRate => switch (lang) {
    AppLanguage.ko => '환율 조회 (예: USD/KRW)',
    AppLanguage.ja => '為替レートを取得 (例: USD/KRW)',
    AppLanguage.zh => '获取汇率（如 USD/KRW）',
    AppLanguage.en => 'Get FX rate (e.g., USD/KRW)',
  };

  String get descConvertCurrency => switch (lang) {
    AppLanguage.ko => '통화 간 금액 환산',
    AppLanguage.ja => '通貨間の金額換算',
    AppLanguage.zh => '跨币种金额换算',
    AppLanguage.en => 'Convert amount across currencies',
  };

  String get descSearchPlaces => switch (lang) {
    AppLanguage.ko => '도시/검색어 기반 추천 장소 검색',
    AppLanguage.ja => '都市・キーワードで人気スポットを検索',
    AppLanguage.zh => '按城市/关键词搜索热门地点',
    AppLanguage.en => 'Search ranked places by query/city',
  };

  String get descCreateReminder => switch (lang) {
    AppLanguage.ko => '리마인더 예약 (비차단 실행)',
    AppLanguage.ja => 'リマインダーを登録 (非ブロッキング)',
    AppLanguage.zh => '设置提醒事项（非阻塞执行）',
    AppLanguage.en => 'Schedule reminder (non-blocking)',
  };

  String get tryHint => switch (lang) {
    AppLanguage.ko => '추천: 날씨/시간 + 환율 계산 + 카페/맛집 검색 + 리마인더',
    AppLanguage.ja => 'お試し: 天気・時刻 + 為替換算 + カフェ検索 + リマインダー',
    AppLanguage.zh => '试试：天气/时间 + 汇率换算 + 地点搜索 + 提醒事项',
    AppLanguage.en =>
      'Try: weather/time + FX conversion + cafe search + reminders',
  };

  // InputArea
  String get quickPromptWeather => switch (lang) {
    AppLanguage.ko => '서울 날씨를 섭씨로 알려줘',
    AppLanguage.ja => 'ソウルの天気を摂氏で教えて',
    AppLanguage.zh => '用摄氏度查询首尔的天气',
    AppLanguage.en => 'Weather in Seoul in celsius',
  };

  String get quickPromptCurrency => switch (lang) {
    AppLanguage.ko => '120 USD를 KRW로 환산해 줘',
    AppLanguage.ja => '120 USD を KRW に換算して',
    AppLanguage.zh => '将 120 USD 换算为 KRW',
    AppLanguage.en => 'Convert 120 USD to KRW',
  };

  String get quickPromptPlaces => switch (lang) {
    AppLanguage.ko => '도쿄 라멘 맛집 3곳 찾아줘',
    AppLanguage.ja => '東京のラーメン店を3つ探して',
    AppLanguage.zh => '查找东京的3家拉面店',
    AppLanguage.en => 'Find 3 ramen places in Tokyo',
  };

  String get quickPromptReminder => switch (lang) {
    AppLanguage.ko => '내일 오전 9시(Asia/Seoul)에 주간 보고서 제출 리마인더 등록해 줘',
    AppLanguage.ja => '明日午前9時(Asia/Seoul)に週報提出のリマインダーを設定して',
    AppLanguage.zh => '提醒我明天上午9点（Asia/Seoul）提交周报',
    AppLanguage.en =>
      'Remind me tomorrow 9am Asia/Seoul to submit weekly report',
  };

  String get inputHint => switch (lang) {
    AppLanguage.ko => '날씨, 시간, 환율 계산, 장소 검색, 리마인더를 요청해 보세요...',
    AppLanguage.ja => '天気・時刻・為替換算・場所検索・リマインダーを質問...',
    AppLanguage.zh => '询问天气、时间、汇率换算、地点搜索或设置提醒...',
    AppLanguage.en => 'Ask weather/time/fx conversion/place search/reminder...',
  };

  String get sendTooltip => switch (lang) {
    AppLanguage.ko => '전송',
    AppLanguage.ja => '送信',
    AppLanguage.zh => '发送',
    AppLanguage.en => 'Send',
  };

  // System messages in ViewModel
  String get sysApiKeyNotConfigured => switch (lang) {
    AppLanguage.ko => '❌ API 키가 설정되지 않았습니다. 먼저 설정을 열어주세요.',
    AppLanguage.ja => '❌ APIキーが設定されていません。先に設定を開いてください。',
    AppLanguage.zh => '❌ 未配置 API 密钥。请先打开设置。',
    AppLanguage.en => '❌ API key is not configured. Open Settings first.',
  };

  String get sysConnecting => switch (lang) {
    AppLanguage.ko => 'Gemini 3.8 Live에 함수 호출 기능과 함께 연결 중...',
    AppLanguage.ja => 'Gemini 3.8 Live に関数呼び出し有効で接続中...',
    AppLanguage.zh => '正在启用函数调用连接到 Gemini 3.8 Live...',
    AppLanguage.en =>
      'Connecting with function calling enabled on Gemini 3.8 Live...',
  };

  String get sysConnected => switch (lang) {
    AppLanguage.ko => '✅ 함수 호출 기능으로 연결되었습니다',
    AppLanguage.ja => '✅ 関数呼び出し有効で接続しました',
    AppLanguage.zh => '✅ 已连接并启用函数调用',
    AppLanguage.en => '✅ Connected with function calling',
  };

  String sysError(Object error) => switch (lang) {
    AppLanguage.ko => '❌ 오류: $error',
    AppLanguage.ja => '❌ エラー: $error',
    AppLanguage.zh => '❌ 错误: $error',
    AppLanguage.en => '❌ Error: $error',
  };

  String get sysConnectionClosed => switch (lang) {
    AppLanguage.ko => '🔒 연결이 종료되었습니다',
    AppLanguage.ja => '🔒 接続が閉じられました',
    AppLanguage.zh => '🔒 连接已关闭',
    AppLanguage.en => '🔒 Connection closed',
  };

  String sysConnectionFailed(Object error) => switch (lang) {
    AppLanguage.ko => '❌ 연결 실패: $error',
    AppLanguage.ja => '❌ 接続失敗: $error',
    AppLanguage.zh => '❌ 连接失败: $error',
    AppLanguage.en => '❌ Connection failed: $error',
  };

  String get sysReceivedAudio => switch (lang) {
    AppLanguage.ko => '🔊 오디오 응답 수신',
    AppLanguage.ja => '🔊 音声応答を受信しました',
    AppLanguage.zh => '🔊 收到音频回复',
    AppLanguage.en => '🔊 Received audio response',
  };

  String sysToolCallsCancelled(String ids) => switch (lang) {
    AppLanguage.ko => '❌ 도구 호출 취소됨: $ids',
    AppLanguage.ja => '❌ ツール呼び出しがキャンセルされました: $ids',
    AppLanguage.zh => '❌ 工具调用已取消: $ids',
    AppLanguage.en => '❌ Tool calls cancelled: $ids',
  };

  String get sysPlayingAudio => switch (lang) {
    AppLanguage.ko => '▶️ 수신된 오디오 재생 중',
    AppLanguage.ja => '▶️ 受信した音声を再生中',
    AppLanguage.zh => '▶️ 正在播放收到的音频',
    AppLanguage.en => '▶️ Playing received audio',
  };

  String sysFunctionCall(String? name, String? id) => switch (lang) {
    AppLanguage.ko => '🔧 함수 호출: $name (id: $id)',
    AppLanguage.ja => '🔧 関数呼び出し: $name (id: $id)',
    AppLanguage.zh => '🔧 函数调用: $name (id: $id)',
    AppLanguage.en => '🔧 Function call: $name (id: $id)',
  };

  String sysFunctionArgs(Object? args) => switch (lang) {
    AppLanguage.ko => '   인자: $args',
    AppLanguage.ja => '   引数: $args',
    AppLanguage.zh => '   参数: $args',
    AppLanguage.en => '   Args: $args',
  };

  String sysSendingResponse(Object result) => switch (lang) {
    AppLanguage.ko => '📤 응답 전송 중: $result',
    AppLanguage.ja => '📤 応答を送信中: $result',
    AppLanguage.zh => '📤 正在发送响应: $result',
    AppLanguage.en => '📤 Sending response: $result',
  };

  String get sysNotConnected => switch (lang) {
    AppLanguage.ko => '❌ 연결되어 있지 않습니다',
    AppLanguage.ja => '❌ 接続されていません',
    AppLanguage.zh => '❌ 未连接',
    AppLanguage.en => '❌ Not connected',
  };

  String get sysToolsReEnabled => switch (lang) {
    AppLanguage.ko =>
      '🔄 sendContextUpdate(tools: defaultTools)로 세션 내 도구가 다시 활성화되었습니다',
    AppLanguage.ja =>
      '🔄 sendContextUpdate(tools: defaultTools) でセッション内のツールを再有効化しました',
    AppLanguage.zh =>
      '🔄 已通过 sendContextUpdate(tools: defaultTools) 在会话中重新启用工具',
    AppLanguage.en =>
      '🔄 Tools re-enabled in-session via sendContextUpdate(tools: defaultTools)',
  };

  String get sysToolsCleared => switch (lang) {
    AppLanguage.ko => '🔄 sendContextUpdate(tools: [])로 세션 내 모든 도구가 해제되었습니다',
    AppLanguage.ja => '🔄 sendContextUpdate(tools: []) でセッション内の全ツールをクリアしました',
    AppLanguage.zh => '🔄 已通过 sendContextUpdate(tools: []) 在会话中清除所有工具',
    AppLanguage.en =>
      '🔄 All tools cleared in-session via sendContextUpdate(tools: [])',
  };
}
