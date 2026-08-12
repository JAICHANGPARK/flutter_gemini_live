# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[[English]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [[한국어]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [[日本語]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [[简体中文]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- 用于使用 [实验性 Gemini Live API](https://ai.google.dev/gemini-api/docs/live) 的 Flutter 软件包，实现与 Google Gemini 模型的实时多模态对话。
- 无 Firebase / Firebase AI Logic 依赖。
- 支持当前的 Gemini Live 模型系列：`gemini-3.1-flash-live-preview`（最新）和 `gemini-2.5-flash-native-audio-preview-12-2025`。
- 根据模型能力，支持 `TEXT`、`AUDIO` 和 `VIDEO` 响应模态。

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e


## ✨ 功能特性

* **实时通信**：建立 WebSocket 连接，实现低延迟的双向交互。
* **多模态输入**：在单个对话轮次中发送文本、图像和音频。
* **流式响应**：在模型生成文本响应时实时接收。
* **易于使用的回调**：基于事件的简单处理程序，支持 `onOpen`、`onMessage`、`onError` 和 `onClose`。
* **函数调用 (Function Calling)**：通过 `Behavior` 和 `FunctionResponseScheduling` 控制同步和异步函数调用。
* **会话恢复**：连接中断后，可使用保存的句柄恢复会话。
* **语音活动检测 (VAD)**：自动或手动语音活动检测。
* **实时媒体分片**：实时发送音频/图像块。
* **语音转写**：将语音输入和输出转写为文本，支持 `LanguageAuto`、`LanguageHints` 和 `customVocabulary` 自定义词汇提示。
* **实时翻译**：通过 `TranslationConfig` 实现实时语音到语音翻译。
* **上下文窗口压缩**：滑动窗口压缩，使长会话保持在 Token 限制内。
* **历史记录配置**：通过 `HistoryConfig` 在实时轮次之前预加载对话历史。
* **接地 (Grounding)**：Google 搜索接地和 URL 上下文工具。
* **Google Maps 接地**：支持位置和路线感知的 `GoogleMaps` 接地 (`places`, `routing`)。
* **临时令牌 (Ephemeral Tokens)**：通过短有效期令牌实现安全的客户端身份验证。

| 演示 1：吉娃娃 vs 玛芬 | 演示 2：拉布拉多贵宾犬 vs 炸鸡 |
| :---: | :---: |
| <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222333.png?raw=true" alt="实时对话演示" width="400"/> | <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222355.png?raw=true" alt="多模态输入演示" width="400"/> |
| *吉娃娃 vs 玛芬* | *拉布拉多贵宾犬 vs 炸鸡* |

## 🏁 快速入门

### 前置条件

使用此软件包需要 Google Gemini API 密钥。您可以从 [Google AI Studio](https://aistudio.google.com/app/apikey) 获取密钥。

### 安装

将软件包添加到您的 `pubspec.yaml` 文件中：

```yaml
dependencies:
  gemini_live: ^2026.8.12 # 使用最新发布的版本
```

或运行此命令（推荐）：

```bash
flutter pub add gemini_live
```

在终端中安装软件包：

```bash
flutter pub get
```

现在，在您的 Dart 代码中导入软件包：

```dart
import 'package:gemini_live/gemini_live.dart';
```

## 🚀 使用方法

### 基础示例

以下是使用 `gemini_live` 软件包启动会话并发送消息的基础示例。

**安全提示**：请勿硬编码您的 API 密钥。强烈建议配合 `flutter_dotenv` 等软件包使用 `.env` 文件来保持凭据安全。

```dart
import 'package:gemini_live/gemini_live.dart';

// 1. 使用 API 密钥初始化 Gemini
final genAI = GoogleGenAI(apiKey: 'YOUR_API_KEY_HERE');
LiveSession? session;

// 2. 连接到 Live API
Future<void> connect() async {
  try {
    session = await genAI.live.connect(
      LiveConnectParameters(
        model: 'gemini-3.1-flash-live-preview',
        config: GenerationConfig(responseModalities: [Modality.TEXT]),
        callbacks: LiveCallbacks(
          onOpen: () => print('✅ 连接已建立'),
          onMessage: (LiveServerMessage message) {
            // 3. 处理来自模型的接收消息
            if (message.text != null) {
              print('接收到分片: ${message.text}');
            }
            if (message.serverContent?.turnComplete ?? false) {
              print('✅ 对话轮次完成!');
            }
          },
          onError: (e, s) => print('🚨 错误: $e'),
          onClose: (code, reason) => print('🚪 连接已关闭'),
        ),
      ),
    );
  } catch (e) {
    print('连接失败: $e');
  }
}

// 4. 向模型发送消息
void sendMessage(String text) {
  session?.sendText(text);
}
```

## 📖 示例与详细文档

有关更详细的使用示例，请参阅 [`examples/`](https://github.com/JAICHANGPARK/flutter_gemini_live/tree/main/examples) 目录：

* **[`basic_usage.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/examples/basic_usage.dart)**：连接、发送和接收的基本流程。
* **[`function_calling.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/examples/function_calling.dart)**：Function Calling 的设置与响应处理。
* **[`realtime_audio_video.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/examples/realtime_audio_video.dart)**：实时音频和视频流传输。
* **[`google_maps_grounding.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/examples/google_maps_grounding.dart)**：Google Maps 接地与自定义词汇表设置。
* **[`session_resumption.dart`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/examples/session_resumption.dart)**：保存与恢复会话句柄。

---

## 📄 开源许可

本项目遵循 BSD 3-Clause 许可证开源。详情请参阅 [LICENSE](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/LICENSE) 文件。
