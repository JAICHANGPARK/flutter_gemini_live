# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[[English]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [[한국어]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [[日本語]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [[简体中文]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- GoogleのGeminiモデルとリアルタイムでマルチモーダルな会話を実現する[実験的なGemini Live API](https://ai.google.dev/gemini-api/docs/live)用のFlutterパッケージです。
- Firebase / Firebase AI Logic への依存関係はありません。
- 現在のGemini Liveモデルファミリーをサポート: `gemini-3.1-flash-live-preview` (最新) および `gemini-2.5-flash-native-audio-preview-12-2025`。
- モデルの機能に応じて `TEXT`、`AUDIO`、`VIDEO` の応答モダリティをサポートします。

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e


## ✨ 特徴

* **リアルタイム通信**: 低レイテンシで双方向の対話を可能にするWebSocket接続を確立します。
* **マルチモーダル入力**: 1つの会話ターンでテキスト、画像、音声の送信が可能です。
* **ストリーミング応答**: モデルが生成している最中のテキスト応答をリアルタイムで受信します。
* **使いやすいコールバック**: `onOpen`, `onMessage`, `onError`, `onClose` の簡単なイベントベースハンドラー。
* **Function Calling**: `Behavior` と `FunctionResponseScheduling` 制御による同期/非同期の関数呼び出し。
* **セッション再開**: 保存されたハンドルを使用して、接続が切断された場合でもセッションを再開します。
* **音声アクティビティ検出 (VAD)**: 自動または手動での音声アクティビティ検出。
* **リアルタイムメディアチャンク**: 音声/画像チャンクをリアルタイムで送信します。
* **音声書き起こし**: 音声入力および出力をテキストに書き起こし、`LanguageAuto`, `LanguageHints`, `customVocabulary` のヒントをサポート。
* **リアルタイム翻訳**: `TranslationConfig` を使用したリアルタイムの音声対音声翻訳。
* **コンテキストウィンドウ圧縮**: 長いセッションでもトークン制限内に収めるスライディングウィンドウ圧縮。
* **履歴設定**: `HistoryConfig` を使用して、リアルタイムターンの前に会話履歴をあらかじめ読み込みます。
* **グラウンディング**: Google検索グラウンディングおよびURLコンテキストツール。
* **Google Maps グラウンディング**: 地元情報やルートを認識する `GoogleMaps` グラウンディング (`places`, `routing`)。
* **エフェメラルトークン**: 短時間有効なトークンによる安全なクライアントサイド認証。

| デモ 1: チワワ vs マフィン | デモ 2: ラブラドゥードル vs フライドチキン |
| :---: | :---: |
| <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222333.png?raw=true" alt="リアルタイム会話デモ" width="400"/> | <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222355.png?raw=true" alt="マルチモーダル入力デモ" width="400"/> |
| *チワワ vs マフィン* | *ラブラドゥードル vs フライドチキン* |

## 🏁 はじめに

### 前提条件

このパッケージを使用するには、Google Gemini APIキーが必要です。[Google AI Studio](https://aistudio.google.com/app/apikey) からキーを取得できます。

### インストール

`pubspec.yaml` ファイルにパッケージを追加します：

```yaml
dependencies:
  gemini_live: ^2026.8.12 # 最新の公開バージョンを使用してください
```

または、以下のコマンドを実行します (推奨)：

```bash
flutter pub add gemini_live
```

ターミナルからパッケージをインストールします：

```bash
flutter pub get
```

次に、Dartコードでパッケージをインポートします：

```dart
import 'package:gemini_live/gemini_live.dart';
```

## 🚀 使い方

### 基本的な例

以下は、`gemini_live` パッケージを使用してセッションを開始し、メッセージを送信する基本的な例です。

**セキュリティ上の注意**: APIキーをハードコードしないでください。資格情報を安全に保つために、`flutter_dotenv` などのパッケージを使用して `.env` ファイルを使用することを強くお勧めします。

```dart
import 'package:gemini_live/gemini_live.dart';

// 1. APIキーでGeminiを初期化
final genAI = GoogleGenAI(apiKey: 'YOUR_API_KEY_HERE');
LiveSession? session;

// 2. Live APIに接続
Future<void> connect() async {
  try {
    session = await genAI.live.connect(
      LiveConnectParameters(
        model: 'gemini-3.1-flash-live-preview',
        config: GenerationConfig(responseModalities: [Modality.TEXT]),
        callbacks: LiveCallbacks(
          onOpen: () => print('✅ 接続が開きました'),
          onMessage: (LiveServerMessage message) {
            // 3. モデルからの受信メッセージを処理
            if (message.text != null) {
              print('受信チャンク: ${message.text}');
            }
            if (message.serverContent?.turnComplete ?? false) {
              print('✅ ターン完了!');
            }
          },
          onError: (e, s) => print('🚨 エラー: $e'),
          onClose: (code, reason) => print('🚪 接続が閉じられました'),
        ),
      ),
    );
  } catch (e) {
    print('接続に失敗しました: $e');
  }
}

// 4. モデルにメッセージを送信
void sendMessage(String text) {
  session?.sendText(text);
}
```

#### Google Maps グラウンディング ツール

`GoogleMaps` ツールを使用して、位置情報やルートを認識するグラウンディングを有効化します：

```dart
final session = await genAI.live.connect(
  LiveConnectParameters(
    model: 'gemini-3.1-flash-live-preview',
    tools: [
      Tool(
        googleMaps: GoogleMaps(
          groundingTypes: ['places', 'routing'],
        ),
      ),
    ],
  ),
);
```

## 📚 API リファレンス

### LiveSession メソッド

- `sendText(String text)` - テキストメッセージの送信
- `sendClientContent({List<Content>? turns, bool turnComplete})` - マルチターンコンテンツの送信
- `sendRealtimeInput({...})` - リアルタイム入力（音声、画像フレーム、テキスト）の送信
- `sendMediaChunks(List<Blob> mediaChunks)` - メディアチャンクの送信
- `sendAudioStreamEnd()` - 音声ストリーム終了シグナルの送信
- `sendRealtimeText(String text)` - リアルタイムテキストの送信
- `sendActivityStart()` / `sendActivityEnd()` - アクティビティ開始/終了シグナルの送信
- `sendToolResponse({required List<FunctionResponse> functionResponses})` - ツール応答の送信
- `sendFunctionResponse({required String id, required String name, required Map<String, dynamic> response})` - 単一の関数応答の送信
- `sendVideo(List<int> videoBytes, {String mimeType})` - Live API の `video` フィールド経由で画像バイトを送信 (`image/*` MIME タイプ)
- `sendAudio(List<int> audioBytes)` - 音声の送信
- `close()` - 接続を閉じる
- `isClosed` - 接続状態の確認

### LiveServerMessage プロパティ

- `text` - テキスト応答（現在のターンからの思考部分を除いた連結テキスト）
- `data` - 現在のターンからの Base64 エンコードされたインラインバイナリデータ
- `serverContent` - サーバーコンテンツ (`modelTurn`, `turnComplete`, `interrupted`, `inputTranscription`, `outputTranscription`, `interimInputTranscription`, `TOO_MANY_TOOL_CALLS` を含む `turnCompleteReason` など)
- `setupComplete` - `sessionId` およびオプションの `voiceConsentSignature` を含むセットアップ完了通知
- `toolCall` - ツール呼び出しリクエスト
- `toolCallCancellation` - ツール呼び出しのキャンセル
- `sessionResumptionUpdate` - セッション再開トークンの更新
- `voiceActivity` - 音声アクティビティイベント (`audioOffset` 付き)
- `voiceActivityDetectionSignal` - 低レベル VAD シグナル
- `goAway` - サーバー切断警告 (`timeRemaining` ヘルパー付き)
- `usageMetadata` - トークン使用量の内訳（プロンプト、応答、思考、モダリティ詳細）

## 📖 サンプルと詳細ドキュメント

より詳細な使用例については、[`examples/`](https://github.com/JAICHANGPARK/flutter_gemini_live/tree/main/examples) ディレクトリを参照してください：

* **[`basic_usage.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/examples/basic_usage.dart)**: 接続、送信、受信の基本フロー。
* **[`function_calling.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/examples/function_calling.dart)**: Function Calling の設定と応答処理。
* **[`realtime_audio_video.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/examples/realtime_audio_video.dart)**: リアルタイムの音声・映像ストリーミング。
* **[`google_maps_grounding.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/examples/google_maps_grounding.dart)**: Google Maps グラウンディングとカスタム単語帳設定。
* **[`session_resumption.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/examples/session_resumption.dart)**: セッションハンドルの保存と再開。

---

## 📄 ライセンス

このプロジェクトは BSD 3-Clause ライセンスのもとでライセンスされています。[LICENSE](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/LICENSE) ファイルを参照してください。
