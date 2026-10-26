import 'package:example/app_translations.dart';

/// Multilingual translation helper for ChatPage (en, ko, ja, zh).
class ChatI18n {
  final AppLanguage lang;
  const ChatI18n(this.lang);

  static ChatI18n get current =>
      ChatI18n(AppLanguageController.instance.currentLanguage);

  String get appBarTitle => switch (lang) {
    AppLanguage.ko => 'Gemini Live API 채팅',
    AppLanguage.ja => 'Gemini Live API チャット',
    AppLanguage.zh => 'Gemini Live API 聊天',
    AppLanguage.en => 'Gemini Live API',
  };

  String get chatModeTooltip => switch (lang) {
    AppLanguage.ko => '채팅 모드',
    AppLanguage.ja => 'チャットモード',
    AppLanguage.zh => '聊天模式',
    AppLanguage.en => 'Chat mode',
  };

  String get textMode => switch (lang) {
    AppLanguage.ko => '텍스트 모드',
    AppLanguage.ja => 'テキストモード',
    AppLanguage.zh => '文本模式',
    AppLanguage.en => 'Text Mode',
  };

  String get voiceMode => switch (lang) {
    AppLanguage.ko => '음성 모드',
    AppLanguage.ja => '音声モード',
    AppLanguage.zh => '语音模式',
    AppLanguage.en => 'Voice Mode',
  };

  String get settingsTooltip => switch (lang) {
    AppLanguage.ko => 'API 키 및 모델 설정',
    AppLanguage.ja => 'APIキーとモデル設定',
    AppLanguage.zh => 'API密钥与模型设置',
    AppLanguage.en => 'API Key & Model Settings',
  };

  String get reconnect => switch (lang) {
    AppLanguage.ko => '다시 연결',
    AppLanguage.ja => '再接続',
    AppLanguage.zh => '重新连接',
    AppLanguage.en => 'Reconnect',
  };

  String get recordingVoiceNotice => switch (lang) {
    AppLanguage.ko => '음성 입력 녹음 중... 마이크를 다시 탭하면 전송됩니다.',
    AppLanguage.ja => '音声入力を録音中... マイクをもう一度タップすると送信します。',
    AppLanguage.zh => '正在录制语音输入... 再次轻触麦克风即可发送。',
    AppLanguage.en => 'Recording voice input... tap the mic again to send it.',
  };

  String get voiceModeReadyNotice => switch (lang) {
    AppLanguage.ko => '음성 모드가 준비되었습니다. 마이크를 탭하여 음성을 녹음하세요.',
    AppLanguage.ja => '音声モードの準備ができました。マイクをタップして音声を録音してください。',
    AppLanguage.zh => '语音模式已就绪。轻触麦克风开始录制语音。',
    AppLanguage.en =>
      'Voice mode is ready. Tap the mic to record spoken input.',
  };

  String get stopRecordingTooltip => switch (lang) {
    AppLanguage.ko => '녹음 중지',
    AppLanguage.ja => '録音を停止',
    AppLanguage.zh => '停止录音',
    AppLanguage.en => 'Stop recording',
  };

  String get recordVoiceTooltip => switch (lang) {
    AppLanguage.ko => '음성 녹음',
    AppLanguage.ja => '音声を録音',
    AppLanguage.zh => '录制语音',
    AppLanguage.en => 'Record voice',
  };

  String get pickImageTooltip => switch (lang) {
    AppLanguage.ko => '이미지 첨부',
    AppLanguage.ja => '画像を添付',
    AppLanguage.zh => '添加图片',
    AppLanguage.en => 'Attach image',
  };

  String get sendTooltip => switch (lang) {
    AppLanguage.ko => '전송',
    AppLanguage.ja => '送信',
    AppLanguage.zh => '发送',
    AppLanguage.en => 'Send',
  };

  String get hintVoiceMode => switch (lang) {
    AppLanguage.ko => '메시지를 입력하거나 마이크를 사용하세요',
    AppLanguage.ja => 'メッセージを入力するかマイクを使用してください',
    AppLanguage.zh => '输入消息或使用麦克风',
    AppLanguage.en => 'Type a message or use the mic',
  };

  String get hintTextMode => switch (lang) {
    AppLanguage.ko => '메시지 또는 이미지 설명을 입력하세요',
    AppLanguage.ja => 'メッセージまたは画像の説明を入力してください',
    AppLanguage.zh => '输入消息或图片描述',
    AppLanguage.en => 'Enter a message or image description',
  };

  String get apiKeyNotConfigured => switch (lang) {
    AppLanguage.ko => 'Gemini API 키가 설정되지 않았습니다. 홈 화면으로 돌아가 설정을 열어주세요.',
    AppLanguage.ja => 'Gemini APIキーが設定されていません。ホーム画面に戻り設定を開いてください。',
    AppLanguage.zh => '未配置 Gemini API 密钥。请返回主屏幕并打开设置。',
    AppLanguage.en =>
      'Gemini API key is not configured. Go back and open Settings on the home screen.',
  };

  String get connectingVoice => switch (lang) {
    AppLanguage.ko => 'Gemini Live API에 연결 중 (음성 모드)...',
    AppLanguage.ja => 'Gemini Live API に接続中 (音声モード)...',
    AppLanguage.zh => '正在连接到 Gemini Live API（语音模式）...',
    AppLanguage.en => 'Connecting to Gemini Live API (voice mode)...',
  };

  String get connectingText => switch (lang) {
    AppLanguage.ko => 'Gemini Live API에 연결 중 (텍스트 모드)...',
    AppLanguage.ja => 'Gemini Live API に接続中 (テキストモード)...',
    AppLanguage.zh => '正在连接到 Gemini Live API（文本模式）...',
    AppLanguage.en => 'Connecting to Gemini Live API (text mode)...',
  };

  String get welcomeVoice => switch (lang) {
    AppLanguage.ko =>
      '안녕하세요! 음성 모드가 켜져 있습니다. 마이크 버튼을 눌러 말씀해 보세요. 응답이 실시간 자막으로 표시됩니다.',
    AppLanguage.ja =>
      'こんにちは！音声モードが有効です。マイクボタンを押して話しかけてください。応答はリアルタイム文字起こしとして表示されます。',
    AppLanguage.zh => '您好！语音模式已开启。请按麦克风按钮说话，回复将以实时字幕形式显示。',
    AppLanguage.en =>
      'Hello! Voice mode is on. Press the mic button to speak. Responses appear as live transcripts.',
  };

  String get welcomeText => switch (lang) {
    AppLanguage.ko =>
      '안녕하세요! 텍스트 모드가 켜져 있습니다. 메시지를 입력하거나 이미지를 첨부해 보세요. 응답이 실시간으로 표시됩니다.',
    AppLanguage.ja =>
      'こんにちは！テキストモードが有効です。メッセージを入力するか画像を添付してください。応答はリアルタイムで表示されます。',
    AppLanguage.zh => '您好！文本模式已开启。请输入消息或添加图片，回复将实时显示。',
    AppLanguage.en =>
      'Hello! Text mode is on. Type a message or attach an image. Responses appear as live transcripts.',
  };

  String connectionFailed(Object error) => switch (lang) {
    AppLanguage.ko =>
      'Gemini Live API 연결 실패: $error\n설정에서 API 키 또는 모델을 확인해 주세요.',
    AppLanguage.ja =>
      'Gemini Live API への接続に失敗しました: $error\n設定でAPIキーまたはモデルを確認してください。',
    AppLanguage.zh => '连接 Gemini Live API 失败: $error\n请在设置中检查您的 API 密钥或模型。',
    AppLanguage.en =>
      'Failed to connect to Gemini Live API: $error\nPlease check your API key or model in Settings.',
  };

  String get imageSelectionFailed => switch (lang) {
    AppLanguage.ko => '이미지 선택에 실패했습니다. 플랫폼 권한을 확인해 주세요.',
    AppLanguage.ja => '画像の選択に失敗しました。権限を確認してください。',
    AppLanguage.zh => '选择图片失败，请检查平台权限。',
    AppLanguage.en => 'Image selection failed. Check platform permissions.',
  };

  String get voiceInputSent => switch (lang) {
    AppLanguage.ko => '[음성 입력 전송됨]',
    AppLanguage.ja => '[音声入力を送信しました]',
    AppLanguage.zh => '[已发送语音输入]',
    AppLanguage.en => '[Voice input sent]',
  };

  String get yourVoiceInputLabel => switch (lang) {
    AppLanguage.ko => '내 음성 입력',
    AppLanguage.ja => 'あなたの音声入力',
    AppLanguage.zh => '您的语音输入',
    AppLanguage.en => 'Your voice input',
  };

  String get micPermissionRequired => switch (lang) {
    AppLanguage.ko =>
      '마이크 권한이 필요합니다. macOS [시스템 설정 > 개인정보 보호 및 보안 > 마이크]에서 앱을 허용해 주세요.',
    AppLanguage.ja => 'マイクの権限が必要です。システム設定の「プライバシーとセキュリティ > マイク」で許可してください。',
    AppLanguage.zh => '需要麦克风权限。请在系统设置的“隐私与安全性 > 麦克风”中允许此应用。',
    AppLanguage.en =>
      'Microphone permission is required. Please allow microphone access in System Settings.',
  };

  String micRecordingError(Object error) => switch (lang) {
    AppLanguage.ko => '마이크 녹음 오류: $error',
    AppLanguage.ja => 'マイク録音エラー: $error',
    AppLanguage.zh => '麦克风录音错误: $error',
    AppLanguage.en => 'Microphone recording error: $error',
  };
}
