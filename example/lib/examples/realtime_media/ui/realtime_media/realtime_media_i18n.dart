import 'package:example/app_translations.dart';

/// Multilingual translation helper for RealtimeMediaDemoPage (en, ko, ja, zh).
class RealtimeMediaI18n {
  final AppLanguage lang;
  const RealtimeMediaI18n(this.lang);

  static RealtimeMediaI18n get current =>
      RealtimeMediaI18n(AppLanguageController.instance.currentLanguage);

  String get appBarTitle => switch (lang) {
    AppLanguage.ko => '실시간 미디어 데모',
    AppLanguage.ja => 'リアルタイムメディアデモ',
    AppLanguage.zh => '实时媒体演示',
    AppLanguage.en => 'Realtime Media Demo',
  };

  // ModeSelection
  String get modeSelectionTitle => switch (lang) {
    AppLanguage.ko => '발화 감지 모드:',
    AppLanguage.ja => 'アクティビティ検出モード:',
    AppLanguage.zh => '活动检测模式:',
    AppLanguage.en => 'Activity Detection Mode:',
  };

  String get modeAutomatic => switch (lang) {
    AppLanguage.ko => '자동',
    AppLanguage.ja => '自動',
    AppLanguage.zh => '自动',
    AppLanguage.en => 'Automatic',
  };

  String get modeManual => switch (lang) {
    AppLanguage.ko => '수동',
    AppLanguage.ja => '手動',
    AppLanguage.zh => '手动',
    AppLanguage.en => 'Manual',
  };

  String get modeManualDesc => switch (lang) {
    AppLanguage.ko =>
      '수동 모드: 실시간 카메라+음성 시작 시 발화 활동이 자동으로 시작되며, 직접 종료할 수도 있습니다.',
    AppLanguage.ja =>
      '手動モード: ライブカメラ+音声の開始時にアクティビティが自動開始され、手動で終了することもできます。',
    AppLanguage.zh => '手动模式：开启实时摄像头+语音时会自动启动活动，您也可以手动结束。',
    AppLanguage.en =>
      'Manual mode: live camera + voice starts an activity automatically, and you can still end it yourself.',
  };

  String get modeAutoDesc => switch (lang) {
    AppLanguage.ko =>
      '자동 모드: 마이크 오디오가 연속 스트리밍되며, 음성이 감지되는 동안에만 카메라 프레임이 업로드됩니다.',
    AppLanguage.ja =>
      '自動モード: マイク音声は連続ストリーミングされ、発話検出中のみカメラフレームがアップロードされます。',
    AppLanguage.zh => '自动模式：麦克风音频持续流式传输，仅在检测到说话时上传摄像头画面。',
    AppLanguage.en =>
      'Auto mode: microphone audio streams continuously, and camera frames upload only while speech is detected.',
  };

  // ConnectionButtons
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

  String get connect => switch (lang) {
    AppLanguage.ko => '연결',
    AppLanguage.ja => '接続',
    AppLanguage.zh => '连接',
    AppLanguage.en => 'Connect',
  };

  String get disconnect => switch (lang) {
    AppLanguage.ko => '연결 해제',
    AppLanguage.ja => '切断',
    AppLanguage.zh => '断开连接',
    AppLanguage.en => 'Disconnect',
  };

  // CameraVoiceCard
  String get liveCameraVoiceTitle => switch (lang) {
    AppLanguage.ko => '실시간 카메라 + 음성',
    AppLanguage.ja => 'ライブカメラ + 音声',
    AppLanguage.zh => '实时摄像头 + 语音',
    AppLanguage.en => 'Live Camera + Voice',
  };

  String get statusAudioVideo => switch (lang) {
    AppLanguage.ko => '오디오 + 비디오',
    AppLanguage.ja => '音声 + 映像',
    AppLanguage.zh => '音频 + 视频',
    AppLanguage.en => 'Audio + Video',
  };

  String get statusAudioOnly => switch (lang) {
    AppLanguage.ko => '오디오 전용',
    AppLanguage.ja => '音声のみ',
    AppLanguage.zh => '仅音频',
    AppLanguage.en => 'Audio Only',
  };

  String get statusIdle => switch (lang) {
    AppLanguage.ko => '대기 중',
    AppLanguage.ja => '待機中',
    AppLanguage.zh => '空闲',
    AppLanguage.en => 'Idle',
  };

  String get cameraVoiceManualDesc => switch (lang) {
    AppLanguage.ko =>
      '이 예제는 실시간 카메라 프리뷰를 화면에 유지하며, 활동이 활성화된 동안 1.2초마다 JPEG 스냅샷을 업로드하고 동일한 Live 세션으로 마이크 PCM 청크를 스트리밍합니다.',
    AppLanguage.ja =>
      'このサンプルはライブカメラプレビューを表示し、アクティビティ有効中に1.2秒ごとにJPEGスナップショットを送信しながら、同じLiveセッションへマイクPCMチャンクをストリーミングします。',
    AppLanguage.zh =>
      '此示例在屏幕上保持实时摄像头预览，在活动激活期间每 1.2 秒上传一次 JPEG 快照，并向同一 Live 会话流式传输麦克风 PCM 数据块。',
    AppLanguage.en =>
      'This example keeps a live camera preview on screen, uploads a JPEG snapshot every 1.2 seconds while the activity is active, and streams microphone PCM chunks to the same Live session.',
  };

  String get cameraVoiceAutoDesc => switch (lang) {
    AppLanguage.ko =>
      '이 예제는 실시간 카메라 프리뷰를 화면에 유지하며, 마이크 PCM 청크를 연속 스트리밍하고 음성이 감지되는 동안에만 JPEG 스냅샷을 업로드합니다.',
    AppLanguage.ja =>
      'このサンプルはライブカメラプレビューを表示し、マイクPCMチャンクを連続ストリーミングしながら、発話検出中のみJPEGスナップショットをアップロードします。',
    AppLanguage.zh =>
      '此示例在屏幕上保持实时摄像头预览，持续流式传输麦克风 PCM 数据块，并仅在检测到语音时上传 JPEG 快照。',
    AppLanguage.en =>
      'This example keeps a live camera preview on screen, streams microphone PCM chunks continuously, and uploads JPEG snapshots only while speech is being detected.',
  };

  String get refreshCamera => switch (lang) {
    AppLanguage.ko => '카메라 새로고침',
    AppLanguage.ja => 'カメラを再読込',
    AppLanguage.zh => '刷新摄像头',
    AppLanguage.en => 'Refresh Camera',
  };

  String get initializeCamera => switch (lang) {
    AppLanguage.ko => '카메라 초기화',
    AppLanguage.ja => 'カメラを初期化',
    AppLanguage.zh => '初始化摄像头',
    AppLanguage.en => 'Initialize Camera',
  };

  String get switchCamera => switch (lang) {
    AppLanguage.ko => '카메라 전환',
    AppLanguage.ja => 'カメラ切替',
    AppLanguage.zh => '切换摄像头',
    AppLanguage.en => 'Switch Camera',
  };

  String get startCameraVoice => switch (lang) {
    AppLanguage.ko => '카메라 + 음성 시작',
    AppLanguage.ja => 'カメラ + 音声を開始',
    AppLanguage.zh => '开启摄像头 + 语音',
    AppLanguage.en => 'Start Camera + Voice',
  };

  String get stopStream => switch (lang) {
    AppLanguage.ko => '스트림 중지',
    AppLanguage.ja => 'ストリーム停止',
    AppLanguage.zh => '停止流式传输',
    AppLanguage.en => 'Stop Stream',
  };

  String get micOn => switch (lang) {
    AppLanguage.ko => '마이크 켜짐',
    AppLanguage.ja => 'マイク ON',
    AppLanguage.zh => '麦克风已开启',
    AppLanguage.en => 'Mic on',
  };

  String get micIdle => switch (lang) {
    AppLanguage.ko => '마이크 대기',
    AppLanguage.ja => 'マイク待機',
    AppLanguage.zh => '麦克风空闲',
    AppLanguage.en => 'Mic idle',
  };

  String framesCount(int count) => switch (lang) {
    AppLanguage.ko => '프레임 $count',
    AppLanguage.ja => 'フレーム $count',
    AppLanguage.zh => '帧数 $count',
    AppLanguage.en => 'Frames $count',
  };

  String audioChunksCount(int count) => switch (lang) {
    AppLanguage.ko => '오디오 청크 $count',
    AppLanguage.ja => '音声チャンク $count',
    AppLanguage.zh => '音频块 $count',
    AppLanguage.en => 'Audio chunks $count',
  };

  // CameraPreviewView
  String get cameraNotReadyMessage => switch (lang) {
    AppLanguage.ko => '카메라 프리뷰가 아직 준비되지 않았습니다. 카메라 초기화를 탭하세요.',
    AppLanguage.ja => 'カメラプレビューはまだ準備できていません。「カメラを初期化」をタップしてください。',
    AppLanguage.zh => '摄像头预览尚未就绪。请轻触“初始化摄像头”。',
    AppLanguage.en =>
      'Camera preview is not ready yet. Tap Initialize Camera.',
  };

  String get cameraUnavailableMessage => switch (lang) {
    AppLanguage.ko =>
      '이 기기에서 카메라 프리뷰를 사용할 수 없거나, 권한이 허용되지 않았거나, 연결된 카메라가 없습니다.',
    AppLanguage.ja =>
      'このデバイスではカメラプレビューを利用できないか、権限が許可されていないか、カメラが接続されていません。',
    AppLanguage.zh => '此设备无法使用摄像头预览、未授予权限或未连接摄像头。',
    AppLanguage.en =>
      'Camera preview is unavailable on this device, permission has not been granted, or no camera is attached.',
  };

  // MediaControls
  String get sendRealtimeTextHint => switch (lang) {
    AppLanguage.ko => '실시간 텍스트 전송...',
    AppLanguage.ja => 'リアルタイムテキストを送信...',
    AppLanguage.zh => '发送实时文本...',
    AppLanguage.en => 'Send realtime text...',
  };

  String get endActivity => switch (lang) {
    AppLanguage.ko => '발화 활동 종료',
    AppLanguage.ja => 'アクティビティ終了',
    AppLanguage.zh => '结束活动',
    AppLanguage.en => 'End Activity',
  };

  String get startActivity => switch (lang) {
    AppLanguage.ko => '발화 활동 시작',
    AppLanguage.ja => 'アクティビティ開始',
    AppLanguage.zh => '开始活动',
    AppLanguage.en => 'Start Activity',
  };

  String get audioEnd => switch (lang) {
    AppLanguage.ko => '오디오 종료 신호',
    AppLanguage.ja => '音声終了信号',
    AppLanguage.zh => '音频结束信号',
    AppLanguage.en => 'Audio End',
  };

  String get sendImage => switch (lang) {
    AppLanguage.ko => '이미지 전송',
    AppLanguage.ja => '画像を送信',
    AppLanguage.zh => '发送图片',
    AppLanguage.en => 'Send Image',
  };

  String get mediaChunks => switch (lang) {
    AppLanguage.ko => '미디어 청크',
    AppLanguage.ja => 'メディアチャンク',
    AppLanguage.zh => '媒体数据块',
    AppLanguage.en => 'Media Chunks',
  };

  String get framePlusPrompt => switch (lang) {
    AppLanguage.ko => '프레임 + 프롬프트',
    AppLanguage.ja => 'フレーム + プロンプト',
    AppLanguage.zh => '当前帧 + 提示词',
    AppLanguage.en => 'Frame + Prompt',
  };

  // LogSection
  String get liveLogsTitle => switch (lang) {
    AppLanguage.ko => '실시간 로그',
    AppLanguage.ja => 'ライブログ',
    AppLanguage.zh => '实时日志',
    AppLanguage.en => 'Live Logs',
  };

  String entriesCount(int count) => switch (lang) {
    AppLanguage.ko => '$count개 항목',
    AppLanguage.ja => '$count 件',
    AppLanguage.zh => '$count 条记录',
    AppLanguage.en => '$count entries',
  };

  // ViewModel prompts & logs
  String get frameDescribePrompt => switch (lang) {
    AppLanguage.ko => '현재 카메라 화면에서 무엇이 보이는지 설명해 주세요.',
    AppLanguage.ja => '現在のカメラフレームに何が映っているか説明してください。',
    AppLanguage.zh => '请描述您在当前摄像头画面中看到的内容。',
    AppLanguage.en => 'Describe what you see in the current camera frame.',
  };

  String get logNoCamerasFound => switch (lang) {
    AppLanguage.ko => '⚠️ 이 플랫폼에서 카메라 장치를 찾을 수 없습니다.',
    AppLanguage.ja => '⚠️ このプラットフォームでカメラデバイスが見つかりませんでした。',
    AppLanguage.zh => '⚠️ 在此平台上未找到摄像头设备。',
    AppLanguage.en => '⚠️ No camera devices were found on this platform.',
  };

  String logCameraUnavailable(Object error) => switch (lang) {
    AppLanguage.ko => '❌ 카메라 사용 불가: $error',
    AppLanguage.ja => '❌ カメラを利用できません: $error',
    AppLanguage.zh => '❌ 摄像头不可用: $error',
    AppLanguage.en => '❌ Camera is unavailable: $error',
  };

  String logCameraReady(String label) => switch (lang) {
    AppLanguage.ko => '✅ 카메라 준비됨: $label',
    AppLanguage.ja => '✅ カメラ準備完了: $label',
    AppLanguage.zh => '✅ 摄像头已就绪: $label',
    AppLanguage.en => '✅ Camera ready: $label',
  };

  String logCameraInitFailed(Object error) => switch (lang) {
    AppLanguage.ko => '❌ 카메라 초기화 실패: $error',
    AppLanguage.ja => '❌ カメラ初期化失敗: $error',
    AppLanguage.zh => '❌ 摄像头初始化失败: $error',
    AppLanguage.en => '❌ Camera init failed: $error',
  };

  String get logCameraPreviewUnavailable => switch (lang) {
    AppLanguage.ko => '❌ 카메라 프리뷰를 사용할 수 없습니다. 카메라 권한 및 연결 상태를 확인하세요.',
    AppLanguage.ja => '❌ カメラプレビューを利用できません。カメラの権限と接続を確認してください。',
    AppLanguage.zh => '❌ 摄像头预览不可用。请检查摄像头权限和设备连接。',
    AppLanguage.en =>
      '❌ Camera preview is unavailable. Check camera access and whether a camera device is attached.',
  };

  String get logApiKeyNotConfigured => switch (lang) {
    AppLanguage.ko => '❌ API 키가 설정되지 않았습니다. 먼저 설정을 열어주세요.',
    AppLanguage.ja => '❌ APIキーが設定されていません。先に設定を開いてください。',
    AppLanguage.zh => '❌ 未配置 API 密钥。请先打开设置。',
    AppLanguage.en => '❌ API key is not configured. Open Settings first.',
  };

  String logConnecting(String model) => switch (lang) {
    AppLanguage.ko => 'Gemini 3.8 Live ($model)로 Live API에 연결 중...',
    AppLanguage.ja => 'Gemini 3.8 Live ($model) で Live API に接続中...',
    AppLanguage.zh => '正在使用 Gemini 3.8 Live ($model) 连接到 Live API...',
    AppLanguage.en =>
      'Connecting to Live API with Gemini 3.8 Live ($model)...',
  };

  String get logConnected => switch (lang) {
    AppLanguage.ko => '✅ 연결됨',
    AppLanguage.ja => '✅ 接続済み',
    AppLanguage.zh => '✅ 已连接',
    AppLanguage.en => '✅ Connected',
  };

  String get logDisconnected => switch (lang) {
    AppLanguage.ko => '🔒 연결 해제됨',
    AppLanguage.ja => '🔒 切断されました',
    AppLanguage.zh => '🔒 已断开连接',
    AppLanguage.en => '🔒 Disconnected',
  };

  String logConnectionFailed(Object error) => switch (lang) {
    AppLanguage.ko => '❌ 연결 실패: $error',
    AppLanguage.ja => '❌ 接続失敗: $error',
    AppLanguage.zh => '❌ 连接失败: $error',
    AppLanguage.en => '❌ Connection failed: $error',
  };
}
