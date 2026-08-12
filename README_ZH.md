# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[[English]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [[한국어]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [[日本語]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [[简体中文]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- 用于 [实验性 Gemini Live API](https://ai.google.dev/gemini-api/docs/live) 的 Flutter 软件包，实现与 Google Gemini 模型的实时多模态对话。
- **零 Firebase 依赖**：无须安装 Firebase 或 Firebase AI Logic，直接通过 WebSocket 建立连接。
- 支持最新的 Gemini Live 模型（`gemini-3.1-flash-live-preview`，`gemini-2.5-flash-native-audio-preview-12-2025`）。
- 支持 `TEXT`、`AUDIO` 和 `VIDEO` 响应模态。

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

## 安装 (Installation)

在 Flutter 项目中添加软件包：

```bash
flutter pub add gemini_live
```

在 Dart 代码中导入软件包：

```dart
import 'package:gemini_live/gemini_live.dart';
```

## 快速入门 (Quick Start)

只需不到 20 行代码即可轻松启动对话：

```dart
import 'package:gemini_live/gemini_live.dart';

void main() async {
  // 1. 初始化 Gemini Live 客户端
  final genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY', logger: print);

  // 2. 连接到 Live API
  final session = await genAI.live.connect(
    LiveConnectParameters(
      model: 'gemini-3.1-flash-live-preview',
      config: GenerationConfig(responseModalities: [Modality.TEXT]),
      callbacks: LiveCallbacks(
        onOpen: () => print('Live 会话已连接！'),
        onMessage: (message) {
          if (message.text != null) {
            print('Gemini: ${message.text}');
          }
        },
        onError: (error, st) => print('错误: $error'),
        onClose: (code, reason) => print('连接已关闭: $code - $reason'),
      ),
    ),
  );

  // 3. 发送消息
  session.sendText('你好 Gemini，请讲一个简短的笑话！');
}
```

## 文档与指南 (Documentation)

更详细的指南与 API 参考已按模块整理至 [`doc/`](doc/) 目录：

- **[AI Agent Skill 指南](SKILL.md)**：供 AI 编程助手 (Antigravity, Cursor, Windsurf, Claude Code 等) 正确集成此软件包的提示词与 Skill 规范
- **[API 参考指南](doc/api_reference.md)**：包含 `GoogleGenAI`、`LiveSession`、`LiveServerMessage` 等完整类与方法说明
- **[高级配置指南](doc/advanced_configuration.md)**：包含 Function Calling、VAD、会话恢复、音频转写、实时翻译、接地与临时令牌使用说明
- **[错误代码与规范](doc/error_codes_specification.md)**：包含完整错误代码、关闭代码、`TurnCompleteReason` 枚举及故障排除指南
- **[可运行示例集](examples/README.md)**：包含基础对话、工具调用、摄像头/音频流传输与 Google Maps 接地 CLI 脚本

## 主要功能特性

* **实时通信**：低延迟 WebSocket 双向交互。
* **多模态输入与流式输出**：支持文本、音频、摄像头图像帧输入与实时响应流。
* **函数调用 (Function Calling)**：同步与异步函数执行。
* **会话恢复**：通过会话句柄无缝恢复断开的连接。
* **Google Maps 与搜索接地**：位置与路线感知的智能接地响应。
* **语音活动检测 (VAD)**：支持自动与手动 VAD。
* **实时语音翻译**：语音到语音实时翻译 (`TranslationConfig`)。

---

## 开源许可

本项目遵循 BSD 3-Clause 许可证开源。详情请参阅 [LICENSE](LICENSE) 文件。
