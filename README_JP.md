# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[[English]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [[한국어]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [[日本語]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [[简体中文]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- GoogleのGeminiモデルとリアルタイムでマルチモーダルな会話を実現する[Gemini Live API](https://ai.google.dev/gemini-api/docs/live)用のFlutterパッケージです。
- **Firebase 依存なし**: Firebase や Firebase AI Logic を使用せず、直接 WebSocket で接続可能です。
- 最新の Gemini Live・翻訳・Lyria 音楽モデルをサポートします。[Supported Models](#supported-models) を参照してください。
- `TEXT`、`AUDIO`、`VIDEO` の応答モダリティをサポート。

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

## 🤖 AI エージェント & コーディングアシスタントガイド (AI Agents Guide)

AI コーディングアシスタント（**Claude Code**, **Gemini CLI / Antigravity**, **OpenAI Codex**, **Cursor**, **Windsurf**, **GitHub Copilot** など）をご利用の場合、コード生成前にパッケージ公式の Skill 仕様を必ず参照してください：

| アシスタント / エコシステム | 専用 Skill 探索パス | プロジェクトガイド |
|---|---|---|
| **ルート共通** | [`SKILL.md`](SKILL.md) | - |
| **共通 Skills ディレクトリ** | [`skills/flutter-gemini-live/SKILL.md`](skills/flutter-gemini-live/SKILL.md) | [`skills/README.md`](skills/README.md) |
| **Claude Code** | [`.claude/skills/flutter-gemini-live/SKILL.md`](.claude/skills/flutter-gemini-live/SKILL.md) | [`CLAUDE.md`](CLAUDE.md) |
| **Gemini CLI / Antigravity** | [`.gemini/skills/flutter-gemini-live/SKILL.md`](.gemini/skills/flutter-gemini-live/SKILL.md) | [`GEMINI.md`](GEMINI.md) |
| **OpenAI Codex / Cursor** | [`.codex/skills/flutter-gemini-live/SKILL.md`](.codex/skills/flutter-gemini-live/SKILL.md) | [`CODEX.md`](CODEX.md) |
| **Agent Skills オープン標準** | [`.agents/skills/flutter-gemini-live/SKILL.md`](.agents/skills/flutter-gemini-live/SKILL.md) | - |

### 📌 AI エージェント実装ルール
1. **Firebase 依存の排除**: リアルタイムストリーミングには `firebase_core` や `firebase_vertexai` を使用せず、`GoogleGenAI` の WebSocket エンドポイントに直接接続します。
2. **推奨 UI 状態管理**: Flutter UI アプリでは、接続ライフサイクルや割り込み（Barge-in）を自動処理する `GeminiLiveSessionController` (`ChangeNotifier`) を優先的に使用します。
3. **組み込み Material 3 ウィジェット**: パッケージ標準のウィジェット（`GeminiLiveWaveform`, `GeminiLiveCaptionBubble`, `GeminiLiveMicButton`, `GeminiLiveStatusBadge`, `GeminiLiveVoiceIndicator`, `GeminiLiveUsageBadge`）を活用します。
4. **Barge-in バッファの即時破棄**: `serverContent.interrupted == true` または `controller.isInterrupted` が検知された場合、ハウリングを防ぐため直ちにローカル再生バッファをクリアします。
5. **音声フォーマット**: マイク入力は Linear PCM 16-bit, 16,000 Hz モノラル、出力は 24,000 Hz モノラル（音楽は 48,000 Hz ステレオ）です。
6. **推奨モデル**: 通常対話は `gemini-3.8-live`、高度な推論対話は `gemini-3.8-live-extended-thinking` を指定します。
7. **音声入出力は自分で接続**: `GeminiLiveSessionController` は録音も再生も行いません。マイクの PCM を `sendRealtimeAudio()` に送り、`incomingAudioStream` を再生してください (例: `record` + `flutter_soloud`)。

## Supported Models

モデル ID 文字列、または `LiveModels` / `LiveMusicModels` の定数を使用してください。

### Live API (`genAI.live.connect`)

| モデル ID | 定数 | 用途 | ステータス |
|---|---|---|---|
| `gemini-3.8-live` | `LiveModels.gemini38Live` | **デフォルト。** 低レイテンシの音声・マルチモーダル対話 | Stable |
| `gemini-3.8-live-extended-thinking` | `LiveModels.gemini38LiveExtendedThinking` | 深い推論を伴う音声対話 (`thinkingConfig`) | Stable |
| `gemini-3.5-live-translate-preview` | `LiveModels.gemini35LiveTranslatePreview` | リアルタイム音声翻訳 (`TranslationConfig`) | Preview |
| `gemini-3.1-flash-live-preview` | `LiveModels.gemini31FlashLivePreview` | 前世代 | Preview |
| `gemini-2.5-flash-native-audio-preview-12-2025` | `LiveModels.gemini25FlashNativeAudioPreview` | ネイティブ音声出力 | Preview |

### Live Music (`genAI.live.music.connect`)

| モデル ID | 定数 | 用途 | ステータス |
|---|---|---|---|
| `models/lyria-realtime-exp` | `LiveMusicModels.lyriaRealtimeExp` | **デフォルト。** リアルタイム音楽生成 | Experimental |

> - `thinkingConfig` は `gemini-3.8-live-extended-thinking` にのみ渡してください。`gemini-3.8-live` ではエラーになります。
> - `gemini-3.8-live` はツール呼び出しをデフォルトで non-blocking (`Behavior.NON_BLOCKING`) で実行します。
> - Live の出力音声は 16-bit PCM 24 kHz モノラル、Lyria の出力は 16-bit PCM 48 kHz ステレオです。
> - モデルの提供状況は変わる可能性があります。最新情報は [Gemini API モデルページ](https://ai.google.dev/gemini-api/docs/models) を確認してください。

## インストール (Installation)

Flutter プロジェクトにパッケージを追加します：

```bash
flutter pub add gemini_live
```

Dart コードでインポートします：

```dart
import 'package:gemini_live/gemini_live.dart';
```

## クイックスタート (Quick Start)

20行未満のコードで簡単に対話を開始できます：

```dart
import 'package:gemini_live/gemini_live.dart';

void main() async {
  // 1. Gemini Live クライアントの初期化
  final genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY', logger: print);

  // 2. Live API 接続
  final session = await genAI.live.connect(
    LiveConnectParameters(
      model: 'gemini-3.8-live',
      config: GenerationConfig(responseModalities: [Modality.TEXT]),
      callbacks: LiveCallbacks(
        onOpen: () => print('Live セッション接続完了!'),
        onMessage: (message) {
          if (message.text != null) {
            print('Gemini: ${message.text}');
          }
        },
        onError: (error, st) => print('エラー: $error'),
        onClose: (code, reason) => print('接続終了: $code - $reason'),
      ),
    ),
  );

  // 3. メッセージ送信
  session.sendText('こんにちは Gemini、ジョークをひとつ教えて！');
}
```

## 音声会話クイックスタート (Voice Quick Start)

Live アプリの多くは音声アプリです。`GeminiLiveSessionController` は音声データを送受信するだけで、マイク録音と音声再生は**行いません**。入力は [`record`](https://pub.dev/packages/record)、出力は [`flutter_soloud`](https://pub.dev/packages/flutter_soloud) と接続してください:

```bash
flutter pub add gemini_live record flutter_soloud
```

プラットフォームごとにマイク権限を追加してください:

| プラットフォーム | 設定 |
|---|---|
| Android | `AndroidManifest.xml`: `android.permission.RECORD_AUDIO`, `android.permission.INTERNET` |
| iOS | `Info.plist`: `NSMicrophoneUsageDescription` |
| macOS | Entitlements: `com.apple.security.device.audio-input`, `com.apple.security.network.client` |

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

final genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY');
final controller = GeminiLiveSessionController(liveService: genAI.live);
final recorder = AudioRecorder();

Future<void> startVoiceChat() async {
  if (!await recorder.hasPermission()) return;

  await controller.connect(
    LiveConnectParameters(
      model: 'gemini-3.8-live',
      config: GenerationConfig(responseModalities: [Modality.AUDIO]),
      outputAudioTranscription: AudioTranscriptionConfig(),
      callbacks: LiveCallbacks(onError: (e, st) => debugPrint('Live error: $e')),
    ),
  );

  // Speaker: model audio is 16-bit PCM, 24 kHz, mono.
  await SoLoud.instance.init();
  final speaker = SoLoud.instance.setBufferStream(
    sampleRate: 24000,
    channels: Channels.mono,
    format: BufferType.s16le,
    bufferingType: BufferingType.released,
  );
  SoLoud.instance.play(speaker);
  controller.incomingAudioStream.listen(
    (pcm) => SoLoud.instance.addAudioDataStream(speaker, pcm),
  );

  // Barge-in: drop queued model audio when the user interrupts.
  controller.addListener(() {
    if (controller.isInterrupted) SoLoud.instance.resetBufferStream(speaker);
  });

  // Mic: send 16-bit PCM, 16 kHz, mono.
  final mic = await recorder.startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
    ),
  );
  mic.listen(controller.sendRealtimeAudio);
}
```

字幕・波形・Barge-in 処理を含む完全な画面例は、[Agent Skill クイックスタート](skills/flutter-gemini-live/SKILL.md) と [サンプルアプリ](example/lib/) を参照してください。

> **🔐 API キーのセキュリティ:** 本番アプリに Gemini API キーをそのまま埋め込まないでください。バックエンドで `genAI.authTokens.create(...)` を使って短期間有効な**エフェメラルトークン**を発行し、クライアントはそのトークンで接続してください。[エフェメラルトークンガイド](doc/advanced_configuration.md) と [`examples/ephemeral_token.dart`](examples/ephemeral_token.dart) を参照してください。

## ドキュメント & ガイド (Documentation)

詳細なガイドや仕様は [`doc/`](doc/) ディレクトリに整理されています：

- **[AI Agent Skill ガイド](SKILL.md)** ([skills/](skills/README.md)): Claude Code, Gemini CLI / Antigravity, OpenAI Codex, Cursor などに対応したマルチエージェントスキルガイド
- **[API リファレンス](doc/api_reference.md)**: `GoogleGenAI`, `LiveSession`, `LiveServerMessage` などの完全なクラス・メソッド仕様
- **[ウィジェットガイド](doc/widgets_guide.md)**: `GeminiLiveSessionController` とすべての組み込みウィジェットの使い方と画面例
- **[高度な設定ガイド](doc/advanced_configuration.md)**: Function Calling, VAD, セッション再開, 音声書き起こし, リアルタイム翻訳, グラウンディング, エフェメラルトークンの詳細
- **[エラーコード & 仕様書](doc/error_codes_specification.md)**: エラーコード, 終了コード, `TurnCompleteReason` Enum, トラブルシューティング
- **[実行可能なサンプル集](examples/README.md)**: 基本会話, ツール呼び出し, カメラ/音声ストリーミング, Google Maps グラウンディング CLI 例

## 主な機能概要

* **リアルタイム通信**: 低レイテンシの WebSocket 双方向対話。
* **マルチモーダル入力 & ストリーミング出力**: テキスト、音声、カメラフレーム入力とリアルタイム応答。
* **Function Calling**: 同期/非同期の関数実行。
* **セッション再開**: 切断された接続をセッションハンドルで復元。
* **Google Maps & 検索グラウンディング**: 位置やルートを認識した応答。
* **音声アクティビティ検出 (VAD)**: 自動および手動 VAD。
* **組み込み Flutter ウィジェット & コントローラー**: `GeminiLiveSessionController`, `GeminiLiveWaveform`, `GeminiLiveCaptionBubble`, `GeminiLiveMicButton`, `GeminiLiveStatusBadge`, `GeminiLiveUsageBadge`, `GeminiLiveVoiceIndicator`。
* **リアルタイム音声翻訳**: Speech-to-Speech のリアルタイム翻訳 (`TranslationConfig`)。
* **Live Music (Lyria Realtime)**: `genAI.live.music` によるリアルタイム音楽生成と調整。
* **エフェメラル認証トークン**: `genAI.authTokens` で短期クライアントトークンを発行し、端末に API キーを置きません。
* **トークン使用量トラッキング**: `GeminiTokenUsageTracker` によるセッションごとのトークン集計。

---

## 組み込み UI ウィジェット (Pre-built UI Widgets)

Flutter アプリですぐに利用可能な軽量・高機能な Material 3 ウィジェットが同梱されています：

```dart
// 1. 高水準セッションコントローラー (ChangeNotifier)
final controller = GeminiLiveSessionController(liveService: genAI.live);
await controller.connect(
  LiveConnectParameters(
    model: 'gemini-3.8-live',
    config: GenerationConfig(responseModalities: [Modality.AUDIO]),
    callbacks: LiveCallbacks(),
  ),
);

// 2. リアルタイム音声波形ビジュアライザー (カプセルバー & ブリージング動作)
GeminiLiveWaveform(
  audioStream: controller.incomingAudioStream,
  barCount: 28,
  height: 64,
  color: Theme.of(context).colorScheme.primary,
  enableIdleBreathing: true,
)

// 3. すりガラス字幕バブル (BackdropFilter ブラー & 話者チップ)
GeminiLiveCaptionBubble(
  text: controller.latestTranscript ?? '',
  speaker: controller.latestTranscriptRole == 'user' ? 'あなた' : 'Gemini',
  isStreaming: controller.isModelSpeaking,
  enableBlur: true,
)

// 4. 同心円音響リップルマイクボタン
GeminiLiveMicButton(
  isRecording: controller.isConnected,
  onPressed: () => toggleLiveSession(),
)

// 5. 接続状態バッジ (パルスヘイローインジケーター)
GeminiLiveStatusBadge.fromFlags(
  isConnected: controller.isConnected,
  isConnecting: isConnecting,
)

// 6. リアルタイムトークン使用量バッジ
GeminiLiveUsageBadge(
  tracker: controller.tokenTracker,
)

// 7. デュアルハーモニック音声インジケーター
GeminiLiveVoiceIndicator(
  isSpeaking: controller.isModelSpeaking,
  barCount: 5,
)
```

---

## ライセンス

このプロジェクトは BSD 3-Clause ライセンスのもとでライセンスされています。[LICENSE](LICENSE) ファイルを参照してください。
