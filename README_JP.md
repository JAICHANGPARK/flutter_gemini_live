# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[[English]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [[한국어]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [[日本語]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [[简体中文]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- GoogleのGeminiモデルとリアルタイムでマルチモーダルな会話を実現する[実験的なGemini Live API](https://ai.google.dev/gemini-api/docs/live)用のFlutterパッケージです。
- **Firebase 依存なし**: Firebase や Firebase AI Logic を使用せず、直接 WebSocket で接続可能です。
- 最新の Gemini Live モデルをサポート (`gemini-3.1-flash-live-preview`, `gemini-2.5-flash-native-audio-preview-12-2025`)。
- `TEXT`、`AUDIO`、`VIDEO` の応答モダリティをサポート。

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

## 🏁 インストール (Installation)

Flutter プロジェクトにパッケージを追加します：

```bash
flutter pub add gemini_live
```

Dart コードでインポートします：

```dart
import 'package:gemini_live/gemini_live.dart';
```

## ⚡ クイックスタート (Quick Start)

20行未満のコードで簡単に対話を開始できます：

```dart
import 'package:gemini_live/gemini_live.dart';

void main() async {
  // 1. Gemini Live クライアントの初期化
  final genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY', logger: print);

  // 2. Live API 接続
  final session = await genAI.live.connect(
    LiveConnectParameters(
      model: 'gemini-3.1-flash-live-preview',
      config: GenerationConfig(responseModalities: [Modality.TEXT]),
      callbacks: LiveCallbacks(
        onOpen: () => print('✅ Live セッション接続完了!'),
        onMessage: (message) {
          if (message.text != null) {
            print('Gemini: ${message.text}');
          }
        },
        onError: (error, st) => print('🚨 エラー: $error'),
        onClose: (code, reason) => print('🔒 接続終了: $code - $reason'),
      ),
    ),
  );

  // 3. メッセージ送信
  session.sendText('こんにちは Gemini、ジョークをひとつ教えて！');
}
```

## 📚 ドキュメント & ガイド (Documentation)

詳細なガイドや仕様は [`doc/`](doc/) ディレクトリに整理されています：

- 📖 **[API リファレンス](doc/api_reference.md)**: `GoogleGenAI`, `LiveSession`, `LiveServerMessage` などの完全なクラス・メソッド仕様
- ⚙️ **[高度な設定ガイド](doc/advanced_configuration.md)**: Function Calling, VAD, セッション再開, 音声書き起こし, リアルタイム翻訳, グラウンディング, エフェメラルトークンの詳細
- 📘 **[エラーコード & 仕様書](doc/error_codes_specification.md)**: エラーコード, 終了コード, `TurnCompleteReason` Enum, トラブルシューティング
- 💡 **[実行可能なサンプル集](examples/README.md)**: 基本会話, ツール呼び出し, カメラ/音声ストリーミング, Google Maps グラウンディング CLI 例

## ✨ 主な機能概要

* **リアルタイム通信**: 低レイテンシの WebSocket 双方向対話。
* **マルチモーダル入力 & ストリーミング出力**: テキスト、音声、カメラフレーム入力とリアルタイム応答。
* **Function Calling**: 同期/非同期の関数実行。
* **セッション再開**: 切断された接続をセッションハンドルで復元。
* **Google Maps & 検索グラウンディング**: 位置やルートを認識した応答。
* **音声アクティビティ検出 (VAD)**: 自動および手動 VAD。
* **リアルタイム音声翻訳**: 音声から音声へのリアルタイム翻訳 (`TranslationConfig`)。

---

## 📄 ライセンス

このプロジェクトは BSD 3-Clause ライセンスのもとでライセンスされています。[LICENSE](LICENSE) ファイルを参照してください。
