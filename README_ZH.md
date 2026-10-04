# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[[English]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [[한국어]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [[日本語]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [[简体中文]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- 用于 [Gemini Live API](https://ai.google.dev/gemini-api/docs/live) 的 Flutter 软件包，实现与 Google Gemini 模型的实时多模态对话。
- **零 Firebase 依赖**：无须安装 Firebase 或 Firebase AI Logic，直接通过 WebSocket 建立连接。
- **兼容 Firebase AI Logic**：可选的兼容层，与 `firebase_ai` 的 Live API 形式一致，只需替换 import 即可在两个包之间迁移。参见 [Firebase AI Logic 兼容](#firebase-ai-logic-兼容)。
- 支持最新的 Gemini Live、翻译和 Lyria 音乐模型。参见 [Supported Models](#supported-models)。
- 支持 `TEXT`、`AUDIO` 和 `VIDEO` 响应模态。

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

## 🤖 AI 智能体与编程助手指南 (AI Agents Guide)

如果您使用的是 AI 编程助手（**Claude Code**、**Gemini CLI / Antigravity**、**OpenAI Codex**、**Cursor**、**Windsurf**、**GitHub Copilot** 等）：
在编写代码前，请务必首先查阅软件包官方 Skill 规范：

### 可用技能 (Available Skills)

| 技能 (Skill) | 描述 (Description) | 提示词示例 (Example prompt) |
|---|---|---|
| [`flutter-gemini-live`](skills/flutter-gemini-live/SKILL.md) | 在 Flutter 中无需 Firebase 直接连接 Google Gemini Live API 构建低延迟多模态流式应用（低延迟语音通话、摄像头视频流、工具函数调用、音频转录、实时翻译、Lyria 音乐生成等） | *构建一个包含摄像头实时画面流与函数调用的低延迟 Gemini Live 语音通话界面* |
| [`gemini-live-widgets`](skills/gemini-live-widgets/SKILL.md) | 开箱即用的 Flutter Material 3 与 Cupertino UI 组件：麦克风波纹按钮、32 段 FFT 频谱波形图、磨砂玻璃字幕气泡、状态胶囊、Token 用量监控及 `GeminiLiveSessionController` 状态绑定指南 | *在我的 Gemini Live 通话页面中添加实时音频波形图和动态麦克风按钮* |
| [`gemini-live-firebase-migration`](skills/gemini-live-firebase-migration/SKILL.md) | `firebase_ai` (Firebase AI Logic) 与 `gemini_live` 之间的 1:1 双向无缝迁移。使用 `package:gemini_live/compat/firebase_ai.dart` 无需改动业务逻辑即可完全移除 Firebase 依赖 | *将现有的 firebase_ai LiveSession 代码迁移到 gemini_live 并移除 Firebase 依赖* |

### 智能体兼容性与技能发现路径 (Agent Compatibility)

| 助手 / 生态系统 | 原生 Skill 探索路径 | 项目指南 |
|---|---|---|
| **根目录通用 / AGENTS.md** | [`SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/SKILL.md) | [`AGENTS.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/AGENTS.md) |
| **通用 Skills 目录 / Hermes** | [`skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/flutter-gemini-live/SKILL.md) | [`skills/README.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/README.md) |
| **Hermes Agent** | [`.hermes/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.hermes/skills/flutter-gemini-live/SKILL.md) | - |
| **Pi Agent** | [`.pi/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.pi/skills/flutter-gemini-live/SKILL.md) | - |
| **Claude Code** | [`.claude/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.claude/skills/flutter-gemini-live/SKILL.md) | [`CLAUDE.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/CLAUDE.md) |
| **Gemini CLI / Antigravity** | [`.gemini/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.gemini/skills/flutter-gemini-live/SKILL.md) | [`GEMINI.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/GEMINI.md) |
| **OpenAI Codex / Cursor** | [`.codex/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.codex/skills/flutter-gemini-live/SKILL.md) | [`CODEX.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/CODEX.md) |
| **Agent Skills 开放规范** | [`.agents/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.agents/skills/flutter-gemini-live/SKILL.md) | - |

```bash
# 自动检测正在使用的智能体并一键安装 (~/.claude, ~/.gemini, ~/.codex 等)
curl -fsSL https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main/tool/install_skills.sh | bash

# 或仅指定特定目标进行安装：
# curl -fsSL https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main/tool/install_skills.sh | bash -s -- claude gemini
```

### 📌 AI 智能体核心规范
1. **零 Firebase 依赖**：实时流式传输切勿引入 `firebase_core` 或 `firebase_vertexai`，直接使用 `GoogleGenAI` 的 WebSocket 接口。
2. **推荐 UI 状态管理**：开发 Flutter 界面时，优先使用自动管理生命周期与打断（Barge-in）的 `GeminiLiveSessionController` (`ChangeNotifier`)。
3. **内置 Material 3 组件**：使用软件包内置原生组件（`GeminiLiveWaveform`、`GeminiLiveCaptionBubble`、`GeminiLiveMicButton`、`GeminiLiveStatusBadge`、`GeminiLiveVoiceIndicator`、`GeminiLiveUsageBadge`）。
4. **即时清空打断音频缓冲**：检测到 `serverContent.interrupted == true` 或 `controller.isInterrupted` 时，必须立即清空本地音频播放缓冲，防止啸叫回音。
5. **音频格式规范**：麦克风输入为线性 PCM 16-bit 16,000 Hz 单声道，Live 响应输出为 24,000 Hz 单声道（音乐生成为 48,000 Hz 立体声）。
6. **推荐模型**：通用对话首选 `gemini-3.8-live`，深度推理对话首选 `gemini-3.8-live-extended-thinking`。
7. **音频输入输出需自行接入**：`GeminiLiveSessionController` 不负责录音和播放。请将麦克风 PCM 发送到 `sendRealtimeAudio()`，并播放 `incomingAudioStream`（例如 `record` + `flutter_soloud`）。

## Supported Models

可直接使用模型 ID 字符串，或使用 `LiveModels` / `LiveMusicModels` 中对应的常量。

### Live API (`genAI.live.connect`)

| 模型 ID | 常量 | 用途 | 状态 |
|---|---|---|---|
| `gemini-3.8-live` | `LiveModels.gemini38Live` | **默认。** 低延迟语音与多模态对话 | Stable |
| `gemini-3.8-live-extended-thinking` | `LiveModels.gemini38LiveExtendedThinking` | 需要深度推理的语音对话（`thinkingConfig`） | Stable |
| `gemini-3.5-live-translate-preview` | `LiveModels.gemini35LiveTranslatePreview` | 实时语音翻译（`TranslationConfig`） | Preview |
| `gemini-3.1-flash-live-preview` | `LiveModels.gemini31FlashLivePreview` | 上一代 | Preview |
| `gemini-2.5-flash-native-audio-preview-12-2025` | `LiveModels.gemini25FlashNativeAudioPreview` | 原生音频输出 | Preview |

### Live Music (`genAI.live.music.connect`)

| 模型 ID | 常量 | 用途 | 状态 |
|---|---|---|---|
| `models/lyria-realtime-exp` | `LiveMusicModels.lyriaRealtimeExp` | **默认。** 实时音乐生成 | Experimental |

> - `thinkingConfig` 只能传给 `gemini-3.8-live-extended-thinking`，传给 `gemini-3.8-live` 会报错。
> - `gemini-3.8-live` 默认以非阻塞方式（`Behavior.NON_BLOCKING`）执行工具调用。
> - Live 输出音频为 16-bit PCM 24 kHz 单声道，Lyria 输出为 16-bit PCM 48 kHz 立体声。
> - 模型可用性可能会变化，最新状态请查看 [Gemini API 模型页面](https://ai.google.dev/gemini-api/docs/models)。

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
      model: 'gemini-3.8-live',
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

## 语音对话快速入门 (Voice Quick Start)

大多数 Live 应用都是语音应用。`GeminiLiveSessionController` 只负责收发音频数据，**不会**录制麦克风或播放声音。输入请接入 [`record`](https://pub.dev/packages/record)，输出请接入 [`flutter_soloud`](https://pub.dev/packages/flutter_soloud)：

```bash
flutter pub add gemini_live record flutter_soloud
```

为各平台添加麦克风权限：

| 平台 | 设置 |
|---|---|
| Android | `AndroidManifest.xml`：`android.permission.RECORD_AUDIO`、`android.permission.INTERNET` |
| iOS | `Info.plist`：`NSMicrophoneUsageDescription` |
| macOS | Entitlements：`com.apple.security.device.audio-input`、`com.apple.security.network.client` |

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

包含字幕、波形和 Barge-in 处理的完整页面示例，请参阅 [Agent Skill 快速入门](skills/flutter-gemini-live/SKILL.md) 和 [示例应用](example/lib/)。

> **🔐 API 密钥安全：** 请勿在生产应用中直接内置 Gemini API 密钥。请在后端使用 `genAI.authTokens.create(...)` 签发短期有效的**临时令牌**，客户端使用该令牌连接。参见 [临时令牌指南](doc/advanced_configuration.md) 和 [`examples/ephemeral_token.dart`](examples/ephemeral_token.dart)。

## Firebase AI Logic 兼容

`package:gemini_live/compat/firebase_ai.dart` 与 **[`firebase_ai`](https://pub.dev/packages/firebase_ai) 4.x 的 Live API** 拥有相同的类名、构造函数、方法和默认值，完整支持 `FirebaseAI.googleAI()`、`liveGenerativeModel`、`LiveGenerationConfig`、`LiveSession.send*`、`receive()`、工具调用和会话恢复。它运行在 gemini_live 引擎之上，无需 Firebase 项目。现有的 `gemini_live` 核心 API 保持不变，兼容层是一个独立的入口。

```dart
import 'package:gemini_live/compat/firebase_ai.dart';

FirebaseAI.initialize(apiKey: 'YOUR_KEY_OR_EPHEMERAL_TOKEN');

final model = FirebaseAI.googleAI().liveGenerativeModel(
  model: 'gemini-2.5-flash-native-audio-preview-12-2025',
  liveGenerationConfig: LiveGenerationConfig(
    responseModalities: [ResponseModalities.audio],
    speechConfig: SpeechConfig(voiceName: 'Puck'),
    outputAudioTranscription: AudioTranscriptionConfig(),
  ),
);
final session = await model.connect();

session.receive().listen((response) async {
  final message = response.message;
  if (message is LiveServerContent) {
    for (final part in message.modelTurn?.parts ?? const <Part>[]) {
      if (part is InlineDataPart) playPcm(part.bytes);
    }
  } else if (message is LiveServerToolCall) {
    for (final call in message.functionCalls ?? const <FunctionCall>[]) {
      await session.sendToolResponse([
        FunctionResponse(call.name, await runTool(call), id: call.id),
      ]);
    }
  }
});

await session.sendAudioRealtime(InlineDataPart('audio/pcm;rate=16000', chunk));

// gemini_live 独有功能（firebase_ai 不提供 Live 用量元数据）：
print(session.tokenTracker.formatCost());
```

仅支持 Live API。`vertexAI()`、`generativeModel` 等非 Live API 未提供，使用时会产生编译错误。

## 迁移指南 (Migration)

**firebase_ai → gemini_live**（只需修改两处，`FirebaseAI.googleAI()` 之后的代码保持不变）：

```diff
- import 'package:firebase_core/firebase_core.dart';
- import 'package:firebase_ai/firebase_ai.dart';
+ import 'package:gemini_live/compat/firebase_ai.dart';

- await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
+ FirebaseAI.initialize(apiKey: 'YOUR_KEY_OR_EPHEMERAL_TOKEN');
```

- Firebase App Check 将不再保护密钥。生产环境请使用[临时令牌](doc/advanced_configuration.md)。`auth_tokens/...` 令牌会自动使用 `v1alpha`。
- `FirebaseAI.vertexAI()` 需要改为 `googleAI()`。

**gemini_live → firebase_ai**（将上面两处反向修改）：

- 删除编译器提示的 gemini_live 独有功能：`FirebaseAI.initialize`、`googleAI(apiKey:)`、`session.tokenTracker`、`session.rawSession`、`response.rawMessage`。
- 请在发送之前先订阅 `receive()`。gemini_live 会保留订阅前收到的响应，而 firebase_ai 会丢弃它们。
- 只有使用兼容层编写的代码可以迁移。使用核心 API（`GoogleGenAI`、`GeminiLiveSessionController`）编写的代码需要重写。

完整的 API 对照表、行为差异以及在同一应用中同时使用两个包的方法，请参阅 [Firebase AI 兼容指南](doc/firebase_ai_compat.md)。双向兼容性由 [`tool/check_firebase_ai_compat.sh`](tool/check_firebase_ai_compat.sh) 验证，它会用两个包分别编译同一个示例。

## 文档与指南 (Documentation)

更详细的指南与 API 参考已按模块整理至 [`doc/`](doc/) 目录：

- **[AI Agent Skill 指南](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/SKILL.md)** ([skills/](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/README.md))：支持 Claude Code, Gemini CLI / Antigravity, OpenAI Codex, Cursor 等所有 AI 助手的多 Agent 技能规范
- **[API 参考指南](doc/api_reference.md)**：包含 `GoogleGenAI`、`LiveSession`、`LiveServerMessage` 等完整类与方法说明
- **[组件指南](doc/widgets_guide.md)**：`GeminiLiveSessionController` 及所有内置组件的用法与页面示例
- **[高级配置指南](doc/advanced_configuration.md)**：包含 Function Calling、VAD、会话恢复、音频转写、实时翻译、接地与临时令牌使用说明
- **[Firebase AI 兼容与迁移指南](doc/firebase_ai_compat.md)**：与 `firebase_ai` 兼容的 Live API（`package:gemini_live/compat/firebase_ai.dart`）、双向迁移清单及行为差异
- **[错误代码与规范](doc/error_codes_specification.md)**：包含完整错误代码、关闭代码、`TurnCompleteReason` 枚举及故障排除指南
- **[可运行示例集](examples/README.md)**：包含基础对话、工具调用、摄像头/音频流传输与 Google Maps 接地 CLI 脚本

## 主要功能特性

* **实时通信**：低延迟 WebSocket 双向交互。
* **多模态输入与流式输出**：支持文本、音频、摄像头图像帧输入与实时响应流。
* **函数调用 (Function Calling)**：同步与异步函数执行。
* **会话恢复**：通过会话句柄无缝恢复断开的连接。
* **Google Maps 与搜索接地**：位置与路线感知的智能接地响应。
* **语音活动检测 (VAD)**：支持自动与手动 VAD。
* **内置 Flutter 组件与控制器**：`GeminiLiveSessionController`、`GeminiLiveWaveform`、`GeminiLiveCaptionBubble`、`GeminiLiveMicButton`、`GeminiLiveStatusBadge`、`GeminiLiveUsageBadge`、`GeminiLiveVoiceIndicator`。
* **实时语音翻译**：Speech-to-Speech 实时翻译（`TranslationConfig`）。
* **Live Music (Lyria Realtime)**：通过 `genAI.live.music` 实时生成并调控音乐。
* **临时认证令牌**：通过 `genAI.authTokens` 签发短期客户端令牌，避免在设备上存放 API 密钥。
* **Token 用量追踪**：使用 `GeminiTokenUsageTracker` 统计每个会话的 Token 用量。

---

## 内置 UI 组件 (Pre-built UI Widgets)

软件包随附开箱即用的 Material 3 原生组件，加速 Live 对话界面的构建：

```dart
// 1. 高级会话控制器 (基于 ChangeNotifier)
final controller = GeminiLiveSessionController(liveService: genAI.live);
await controller.connect(
  LiveConnectParameters(
    model: 'gemini-3.8-live',
    config: GenerationConfig(responseModalities: [Modality.AUDIO]),
    callbacks: LiveCallbacks(),
  ),
);

// 2. 实时音频波形可视化器 (胶囊条柱与呼吸动效)
GeminiLiveWaveform(
  audioStream: controller.incomingAudioStream,
  barCount: 28,
  height: 64,
  color: Theme.of(context).colorScheme.primary,
  enableIdleBreathing: true,
)

// 3. 毛玻璃实时字幕气泡 (BackdropFilter 模糊与说话人徽标)
GeminiLiveCaptionBubble(
  text: controller.latestTranscript ?? '',
  speaker: controller.latestTranscriptRole == 'user' ? '你' : 'Gemini',
  isStreaming: controller.isModelSpeaking,
  enableBlur: true,
)

// 4. 同心声学涟漪麦克风按钮
GeminiLiveMicButton(
  isRecording: controller.isConnected,
  onPressed: () => toggleLiveSession(),
)

// 5. 连接状态徽标 (脉冲光晕环指示器)
GeminiLiveStatusBadge.fromFlags(
  isConnected: controller.isConnected,
  isConnecting: isConnecting,
)

// 6. 实时 Token 用量监控徽标
GeminiLiveUsageBadge(
  tracker: controller.tokenTracker,
)

// 7. 双谐波声活动指示器
GeminiLiveVoiceIndicator(
  isSpeaking: controller.isModelSpeaking,
  barCount: 5,
)
```

---

## 开源许可

本项目遵循 BSD 3-Clause 许可证开源。详情请参阅 [LICENSE](LICENSE) 文件。
