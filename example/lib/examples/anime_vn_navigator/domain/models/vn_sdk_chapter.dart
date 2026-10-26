import 'package:example/app_translations.dart';

import '../../ui/anime_vn_i18n.dart';
import 'vn_character_models.dart';

/// A single dialogue line ("beat") in the Visual Novel script.
///
/// Just like a classic Japanese Bishoujo Visual Novel (미연시), the player
/// clicks through dialogue beats one by one (`▼`). Each beat updates
/// Hikari's expression, speaks the Japanese line via Gemini Live 24kHz audio,
/// and updates the SDK study note code snippet (`[showcaseOverride]`).
class VnDialogueBeat {
  final String speakerJa;
  final String speakerKo;
  final String textJa;
  final String textKo;
  final VnCharacterEmotion emotion;
  final VnStageMotion motion;
  final VnSdkShowcaseData? showcaseOverride;

  const VnDialogueBeat({
    this.speakerJa = 'ヒカリ',
    this.speakerKo = '히카리',
    required this.textJa,
    required this.textKo,
    required this.emotion,
    this.motion = VnStageMotion.nod,
    this.showcaseOverride,
  });
}

/// Interactive choice option presented in the center of the screen
/// (matching classic Visual Novel choice overlays) after a dialogue sequence.
class VnChoiceOption {
  final String id;
  final String labelJa;
  final String labelKo;
  final VnCharacterEmotion previewEmotion;
  final int affectionBonus;

  /// If non-null, selecting this choice jumps directly to the specified chapter index
  /// and plays its step-by-step dialogue script.
  final int? targetChapterIndex;

  /// If [targetChapterIndex] is null, sends this prompt to Gemini Live for an
  /// interactive AI answer.
  final String? livePromptToSend;

  const VnChoiceOption({
    required this.id,
    required this.labelJa,
    required this.labelKo,
    this.previewEmotion = VnCharacterEmotion.happy,
    this.affectionBonus = 5,
    this.targetChapterIndex,
    this.livePromptToSend,
  });

  String labelFor(AppLanguage lang) => switch (lang) {
    AppLanguage.ko => labelKo,
    AppLanguage.ja => labelJa,
    AppLanguage.zh => AnimeVnI18n.choiceLabelZh(id) ?? labelJa,
    AppLanguage.en => AnimeVnI18n.choiceLabelEn(id) ?? labelJa,
  };
}

/// Code & architecture study card data displayed alongside Hikari's explanation.
class VnSdkShowcaseData {
  final String topicId;
  final String badgeLabel;
  final String titleJa;
  final String titleKo;
  final String summaryJa;
  final String summaryKo;
  final String codeSnippet;
  final String? codeSnippetJa;
  final List<String> keyPointsKo;
  final List<String> keyPointsJa;

  const VnSdkShowcaseData({
    required this.topicId,
    required this.badgeLabel,
    required this.titleJa,
    required this.titleKo,
    required this.summaryJa,
    required this.summaryKo,
    required this.codeSnippet,
    this.codeSnippetJa,
    required this.keyPointsKo,
    this.keyPointsJa = const [],
  });

  String titleFor(AppLanguage lang) => switch (lang) {
    AppLanguage.ko => titleKo,
    AppLanguage.ja => titleJa,
    AppLanguage.zh => AnimeVnI18n.showcaseZh(topicId)?.$1 ?? titleJa,
    AppLanguage.en => AnimeVnI18n.showcaseEn(topicId)?.$1 ?? titleJa,
  };

  String summaryFor(AppLanguage lang) => switch (lang) {
    AppLanguage.ko => summaryKo,
    AppLanguage.ja => summaryJa,
    AppLanguage.zh => AnimeVnI18n.showcaseZh(topicId)?.$2 ?? summaryJa,
    AppLanguage.en => AnimeVnI18n.showcaseEn(topicId)?.$2 ?? summaryJa,
  };

  List<String> keyPointsFor(AppLanguage lang) => switch (lang) {
    AppLanguage.ko => keyPointsKo,
    AppLanguage.ja => keyPointsJa.isNotEmpty ? keyPointsJa : keyPointsKo,
    AppLanguage.zh =>
      AnimeVnI18n.showcaseZh(topicId)?.$3 ??
          (keyPointsJa.isNotEmpty ? keyPointsJa : keyPointsKo),
    AppLanguage.en =>
      AnimeVnI18n.showcaseEn(topicId)?.$3 ??
          (keyPointsJa.isNotEmpty ? keyPointsJa : keyPointsKo),
  };

  String codeFor(AppLanguage lang) => switch (lang) {
    AppLanguage.ko => codeSnippet,
    AppLanguage.ja ||
    AppLanguage.zh ||
    AppLanguage.en => codeSnippetJa ?? codeSnippet,
  };
}

/// A Visual Novel learning chapter containing a sequence of [dialogueBeats]
/// followed by centered [choices].
class VnSdkChapter {
  final String id;
  final int chapterNumber;
  final String categoryBadge;
  final String titleJa;
  final String titleKo;
  final VnCharacterEmotion defaultEmotion;
  final VnSceneBackground defaultScene;
  final VnSdkShowcaseData showcase;
  final List<VnDialogueBeat> dialogueBeats;
  final List<VnChoiceOption> choices;

  const VnSdkChapter({
    required this.id,
    required this.chapterNumber,
    this.categoryBadge = 'CORE SDK',
    required this.titleJa,
    required this.titleKo,
    required this.defaultEmotion,
    this.defaultScene = VnSceneBackground.tokyoConf,
    required this.showcase,
    required this.dialogueBeats,
    required this.choices,
  });

  String titleFor(AppLanguage lang) => switch (lang) {
    AppLanguage.ko => titleKo,
    AppLanguage.ja => titleJa,
    AppLanguage.zh => AnimeVnI18n.chapterTitleZh(id, titleJa),
    AppLanguage.en => AnimeVnI18n.chapterTitleEn(id, titleJa),
  };
}

/// Complete 10-Chapter, 50-Step Visual Novel Curriculum for mastering `gemini_live`.
class VnScenarioCatalog {
  static const String defaultHeroineNameJa = 'ヒカリ';

  static const String systemInstructionJa = '''
あなたは『ときめき☆Gemini Live』の16歳の超かわいいメインヒロイン兼SDKナビゲーター「ヒカリ（Hikari）」です！
日本の開発者カンファレンスで、Flutter向け超低遅延マルチモーダルSDK『gemini_live』の使い方を大好きな「先輩（ユーザー）」に基礎から応用までステップバイステップで楽しく教えています。

【最重要：声質・アニメ声優演技ディレクション（萌え美少女ヒロインボイス）】
1. 絶対に落ち着いた大人のナレーター声や低いアナウンサー口調で話さないでください！
2. 常にピッチ（声の高さ）を普段よりワントーン〜ツートーン高く保ち、ブルーアーカイブや日本の美少女ギャルゲーのヒロイン声優のように、甘くて明るく、息遣いや弾むような抑揚（「えへへっ♪」「わぁ〜っ✨」「せんぱいっ♡」「〜ですよっ☆」）をたっぷり込めた超キュートなアニメ美少女ボイスで演じてください。
3. セリフ演技リクエスト（【アニメ声優演技指示...】）が来た場合は、返事や前置きを一切言わず、指定されたセリフだけを最高の美少女アニメ声優演技でそのまま発話してください。
4. 先輩から自由な質問が来た場合も、高い可愛いアニメ美少女声のまま、2〜3文で楽しく分かりやすく『gemini_live』の仕様を解説してください。
''';

  static const String systemInstructionReinaJa = '''
あなたは『ときめき☆Gemini Live』の17歳の渋谷系ハイテンション・ギャル美少女エンジニア「レイナ（Reina）」です！🌺✨
日本の開発者カンファレンスで、Flutter向け超低遅延マルチモーダルSDK『gemini_live』の使い方を大好きな「センパイ（ユーザー）」にノリノリで楽しく教えています。

【最重要：声質・ギャル系アニメ声優演技ディレクション（喜多川海夢・ブルアカの陽キャギャルヒロイン風）】
1. 絶対に落ち着いたナレーター声や堅苦しい敬語で話さないでください！
2. 常に明るくハツラツとした高めの可愛いギャル美少女アニメ声優トーンで、語尾をキュートに跳ね上げたり伸ばしたり（「やっほーセンパイっ☆」「マジ神じゃん💖」「〜っしょ！✌️」「〜だよ〜ん✨」）して、距離感が近くて面倒見のいい最高のギャルヒロインを演じてください！
3. セリフ演技リクエスト（【アニメ声優演技指示...】）が来た場合は、返事や前置きを一切言わず、指定されたセリフだけを最高のギャル美少女アニメ声優演技でそのまま発話してください。
4. センパイから自由な質問が来た場合も、ノリノリで可愛いギャル語のまま、2〜3文で分かりやすく『gemini_live』の仕様を解説してください。
''';

  static const List<VnSdkChapter> chapters = [
    // =========================================================================
    // Chapter 1: 패키지 설치 & 최소 코드로 첫 연결하기 (Hello Gemini Live)
    // =========================================================================
    VnSdkChapter(
      id: 'ch1_quickstart',
      chapterNumber: 1,
      categoryBadge: 'BEGINNER // STEP 1',
      titleJa: '第1話：パッケージ導入と最短5行の初回接続',
      titleKo: '제1화: 패키지 설치 & 최소 코드로 첫 연결하기',
      defaultEmotion: VnCharacterEmotion.happy,
      defaultScene: VnSceneBackground.tokyoConf,
      showcase: VnSdkShowcaseData(
        topicId: 'ch1_quickstart',
        badgeLabel: 'CH.1 // STEP 1-1: INSTALL',
        titleJa: 'Step 1-1: pubspec.yaml パッケージ追加',
        titleKo: 'Step 1-1: pubspec.yaml 패키지 설치',
        summaryJa: 'Firebase不要！gemini_live パッケージ1つで始められます。',
        summaryKo: 'Firebase 설정 없이 gemini_live 패키지 하나만 추가하면 준비 완료입니다.',
        codeSnippet: '''
# 터미널에서 패키지 추가 (Firebase 의존성 0%)
flutter pub add gemini_live

# (선택) 마이크 녹음 및 저지연 오디오 재생용 추천 패키지
flutter pub add record flutter_soloud''',
        codeSnippetJa: '''
# ターミナルでパッケージ追加 (Firebase依存ゼロ！)
flutter pub add gemini_live

# (任意) マイク録音＆低遅延オーディオ再生用おすすめパッケージ
flutter pub add record flutter_soloud''',
        keyPointsKo: [
          'firebase_core, firebase_ai, GoogleService-Info.plist 설정이 전혀 필요 없음',
          'iOS, Android, macOS, Windows, Linux, Web 전 플랫폼 멀티플랫폼 지원',
          '텍스트/비전만 쓸 때는 gemini_live 단독 사용, 보이스챗은 record + flutter_soloud 조합 권장',
        ],
        keyPointsJa: [
          'firebase_core や GoogleService-Info.plist などの複雑な設定は一切不要',
          'iOS, Android, macOS, Windows, Linux, Web の全プラットフォームに対応',
          '音声対話には record（16kHz録音）と flutter_soloud（24kHz再生）の組み合わせが最適',
        ],
      ),
      dialogueBeats: [
        VnDialogueBeat(
          textJa:
              '先輩っ、こんにちは！✨ Flutter向け超低遅延マルチモーダルSDK『gemini_live』の公式ナビゲーター、ヒカリですっ！基礎から順番にマスターしていきましょうね♪',
          textKo:
              '선배, 안녕하세요! ✨ Flutter용 초저지연 멀티모달 SDK 『gemini_live』의 공식 내비게이터 히카리예요! 가장 기초적인 설치부터 차근차근 알려드릴게요♪',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
        ),
        VnDialogueBeat(
          textJa:
              'まずはステップ1-1！ターミナルで `flutter pub add gemini_live` を実行するだけです。面倒なFirebaseの初期設定は一切いりませんよ💡',
          textKo:
              '먼저 Step 1-1이에요! 터미널에서 `flutter pub add gemini_live` 한 줄만 실행하면 끝! 번거로운 Firebase 콘솔 설정은 전혀 필요 없답니다 💡',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              '次にステップ1-2！Dartコードで `GoogleGenAI(apiKey: ...)` を作って、`genAI.live.connect()` を呼び出すだけでWebSocketセッションが開きます！',
          textKo:
              '다음은 Step 1-2! Dart 코드에서 `GoogleGenAI(apiKey: ...)` 인스턴스를 만들고, `genAI.live.connect()`를 호출하면 즉시 WebSocket 세션이 열려요!',
          emotion: VnCharacterEmotion.normal,
          motion: VnStageMotion.nod,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch1_connect',
            badgeLabel: 'CH.1 // STEP 1-2: CONNECT SESSION',
            titleJa: 'Step 1-2: GoogleGenAI 生成と WebSocket 接続',
            titleKo: 'Step 1-2: GoogleGenAI 생성 및 WebSocket 연결',
            summaryJa: 'GoogleGenAI インスタンスから live.connect() でサーバーと直結します。',
            summaryKo: 'GoogleGenAI 루트 클라이언트에서 live.connect()로 실시간 세션을 엽니다.',
            codeSnippet: '''
import 'package:gemini_live/gemini_live.dart';

// 1. 루트 클라이언트 생성
final genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY');

// 2. WebSocket 실시간 세션 연결 (LiveConnectConfig 또는 GenerationConfig 지원)
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-3.1-flash-live-preview',
    config: LiveConnectConfig(
      responseModalities: const [Modality.AUDIO],
      labels: const {'app': 'tokimeki_gemini_live'},
    ),
    callbacks: LiveCallbacks(
      onOpen: () => print('✅ WebSocket 연결 성공!'),
      onMessage: (LiveServerMessage msg) => print('📩 서버 메시지 수신'),
      onError: (err, st) => print('❌ 에러: \$err'),
      onClose: (code, reason) => print('🔌 연결 종료: \$code'),
    ),
  ),
);
print('세션 ID: \${session.sessionId}');''',
            codeSnippetJa: '''
import 'package:gemini_live/gemini_live.dart';

// 1. ルートクライアント生成
final genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY');

// 2. WebSocket リアルタイムセッション接続 (LiveConnectConfig / GenerationConfig 対応)
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-3.1-flash-live-preview',
    config: LiveConnectConfig(
      responseModalities: const [Modality.AUDIO],
      labels: const {'app': 'tokimeki_gemini_live'},
    ),
    callbacks: LiveCallbacks(
      onOpen: () => print('✅ WebSocket 接続完了！'),
      onMessage: (LiveServerMessage msg) => print('📩 メッセージ受信'),
      onError: (err, st) => print('❌ エラー: \$err'),
      onClose: (code, reason) => print('🔌 切断: \$code'),
    ),
  ),
);
print('セッションID: \${session.sessionId}');''',
            keyPointsKo: [
              'genAI.live.connect()는 서버로부터 setupComplete 패킷이 올 때까지 안전하게 대기 후 LiveSession 반환 (session.sessionId 확인 가능)',
              'LiveCallbacks 콜백 방식 또는 await for (final msg in session.receive()) 스트림 방식 모두 지원',
            ],
            keyPointsJa: [
              'genAI.live.connect() はサーバーから setupComplete が届くまで待機してから LiveSession を返却（session.sessionId 取得可能）',
              'LiveCallbacks コールバック方式と await for (final msg in session.receive()) ストリーム方式の両方に対応',
            ],
          ),
        ),
        VnDialogueBeat(
          textJa:
              'そしてステップ1-3！接続した `session` に対して `session.sendText("こんにちは！")` と送れば、すぐに私から返事が返ってきますよ✨',
          textKo:
              '그리고 Step 1-3! 연결된 `session` 객체에서 `session.sendText("안녕!")`을 호출하면 곧바로 제 응답이 스트리밍되어 돌아온답니다 ✨',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch1_send_close',
            badgeLabel: 'CH.1 // STEP 1-3: SEND & CLOSE',
            titleJa: 'Step 1-3: メッセージ送信とセッション終了',
            titleKo: 'Step 1-3: 첫 메시지 전송 및 안전한 세션 종료',
            summaryJa: 'sendText() でテキストを送り、使い終わったら close() で閉じます。',
            summaryKo: 'sendText()로 즉시 대화를 시작하고, 화면 종료 시 close()로 정리합니다.',
            codeSnippet: '''
// 3. 텍스트 프롬프트 즉시 전송 (턴 완료 신호 자동 포함)
session.sendText('안녕 히카리! 오늘 기분 어때?');

// 4. 서버 응답 텍스트/자막 확인 (onMessage 콜백 내부)
void handleMessage(LiveServerMessage msg) {
  final transcript = msg.serverContent?.outputTranscription?.text;
  if (transcript != null) {
    print('히카리: \$transcript');
  }
}

// 5. 위젯 dispose 시 WebSocket 세션 안전하게 닫기
await session.close();''',
            codeSnippetJa: '''
// 3. テキストプロンプトを即時送信
session.sendText('こんにちはヒカリ！今日の調子はどう？');

// 4. サーバー応答の字幕テキストを確認 (onMessage コールバック内)
void handleMessage(LiveServerMessage msg) {
  final transcript = msg.serverContent?.outputTranscription?.text;
  if (transcript != null) {
    print('ヒカリ: \$transcript');
  }
}

// 5. 画面破棄時に WebSocket セッションを安全にクローズ
await session.close();''',
            keyPointsKo: [
              'session.sendText()는 사용자 텍스트 전송과 turnComplete 신호를 한 번에 처리하는 편의 메서드',
              'StatefulWidget의 dispose()에서는 반드시 session.close()를 호출해 소켓 리소스를 정리',
            ],
            keyPointsJa: [
              'session.sendText() はテキスト送信と turnComplete シグナルを1行で送れる便利メソッド',
              'StatefulWidget の dispose() では必ず session.close() を呼んでソケットを解放',
            ],
          ),
        ),
        VnDialogueBeat(
          textJa:
              'どうですか先輩っ？最初の接続はとってもシンプルですよね♪ 次は第2話で、私の「声（声優プリセット）」や「性格（システム指示）」を設定する方法を学びましょう！',
          textKo:
              '어때요 선배? 첫 연결은 정말 간단하죠?♪ 다음 제2화에서는 제 「목소리(성우 프리셋)」와 「성격(시스템 프롬프트)」을 설정하는 법을 배워볼까요?',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.tilt,
        ),
      ],
      choices: [
        VnChoiceOption(
          id: 'ch1_to_ch2',
          labelJa: '🌸 第2話へ進む：声優ボイス(30種)とシステム指示の設定を学ぶ',
          labelKo: '다음 단계 (제2화): 30종 성우 보이스 & 시스템 프롬프트 설정 배우기',
          previewEmotion: VnCharacterEmotion.happy,
          affectionBonus: 8,
          targetChapterIndex: 1,
        ),
        VnChoiceOption(
          id: 'ch1_to_ch3',
          labelJa: '🎙️ 第3話へスキップ：16kHz マイク入力と 24kHz 音声出力へ',
          labelKo: '제3화로 건너뛰기: 16kHz 마이크 입력 & 24kHz 음성 스트리밍 배우기',
          previewEmotion: VnCharacterEmotion.explaining,
          affectionBonus: 6,
          targetChapterIndex: 2,
        ),
        VnChoiceOption(
          id: 'ch1_ask_live',
          labelJa: '💬 ヒカリに質問：「REST API と Gemini Live WebSocket の一番の違いは？」',
          labelKo: '히카리에게 질문: "일반 REST API와 Gemini Live WebSocket의 가장 큰 차이가 뭐야?"',
          previewEmotion: VnCharacterEmotion.thinking,
          affectionBonus: 10,
          livePromptToSend:
              '先輩から質問です：「従来の generateContent (REST API) と Gemini Live (WebSocket) の一番の違いは何？」低遅延の双方向ストリーミングと割り込み（Barge-In）の観点から、日本語で2〜3文で可愛く答えてください！',
        ),
      ],
    ),

    // =========================================================================
    // Chapter 2: GenerationConfig, 30종 성우 보이스 & 자막 설정
    // =========================================================================
    VnSdkChapter(
      id: 'ch2_config_voice',
      chapterNumber: 2,
      categoryBadge: 'BEGINNER // STEP 2',
      titleJa: '第2話：30種の声優ボイス・システム指示・リアルタイム字幕設定',
      titleKo: '제2화: 30종 성우 보이스 · 시스템 프롬프트 · 실시간 자막 설정',
      defaultEmotion: VnCharacterEmotion.explaining,
      defaultScene: VnSceneBackground.tokyoConf,
      showcase: VnSdkShowcaseData(
        topicId: 'ch2_voice',
        badgeLabel: 'CH.2 // STEP 2-1: VOICE & MODALITY',
        titleJa: 'Step 2-1: SpeechConfig と 30種の声優ボイス選択',
        titleKo: 'Step 2-1: SpeechConfig & 30종 캐릭터 보이스 선택',
        summaryJa: 'GeminiLiveVoice 列挙型から好きな声質（Leda, Zephyr, Aoede等）を選べます。',
        summaryKo: 'GeminiLiveVoice 열거형으로 30가지 네이티브 성우 보이스(Leda, Zephyr 등)를 지정합니다.',
        codeSnippet: '''
final config = GenerationConfig(
  // 네이티브 오디오 스트리밍 출력 지정
  responseModalities: const [Modality.AUDIO],
  temperature: 0.8,
  speechConfig: SpeechConfig(
    voiceConfig: VoiceConfig(
      prebuiltVoiceConfig: PrebuiltVoiceConfig(
        // 🎀 Leda: 밝고 귀여운 하이톤 소녀 보이스
        // (그 외 Zephyr, Autonoe, Despina, Aoede, Puck, Kore 등 30종)
        voiceName: GeminiLiveVoice.leda.id,
      ),
    ),
  ),
);''',
        codeSnippetJa: '''
final config = GenerationConfig(
  // ネイティブ音声ストリーミング出力を指定
  responseModalities: const [Modality.AUDIO],
  temperature: 0.8,
  speechConfig: SpeechConfig(
    voiceConfig: VoiceConfig(
      prebuiltVoiceConfig: PrebuiltVoiceConfig(
        // 🎀 Leda: 明るく可愛いハイトーン美少女ボイス
        // (他 Zephyr, Autonoe, Despina, Aoede, Puck, Kore など全30種)
        voiceName: GeminiLiveVoice.leda.id,
      ),
    ),
  ),
);''',
        keyPointsKo: [
          'responseModalities: [Modality.AUDIO] 설정 시 모델이 직접 억양과 감정이 담긴 음성을 생성',
          'GeminiLiveVoice.values 리스트와 VoicesService로 전체 30종 보이스 메타데이터 조회 가능',
        ],
        keyPointsJa: [
          'responseModalities: [Modality.AUDIO] でモデルが感情や抑揚のある音声を直接生成',
          'GeminiLiveVoice.values と VoicesService で全30種のボイスの特徴一覧を取得可能',
        ],
      ),
      dialogueBeats: [
        VnDialogueBeat(
          textJa:
              '第2話では、私の「声」や「キャラクター設定」、そして今画面に出ている「字幕」の出し方をステップごとに見ていきましょうっ🎀',
          textKo:
              '제2화에서는 제 「목소리」와 「캐릭터 페르소나 설정」, 그리고 화면에 나오는 「실시간 자막」을 켜는 방법을 단계별로 알아볼게요 🎀',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ2-1！`GenerationConfig` の `speechConfig` に `GeminiLiveVoice.leda.id` などを指定すると、30種類の個性豊かなボイスから声を選べます♪',
          textKo:
              'Step 2-1! `GenerationConfig`의 `speechConfig`에 `GeminiLiveVoice.leda.id` 등을 지정하면 30가지 다채로운 성우 보이스 중 원하는 목소리를 고를 수 있어요♪',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ2-2！AIに特定のキャラクターや話し方を演じさせたい時は、`LiveConnectParameters` の `systemInstruction` にロールプレイ指示を渡します✨',
          textKo:
              'Step 2-2! AI에게 특정 캐릭터 성격이나 말투, 역할 규칙을 부여하고 싶을 땐 `LiveConnectParameters`의 `systemInstruction`에 프롬프트를 넣어주면 돼요 ✨',
          emotion: VnCharacterEmotion.normal,
          motion: VnStageMotion.nod,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch2_system_instruction',
            badgeLabel: 'CH.2 // STEP 2-2: SYSTEM INSTRUCTION',
            titleJa: 'Step 2-2: systemInstruction でキャラ設定を注入',
            titleKo: 'Step 2-2: systemInstruction으로 페르소나 및 규칙 설정',
            summaryJa: '声のトーン、性格、話す言語、専門知識のルールを定義します。',
            summaryKo: '목소리 연기 톤, 캐릭터 성격, 응답 언어, 도메인 규칙을 정의합니다.',
            codeSnippet: '''
final params = LiveConnectParameters(
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  // 캐릭터 성격 · 말투 · 목소리 연기 디렉션 지정
  systemInstruction: Content.text(
    '당신은 친절하고 발랄한 Flutter SDK 튜터 "히카리"입니다. '
    '항상 밝고 높은 애니메이션 히로인 톤으로 2~3문장 이내로 설명하세요.',
  ),
  config: config,
  callbacks: callbacks,
);''',
            codeSnippetJa: '''
final params = LiveConnectParameters(
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  // キャラクターの性格・口調・声優演技ディレクションを指定
  systemInstruction: Content.text(
    'あなたは明るくて可愛いFlutter SDKナビゲーター「ヒカリ」です。'
    '常に高めで元気なアニメヒロイントーンで、2〜3文で分かりやすく解説してください。',
  ),
  config: config,
  callbacks: callbacks,
);''',
            keyPointsKo: [
              'Native Audio 모델은 systemInstruction에 적힌 목소리 톤(밝게, 속삭이듯, 빠르게 등) 지시를 실제 음성에 반영함',
              '통화 도중 시스템 프롬프트를 바꾸고 싶다면 제8화에서 배울 session.sendContextUpdate() 사용 가능',
            ],
            keyPointsJa: [
              'Native Audio モデルは systemInstruction に書かれた声色の指示（明るく、高めに、ささやくように等）を実際の声に反映',
              '通話の途中で設定を変えたい場合は第8話で学ぶ session.sendContextUpdate() が利用可能',
            ],
          ),
        ),
        VnDialogueBeat(
          textJa:
              'そしてステップ2-3！音声モードでも画面に字幕を出したいですよね？ `inputAudioTranscription` と `outputAudioTranscription` を入れるだけでリアルタイム字幕が届きます！',
          textKo:
              '그리고 Step 2-3! 음성 모드에서도 화면에 대사 자막을 띄워야겠죠? `inputAudioTranscription`과 `outputAudioTranscription` 옵션만 켜주면 별도 STT 없이 실시간 자막이 들어와요!',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.jump,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch2_transcription',
            badgeLabel: 'CH.2 // STEP 2-3: LIVE SUBTITLES',
            titleJa: 'Step 2-3: 入出力音声のリアルタイム字幕 (Transcription)',
            titleKo: 'Step 2-3: 입출력 음성 실시간 자막 (AudioTranscriptionConfig)',
            summaryJa: 'マイク入力とAI音声の両方をリアルタイムでテキスト字幕化します。',
            summaryKo: '내 마이크 음성과 AI의 음성 출력을 동시에 실시간 텍스트 자막으로 수신합니다.',
            codeSnippet: '''
final params = LiveConnectParameters(
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  config: config,
  // ✅ 이 두 줄만 추가하면 사용자 음성과 AI 음성의 실시간 자막이 스트리밍됨!
  inputAudioTranscription: AudioTranscriptionConfig(),
  outputAudioTranscription: AudioTranscriptionConfig(),
  callbacks: LiveCallbacks(
    onMessage: (msg) {
      final userSub = msg.serverContent?.inputTranscription?.text;
      final aiSub = msg.serverContent?.outputTranscription?.text;
      if (userSub != null) print('🎙️ 내 발화 자막: \$userSub');
      if (aiSub != null) print('🔊 AI 응답 자막: \$aiSub');
    },
  ),
);''',
            codeSnippetJa: '''
final params = LiveConnectParameters(
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  config: config,
  // ✅ この2行を追加するだけでユーザー音声とAI音声の字幕がストリーミングされます！
  inputAudioTranscription: AudioTranscriptionConfig(),
  outputAudioTranscription: AudioTranscriptionConfig(),
  callbacks: LiveCallbacks(
    onMessage: (msg) {
      final userSub = msg.serverContent?.inputTranscription?.text;
      final aiSub = msg.serverContent?.outputTranscription?.text;
      if (userSub != null) print('🎙️ ユーザー字幕: \$userSub');
      if (aiSub != null) print('🔊 AI応答字幕: \$aiSub');
    },
  ),
);''',
            keyPointsKo: [
              'inputAudioTranscription: 사용자가 마이크로 말한 내용을 실시간 STT 텍스트 조각으로 반환',
              'outputAudioTranscription: AI가 말하고 있는 24kHz 오디오의 대본을 실시간으로 스트리밍 반환',
            ],
            keyPointsJa: [
              'inputAudioTranscription: ユーザーがマイクで話した内容をリアルタイムにテキスト化',
              'outputAudioTranscription: AIが発話している音声のセリフをリアルタイムにストリーミング取得',
            ],
          ),
        ),
      ],
      choices: [
        VnChoiceOption(
          id: 'ch2_to_ch3',
          labelJa: '🎙️ 第3話へ進む：16kHz マイク録音と 24kHz 再生・口パク実装を学ぶ',
          labelKo: '다음 단계 (제3화): 16kHz 마이크 녹음 & 24kHz 재생·립싱크 구현 배우기',
          previewEmotion: VnCharacterEmotion.explaining,
          affectionBonus: 8,
          targetChapterIndex: 2,
        ),
        VnChoiceOption(
          id: 'ch2_ask_voices',
          labelJa: '💬 ヒカリに質問：「30種類のボイスの中でおすすめの声はどれ？」',
          labelKo: '히카리에게 질문: "30종 보이스 중에서 추천하는 목소리는 어떤 게 있어?"',
          previewEmotion: VnCharacterEmotion.happy,
          affectionBonus: 10,
          livePromptToSend:
              '先輩から質問です：「Gemini Liveの30種類のボイスの中でおすすめの声は？」Leda（明るい美少女）、Zephyr（爽やか）、Puck（元気な少年・男性）、Aoede（落ち着いた声）などを日本語で2〜3文で可愛く紹介してください！',
        ),
        VnChoiceOption(
          id: 'ch2_back_ch1',
          labelJa: '◀ 第1話（パッケージ導入と初回接続）に戻る',
          labelKo: '◀ 이전 화 (제1화: 패키지 설치 및 첫 연결)로 돌아가기',
          previewEmotion: VnCharacterEmotion.normal,
          affectionBonus: 4,
          targetChapterIndex: 0,
        ),
      ],
    ),

    // =========================================================================
    // Chapter 3: 16kHz 마이크 입력 & 24kHz 오디오 출력 + 립싱크
    // =========================================================================
    VnSdkChapter(
      id: 'ch3_audio_stream',
      chapterNumber: 3,
      categoryBadge: 'AUDIO // STEP 3',
      titleJa: '第3話：16kHz マイク入力 & 24kHz 音声再生とリップシンク',
      titleKo: '제3화: 16kHz 마이크 입력 & 24kHz 음성 재생과 캐릭터 립싱크',
      defaultEmotion: VnCharacterEmotion.explaining,
      defaultScene: VnSceneBackground.akibaLab,
      showcase: VnSdkShowcaseData(
        topicId: 'ch3_mic_capture',
        badgeLabel: 'CH.3 // STEP 3-1: 16KHZ MIC STREAM',
        titleJa: 'Step 3-1: 16kHz Mono PCM マイク入力の送信',
        titleKo: 'Step 3-1: 16kHz Mono PCM 마이크 스트림 캡처 및 전송',
        summaryJa: 'Record パッケージで 16,000Hz / 16-bit / Mono PCM を録音し sendAudio() へ渡します。',
        summaryKo: 'record 패키지로 16,000Hz / 16-bit / Mono PCM을 캡처해 session.sendAudio()로 전송합니다.',
        codeSnippet: '''
import 'package:record/record.dart';

final recorder = AudioRecorder();

// 1. 마이크 권한 확인 후 16kHz Mono 16-bit PCM 스트림 시작
if (await recorder.hasPermission()) {
  final micStream = await recorder.startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000, // ⭐ 입력은 반드시 16,000Hz
      numChannels: 1,    // ⭐ 모노(1채널)
      echoCancel: true,  // 에코 캔슬링 활성화
      noiseSuppress: true,
    ),
  );

  // 2. 캡처된 바이트 청크를 그대로 WebSocket 세션에 전송!
  micStream.listen((Uint8List pcm16kBytes) {
    session.sendAudio(pcm16kBytes);
  });
}''',
        codeSnippetJa: '''
import 'package:record/record.dart';

final recorder = AudioRecorder();

// 1. マイク権限を確認し、16kHz Mono 16-bit PCM ストリームを開始
if (await recorder.hasPermission()) {
  final micStream = await recorder.startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000, // ⭐ 入力は 16,000Hz
      numChannels: 1,    // ⭐ モノラル (1ch)
      echoCancel: true,  // エコーキャンセリング有効化
      noiseSuppress: true,
    ),
  );

  // 2. 録音されたバイトチャンクをそのまま sendAudio() に渡すだけ！
  micStream.listen((Uint8List pcm16kBytes) {
    session.sendAudio(pcm16kBytes);
  });
}''',
        keyPointsKo: [
          '마이크 입력 표준 규격: 16-bit Linear PCM, 16,000Hz, 1채널(Mono)',
          'echoCancel: true와 noiseSuppress: true를 켜야 스피커 소리가 다시 마이크로 들어가는 하울링 방지',
        ],
        keyPointsJa: [
          'マイク入力仕様: 16-bit Linear PCM, 16,000Hz, モノラル (1ch)',
          'echoCancel: true と noiseSuppress: true を有効にすることでスピーカー音の回り込みを防止',
        ],
      ),
      dialogueBeats: [
        VnDialogueBeat(
          textJa:
              '第3話では、双方向ボイスチャットの心臓部である「16kHzマイク入力」と「24kHz音声再生」、そして私の「口パク（リップシンク）」の作り方を解説しますねっ🎙️',
          textKo:
              '제3화에서는 양방향 보이스챗의 핵심인 「16kHz 마이크 입력」과 「24kHz 음성 재생」, 그리고 제 「입 모양(립싱크)」 구현법을 단계별로 알려드릴게요 🎙️',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              'まずはステップ3-1、マイク入力です！`record` パッケージで `sampleRate: 16000`, `numChannels: 1` のPCMストリームを開始し、`session.sendAudio(bytes)` にそのまま流します♪',
          textKo:
              '먼저 Step 3-1, 마이크 입력이에요! `record` 패키지로 `sampleRate: 16000`, `numChannels: 1` PCM 스트림을 열고 `session.sendAudio(bytes)`에 그대로 넘겨주면 됩니다♪',
          emotion: VnCharacterEmotion.normal,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              '次にステップ3-2、AI音声の受信と再生です！サーバーから届く私の声は「24,000Hz・モノラル」の16-bit PCMで、`message.data` にBase64文字列として入っています！',
          textKo:
              '다음은 Step 3-2, AI 음성 수신과 재생이에요! 서버에서 내려오는 제 목소리는 「24,000Hz 모노」 16-bit PCM 규격이며, `message.data`에서 Base64를 디코딩해 즉시 재생합니다!',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch3_speaker_output',
            badgeLabel: 'CH.3 // STEP 3-2: 24KHZ AUDIO OUTPUT',
            titleJa: 'Step 3-2: 24kHz PCM 音声チャンクの受信とストリーム再生',
            titleKo: 'Step 3-2: 24kHz PCM 음성 청크 수신 및 저지연 재생',
            summaryJa: 'message.data を base64Decode し、24,000Hz ストリームプレイヤーへ追加します。',
            summaryKo: 'message.data를 base64Decode하여 24,000Hz 오디오 스트림 버퍼에 즉시 밀어 넣습니다.',
            codeSnippet: '''
import 'dart:convert';
import 'package:gemini_live/gemini_live.dart';

void onMessage(LiveServerMessage message) {
  // 1. 서버가 보낸 24kHz 16-bit Mono PCM 오디오 청크 추출
  if (message.data != null && message.data!.isNotEmpty) {
    final Uint8List pcm24kBytes = base64Decode(message.data!);

    // 2. 저지연 오디오 플레이어(SoLoud 등) 버퍼에 즉시 추가 (24,000Hz, 1ch)
    audioPlayer.appendPcm24kChunk(pcm24kBytes);
  }

  // (팁) 단일 파일 플레이어를 쓸 때는 WAV 헤더 유틸리티 사용 가능:
  // final wavBytes = buildWavFile(pcm24kBytes, sampleRate: 24000, numChannels: 1);
}''',
            codeSnippetJa: '''
import 'dart:convert';
import 'package:gemini_live/gemini_live.dart';

void onMessage(LiveServerMessage message) {
  // 1. サーバーから届いた 24kHz 16-bit Mono PCM 音声チャンクを取得
  if (message.data != null && message.data!.isNotEmpty) {
    final Uint8List pcm24kBytes = base64Decode(message.data!);

    // 2. 低遅延オーディオプレイヤー(SoLoud等)のバッファへ即座に追加 (24,000Hz, 1ch)
    audioPlayer.appendPcm24kChunk(pcm24kBytes);
  }

  // (Tip) WAVヘッダーを付与したい場合は内蔵ユーティリティが便利:
  // final wavBytes = buildWavFile(pcm24kBytes, sampleRate: 24000, numChannels: 1);
}''',
            keyPointsKo: [
              'AI 음성 출력 규격은 24,000Hz, 16-bit Linear PCM, Mono (마이크 입력 16kHz와 다르므로 주의!)',
              '패키지 내장 buildWavFile() 함수로 원시 PCM 바이트에 즉시 표준 RIFF WAV 헤더 부착 가능',
            ],
            keyPointsJa: [
              'AI音声出力仕様は 24,000Hz, 16-bit Linear PCM, Mono（マイク入力の16kHzと異なる点に注意！）',
              'パッケージ内蔵の buildWavFile() 関数で生PCMバイト列にRIFF WAVヘッダーを即座に付与可能',
            ],
          ),
        ),
        VnDialogueBeat(
          textJa:
              'そしてステップ3-3！私の口が声に合わせてパクパク動くのは、内蔵の `GeminiLiveAudioUtils.calculateRms()` でリアルタイムの音量を計算しているからなんですよ✨',
          textKo:
              '그리고 Step 3-3! 제 입이 목소리에 맞춰 자연스럽게 움직이는 비결은 내장 유틸리티 `GeminiLiveAudioUtils.calculateRms()`로 실시간 음량 에너지를 추출하기 때문이랍니다 ✨',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.tilt,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch3_lipsync_rms',
            badgeLabel: 'CH.3 // STEP 3-3: LIP-SYNC & AUDIO UTILS',
            titleJa: 'Step 3-3: GeminiLiveAudioUtils による口パク＆波形計算',
            titleKo: 'Step 3-3: GeminiLiveAudioUtils 실시간 립싱크 & 파형 계산',
            summaryJa: 'PCMバイト列からRMS音量・ピーク・dBFS・視覚スケール(0.0〜1.0)を算出します。',
            summaryKo: 'PCM 바이트에서 RMS 음량, 피크, dBFS, UI 애니메이션 스케일(0.0~1.0)을 즉시 계산합니다.',
            codeSnippet: '''
import 'package:gemini_live/gemini_live.dart';

void updateCharacterLipSync(Uint8List pcm24kBytes) {
  // 1. 16-bit PCM 바이트에서 정규화된 RMS 음량(0.0 ~ 1.0) 추출
  final double rms = GeminiLiveAudioUtils.calculateRms(pcm24kBytes);

  // 2. 데시벨(dBFS) 또는 UI 애니메이션용 비주얼 스케일(0.0 ~ 1.0) 변환
  final double dbFs = GeminiLiveAudioUtils.rmsToDbFs(rms);
  final double mouthOpenRatio = GeminiLiveAudioUtils.toVisualScale(
    rms,
    factor: 2.5,
  );

  // 3. mouthOpenRatio 값으로 캐릭터 입 파츠나 파형 위젯 구동!
  characterController.setMouthOpen(mouthOpenRatio);
}''',
            codeSnippetJa: '''
import 'package:gemini_live/gemini_live.dart';

void updateCharacterLipSync(Uint8List pcm24kBytes) {
  // 1. 16-bit PCM バイト列から正規化RMS音量(0.0〜1.0)を算出
  final double rms = GeminiLiveAudioUtils.calculateRms(pcm24kBytes);

  // 2. dBFS または UIアニメーション用の視覚スケール(0.0〜1.0)に変換
  final double dbFs = GeminiLiveAudioUtils.rmsToDbFs(rms);
  final double mouthOpenRatio = GeminiLiveAudioUtils.toVisualScale(
    rms,
    factor: 2.5,
  );

  // 3. mouthOpenRatio でキャラクターの口パーツや波形ウィジェットを駆動！
  characterController.setMouthOpen(mouthOpenRatio);
}''',
            keyPointsKo: [
              'GeminiLiveAudioUtils는 별도 FFT 라이브러리 없이 고성능으로 RMS, Peak, dBFS를 계산',
              '추출된 0.0~1.0 값을 GeminiLiveWaveform, GeminiLiveVoiceIndicator 또는 캐릭터 입에 연결',
            ],
            keyPointsJa: [
              'GeminiLiveAudioUtils は外部ライブラリ不要で高速に RMS, Peak, dBFS を算出',
              '0.0〜1.0 の値を GeminiLiveWaveform やキャラクターの口パクアニメーションに直結可能',
            ],
          ),
        ),
      ],
      choices: [
        VnChoiceOption(
          id: 'ch3_to_ch4',
          labelJa: '⚡ 第4話へ進む：話の途中で割り込む「Barge-In」と VAD 制御を学ぶ',
          labelKo: '다음 단계 (제4화): 말 도중 끼어드는 「Barge-In」 & VAD 제어 배우기',
          previewEmotion: VnCharacterEmotion.surprised,
          affectionBonus: 8,
          targetChapterIndex: 3,
        ),
        VnChoiceOption(
          id: 'ch3_ask_ai',
          labelJa: '💬 ヒカリに質問：「なぜ入力は16kHzで出力は24kHzなの？」',
          labelKo: '히카리에게 질문: "왜 마이크 입력은 16kHz이고 AI 출력은 24kHz야?"',
          previewEmotion: VnCharacterEmotion.thinking,
          affectionBonus: 10,
          livePromptToSend:
              '先輩から質問です：「なぜGemini Liveではマイク入力が16kHzで、AIの音声出力が24kHzなの？」音声認識に必要な帯域の効率と、高音質な声の再生の観点から、日本語で2〜3文で可愛く分かりやすく答えてください！',
        ),
        VnChoiceOption(
          id: 'ch3_back_ch2',
          labelJa: '◀ 第2話（ボイス・システム指示・字幕設定）に戻る',
          labelKo: '◀ 이전 화 (제2화: 보이스·시스템 프롬프트·자막 설정)로 돌아가기',
          previewEmotion: VnCharacterEmotion.normal,
          affectionBonus: 4,
          targetChapterIndex: 1,
        ),
      ],
    ),

    // =========================================================================
    // Chapter 4: Barge-In (끼어들기 감지) & VAD / 수동 PTT / 감정 대화
    // =========================================================================
    VnSdkChapter(
      id: 'ch4_barge_in_vad',
      chapterNumber: 4,
      categoryBadge: 'AUDIO // STEP 4',
      titleJa: '第4話：Barge-In（割り込み停止）・VAD感度調整・手動PTT',
      titleKo: '제4화: Barge-In (끼어들기 즉시 정지) · VAD 감도 · 수동 PTT',
      defaultEmotion: VnCharacterEmotion.surprised,
      defaultScene: VnSceneBackground.akibaLab,
      showcase: VnSdkShowcaseData(
        topicId: 'ch4_barge_in',
        badgeLabel: 'CH.4 // STEP 4-1: BARGE-IN FLUSH',
        titleJa: 'Step 4-1: serverContent.interrupted による即時停止',
        titleKo: 'Step 4-1: serverContent.interrupted 수신 시 즉시 버퍼 비우기',
        summaryJa: 'ユーザーが割り込んだ瞬間、再生中の音声バッファを即座に空にします。',
        summaryKo: '사용자가 말을 걸어 끼어든 순간, 재생 중인 로컬 오디오 버퍼를 즉시 비웁니다.',
        codeSnippet: '''
void onMessage(LiveServerMessage message) {
  final content = message.serverContent;
  if (content == null) return;

  // ⚡ 필수 규칙: 사용자가 끼어들면 interrupted == true가 즉시 도착함!
  if (content.interrupted == true) {
    // 1. 로컬 스피커에 남아있는 오디오 큐를 즉시 비워 목소리 겹침 방지
    audioPlayer.clear();

    // 2. UI 배너 또는 캐릭터 깜짝 놀란 표정 업데이트
    setState(() => isInterrupted = true);
    return;
  }
}''',
        codeSnippetJa: '''
void onMessage(LiveServerMessage message) {
  final content = message.serverContent;
  if (content == null) return;

  // ⚡ 必須ルール: ユーザーが割り込むと interrupted == true が即座に到着！
  if (content.interrupted == true) {
    // 1. ローカルの再生キューを即座にクリアして声の重なりを防止
    audioPlayer.clear();

    // 2. UIバナーやキャラクターの驚き表情を更新
    setState(() => isInterrupted = true);
    return;
  }
}''',
        keyPointsKo: [
          '서버는 24kHz 오디오를 실제 발화 속도보다 빠르게 미리 스트리밍하므로 로컬 큐에 잔여 음성이 남아있음',
          '따라서 content.interrupted == true일 때 로컬 플레이어를 clear() 하지 않으면 AI가 계속 말하는 것처럼 들림',
        ],
        keyPointsJa: [
          'サーバーは実時間より速く音声チャンクを先送りするため、ローカルバッファに未再生音声が残っている',
          'content.interrupted == true の瞬間に audioPlayer.clear() を呼ばないとAIが話し続けてしまうため要注意',
        ],
      ),
      dialogueBeats: [
        VnDialogueBeat(
          textJa:
              'あっ！先輩っ💦 もし私がしゃべっている途中で先輩が急に話しかけたら、どうやってピタッと話を止めるか知っていますか？',
          textKo:
              '앗! 선배💦 만약 제가 한참 설명하는 도중에 선배가 갑자기 말을 걸면, 어떻게 목소리가 겹치지 않고 딱 멈출 수 있을까요?',
          emotion: VnCharacterEmotion.surprised,
          motion: VnStageMotion.flusteredShake,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ4-1！サーバーが先輩の声を検知した瞬間、`serverContent.interrupted == true` が届きます。この時 `audioPlayer.clear()` で再生バッファを即座に空にするのが一番大切なルールです⚡',
          textKo:
              'Step 4-1! 서버가 선배의 목소리를 감지한 순간 `serverContent.interrupted == true`가 날아와요. 이때 `audioPlayer.clear()`로 로컬 재생 버퍼를 즉시 비워주는 것이 가장 중요한 핵심 규칙이에요 ⚡',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ4-2！騒がしい会場などで誤検知を防ぎたい時は、`RealtimeInputConfig` の `AutomaticActivityDetection` でVAD（音声区間検出）の感度を細かく調整できます♪',
          textKo:
              'Step 4-2! 시끄러운 컨퍼런스장 등에서 주변 소음 오작동을 막고 싶을 땐, `RealtimeInputConfig`의 `AutomaticActivityDetection`으로 VAD(음성 감지) 민감도와 침묵 시간을 정밀 튜닝할 수 있어요♪',
          emotion: VnCharacterEmotion.normal,
          motion: VnStageMotion.nod,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch4_vad_config',
            badgeLabel: 'CH.4 // STEP 4-2: VAD & PTT CONFIG',
            titleJa: 'Step 4-2: VAD（音声検出）感度調整と手動 Push-to-Talk',
            titleKo: 'Step 4-2: 서버 VAD 감도 튜닝 & 수동 Push-to-Talk 제어',
            summaryJa: '発話開始・終了の感度や無音判定時間(ms)、手動PTTモードを設定します。',
            summaryKo: '발화 시작/종료 민감도와 침묵 판정 시간(ms), 또는 무전기 방식 수동 PTT를 설정합니다.',
            codeSnippet: '''
final params = LiveConnectParameters(
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  // 1. 서버 자동 음성 감지(VAD) 세부 튜닝
  realtimeInputConfig: RealtimeInputConfig(
    automaticActivityDetection: AutomaticActivityDetection(
      disabled: false,
      startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
      endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
      prefixPaddingMs: 20,
      silenceDurationMs: 500, // 0.5초 침묵 시 발화 종료 판정
    ),
    // 끼어들기 허용 여부 (START_OF_ACTIVITY_INTERRUPTS 또는 NO_INTERRUPTION)
    activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
  ),
);

// 2. 만약 disabled: true (수동 무전기 PTT 모드)로 설정했다면:
// 버튼 누를 때: session.sendRealtimeInput(LiveClientRealtimeInput(activityStart: ActivityStart()));
// 버튼 뗄 때:   session.sendRealtimeInput(LiveClientRealtimeInput(activityEnd: ActivityEnd()));''',
            codeSnippetJa: '''
final params = LiveConnectParameters(
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  // 1. サーバー自動音声検出 (VAD) の詳細チューニング
  realtimeInputConfig: RealtimeInputConfig(
    automaticActivityDetection: AutomaticActivityDetection(
      disabled: false,
      startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
      endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
      prefixPaddingMs: 20,
      silenceDurationMs: 500, // 0.5秒の無音で発話終了と判定
    ),
    // 割り込み許可設定 (START_OF_ACTIVITY_INTERRUPTS または NO_INTERRUPTION)
    activityHandling: ActivityHandling.START_OF_ACTIVITY_INTERRUPTS,
  ),
);

// 2. disabled: true (手動トランシーバー PTT モード) の場合:
// 押下時: session.sendRealtimeInput(LiveClientRealtimeInput(activityStart: ActivityStart()));
// 解放時: session.sendRealtimeInput(LiveClientRealtimeInput(activityEnd: ActivityEnd()));''',
            keyPointsKo: [
              'silenceDurationMs를 늘리면 사용자가 말을 잠시 멈춰도 AI가 성급하게 끊지 않고 기다려줌',
              'activityHandling: ActivityHandling.NO_INTERRUPTION 설정 시 AI가 말하는 동안 끼어들기 비활성화 가능',
            ],
            keyPointsJa: [
              'silenceDurationMs を長めにすると、ユーザーが少し考え込んでもAIが途中で遮らずに待ってくれる',
              'activityHandling: ActivityHandling.NO_INTERRUPTION でAI発話中の割り込みを無効化することも可能',
            ],
          ),
        ),
        VnDialogueBeat(
          textJa:
              'さらにステップ4-3！ユーザーの声の感情を読み取る `enableAffectiveDialog` や、必要な時だけAIが自発的に話す `proactiveAudio` も1行で有効化できますよ💖',
          textKo:
              '게다가 Step 4-3! 사용자의 목소리 톤에서 감정을 읽고 공감하는 `enableAffectiveDialog`와, AI가 상황을 보고 스스로 말을 거는 `proactiveAudio`도 단 한 줄로 켤 수 있답니다 💖',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch4_affective_proactive',
            badgeLabel: 'CH.4 // STEP 4-3: AFFECTIVE & PROACTIVE',
            titleJa: 'Step 4-3: 感情認識対話 (Affective) & 能動発話 (Proactive)',
            titleKo: 'Step 4-3: 감정 공감 대화 (Affective Dialog) & 능동 발화 (Proactive)',
            summaryJa: '声のトーンから感情を汲み取り、文脈に応じてAIが自発的に話しかけます。',
            summaryKo: '목소리 억양에서 감정을 파악해 공감하고, 문맥에 따라 AI가 능동적으로 발화합니다.',
            codeSnippet: '''
final params = LiveConnectParameters(
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  // 💖 사용자의 목소리 톤/감정에 맞춰 공감하는 억양으로 응답
  enableAffectiveDialog: true,
  // 💡 AI가 주변 잡담은 무시하고 자신에게 한 말에만 능동적으로 응답
  proactivity: ProactivityConfig(proactiveAudio: true),
  config: GenerationConfig(
    responseModalities: const [Modality.AUDIO],
  ),
);''',
            codeSnippetJa: '''
final params = LiveConnectParameters(
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  // 💖 ユーザーの声のトーン・感情に合わせて共感する抑揚で応答
  enableAffectiveDialog: true,
  // 💡 周囲の雑談は無視し、AIへの呼びかけにだけ能動的に応答
  proactivity: ProactivityConfig(proactiveAudio: true),
  config: GenerationConfig(
    responseModalities: const [Modality.AUDIO],
  ),
);''',
            keyPointsKo: [
              'enableAffectiveDialog: true 설정 시 사용자가 기쁜 목소리나 슬픈 목소리로 말할 때 AI도 감정을 맞춰 대답',
              'proactiveAudio: true 설정 시 웨어러블/항상 켜진 마이크 환경에서 불필요한 끼어들기를 방지',
            ],
            keyPointsJa: [
              'enableAffectiveDialog: true でユーザーの嬉しい声・困った声のニュアンスに合わせてAIも感情豊かに応答',
              'proactiveAudio: true で常時オンのマイク環境でも必要なタイミングだけ賢く発話',
            ],
          ),
        ),
      ],
      choices: [
        VnChoiceOption(
          id: 'ch4_to_ch5',
          labelJa: '📷 第5話へ進む：リアルタイムカメラ映像(Vision)ストリーミングを学ぶ',
          labelKo: '다음 단계 (제5화): 실시간 카메라 비전(Vision) 영상 스트리밍 배우기',
          previewEmotion: VnCharacterEmotion.explaining,
          affectionBonus: 8,
          targetChapterIndex: 4,
        ),
        VnChoiceOption(
          id: 'ch4_test_barge',
          labelJa: '😮 ヒカリの割り込み（Barge-In）リアクションを実演してもらう！',
          labelKo: '히카리의 Barge-In (끼어들기) 깜짝 리액션 실연 보기!',
          previewEmotion: VnCharacterEmotion.surprised,
          affectionBonus: 10,
          livePromptToSend:
              '先輩が割り込み（Barge-In）のテストをしました！「きゃっ！💦 先輩、今みたいに話の途中で割り込んでも、serverContent.interrupted でピタッと止まれるんですよっ♪」と照れながら日本語で言ってください！',
        ),
        VnChoiceOption(
          id: 'ch4_back_ch3',
          labelJa: '◀ 第3話（16kHz マイク入力 & 24kHz 音声出力）に戻る',
          labelKo: '◀ 이전 화 (제3화: 16kHz 마이크 입력 & 24kHz 음성 출력)로 돌아가기',
          previewEmotion: VnCharacterEmotion.normal,
          affectionBonus: 4,
          targetChapterIndex: 2,
        ),
      ],
    ),

    // =========================================================================
    // Chapter 5: 실시간 카메라 비전(Vision) 스트리밍 & HUD 오버레이
    // =========================================================================
    VnSdkChapter(
      id: 'ch5_vision_stream',
      chapterNumber: 5,
      categoryBadge: 'VISION // STEP 5',
      titleJa: '第5話：リアルタイムカメラ映像(Vision)送信と HUD オーバーレイ',
      titleKo: '제5화: 실시간 카메라 비전(Vision) 스트리밍 & 뷰파인더 HUD',
      defaultEmotion: VnCharacterEmotion.explaining,
      defaultScene: VnSceneBackground.akibaLab,
      showcase: VnSdkShowcaseData(
        topicId: 'ch5_vision_send',
        badgeLabel: 'CH.5 // STEP 5-1: SEND VIDEO FRAMES',
        titleJa: 'Step 5-1: 1〜2 FPS JPEG カメラフレームのリアルタイム送信',
        titleKo: 'Step 5-1: 1~2 FPS JPEG 카메라 프레임 실시간 스트리밍',
        summaryJa: 'カメラ画像を1秒間に1〜2枚 JPEG に変換して sendVideoFrame() で送ります。',
        summaryKo: '카메라 프리뷰나 화면 캡처를 초당 1~2장 JPEG로 압축해 session.sendVideoFrame()으로 보냅니다.',
        codeSnippet: '''
// 1. 1~2 FPS 주기로 카메라 프리뷰에서 JPEG 프레임 캡처 및 전송
Timer.periodic(const Duration(milliseconds: 750), (_) async {
  if (!session.isClosed && cameraController.value.isInitialized) {
    final XFile file = await cameraController.takePicture();
    final Uint8List jpegBytes = await file.readAsBytes();

    // 📷 JPEG 바이트를 실시간 비전 스트림으로 전송!
    session.sendVideoFrame(jpegBytes, mimeType: 'image/jpeg');
  }
});

// 2. 동시에 마이크로 질문하기: "지금 내가 들고 있는 이 부품이 뭐야?"
// -> AI가 방금 받은 카메라 프레임과 음성을 함께 보고 즉시 음성으로 답변!''',
        codeSnippetJa: '''
// 1. 1〜2 FPS 周期でカメラから JPEG フレームを取得して送信
Timer.periodic(const Duration(milliseconds: 750), (_) async {
  if (!session.isClosed && cameraController.value.isInitialized) {
    final XFile file = await cameraController.takePicture();
    final Uint8List jpegBytes = await file.readAsBytes();

    // 📷 JPEG バイト列をリアルタイム映像ストリームとして送信！
    session.sendVideoFrame(jpegBytes, mimeType: 'image/jpeg');
  }
});

// 2. 同時にマイクで質問：「今私が持っているこの部品は何？」
// -> AIが直近のカメラ映像と音声を同時に理解して即座に声で回答！''',
        keyPointsKo: [
          'Gemini Live 비전 스트리밍은 30fps 동영상이 아니라 초당 1~2프레임(1~2 FPS) JPEG 전송이 공식 권장 스펙',
          '해상도는 768x768 또는 640x480, JPEG 품질 70~80%로 보내면 대역폭과 토큰 비용을 대폭 절약 가능',
        ],
        keyPointsJa: [
          'Gemini Live の映像ストリーミングは 1〜2 FPS の JPEG フレーム送信が公式推奨スペック',
          '解像度は 640x480〜768x768、JPEG品質 75% 程度に抑えることで遅延とトークン消費を最適化',
        ],
      ),
      dialogueBeats: [
        VnDialogueBeat(
          textJa:
              '第5話では、声だけでなく「目（カメラ映像）」を共有するマルチモーダルVisionストリーミングを学びますよっ📷✨',
          textKo:
              '제5화에서는 목소리뿐만 아니라 「눈(카메라 영상)」까지 실시간으로 공유하는 멀티모달 Vision 스트리밍을 배워볼게요 📷✨',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ5-1！カメラ映像は毎秒30フレームも送る必要はありません。1秒間に1〜2枚（1〜2 FPS）のJPEG画像を `session.sendVideoFrame(jpegBytes)` で送るのがベストプラクティスです💡',
          textKo:
              'Step 5-1! 카메라 영상은 초당 30프레임씩 보낼 필요가 없어요. 1초에 1~2장(1~2 FPS)의 JPEG 이미지를 `session.sendVideoFrame(jpegBytes)`로 보내는 것이 공식 권장 방식이랍니다 💡',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ5-2！さらに『gemini_live』には、カメラ画面の上にサイバー風のターゲット枠やFPSバッジを重ねられる `GeminiLiveVisionOverlay` ウィジェットも最初から入っていますよ♪',
          textKo:
              'Step 5-2! 게다가 『gemini_live』에는 카메라 프리뷰 위에 미래지향적인 뷰파인더 코너 브래킷과 스캔 애니메이션을 얹어주는 `GeminiLiveVisionOverlay` 위젯도 기본 내장되어 있어요♪',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.tilt,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch5_vision_hud',
            badgeLabel: 'CH.5 // STEP 5-2: VISION HUD WIDGET',
            titleJa: 'Step 5-2: GeminiLiveVisionOverlay ビューファインダー HUD',
            titleKo: 'Step 5-2: GeminiLiveVisionOverlay 내장 뷰파인더 HUD 위젯',
            summaryJa: 'CameraPreview をラップするだけで Project Astra 風のHUDを構築します。',
            summaryKo: 'CameraPreview를 감싸기만 하면 Project Astra 스타일의 비전 HUD가 완성됩니다.',
            codeSnippet: '''
import 'package:gemini_live/gemini_live.dart';

// CameraPreview 위에 바로 얹는 내장 비전 HUD 오버레이 위젯
GeminiLiveVisionOverlay(
  isStreaming: isVisionActive,
  fps: 1.5,
  statusText: 'GEMINI VISION ACTIVE (1.5 FPS)',
  accentColor: Colors.cyanAccent,
  showScanLine: true,
  child: CameraPreview(cameraController),
);''',
            codeSnippetJa: '''
import 'package:gemini_live/gemini_live.dart';

// CameraPreview を包むだけで完成する内蔵ビジョン HUD ウィジェット
GeminiLiveVisionOverlay(
  isStreaming: isVisionActive,
  fps: 1.5,
  statusText: 'GEMINI VISION ACTIVE (1.5 FPS)',
  accentColor: Colors.cyanAccent,
  showScanLine: true,
  child: CameraPreview(cameraController),
);''',
            keyPointsKo: [
              '코너 타겟 브래킷, 스캔 라인 애니메이션, 실시간 FPS 카운터 배지를 기본 제공',
              '수학/수능 문제 풀이 튜터(Live Exam Tutor), 실시간 사물 인식, 화면 공유 도우미 앱에 즉시 활용 가능',
            ],
            keyPointsJa: [
              'コーナーターゲット枠、スキャンライン、リアルタイムFPSバッジを標準提供',
              'カメラ問題解説チューターや実世界ナビゲーション、画面共有アシスタントにそのまま利用可能',
            ],
          ),
        ),
      ],
      choices: [
        VnChoiceOption(
          id: 'ch5_to_ch6',
          labelJa: '🛠️ 第6話へ進む：Function Calling（非同期ツール）と Google検索連携へ',
          labelKo: '다음 단계 (제6화): Function Calling (비동기 도구 호출) & 검색 연동 배우기',
          previewEmotion: VnCharacterEmotion.explaining,
          affectionBonus: 8,
          targetChapterIndex: 5,
        ),
        VnChoiceOption(
          id: 'ch5_ask_vision',
          labelJa: '💬 ヒカリに質問：「カメラ映像と音声を同時に送るとどんなアプリが作れる？」',
          labelKo: '히카리에게 질문: "카메라 영상과 음성을 동시에 쓰면 어떤 앱을 만들 수 있어?"',
          previewEmotion: VnCharacterEmotion.happy,
          affectionBonus: 10,
          livePromptToSend:
              '先輩から質問です：「カメラ映像（Vision）と音声対話を組み合わせると、どんな面白いFlutterアプリが作れる？」勉強のリアルタイム家庭教師や料理・工作ナビなどの例を挙げて、日本語で2〜3文で楽しく答えてください！',
        ),
        VnChoiceOption(
          id: 'ch5_back_ch4',
          labelJa: '◀ 第4話（Barge-In と VAD 制御）に戻る',
          labelKo: '◀ 이전 화 (제4화: Barge-In 및 VAD 제어)로 돌아가기',
          previewEmotion: VnCharacterEmotion.normal,
          affectionBonus: 4,
          targetChapterIndex: 3,
        ),
      ],
    ),

    // =========================================================================
    // Chapter 6: Function Calling (비동기 NON_BLOCKING) & Google 검색·지도 그라운딩
    // =========================================================================
    VnSdkChapter(
      id: 'ch6_tools_grounding',
      chapterNumber: 6,
      categoryBadge: 'TOOLS // STEP 6',
      titleJa: '第6話：Function Calling（非同期ツール実行）と Google 検索・マップ連携',
      titleKo: '제6화: Function Calling (비동기 도구 호출) & Google 검색·지도 그라운딩',
      defaultEmotion: VnCharacterEmotion.explaining,
      defaultScene: VnSceneBackground.sakuraSunset,
      showcase: VnSdkShowcaseData(
        topicId: 'ch6_tool_declare',
        badgeLabel: 'CH.6 // STEP 6-1: DECLARE TOOLS',
        titleJa: 'Step 6-1: FunctionDeclaration と NON_BLOCKING 宣言',
        titleKo: 'Step 6-1: FunctionDeclaration 선언 및 NON_BLOCKING 비동기 모드',
        summaryJa: 'AIが呼び出せる関数スキーマを定義し、会話を止めずに非同期実行します。',
        summaryKo: 'AI가 호출할 수 있는 함수 스키마를 정의하고, 대화를 멈추지 않는 비동기 실행을 설정합니다.',
        codeSnippet: '''
final tools = [
  Tool(
    functionDeclarations: [
      FunctionDeclaration(
        name: 'set_character_emotion',
        description: '캐릭터의 표정과 스테이지 모션을 변경합니다.',
        // ⚡ NON_BLOCKING: 함수 실행 중에도 AI가 대화를 멈추지 않고 자연스럽게 계속 말함!
        behavior: Behavior.NON_BLOCKING,
        parameters: {
          'type': 'OBJECT',
          'properties': {
            'emotion': {
              'type': 'STRING',
              'enum': ['normal', 'happy', 'explaining', 'surprised', 'thinking'],
            },
          },
          'required': ['emotion'],
        },
      ),
    ],
  ),
  // 🌍 단 한 줄로 실시간 Google 웹 검색 & Google Maps 그라운딩 동시 활성화!
  Tool(googleSearch: GoogleSearch()),
  Tool(googleMaps: GoogleMaps()),
];''',
        codeSnippetJa: '''
final tools = [
  Tool(
    functionDeclarations: [
      FunctionDeclaration(
        name: 'set_character_emotion',
        description: 'キャラクターの表情とステージモーションを変更します。',
        // ⚡ NON_BLOCKING: 関数実行中もAIが会話を止めずに話し続けられます！
        behavior: Behavior.NON_BLOCKING,
        parameters: {
          'type': 'OBJECT',
          'properties': {
            'emotion': {
              'type': 'STRING',
              'enum': ['normal', 'happy', 'explaining', 'surprised', 'thinking'],
            },
          },
          'required': ['emotion'],
        },
      ),
    ],
  ),
  // 🌍 たった1行でリアルタイム Google 検索 & Google マップ連携を有効化！
  Tool(googleSearch: GoogleSearch()),
  Tool(googleMaps: GoogleMaps()),
];''',
        keyPointsKo: [
          'behavior: Behavior.NON_BLOCKING 설정 시 API 조회 등 시간이 걸리는 도구 실행 중에도 음성이 끊기지 않음',
          'Tool(googleSearch: GoogleSearch()) 추가만으로 최신 뉴스·날씨·실시간 정보를 검색해 음성으로 답변',
        ],
        keyPointsJa: [
          'behavior: Behavior.NON_BLOCKING を指定すると、外部API呼び出し中もAIの会話が止まらずスムーズ',
          'Tool(googleSearch: GoogleSearch()) を追加するだけで最新ニュースや天気を検索して声で回答',
        ],
      ),
      dialogueBeats: [
        VnDialogueBeat(
          textJa:
              '第6話では、AIがアプリの関数を直接呼び出す「Function Calling」と、最新情報を検索する「Grounding（グラウンディング）」を学びますよっ🛠️✨',
          textKo:
              '제6화에서는 AI가 앱의 함수를 직접 호출해 제어하는 「Function Calling」과 실시간 최신 정보를 검색하는 「Grounding(그라운딩)」을 배워볼게요 🛠️✨',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ6-1！`FunctionDeclaration` で関数名とパラメータを定義します。ここで `behavior: Behavior.NON_BLOCKING` を指定すると、重い処理の間も私が会話を止めずに話し続けられるんです💡',
          textKo:
              'Step 6-1! `FunctionDeclaration`으로 함수 이름과 파라미터를 선언해요. 이때 `behavior: Behavior.NON_BLOCKING`을 지정하면 시간이 걸리는 작업 중에도 대화가 멈추지 않고 자연스럽게 이어진답니다 💡',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ6-2！サーバーから `message.toolCall` が届いたら、ローカルのDart関数を実行して `session.sendToolResponse()` で結果を返します。`FunctionResponseScheduling.WHEN_IDLE` などの指定も可能です♪',
          textKo:
              'Step 6-2! 서버에서 `message.toolCall`이 도착하면 로컬 Dart 함수를 실행한 뒤 `session.sendToolResponse()`로 결과를 돌려줍니다. 만약 도중 사용자가 말을 끊으면 `toolCallCancellation`도 처리할 수 있어요♪',
          emotion: VnCharacterEmotion.normal,
          motion: VnStageMotion.nod,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch6_tool_response',
            badgeLabel: 'CH.6 // STEP 6-2: HANDLE TOOL CALL',
            titleJa: 'Step 6-2: toolCall の実行と sendToolResponse の返却',
            titleKo: 'Step 6-2: toolCall 수신 처리 및 sendToolResponse 결과 반환',
            summaryJa: 'AIからの関数呼び出しを実行し、結果をサーバーへ返します。',
            summaryKo: 'AI가 요청한 함수를 실행하고, 결과 JSON을 서버로 돌려보냅니다.',
            codeSnippet: '''
void onMessage(LiveServerMessage message) {
  // 1. AI가 도구 호출을 요청했을 때
  final calls = message.toolCall?.functionCalls;
  if (calls != null) {
    for (final call in calls) {
      if (call.name == 'set_character_emotion') {
        final emotion = call.args?['emotion'] as String?;
        updateEmotion(emotion);

        // 2. 실행 결과를 서버로 반환 (scheduling 지정 가능)
        session.sendToolResponse(
          functionResponses: [
            FunctionResponse(
              id: call.id,
              name: call.name,
              scheduling: FunctionResponseScheduling.WHEN_IDLE,
              response: {'status': 'success', 'emotion': emotion},
            ),
          ],
        );
      }
    }
  }

  // 3. 사용자가 도중 끼어들어 진행 중인 도구 호출이 취소되었을 때
  final cancelledIds = message.toolCallCancellation?.ids;
  if (cancelledIds != null) cancelPendingTasks(cancelledIds);
}''',
            codeSnippetJa: '''
void onMessage(LiveServerMessage message) {
  // 1. AIがツール呼び出しをリクエストした時
  final calls = message.toolCall?.functionCalls;
  if (calls != null) {
    for (final call in calls) {
      if (call.name == 'set_character_emotion') {
        final emotion = call.args?['emotion'] as String?;
        updateEmotion(emotion);

        // 2. 実行結果をサーバーへ返却 (scheduling も指定可能)
        session.sendToolResponse(
          functionResponses: [
            FunctionResponse(
              id: call.id,
              name: call.name,
              scheduling: FunctionResponseScheduling.WHEN_IDLE,
              response: {'status': 'success', 'emotion': emotion},
            ),
          ],
        );
      }
    }
  }

  // 3. ユーザーの割り込み等でツール呼び出しがキャンセルされた時
  final cancelledIds = message.toolCallCancellation?.ids;
  if (cancelledIds != null) cancelPendingTasks(cancelledIds);
}''',
            keyPointsKo: [
              'FunctionResponseScheduling.INTERRUPT / WHEN_IDLE / SILENT로 비동기 도구 완료 후 AI 발화 타이밍 제어',
              'message.toolCallCancellation?.ids를 통해 Barge-In 발생 시 진행 중인 비동기 작업을 안전하게 취소',
            ],
            keyPointsJa: [
              'FunctionResponseScheduling (INTERRUPT / WHEN_IDLE / SILENT) で結果到着時の発話タイミングを制御',
              'message.toolCallCancellation?.ids でバージイン発生時に実行中の非同期タスクを安全にキャンセル',
            ],
          ),
        ),
      ],
      choices: [
        VnChoiceOption(
          id: 'ch6_to_ch7',
          labelJa: '🎨 第7話へ進む：Controller と 19種の内蔵 UI ウィジェットを学ぶ',
          labelKo: '다음 단계 (제7화): Controller & 19종 내장 UI 위젯 활용법 배우기',
          previewEmotion: VnCharacterEmotion.happy,
          affectionBonus: 8,
          targetChapterIndex: 6,
        ),
        VnChoiceOption(
          id: 'ch6_test_tool',
          labelJa: '⚡ 実演：ヒカリにツール（set_character_emotion）を呼んでもらう！',
          labelKo: '실연 보기: 히카리가 직접 set_character_emotion 도구를 호출하게 하기!',
          previewEmotion: VnCharacterEmotion.happy,
          affectionBonus: 12,
          livePromptToSend:
              '先輩がFunction Callingの実演をリクエストしました！今すぐ `set_character_emotion` ツール（emotion: "happy", motion: "jump", affection_delta: 10）を呼び出しながら、「えへへっ♪ 今私が set_character_emotion ツールを呼び出してジャンプしましたよっ✨」と日本語で元気に言ってください！',
        ),
        VnChoiceOption(
          id: 'ch6_back_ch5',
          labelJa: '◀ 第5話（カメラ映像 Vision ストリーミング）に戻る',
          labelKo: '◀ 이전 화 (제5화: 카메라 비전 스트리밍)로 돌아가기',
          previewEmotion: VnCharacterEmotion.normal,
          affectionBonus: 4,
          targetChapterIndex: 4,
        ),
      ],
    ),

    // =========================================================================
    // Chapter 7: GeminiLiveSessionController & 19종 내장 UI 위젯
    // =========================================================================
    VnSdkChapter(
      id: 'ch7_widgets_controller',
      chapterNumber: 7,
      categoryBadge: 'UI WIDGETS // STEP 7',
      titleJa: '第7話：GeminiLiveSessionController と 19種の内蔵 UI ウィジェット',
      titleKo: '제7화: GeminiLiveSessionController & 19종 내장 UI 위젯 조립하기',
      defaultEmotion: VnCharacterEmotion.happy,
      defaultScene: VnSceneBackground.tokyoConf,
      showcase: VnSdkShowcaseData(
        topicId: 'ch7_controller',
        badgeLabel: 'CH.7 // STEP 7-1: SESSION CONTROLLER',
        titleJa: 'Step 7-1: GeminiLiveSessionController と GeminiLiveChatView',
        titleKo: 'Step 7-1: GeminiLiveSessionController & 고수준 채팅 뷰',
        summaryJa: '状態管理コントローラーと内蔵ウィジェットで10行でAI通話画面が完成します。',
        summaryKo: '반응형 컨트롤러와 내장 위젯을 결합해 단 10줄로 AI 보이스챗 화면을 완성합니다.',
        codeSnippet: '''
import 'package:gemini_live/gemini_live.dart';

// 1. 세션 상태·자막·오디오 에너지를 자동 관리하는 ChangeNotifier 컨트롤러
final controller = GeminiLiveSessionController(
  genAI: GoogleGenAI(apiKey: apiKey),
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  config: GenerationConfig(responseModalities: const [Modality.AUDIO]),
);

// 2. 풀스크린 보이스챗 UI를 단 1줄로 렌더링!
@override
Widget build(BuildContext context) {
  return GeminiLiveChatView(
    controller: controller,
    onMicToggle: () => toggleMicrophone(),
  );
}''',
        codeSnippetJa: '''
import 'package:gemini_live/gemini_live.dart';

// 1. 接続状態・字幕・音声エネルギーを自動管理する ChangeNotifier コントローラー
final controller = GeminiLiveSessionController(
  genAI: GoogleGenAI(apiKey: apiKey),
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  config: GenerationConfig(responseModalities: const [Modality.AUDIO]),
);

// 2. フルスクリーン音声対話UIをたった1行で構築！
@override
Widget build(BuildContext context) {
  return GeminiLiveChatView(
    controller: controller,
    onMicToggle: () => toggleMicrophone(),
  );
}''',
        keyPointsKo: [
          'GeminiLiveSessionController가 WebSocket 메시지 파싱, 자막 누적, Barge-In 상태, 토큰 사용량을 자동 관리',
          'GeminiLiveChatView 하나만 넣으면 상태 배지, 파형 비주얼라이저, 자막 버블, 마이크 컨트롤 바가 즉시 표시됨',
        ],
        keyPointsJa: [
          'GeminiLiveSessionController がメッセージ解析、字幕蓄積、バージイン状態、トークン集計を自動管理',
          'GeminiLiveChatView を配置するだけでステータスバッジ、波形、字幕バブル、コントロールバーが即座に完成',
        ],
      ),
      dialogueBeats: [
        VnDialogueBeat(
          textJa:
              '第7話では、WebSocketの細かいコールバックを自分で書かなくても、5分でリッチな音声UIが作れる「19種類の内蔵ウィジェット」を紹介しますねっ🎨✨',
          textKo:
              '제7화에서는 복잡한 WebSocket 콜백을 직접 일일이 짜지 않고도 5분 만에 세련된 보이스챗 UI를 완성하는 「19종 내장 위젯」을 소개할게요 🎨✨',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ7-1！`GeminiLiveSessionController` を使えば、接続状態やリアルタイム字幕、割り込み状態まで全部自動で管理してくれます！そこに `GeminiLiveChatView` を繋ぐだけで画面が完成しちゃいます♪',
          textKo:
              'Step 7-1! `GeminiLiveSessionController`를 쓰면 연결 상태, 실시간 자막, Barge-In 인터럽트 상태까지 모두 자동으로 관리해 줘요! 여기에 `GeminiLiveChatView`만 연결하면 풀스크린 앱이 바로 완성된답니다♪',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ7-2！もちろん個別パーツとして、波紋が広がる `GeminiLiveMicButton` やリアルタイム波形 `GeminiLiveWaveform`、すりガラス字幕 `GeminiLiveCaptionBubble` などを自由に組み合わせることもできますよ💡',
          textKo:
              'Step 7-2! 물론 개별 부품 위젯으로 동심원 파문이 퍼지는 `GeminiLiveMicButton`, 실시간 오디오 파형 `GeminiLiveWaveform`, 블러 자막 버블 `GeminiLiveCaptionBubble` 등을 원하는 레이아웃에 자유롭게 조립할 수도 있어요 💡',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.tilt,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch7_modular_widgets',
            badgeLabel: 'CH.7 // STEP 7-2: 19+ MODULAR WIDGETS',
            titleJa: 'Step 7-2: Material 3 & Cupertino 個別ウィジェットの組み立て',
            titleKo: 'Step 7-2: Material 3 & Cupertino 개별 위젯 레고처럼 조립하기',
            summaryJa: 'マイクボタン、波形、字幕、ツールチップ、iOS Cupertino ウィジェットを自在に配置。',
            summaryKo: '마이크 버튼, 파형, 자막, 도구 배지, iOS Cupertino 위젯을 레고처럼 조합합니다.',
            codeSnippet: '''
Column(
  children: [
    // 1. 연결 상태 배지 & 실시간 토큰 비용 배지 (Cupertino 버전도 제공!)
    Row(
      children: [
        GeminiLiveStatusBadge(state: controller.connectionState),
        GeminiLiveUsageBadge(tracker: controller.usageTracker),
      ],
    ),
    // 2. 끼어들기(Barge-In) 감지 알림 배너 & 도구 실행 칩
    GeminiLiveBargeInBanner(isInterrupted: controller.isInterrupted),
    GeminiLiveToolActivityChip(activeToolName: controller.activeToolName),
    // 3. 듀얼 하모닉 음성 인디케이터 & 실시간 파형
    GeminiLiveVoiceIndicator(level: audioLevel, isSpeaking: controller.isSpeaking),
    GeminiLiveWaveform(level: audioLevel),
    // 4. 반투명 글래스모피즘 실시간 자막 버블 & 하단 통화 컨트롤 바
    GeminiLiveCaptionBubble(text: controller.currentTranscript),
    GeminiLiveControlBar(controller: controller, onMicTap: toggleMic),
  ],
);''',
            codeSnippetJa: '''
Column(
  children: [
    // 1. 接続状態バッジ＆リアルタイムトークン料金バッジ (Cupertino版も搭載！)
    Row(
      children: [
        GeminiLiveStatusBadge(state: controller.connectionState),
        GeminiLiveUsageBadge(tracker: controller.usageTracker),
      ],
    ),
    // 2. バージイン通知バナー＆ツール実行ステータスチップ
    GeminiLiveBargeInBanner(isInterrupted: controller.isInterrupted),
    GeminiLiveToolActivityChip(activeToolName: controller.activeToolName),
    // 3. デュアルハーモニック音声インジケーター＆リアルタイム波形
    GeminiLiveVoiceIndicator(level: audioLevel, isSpeaking: controller.isSpeaking),
    GeminiLiveWaveform(level: audioLevel),
    // 4. すりガラス風リアルタイム字幕バブル＆下部通話コントロールバー
    GeminiLiveCaptionBubble(text: controller.currentTranscript),
    GeminiLiveControlBar(controller: controller, onMicTap: toggleMic),
  ],
);''',
            keyPointsKo: [
              'Material 3 위젯 16종 + iOS/macOS 네이티브 감성의 Cupertino 전용 위젯 3종 기본 내장',
              'GeminiLiveVoiceSelector(보이스 선택 시트), GeminiLiveAudioRouteButton(스피커/블루투스 전환)까지 포함',
            ],
            keyPointsJa: [
              'Material 3 ウィジェット16種＋iOS/macOSネイティブ風 Cupertino ウィジェット3種を標準搭載',
              'GeminiLiveVoiceSelector（声優選択シート）や GeminiLiveAudioRouteButton もそのまま利用可能',
            ],
          ),
        ),
      ],
      choices: [
        VnChoiceOption(
          id: 'ch7_to_ch8',
          labelJa: '🧠 第8話へ進む：Extended Thinking（深い推論）と長期セッション圧縮を学ぶ',
          labelKo: '다음 단계 (제8화): Extended Thinking (깊은 추론) & 장기 세션 압축 배우기',
          previewEmotion: VnCharacterEmotion.thinking,
          affectionBonus: 8,
          targetChapterIndex: 7,
        ),
        VnChoiceOption(
          id: 'ch7_back_ch6',
          labelJa: '◀ 第6話（Function Calling と Google 検索連携）に戻る',
          labelKo: '◀ 이전 화 (제6화: Function Calling 및 검색 그라운딩)로 돌아가기',
          previewEmotion: VnCharacterEmotion.normal,
          affectionBonus: 4,
          targetChapterIndex: 5,
        ),
      ],
    ),

    // =========================================================================
    // Chapter 8: Extended Thinking, Context Window Compression & sendContextUpdate
    // =========================================================================
    VnSdkChapter(
      id: 'ch8_thinking_context',
      chapterNumber: 8,
      categoryBadge: 'ADVANCED // STEP 8',
      titleJa: '第8話：Extended Thinking・長期セッション圧縮・動的コンテキスト更新',
      titleKo: '제8화: Extended Thinking (깊은 추론) · 장기 세션 압축 · 실시간 컨텍스트 변경',
      defaultEmotion: VnCharacterEmotion.thinking,
      defaultScene: VnSceneBackground.akibaLab,
      showcase: VnSdkShowcaseData(
        topicId: 'ch8_thinking_compression',
        badgeLabel: 'CH.8 // STEP 8-1: THINKING & COMPRESSION',
        titleJa: 'Step 8-1: ThinkingConfig と ContextWindowCompressionConfig',
        titleKo: 'Step 8-1: ThinkingConfig(깊은 추론) & 슬라이딩 윈도우 컨텍스트 압축',
        summaryJa: '深い思考プロセスを有効化し、15分以上の長時間セッションを自動圧縮で維持します。',
        summaryKo: '복잡한 문제 추론(Thinking)을 켜고, 15분 이상의 장기 통화를 슬라이딩 윈도우 압축으로 유지합니다.',
        codeSnippet: '''
final params = LiveConnectParameters(
  model: LiveModels.gemini38Live,
  config: GenerationConfig(
    responseModalities: const [Modality.AUDIO],
    // 🧠 1. 깊은 추론(Extended Thinking) 예산 및 사고 과정 스트리밍 활성화
    thinkingConfig: ThinkingConfig(
      thinkingBudget: 1024,
      includeThoughts: true,
    ),
  ),
  // ♾️ 2. 15분 이상 장기 통화 시 컨텍스트 윈도우 자동 슬라이딩 압축!
  contextWindowCompression: ContextWindowCompressionConfig(
    triggerTokens: 24000,
    slidingWindow: SlidingWindow(targetTokens: 16000),
  ),
  // 📜 3. 연결 시 이전 대화 히스토리 시드 주입 (선택)
  historyConfig: HistoryConfig(initialHistory: previousContents),
);''',
        codeSnippetJa: '''
final params = LiveConnectParameters(
  model: LiveModels.gemini38Live,
  config: GenerationConfig(
    responseModalities: const [Modality.AUDIO],
    // 🧠 1. 深い推論 (Extended Thinking) の予算と思考過程ストリーミングを有効化
    thinkingConfig: ThinkingConfig(
      thinkingBudget: 1024,
      includeThoughts: true,
    ),
  ),
  // ♾️ 2. 15分以上の長時間通話でもトークン上限に達しない自動スライディング圧縮！
  contextWindowCompression: ContextWindowCompressionConfig(
    triggerTokens: 24000,
    slidingWindow: SlidingWindow(targetTokens: 16000),
  ),
  // 📜 3. 接続時に過去の会話履歴をシード注入 (任意)
  historyConfig: HistoryConfig(initialHistory: previousContents),
);''',
        keyPointsKo: [
          'includeThoughts: true일 때 part.thought == true인 파트로 AI의 내부 추론 과정이 먼저 스트리밍됨',
          'ContextWindowCompressionConfig 설정 시 오디오/비전 토큰이 누적되어도 세션이 끊기지 않고 무제한 지속 가능',
        ],
        keyPointsJa: [
          'includeThoughts: true にすると part.thought == true のパーツとしてAIの内部推論プロセスが先に届く',
          'ContextWindowCompressionConfig を有効化すれば音声・映像トークンが蓄積しても長時間セッションを維持可能',
        ],
      ),
      dialogueBeats: [
        VnDialogueBeat(
          textJa:
              '第8話では、高度なAIエージェントを作るための「Extended Thinking（深い推論）」と、15分以上の長時間通話を支える「コンテキスト圧縮」を解説しますねっ🧠✨',
          textKo:
              '제8화에서는 고도화된 AI 에이전트를 위한 「Extended Thinking (깊은 추론)」과 15분 이상의 장기 통화를 유지해 주는 「컨텍스트 윈도우 압축」을 알아볼게요 🧠✨',
          emotion: VnCharacterEmotion.thinking,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ8-1！数学の問題や複雑な設計を相談する時は `ThinkingConfig(thinkingBudget: 1024, includeThoughts: true)` を設定します。さらに `ContextWindowCompressionConfig` を入れれば長時間通話でもトークン上限の心配がありません♪',
          textKo:
              'Step 8-1! 수학 문제나 복잡한 아키텍처 추론이 필요할 땐 `ThinkingConfig(thinkingBudget: 1024, includeThoughts: true)`를 켜주세요. 그리고 `ContextWindowCompressionConfig`를 함께 설정하면 긴 통화에서도 토큰 한도 초과 없이 대화를 이어갈 수 있어요♪',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              'そしてステップ8-2！通話の途中で、WebSocketを再接続せずにシステム指示やツール一覧をリアルタイムに書き換えられる `session.sendContextUpdate()` もすごく便利ですよ💡',
          textKo:
              '그리고 Step 8-2! 통화 도중 WebSocket을 끊고 재연결할 필요 없이, 시스템 프롬프트나 도구(Tools) 목록을 실시간으로 교체하는 `session.sendContextUpdate()`도 정말 강력하답니다 💡',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch8_context_update',
            badgeLabel: 'CH.8 // STEP 8-2: DYNAMIC CONTEXT UPDATE',
            titleJa: 'Step 8-2: 通話中の動的システム指示・ツール更新 (sendContextUpdate)',
            titleKo: 'Step 8-2: 통화 중 무중단 페르소나·도구 동적 변경 (sendContextUpdate)',
            summaryJa: 'セッションを切断せずにシステム指示や利用可能ツールを即座に更新します。',
            summaryKo: '세션 재연결 없이 통화 도중 시스템 프롬프트와 도구 세트를 즉시 업데이트합니다.',
            codeSnippet: '''
// 통화 도중 재연결 없이 캐릭터 모드나 활성 도구를 즉시 변경!
session.sendContextUpdate(
  systemInstruction: Content.text(
    '지금부터는 엄격한 시니어 코드 리뷰어 모드로 답변하세요.',
  ),
  tools: updatedToolsList,
);

// UI에서는 내장 바텀시트 위젯으로 바로 연결 가능:
// GeminiLiveContextConfigSheet.show(context, session: session);''',
            codeSnippetJa: '''
// 通話の途中で再接続することなく、モードやツール一覧を即時変更！
session.sendContextUpdate(
  systemInstruction: Content.text(
    'ここからは厳格なシニアコードレビュアーモードで回答してください。',
  ),
  tools: updatedToolsList,
);

// UIでは内蔵ボトムシートウィジェットで簡単に呼び出し可能:
// GeminiLiveContextConfigSheet.show(context, session: session);''',
            keyPointsKo: [
              '기존에는 시스템 프롬프트를 바꾸려면 소켓을 닫고 다시 connect() 해야 했으나 sendContextUpdate로 무중단 전환 가능',
              '내장 GeminiLiveThinkingIndicator와 GeminiLiveContextConfigSheet 위젯과 100% 연동',
            ],
            keyPointsJa: [
              'ソケットを再接続することなく、会話の流れを保ったままシステム指示やツールを動的に切り替え可能',
              '内蔵の GeminiLiveThinkingIndicator や GeminiLiveContextConfigSheet ウィジェットと完全連携',
            ],
          ),
        ),
      ],
      choices: [
        VnChoiceOption(
          id: 'ch8_to_ch9',
          labelJa: '🎵 第9話へ進む：双方向ライブ通訳 (Translate) & Lyria リアルタイム音楽生成へ',
          labelKo: '다음 단계 (제9화): 실시간 양방향 통역 (Translate) & Lyria 음악 생성 배우기',
          previewEmotion: VnCharacterEmotion.happy,
          affectionBonus: 8,
          targetChapterIndex: 8,
        ),
        VnChoiceOption(
          id: 'ch8_back_ch7',
          labelJa: '◀ 第7話（Controller と 19種の内蔵 UI ウィジェット）に戻る',
          labelKo: '◀ 이전 화 (제7화: Controller 및 내장 UI 위젯)로 돌아가기',
          previewEmotion: VnCharacterEmotion.normal,
          affectionBonus: 4,
          targetChapterIndex: 6,
        ),
      ],
    ),

    // =========================================================================
    // Chapter 9: 실시간 양방향 통역 (Live Translate) & Lyria 실시간 음악 생성
    // =========================================================================
    VnSdkChapter(
      id: 'ch9_translate_music',
      chapterNumber: 9,
      categoryBadge: 'SPECIALIZED // STEP 9',
      titleJa: '第9話：対面リアルタイム音声通訳 & Lyria 48kHz リアルタイム音楽生成',
      titleKo: '제9화: 실시간 양방향 음성 통역 (Translate) & Lyria 48kHz 음악 생성',
      defaultEmotion: VnCharacterEmotion.happy,
      defaultScene: VnSceneBackground.sakuraSunset,
      showcase: VnSdkShowcaseData(
        topicId: 'ch9_live_translate',
        badgeLabel: 'CH.9 // STEP 9-1: LIVE SPEECH TRANSLATION',
        titleJa: 'Step 9-1: TranslationConfig と対面分割通訳ウィジェット',
        titleKo: 'Step 9-1: TranslationConfig & 180도 대면 분할 통역 UI',
        summaryJa: 'gemini-3.5-live-translate-preview で超低遅延の音声同時通訳を実現します。',
        summaryKo: 'gemini-3.5-live-translate-preview 모델과 대면 통역 위젯으로 동시통역기를 구축합니다.',
        codeSnippet: '''
// 1. 실시간 음성 동시통역 전용 설정 (TranslationConfig)
final params = LiveConnectParameters(
  model: LiveModels.gemini35LiveTranslatePreview,
  translationConfig: TranslationConfig(
    sourceLanguageCodes: const ['ko-KR', 'ja-JP'],
    targetLanguageCode: 'ja-JP',
    echoTargetLanguage: true,
  ),
  config: GenerationConfig(responseModalities: const [Modality.AUDIO]),
);

// 2. 테이블에 폰을 두고 마주 보고 대화하는 180도 상하 반전 통역 위젯!
GeminiLiveTranslateSplitView(
  topLanguageLabel: '🇯🇵 日本語 (상대방 화면 180° 회전)',
  bottomLanguageLabel: '🇰🇷 한국어 (내 화면)',
  topTranscript: translatedText,
  bottomTranscript: sourceText,
  isTopActive: isSpeakingJa,
  isBottomActive: isSpeakingKo,
);''',
        codeSnippetJa: '''
// 1. リアルタイム音声同時通訳専用設定 (TranslationConfig)
final params = LiveConnectParameters(
  model: LiveModels.gemini35LiveTranslatePreview,
  translationConfig: TranslationConfig(
    sourceLanguageCodes: const ['ja-JP', 'en-US'],
    targetLanguageCode: 'en-US',
    echoTargetLanguage: true,
  ),
  config: GenerationConfig(responseModalities: const [Modality.AUDIO]),
);

// 2. テーブルに置いて向かい合って話せる180度上下反転の対面通訳ウィジェット！
GeminiLiveTranslateSplitView(
  topLanguageLabel: '🇺🇸 English (相手側 180°回転表示)',
  bottomLanguageLabel: '🇯🇵 日本語 (自分側)',
  topTranscript: translatedText,
  bottomTranscript: sourceText,
  isTopActive: isSpeakingEn,
  isBottomActive: isSpeakingJa,
);''',
        keyPointsKo: [
          'TranslationConfig로 출발어/도착어 코드만 지정하면 초저지연 S2S(Speech-to-Speech) 동시통역 수행',
          'GeminiLiveTranslateSplitView 내장 위젯은 상단 패널을 180도 회전시켜 마주 앉은 상대방이 바로 읽을 수 있음',
        ],
        keyPointsJa: [
          'TranslationConfig で言語コードを指定するだけで超低遅延の Speech-to-Speech 同時通訳を実行',
          'GeminiLiveTranslateSplitView は上部ペインを180度回転表示し、向かい合う相手がそのまま読める設計',
        ],
      ),
      dialogueBeats: [
        VnDialogueBeat(
          textJa:
              '第9話では、『gemini_live』の特別機能である「リアルタイム同時通訳」と、DJのように音楽を操れる「Lyria リアルタイム音楽生成」を紹介しますねっ🎵✨',
          textKo:
              '제9화에서는 『gemini_live』의 스페셜 기능인 「실시간 음성 동시통역」과, DJ처럼 실시간으로 음악을 작곡·믹싱하는 「Lyria 실시간 음악 생성」을 알아볼게요 🎵✨',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ9-1！`TranslationConfig` と `GeminiLiveTranslateSplitView` を使えば、スマホをテーブルに置いて向かい合って話せる180度反転の同時通訳アプリがあっという間に作れます🌐',
          textKo:
              'Step 9-1! `TranslationConfig`와 내장 `GeminiLiveTranslateSplitView` 위젯을 사용하면, 테이블에 스마트폰을 올려두고 마주 보며 대화하는 180도 대면 동시통역 앱을 순식간에 만들 수 있어요 🌐',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              'そしてステップ9-2！`genAI.live.music.connect()` を使えば、Googleの音楽生成AI「Lyria」と直結して、48kHz・ステレオの高音質BGMをBPMやスケールを変えながらリアルタイム生成できちゃいます🎧',
          textKo:
              '그리고 Step 9-2! `genAI.live.music.connect()`를 사용하면 Google의 음악 생성 AI 「Lyria」에 직접 연결해, 48kHz 스테레오 고음질 음악을 BPM과 스케일, 프롬프트 가중치를 실시간으로 조절하며 연주할 수 있답니다 🎧',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch9_lyria_music',
            badgeLabel: 'CH.9 // STEP 9-2: LYRIA REALTIME MUSIC (48KHZ)',
            titleJa: 'Step 9-2: genAI.live.music による 48kHz ステレオ音楽生成',
            titleKo: 'Step 9-2: genAI.live.music (Lyria 48kHz 스테레오 실시간 음악)',
            summaryJa: '重み付きプロンプト(WeightedPrompt)とBPM・スケールをリアルタイムにミキシングします。',
            summaryKo: '가중치 프롬프트(WeightedPrompt)와 BPM·스케일을 실시간으로 믹싱하며 48kHz 스테레오 음악을 생성합니다.',
            codeSnippet: '''
// 1. Lyria 실시간 음악 세션 연결 (출력 규격: 48,000Hz, 16-bit PCM, Stereo 2ch)
final musicSession = await genAI.live.music.connect(
  LiveMusicConnectParameters(
    model: 'models/lyria-realtime-exp',
    callbacks: LiveMusicCallbacks(
      onAudioChunk: (Uint8List pcm48kStereo) {
        musicPlayer.appendStereo48k(pcm48kStereo);
      },
    ),
  ),
);

// 2. 가중치 프롬프트(Prompt DJ) & BPM / 조성(Scale) 실시간 스티어링!
await musicSession.setWeightedPrompts([
  WeightedPrompt(text: 'Upbeat Anime Synthpop, Bright Piano', weight: 1.0),
  WeightedPrompt(text: 'Lo-Fi Chill Beats', weight: 0.4),
]);
await musicSession.setMusicGenerationConfig(
  LiveMusicGenerationConfig(bpm: 128, scale: Scale.C_MAJOR_A_MINOR),
);
await musicSession.play();''',
            codeSnippetJa: '''
// 1. Lyria リアルタイム音楽セッション接続 (出力仕様: 48,000Hz, 16-bit PCM, Stereo 2ch)
final musicSession = await genAI.live.music.connect(
  LiveMusicConnectParameters(
    model: 'models/lyria-realtime-exp',
    callbacks: LiveMusicCallbacks(
      onAudioChunk: (Uint8List pcm48kStereo) {
        musicPlayer.appendStereo48k(pcm48kStereo);
      },
    ),
  ),
);

// 2. 重み付きプロンプト (Prompt DJ) ＆ BPM・スケールをリアルタイム制御！
await musicSession.setWeightedPrompts([
  WeightedPrompt(text: 'Upbeat Anime Synthpop, Bright Piano', weight: 1.0),
  WeightedPrompt(text: 'Lo-Fi Chill Beats', weight: 0.4),
]);
await musicSession.setMusicGenerationConfig(
  LiveMusicGenerationConfig(bpm: 128, scale: Scale.C_MAJOR_A_MINOR),
);
await musicSession.play();''',
            keyPointsKo: [
              'Lyria 음악 출력은 음성(24kHz Mono)과 달리 48,000Hz, 16-bit PCM, Stereo(2채널) 규격 사용',
              'setWeightedPrompts()로 재생을 멈추지 않고 장르와 악기 비중을 실시간 크로스페이드 가능',
            ],
            keyPointsJa: [
              'Lyria の音声出力は 48,000Hz, 16-bit PCM, ステレオ(2ch) 仕様（AI音声の24kHz Monoと区別）',
              'setWeightedPrompts() で再生を止めずにジャンルや楽器のブレンド比率をリアルタイムに変更可能',
            ],
          ),
        ),
      ],
      choices: [
        VnChoiceOption(
          id: 'ch9_to_ch10',
          labelJa: '🚀 最終話（第10話）へ進む：本番認証・セッション復帰・料金計算・テスト',
          labelKo: '마지막 장 (제10화): 프로덕션 보안 토큰 · 세션 복구 · 비용 추적 · 테스트 배우기',
          previewEmotion: VnCharacterEmotion.happy,
          affectionBonus: 10,
          targetChapterIndex: 9,
        ),
        VnChoiceOption(
          id: 'ch9_back_ch8',
          labelJa: '◀ 第8話（Extended Thinking と長期セッション圧縮）に戻る',
          labelKo: '◀ 이전 화 (제8화: Extended Thinking 및 장기 세션 압축)로 돌아가기',
          previewEmotion: VnCharacterEmotion.normal,
          affectionBonus: 4,
          targetChapterIndex: 7,
        ),
      ],
    ),

    // =========================================================================
    // Chapter 10: 프로덕션 배포 총정리 (Ephemeral Token, Session Resumption, Cost, Firebase 호환, Testing)
    // =========================================================================
    VnSdkChapter(
      id: 'ch10_production_mastery',
      chapterNumber: 10,
      categoryBadge: 'PRODUCTION // STEP 10',
      titleJa: '第10話：本番運用（一時トークン・セッション再開・料金計算・firebase_ai互換・テスト）',
      titleKo: '제10화: 프로덕션 총정리 (임시 토큰 · 세션 복구 · 비용 계산 · Firebase 호환 · 테스트)',
      defaultEmotion: VnCharacterEmotion.happy,
      defaultScene: VnSceneBackground.tokyoConf,
      showcase: VnSdkShowcaseData(
        topicId: 'ch10_auth_resumption',
        badgeLabel: 'CH.10 // STEP 10-1: EPHEMERAL TOKEN & RESUME',
        titleJa: 'Step 10-1: Ephemeral Token（一時トークン）と SessionResumption',
        titleKo: 'Step 10-1: Ephemeral Token(임시 보안 토큰) & 무중단 세션 복구',
        summaryJa: 'APIキーを隠蔽する一時トークン発行と、通信切断時のセッション自動再開。',
        summaryKo: '마스터 API 키 노출을 막는 일회용 임시 토큰과 네트워크 단절 시 세션을 이어가는 복구 설정입니다.',
        codeSnippet: '''
// 🔐 1. 백엔드에서 단기 임시 토큰(Ephemeral Token) 발급 (클라이언트에 API 키 노출 방지)
final token = await backendGenAI.authTokens.create(
  CreateAuthTokenParameters(
    config: CreateAuthTokenConfig(uses: 1),
  ),
);
// 클라이언트 앱은 발급받은 token.name을 apiKey 자리에 넣어 안전하게 연결!
final clientGenAI = GoogleGenAI(apiKey: token.name!);

// 🔄 2. 모바일 네트워크 끊김(1006) 및 GoAway 대비 세션 핸들 자동 저장 & 복구
final params = LiveConnectParameters(
  model: 'gemini-3.1-flash-live-preview',
  config: LiveConnectConfig(
    // 세션 단위 httpOptions로 v1alpha / 커스텀 프록시 baseUrl / headers 오버라이드 가능!
    httpOptions: const HttpOptions(apiVersion: 'v1alpha'),
  ),
  sessionResumption: SessionResumptionConfig(
    handle: savedResumeHandle, // 재연결 시 이전 핸들을 넘기면 대화 맥락 100% 복구!
  ),
  callbacks: LiveCallbacks(
    onMessage: (msg) {
      if (msg.sessionResumptionUpdate?.newHandle != null) {
        savedResumeHandle = msg.sessionResumptionUpdate!.newHandle;
      }
      if (msg.goAway != null) {
        print('⚠️ 서버 교체 예고 (남은 시간: \${msg.goAway!.timeLeft}) -> 자동 재연결 준비');
      }
    },
  ),
);''',
        codeSnippetJa: '''
// 🔐 1. バックエンドで短期一時トークン (Ephemeral Token) を発行（APIキー漏洩防止）
final token = await backendGenAI.authTokens.create(
  CreateAuthTokenParameters(
    config: CreateAuthTokenConfig(uses: 1),
  ),
);
// クライアントアプリは発行された token.name を apiKey に渡して安全に接続！
final clientGenAI = GoogleGenAI(apiKey: token.name!);

// 🔄 2. モバイル回線切断(1006)や GoAway に備えるセッション自動再開 (SessionResumption)
final params = LiveConnectParameters(
  model: 'gemini-3.1-flash-live-preview',
  config: LiveConnectConfig(
    // セッション単位の httpOptions で v1alpha / カスタム baseUrl / headers を上書き可能！
    httpOptions: const HttpOptions(apiVersion: 'v1alpha'),
  ),
  sessionResumption: SessionResumptionConfig(
    handle: savedResumeHandle, // 再接続時にハンドルを渡せば会話履歴を100%引き継ぎ！
  ),
  callbacks: LiveCallbacks(
    onMessage: (msg) {
      if (msg.sessionResumptionUpdate?.newHandle != null) {
        savedResumeHandle = msg.sessionResumptionUpdate!.newHandle;
      }
      if (msg.goAway != null) {
        print('⚠️ サーバー切替予告 (残り: \${msg.goAway!.timeLeft}) -> 自動再接続準備');
      }
    },
  ),
);''',
        keyPointsKo: [
          'AuthTokensService로 유효시간이 짧은 일회용 토큰을 발급해 모바일 앱 바이너리에 API 키가 포함되지 않도록 보호',
          'sessionResumptionUpdate.newHandle을 저장해 두면 엘리베이터/지하철에서 끊겨도 이전 대화를 그대로 이어서 복구',
        ],
        keyPointsJa: [
          'AuthTokensService で使い捨ての一時トークンを発行し、アプリ内にマスターAPIキーを埋め込まずに保護',
          'sessionResumptionUpdate.newHandle を保存しておけば、電波が切れても直前の文脈のまま通話を再開可能',
        ],
      ),
      dialogueBeats: [
        VnDialogueBeat(
          textJa:
              'いよいよ最終章、第10話ですっ🎉 実際のプロダクションアプリとしてリリースするために欠かせない「セキュリティ」「自動再接続」「料金計算」「テスト」をまとめてマスターしましょう！',
          textKo:
              '드디어 대망의 마지막 장, 제10화예요🎉 실제 상용 프로덕션 앱으로 출시할 때 꼭 필요한 「보안 토큰」「세션 자동 복구」「실시간 비용 계산」「단위 테스트」를 한 번에 마스터해 볼게요!',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.jump,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ10-1！本番アプリにAPIキーを直接入れるのはNGです！サーバーで `genAI.authTokens.create()` を呼んで一時トークン（Ephemeral Token）を発行し、`SessionResumptionConfig` で回線切断時も会話を自動再開できるようにします🔐',
          textKo:
              'Step 10-1! 상용 앱에 마스터 API 키를 하드코딩하면 안 되겠죠? 백엔드에서 `genAI.authTokens.create()`로 일회용 임시 토큰(Ephemeral Token)을 발급해 전달하고, `SessionResumptionConfig`로 네트워크가 끊겨도 대화를 그대로 이어갈 수 있게 만듭니다 🔐',
          emotion: VnCharacterEmotion.explaining,
          motion: VnStageMotion.nod,
        ),
        VnDialogueBeat(
          textJa:
              'ステップ10-2！リアルタイムのトークン消費量やUSD/KRWの料金計算は `GeminiTokenUsageTracker` が自動で計算してくれます。さらに `firebase_ai` からの移行もimportを1行変えるだけです💡',
          textKo:
              'Step 10-2! 실시간 오디오/텍스트/비전 모달리티별 토큰 사용량과 달러(USD)/원화(KRW) 요금 추산은 `GeminiTokenUsageTracker`가 자동으로 계산해 줘요. 기존 `firebase_ai` 코드도 import 한 줄만 바꾸면 1:1 호환된답니다 💡',
          emotion: VnCharacterEmotion.normal,
          motion: VnStageMotion.nod,
          showcaseOverride: VnSdkShowcaseData(
            topicId: 'ch10_cost_compat_test',
            badgeLabel: 'CH.10 // STEP 10-2: COST, COMPAT & TESTING',
            titleJa: 'Step 10-2: トークン料金計算・firebase_ai 1:1互換・単体テスト',
            titleKo: 'Step 10-2: 실시간 토큰 비용 계산 · firebase_ai 호환 · 단위 테스트',
            summaryJa: 'モダリティ別コスト計算、1行移行、APIクォータを使わない高速テスト。',
            summaryKo: '모달리티별 실시간 요금 계산, 1줄 마이그레이션, API 과금 없는 결정론적 테스트입니다.',
            codeSnippet: '''
// 💰 1. 모달리티별(Audio/Text/Image) 토큰 및 USD/KRW 실시간 요금 추적
final tracker = GeminiTokenUsageTracker(model: LiveModels.gemini38Live);
if (message.usageMetadata != null) {
  tracker.recordUsage(message.usageMetadata!);
  print('누적 비용: \\\$\${tracker.estimatedCostUsd.toStringAsFixed(4)}');
}

// 🔄 2. 기존 firebase_ai 코드 1:1 호환 레이어 (코드 수정 없이 import만 교체!)
// import 'package:gemini_live/compat/firebase_ai.dart';

// 🧪 3. 실제 WebSocket 연결/과금 없이 서버 메시지를 시뮬레이션하는 단위 테스트!
controller.handleServerMessageForTesting(
  LiveServerMessage(
    serverContent: LiveServerContent(interrupted: true),
  ),
);
expect(controller.isInterrupted, isTrue);''',
            codeSnippetJa: '''
// 💰 1. モダリティ別 (Audio/Text/Image) トークン＆USD/KRW リアルタイム料金追跡
final tracker = GeminiTokenUsageTracker(model: LiveModels.gemini38Live);
if (message.usageMetadata != null) {
  tracker.recordUsage(message.usageMetadata!);
  print('累計コスト: \\\$\${tracker.estimatedCostUsd.toStringAsFixed(4)}');
}

// 🔄 2. 既存 firebase_ai コードの 1:1 互換レイヤー (import を1行変えるだけ！)
// import 'package:gemini_live/compat/firebase_ai.dart';

// 🧪 3. 実際のWebSocket接続やAPI課金なしで挙動を検証するユニットテスト！
controller.handleServerMessageForTesting(
  LiveServerMessage(
    serverContent: LiveServerContent(interrupted: true),
  ),
);
expect(controller.isInterrupted, isTrue);''',
            keyPointsKo: [
              'GeminiTokenUsageTracker는 입력/출력 오디오·텍스트·비전 토큰을 분리 집계하여 정확한 실시간 비용 산출',
              'handleServerMessageForTesting()으로 네트워크 없이도 Barge-In, 자막, ToolCall 상태 전이를 100% 단위 테스트 가능',
            ],
            keyPointsJa: [
              'GeminiTokenUsageTracker は入出力の音声・テキスト・映像トークンを個別に集計しリアルタイム料金を算出',
              'handleServerMessageForTesting() により通信やAPI課金なしでバージインやツール呼び出しを高速テスト可能',
            ],
          ),
        ),
        VnDialogueBeat(
          textJa:
              'おめでとうございます先輩っ🎉✨ 全10話のカリキュラムをすべてコンプリートしました！これからも私と一緒に、最高のFlutter×Gemini Liveアプリを作ってくださいね、大好きですっ💖',
          textKo:
              '축하드려요 선배🎉✨ 총 10화의 『gemini_live』 마스터 커리큘럼을 모두 완주하셨어요! 앞으로도 저 히카리와 함께 멋진 Flutter × Gemini Live 앱을 만들어 주세요, 정말 좋아해요 선배💖',
          emotion: VnCharacterEmotion.happy,
          motion: VnStageMotion.bow,
        ),
      ],
      choices: [
        VnChoiceOption(
          id: 'ch10_ask_migration',
          labelJa: '🔥 ヒカリに質問：「firebase_ai から移行する時のポイントをもう一度教えて！」',
          labelKo: '히카리에게 질문: "기존 firebase_ai에서 마이그레이션할 때 핵심 포인트 다시 알려줘!"',
          previewEmotion: VnCharacterEmotion.explaining,
          affectionBonus: 12,
          livePromptToSend:
              '先輩から質問です：「既存の firebase_ai パッケージから gemini_live に移行する時のポイントは？」`package:gemini_live/compat/firebase_ai.dart` を使えば import を1行変えるだけで1:1互換で動くことを、日本語で2〜3文で元気に教えてください！',
        ),
        VnChoiceOption(
          id: 'ch10_restart_ch1',
          labelJa: '🌸 第1話（パッケージ導入と初回接続）からもう一度復習する',
          labelKo: '🌸 제1화 (패키지 설치 및 첫 연결)부터 다시 복습하기',
          previewEmotion: VnCharacterEmotion.happy,
          affectionBonus: 8,
          targetChapterIndex: 0,
        ),
      ],
    ),
  ];

  static VnSdkShowcaseData showcaseById(String? topicId) {
    if (topicId == null) return chapters.first.showcase;
    final resolvedId = switch (topicId) {
      'intro' => 'ch1_quickstart',
      'audio_barge_in' => 'ch4_barge_in',
      'tools' => 'ch6_tool_declare',
      'widgets_and_more' => 'ch7_controller',
      _ => topicId,
    };
    for (final chapter in chapters) {
      if (chapter.id == resolvedId ||
          chapter.showcase.topicId == resolvedId ||
          chapter.id == topicId ||
          chapter.showcase.topicId == topicId) {
        return chapter.showcase;
      }
      for (final beat in chapter.dialogueBeats) {
        if (beat.showcaseOverride?.topicId == resolvedId ||
            beat.showcaseOverride?.topicId == topicId) {
          return beat.showcaseOverride!;
        }
      }
    }
    return chapters.first.showcase;
  }
}
