# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

[[English]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README.md) | [[한국어]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_KR.md) | [[日本語]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_JP.md) | [[简体中文]](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/README_ZH.md)

---

- Google의 Gemini 모델과 실시간, 멀티모달 대화를 가능하게 해주는 [Gemini Live API](https://ai.google.dev/gemini-api/docs/live)용 Flutter 패키지입니다.
- **Firebase 의존성 Zero**: Firebase / Firebase AI Logic 설치 없이 직접 WebSocket으로 연동됩니다.
- 최신 Gemini Live, 번역, Lyria 음악 모델을 지원합니다. [Supported Models](#supported-models)를 참고하세요.
- 모델 사양에 따라 `TEXT`, `AUDIO`, `VIDEO` 응답 모다리티를 지원합니다.

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

## 🤖 AI 에이전트 및 코딩 어시스턴트 가이드 (AI Agents Guide)

AI 코딩 어시스턴트(**Claude Code**, **Gemini CLI / Antigravity**, **OpenAI Codex**, **Cursor**, **Windsurf**, **GitHub Copilot** 등)를 사용하는 개발자 및 AI 에이전트는 코드 작성 전에 패키지 전용 스킬 명세서를 먼저 참조하십시오:

| 어시스턴트 / 에코시스템 | 전용 스킬 탐색 경로 | 프로젝트 가이드 |
|---|---|---|
| **루트 표준** | [`SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/SKILL.md) | - |
| **공통 Skills 디렉토리** | [`skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/flutter-gemini-live/SKILL.md) | [`skills/README.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/README.md) |
| **Claude Code** | [`.claude/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.claude/skills/flutter-gemini-live/SKILL.md) | [`CLAUDE.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/CLAUDE.md) |
| **Gemini CLI / Antigravity** | [`.gemini/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.gemini/skills/flutter-gemini-live/SKILL.md) | [`GEMINI.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/GEMINI.md) |
| **OpenAI Codex / Cursor** | [`.codex/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.codex/skills/flutter-gemini-live/SKILL.md) | [`CODEX.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/CODEX.md) |
| **Agent Skills 오픈 표준** | [`.agents/skills/flutter-gemini-live/SKILL.md`](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/.agents/skills/flutter-gemini-live/SKILL.md) | - |

**🔗 스킬 직접 가져오기** — pub.dev 패키지에는 숨김 폴더(`.claude/`, `.gemini/` 등)가 포함되지 않으므로 아래 링크를 사용하세요:
- **Raw Markdown (에이전트용)**: https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main/skills/flutter-gemini-live/SKILL.md
- **`flutter pub get` 후 로컬 사본**: `<PUB_CACHE>/hosted/pub.dev/gemini_live-<version>/skills/flutter-gemini-live/SKILL.md`

```bash
# Install as a global skill (keep only the agents you use)
for d in ~/.claude ~/.gemini ~/.codex ~/.agents; do
  mkdir -p "$d/skills/flutter-gemini-live"
  curl -fsSL https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main/skills/flutter-gemini-live/SKILL.md \
    -o "$d/skills/flutter-gemini-live/SKILL.md"
done
```

### 📌 AI 에이전트 핵심 구현 수칙
1. **Firebase 의존성 배제**: 실시간 스트리밍 시 `firebase_core`나 `firebase_vertexai`를 추가하지 않고 `GoogleGenAI`의 WebSocket 엔드포인트를 직접 사용합니다.
2. **권장 UI 상태 관리**: Flutter UI 개발 시 저수준 `LiveSession` 대신 생명주기 및 사용자 발화 중단(Barge-in)을 자동 처리하는 `GeminiLiveSessionController` (`ChangeNotifier`)를 우선적으로 활용합니다.
3. **내장 Material 3 위젯 우선 사용**: 패키지 내장 위젯(`GeminiLiveWaveform`, `GeminiLiveCaptionBubble`, `GeminiLiveMicButton`, `GeminiLiveStatusBadge`, `GeminiLiveVoiceIndicator`, `GeminiLiveUsageBadge`)을 사용하여 완성도 높은 UI를 구성합니다.
4. **Barge-in 오디오 버퍼 즉시 플러시**: `serverContent.interrupted == true` 또는 `controller.isInterrupted`가 감지되면 즉시 로컬 재생 오디오 버퍼를 비워 하울링을 방지합니다.
5. **오디오 포맷 규격**: 마이크 입력은 리니어 PCM 16-bit, 16,000 Hz 모노이며, 라이브 모델 출력은 리니어 PCM 16-bit, 24,000 Hz 모노(음악은 48,000 Hz 스테레오)입니다.
6. **추천 모델**: 기본 대화는 `gemini-3.8-live`, 심층 추론은 `gemini-3.8-live-extended-thinking`을 기본값으로 사용합니다.
7. **오디오 입출력은 직접 연결**: `GeminiLiveSessionController`는 녹음과 재생을 하지 않습니다. 마이크 PCM을 `sendRealtimeAudio()`로 보내고 `incomingAudioStream`을 재생하세요 (예: `record` + `flutter_soloud`).

## Supported Models

모델 ID 문자열을 직접 쓰거나 `LiveModels` / `LiveMusicModels` 상수를 사용하세요.

### Live API (`genAI.live.connect`)

| 모델 ID | 상수 | 용도 | 상태 |
|---|---|---|---|
| `gemini-3.8-live` | `LiveModels.gemini38Live` | **기본값.** 저지연 음성·멀티모달 대화 | Stable |
| `gemini-3.8-live-extended-thinking` | `LiveModels.gemini38LiveExtendedThinking` | 심층 추론이 필요한 음성 대화 (`thinkingConfig`) | Stable |
| `gemini-3.5-live-translate-preview` | `LiveModels.gemini35LiveTranslatePreview` | 실시간 음성 번역 (`TranslationConfig`) | Preview |
| `gemini-3.1-flash-live-preview` | `LiveModels.gemini31FlashLivePreview` | 이전 세대 | Preview |
| `gemini-2.5-flash-native-audio-preview-12-2025` | `LiveModels.gemini25FlashNativeAudioPreview` | 네이티브 오디오 출력 | Preview |

### Live Music (`genAI.live.music.connect`)

| 모델 ID | 상수 | 용도 | 상태 |
|---|---|---|---|
| `models/lyria-realtime-exp` | `LiveMusicModels.lyriaRealtimeExp` | **기본값.** 실시간 음악 생성 | Experimental |

> - `thinkingConfig`는 `gemini-3.8-live-extended-thinking`에만 전달하세요. `gemini-3.8-live`에 넣으면 에러가 납니다.
> - `gemini-3.8-live`는 툴 호출을 기본적으로 non-blocking(`Behavior.NON_BLOCKING`)으로 실행합니다.
> - Live 출력 오디오는 16-bit PCM 24 kHz 모노, Lyria 출력은 16-bit PCM 48 kHz 스테레오입니다.
> - 모델 제공 현황은 바뀔 수 있습니다. 최신 상태는 [Gemini API 모델 페이지](https://ai.google.dev/gemini-api/docs/models)에서 확인하세요.

## 설치하기 (Installation)

Flutter 프로젝트에 패키지를 추가합니다:

```bash
flutter pub add gemini_live
```

Dart 코드에서 패키지를 임포트합니다:

```dart
import 'package:gemini_live/gemini_live.dart';
```

## 빠른 시작 (Quick Start)

20줄 미만의 간단한 코드로 Gemini Live 대화를 시작할 수 있습니다:

```dart
import 'package:gemini_live/gemini_live.dart';

void main() async {
  // 1. Gemini Live 클라이언트 초기화
  final genAI = GoogleGenAI(apiKey: 'YOUR_GEMINI_API_KEY', logger: print);

  // 2. Live API 연결
  final session = await genAI.live.connect(
    LiveConnectParameters(
      model: 'gemini-3.8-live',
      config: GenerationConfig(responseModalities: [Modality.TEXT]),
      callbacks: LiveCallbacks(
        onOpen: () => print('Live 세션 연결 완료!'),
        onMessage: (message) {
          if (message.text != null) {
            print('Gemini: ${message.text}');
          }
        },
        onError: (error, st) => print('에러: $error'),
        onClose: (code, reason) => print('연결 종료: $code - $reason'),
      ),
    ),
  );

  // 3. 메시지 전송
  session.sendText('안녕 Gemini, 농담 하나만 해줘!');
}
```

## 음성 대화 빠른 시작 (Voice Quick Start)

Live 앱은 대부분 음성 앱입니다. `GeminiLiveSessionController`는 오디오 데이터를 주고받기만 하고, 마이크 녹음과 소리 재생은 **하지 않습니다**. 입력은 [`record`](https://pub.dev/packages/record), 출력은 [`flutter_soloud`](https://pub.dev/packages/flutter_soloud)와 연결하세요:

```bash
flutter pub add gemini_live record flutter_soloud
```

플랫폼별 마이크 권한을 추가하세요:

| 플랫폼 | 설정 |
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

자막, 파형, Barge-in 처리까지 포함한 전체 화면 예제는 [Agent Skill 빠른 시작](skills/flutter-gemini-live/SKILL.md)과 [예제 앱](example/lib/)을 참고하세요.

> **🔐 API 키 보안:** 운영 앱에 Gemini API 키를 그대로 넣지 마세요. 백엔드에서 `genAI.authTokens.create(...)`로 수명이 짧은 **에페메럴 토큰**을 발급하고, 클라이언트는 그 토큰으로 연결하세요. [에페메럴 토큰 가이드](doc/advanced_configuration.md)와 [`examples/ephemeral_token.dart`](examples/ephemeral_token.dart)를 참고하세요.

## 상세 문서 & 가이드 (Documentation)

상세한 가이드와 API 명세는 [`doc/`](doc/) 디렉토리에 모듈별로 정리되어 있습니다:

- **[AI Agent Skill 가이드](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/SKILL.md)** ([skills/](https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/skills/README.md)): Claude Code, Gemini CLI / Antigravity, OpenAI Codex, Cursor 등 모든 AI 코딩 어시스턴트를 위한 멀티 에이전트 스킬 명세서
- **[API Reference 명세서](doc/api_reference.md)**: `GoogleGenAI`, `LiveSession`, `LiveServerMessage` 등 전체 클래스 및 메서드 명세
- **[UI 위젯 가이드 & 명세서](doc/widgets_guide.md)**: `GeminiLiveSessionController`와 모든 내장 UI 위젯 상세 사용법 및 전체 화면 예제
- **[고급 기능 설정 가이드](doc/advanced_configuration.md)**: Function Calling, VAD, 세션 재개, 오디오 전사, 실시간 텍스트/음성 번역, 그라운딩, 에페메럴 토큰 사용법
- **[에러 코드 & 트러블슈팅 명세서](doc/error_codes_specification.md)**: 발생 가능한 에러 코드, 종료 코드, `TurnCompleteReason` Enum, 트러블슈팅 가이드
- **[실행 가능한 예제 모음](examples/README.md)**: 기본 대화, 툴 호출, 카메라/오디오 스트리밍, Google Maps 그라운딩 CLI 예제

## 주요 기능 요약

* **실시간 통신**: 저지연 WebSocket 양방향 대화.
* **멀티모달 입력 & 스트리밍 출력**: 텍스트, 오디오, 카메라 프레임 입력 및 실시간 응답 스트리밍.
* **Function Calling (툴 연동)**: 동기/비동기 함수 실행 및 툴 응답 전송.
* **세션 재개 (Session Resumption)**: 끊긴 연결을 세션 핸들로 간편하게 복구.
* **Google Maps & Search 그라운딩**: 위치 및 경로 감지 답변 생성.
* **음성 활동 감지 (VAD)**: 자동 및 수동 VAD 지원.
* **실시간 음성 번역**: Speech-to-Speech 실시간 번역 (`TranslationConfig`).
* **내장 Flutter 위젯 & 컨트롤러**: `GeminiLiveSessionController`, `GeminiLiveWaveform`, `GeminiLiveCaptionBubble`, `GeminiLiveMicButton`, `GeminiLiveStatusBadge`, `GeminiLiveUsageBadge`, `GeminiLiveVoiceIndicator`.
* **Live Music (Lyria Realtime)**: `genAI.live.music`로 실시간 음악 생성 및 조정.
* **에페메럴 인증 토큰**: `genAI.authTokens`로 단기 클라이언트 토큰을 발급해 기기에 API 키를 두지 않습니다.
* **토큰 사용량 추적**: `GeminiTokenUsageTracker`로 세션별 토큰 사용량 집계.

| 데모 1: 치와와 vs 머핀 | 데모 2: 래브라두들 vs 프라이드치킨 |
| :---: | :---: |
| <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222333.png?raw=true" alt="실시간 대화 데모" width="400"/> | <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222355.png?raw=true" alt="멀티모달 데모" width="400"/> |
| *치와와 vs 머핀* | *래브라두들 vs 프라이드치킨* |

---

## 내장 UI 위젯 (Pre-built UI Widgets)

Flutter 개발자가 즉시 연동하여 사용할 수 있도록 가볍고 의존성 없는 핵심 UI 위젯을 기본 제공합니다:

```dart
// 1. 고수준 실시간 세션 컨트롤러 (ChangeNotifier 기반)
final controller = GeminiLiveSessionController(liveService: genAI.live);
await controller.connect(
  LiveConnectParameters(
    model: 'gemini-3.8-live',
    config: GenerationConfig(responseModalities: [Modality.AUDIO]),
    callbacks: LiveCallbacks(),
  ),
);

// 2. 실시간 오디오 파형 시각화기 (캡슐 알약 형태 바 & 유휴 브리딩 모션)
GeminiLiveWaveform(
  audioStream: controller.incomingAudioStream, // 또는 amplitudeStream
  barCount: 28,
  height: 64,
  color: Theme.of(context).colorScheme.primary,
  enableIdleBreathing: true,
)

// 3. 프로스티드 글래스 실시간 자막 버블 (BackdropFilter 블러 & 화자 칩)
GeminiLiveCaptionBubble(
  text: controller.latestTranscript ?? '',
  speaker: controller.latestTranscriptRole == 'user' ? '나' : 'Gemini',
  isStreaming: controller.isModelSpeaking,
  enableBlur: true,
)

// 4. 동심원 음향 리플 마이크 버튼 (M3 햅틱 터치)
GeminiLiveMicButton(
  isRecording: controller.isConnected,
  onPressed: () => toggleLiveSession(),
)

// 5. 연결 상태 배지 (펄스 헤일로 링 인디케이터)
GeminiLiveStatusBadge.fromFlags(
  isConnected: controller.isConnected,
  isConnecting: isConnecting,
)

// 6. 실시간 토큰 사용량 & 상세 모달 다이얼로그 배지
GeminiLiveUsageBadge(
  tracker: controller.tokenTracker,
)

// 7. 듀얼 하모닉 음성 활동 시각화기
GeminiLiveVoiceIndicator(
  isSpeaking: controller.isModelSpeaking,
  barCount: 5,
)
```

---

## 라이선스

이 프로젝트는 BSD 3-Clause 라이선스에 따라 제공됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
